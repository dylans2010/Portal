import Foundation
import OSLog

// MARK: - DefaultFrameworksManager
/// Manages persistent default framework files (.dylib, .deb) that are automatically loaded into apps during signing
class DefaultFrameworksManager: ObservableObject {
	static let shared = DefaultFrameworksManager()
	
	@Published var frameworks: [URL] = []
	private let _fileManager = FileManager.default
	private let _frameworksDirectory: URL
	
	private init() {
		// Store frameworks in Documents/Portal/DefaultFrameworks
		_frameworksDirectory = _fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
			.appendingPathComponent("Feather", isDirectory: true)
			.appendingPathComponent("DefaultFrameworks", isDirectory: true)

		try? _fileManager.createDirectoryIfNeeded(at: _frameworksDirectory)

		loadFrameworks()
	}
	
	func loadFrameworks() {
		do {
			let contents = try _fileManager.contentsOfDirectory(
				at: _frameworksDirectory,
				includingPropertiesForKeys: nil,
				options: [.skipsHiddenFiles]
			)
			frameworks = contents.filter { url in
				let ext = url.pathExtension.lowercased()
				return ext == "dylib" || ext == "deb"
			}.sorted { $0.lastPathComponent < $1.lastPathComponent }
		} catch {
			Logger.misc.warning("Failed to load default frameworks: \(error.localizedDescription)")
			frameworks = []
		}
	}
	
	func addFramework(_ url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				
				try self._fileManager.createDirectoryIfNeeded(at: self._frameworksDirectory)
				
				var destinationURL = self._frameworksDirectory.appendingPathComponent(url.lastPathComponent)
				var counter = 1
				while self._fileManager.fileExists(atPath: destinationURL.path) {
					let baseName = url.deletingPathExtension().lastPathComponent
					let ext = url.pathExtension
					destinationURL = self._frameworksDirectory.appendingPathComponent("\(baseName)_\(counter).\(ext)")
					counter += 1
				}
				
				try self._fileManager.copyItem(at: url, to: destinationURL)
				
				Logger.misc.info("Added default framework: \(destinationURL.lastPathComponent)")
				AppLogManager.shared.success("Added default framework: \(destinationURL.lastPathComponent)", category: "DefaultFrameworks")
				
				DispatchQueue.main.async {
					self.loadFrameworks()
					completion(.success(destinationURL))
				}
			} catch {
				Logger.misc.error("Failed to add default framework: \(error.localizedDescription)")
				AppLogManager.shared.error("Failed to add default framework: \(error.localizedDescription)", category: "DefaultFrameworks")
				DispatchQueue.main.async {
					completion(.failure(error))
				}
			}
		}
	}
	
	func removeFramework(_ url: URL, completion: @escaping () -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			do {
				try self._fileManager.removeItem(at: url)
				Logger.misc.info("Removed default framework: \(url.lastPathComponent)")
				AppLogManager.shared.success("Removed default framework: \(url.lastPathComponent)", category: "DefaultFrameworks")
				
				DispatchQueue.main.async {
					self.loadFrameworks()
					completion()
				}
			} catch {
				Logger.misc.error("Failed to remove default framework: \(error.localizedDescription)")
				AppLogManager.shared.error("Failed to remove default framework: \(error.localizedDescription)", category: "DefaultFrameworks")
				DispatchQueue.main.async {
					completion()
				}
			}
		}
	}
	

	func extractDylibsFromFrameworks() async throws -> (dylibURLs: [URL], tempDir: URL) {
		var dylibURLs: [URL] = []
		let tempDir = _fileManager.temporaryDirectory.appendingPathComponent("DefaultFrameworks_\(UUID().uuidString)", isDirectory: true)
		
		try _fileManager.createDirectoryIfNeeded(at: tempDir)
		
		for frameworkURL in frameworks {
			let ext = frameworkURL.pathExtension.lowercased()
			
			switch ext {
			case "dylib":

				let destURL = tempDir.appendingPathComponent(frameworkURL.lastPathComponent)
				try? _fileManager.copyItem(at: frameworkURL, to: destURL)
				dylibURLs.append(destURL)
				
			case "deb":
				// Extract dylibs from deb
				let extractedDylibs = try await extractDylibsFromDeb(frameworkURL, to: tempDir)
				dylibURLs.append(contentsOf: extractedDylibs)
				
			default:
				Logger.misc.warning("Unsupported default framework type: \(ext)")
			}
		}
		
		return (dylibURLs, tempDir)
	}
	

	private func extractDylibsFromDeb(_ debURL: URL, to outputDir: URL) async throws -> [URL] {
		var dylibURLs: [URL] = []
		
		let uniqueSubDir = outputDir.appendingPathComponent(UUID().uuidString)
		try _fileManager.createDirectoryIfNeeded(at: uniqueSubDir)
		
		// Extract deb using AR handler
		let handler = AR(with: debURL)
		let arFiles = try await handler.extract()
		
		for arFile in arFiles {
			let outputPath = uniqueSubDir.appendingPathComponent(arFile.name)
			try arFile.content.write(to: outputPath)
			
			if ["data.tar.lzma", "data.tar.gz", "data.tar.xz", "data.tar.bz2"].contains(arFile.name) {
				var fileToProcess = outputPath
				try extractFile(at: &fileToProcess)
				try extractFile(at: &fileToProcess)
				
				let foundDylibs = try await searchForDylibs(in: fileToProcess)
				dylibURLs.append(contentsOf: foundDylibs)
			}
		}
		
		if dylibURLs.isEmpty {
			Logger.misc.warning("No .dylib files found in deb: \(debURL.lastPathComponent)")
		} else {
			Logger.misc.info("Extracted \(dylibURLs.count) .dylib file(s) from: \(debURL.lastPathComponent)")
		}
		
		return dylibURLs
	}
	
	private func searchForDylibs(in directory: URL) async throws -> [URL] {
		var dylibURLs: [URL] = []
		
		guard _fileManager.fileExists(atPath: directory.path) else {
			return dylibURLs
		}
		
		let searchPaths = [
			"Library/Frameworks/",
			"var/jb/Library/Frameworks/",
			"Library/MobileSubstrate/DynamicLibraries/",
			"var/jb/Library/MobileSubstrate/DynamicLibraries/"
		]
		
		for searchPath in searchPaths {
			let fullPath = directory.appendingPathComponent(searchPath)
			if _fileManager.fileExists(atPath: fullPath.path) {
				let foundDylibs = try findDylibsInDirectory(fullPath)
				dylibURLs.append(contentsOf: foundDylibs)
			}
		}
		
		return dylibURLs
	}
	
	private func findDylibsInDirectory(_ directory: URL) throws -> [URL] {
		let contents = try _fileManager.contentsOfDirectory(
			at: directory,
			includingPropertiesForKeys: nil,
			options: []
		)
		
		return contents.filter { url in
			let attributes = try? _fileManager.attributesOfItem(atPath: url.path)
			let isSymlink = attributes?[.type] as? FileAttributeType == .typeSymbolicLink
			return url.pathExtension.lowercased() == "dylib" && !isSymlink
		}
	}
}
