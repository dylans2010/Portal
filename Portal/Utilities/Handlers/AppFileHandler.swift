// made by dylan

import Foundation
import Zip
import SwiftUI
import OSLog

final class AppFileHandler: NSObject, @unchecked Sendable {
	private let _fileManager = FileManager.default
	private let _uuid = UUID().uuidString
	private let _uniqueWorkDir: URL
	var uniqueWorkDirPayload: URL?

	private var _ipa: URL
	private let _install: Bool
	private let _download: Download?
	
	init(
		file ipa: URL,
		install: Bool = false,
		download: Download? = nil
	) {
		self._ipa = ipa
		self._install = install
		self._download = download
		self._uniqueWorkDir = _fileManager.temporaryDirectory
			.appendingPathComponent("FeatherImport_\(_uuid)", isDirectory: true)
		
		super.init()
		Logger.misc.debug("Import initiated for: \(self._ipa.lastPathComponent) with ID: \(self._uuid)")
	}
	
	func copy() async throws {
		// Start Live Activity if enabled
		if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
			LiveActivityManager.shared.startActivity(
				appName: _ipa.lastPathComponent,
				bundleId: "com.feather.import",
				appVersion: "1.0"
			)

			await LiveActivityManager.shared.updateActivity(
				progress: 0.1,
				bytesDownloaded: 0,
				totalBytes: 0,
				status: .preparing
			)
		}

		try _fileManager.createDirectoryIfNeeded(at: _uniqueWorkDir)
		
		let destinationURL = _uniqueWorkDir.appendingPathComponent(_ipa.lastPathComponent)

		try _fileManager.removeFileIfNeeded(at: destinationURL)
		
		try _fileManager.copyItem(at: _ipa, to: destinationURL)
		_ipa = destinationURL
		Logger.misc.info("[\(self._uuid)] File copied to: \(self._ipa.path)")
	}
	
	func extract() async throws {
		if _ipa.pathExtension == "ipa" {
			Zip.addCustomFileExtension("ipa")
		}
		if _ipa.pathExtension == "tipa" {
			Zip.addCustomFileExtension("tipa")
		}
		
		let download = self._download
		
		try await withCheckedThrowingContinuation { continuation in
			DispatchQueue.global(qos: .utility).async {
				do {
					try Zip.unzipFile(
						self._ipa,
						destination: self._uniqueWorkDir,
						overwrite: true,
						password: nil,
						progress: { progress in
							if let download = download {
								DispatchQueue.main.async {
									download.unpackageProgress = progress
								}
							}
						}
					)
					
					self.uniqueWorkDirPayload = self._uniqueWorkDir.appendingPathComponent("Payload")
					continuation.resume()
				} catch {
					continuation.resume(throwing: error)
				}
			}
		}
		
		// Load default frameworks after extraction
		try await loadDefaultFrameworks()
	}
	
	/// Load default frameworks into the extracted app
	private func loadDefaultFrameworks() async throws {
		guard let payloadURL = uniqueWorkDirPayload else {
			return
		}
		
		// Find the .app directory
		guard let appURL = _fileManager.getPath(in: payloadURL, for: "app") else {
			Logger.misc.warning("[\(self._uuid)] Could not find .app directory, skipping default frameworks")
			return
		}
		
		// Get default frameworks
		let dylibURLs = try await DefaultFrameworksManager.shared.extractDylibsFromFrameworks()
		
		guard !dylibURLs.dylibURLs.isEmpty else {
			Logger.misc.info("[\(self._uuid)] No default frameworks to load")
			return
		}
		
		Logger.misc.info("[\(self._uuid)] Loading \(dylibURLs.dylibURLs.count) default framework(s)")
		AppLogManager.shared.info("Loading \(dylibURLs.dylibURLs.count) default framework(s) into app", category: "DefaultFrameworks")
		
		// Create Frameworks directory if needed
		let frameworksDir = appURL.appendingPathComponent("Frameworks")
		try _fileManager.createDirectoryIfNeeded(at: frameworksDir)
		
		// Copy dylibs to app
		var successCount = 0
		for dylibURL in dylibURLs.dylibURLs {
			do {
				let destURL = frameworksDir.appendingPathComponent(dylibURL.lastPathComponent)
				
				// Remove existing file if present
				try? _fileManager.removeItem(at: destURL)
				
				// Copy dylib
				try _fileManager.copyItem(at: dylibURL, to: destURL)
				
				Logger.misc.info("[\(self._uuid)] Loaded default framework: \(dylibURL.lastPathComponent)")
				successCount += 1
			} catch {
				Logger.misc.error("[\(self._uuid)] Failed to load default framework \(dylibURL.lastPathComponent): \(error.localizedDescription)")
				AppLogManager.shared.error("Failed to load default framework \(dylibURL.lastPathComponent): \(error.localizedDescription)", category: "DefaultFrameworks", errorCode: .FILE_NOT_FOUND)
				// Continue with other frameworks
			}
		}
		
		if successCount > 0 {
			AppLogManager.shared.success("Successfully loaded \(successCount) default framework(s)", category: "DefaultFrameworks")
		}
	}
	
	func move() async throws {
		guard let payloadURL = uniqueWorkDirPayload else {
			throw ImportedFileHandlerError.payloadNotFound
		}
		
		let destinationURL = try await _directory()
		
		guard _fileManager.fileExists(atPath: payloadURL.path) else {
			throw ImportedFileHandlerError.payloadNotFound
		}
		
		try _fileManager.moveItem(at: payloadURL, to: destinationURL)
		Logger.misc.info("[\(self._uuid)] Moved Payload to: \(destinationURL.path)")
		
		try? _fileManager.removeItem(at: _uniqueWorkDir)
	}
	
	func addToDatabase() async throws {
		let app = try await _directory()
		
		guard let appUrl = _fileManager.getPath(in: app, for: "app") else {
			Logger.misc.error("[\(self._uuid)] Failed to find .app directory in Payload")
			AppLogManager.shared.error("Failed to find .app directory in Payload", category: "Import", errorCode: .APP_NOT_FOUND)
			return
		}
		
		let bundle = Bundle(url: appUrl)
		
		// Log bundle information for debugging
		Logger.misc.info("[\(self._uuid)] Bundle info - name: \(bundle?.name ?? "nil"), identifier: \(bundle?.bundleIdentifier ?? "nil"), version: \(bundle?.version ?? "nil")")
		
		if bundle?.name == nil {
			Logger.misc.warning("[\(self._uuid)] Could not extract app name from bundle")
			AppLogManager.shared.warning("Could not extract app name from bundle, using default", category: "Import")
		}
		
		Storage.shared.addImported(
			uuid: _uuid,
			appName: bundle?.name,
			appIdentifier: bundle?.bundleIdentifier,
			appVersion: bundle?.version,
			appIcon: bundle?.iconFileName
		) { error in
			if #available(iOS 16.2, *) {
				if error == nil {
					LiveActivityManager.shared.endActivityWithSuccess()
				} else {
					LiveActivityManager.shared.endActivityWithError()
				}
			}

			if let error = error {
				Logger.misc.error("[\(self._uuid)] Failed to add to database: \(error.localizedDescription)")
				AppLogManager.shared.error("Failed to add app to database: \(error.localizedDescription)", category: "Import", errorCode: .DB_ERR)
			} else {
				Logger.misc.info("[\(self._uuid)] Successfully added to database")
			}
		}
	}
	
	private func _directory() async throws -> URL {
		// Documents/Feather/Unsigned/\(UUID)
		_fileManager.unsigned(_uuid)
	}
	
	func clean() async throws {
		try _fileManager.removeFileIfNeeded(at: _uniqueWorkDir)
	}
}

private enum ImportedFileHandlerError: Error {
	case payloadNotFound
}
