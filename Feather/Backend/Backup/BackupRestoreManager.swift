import SwiftUI
import ZIPFoundation
import UniformTypeIdentifiers
import CoreData
import NimbleViews

// MARK: - Backup Options
public struct BackupOptions {
	public var includeCertificates: Bool = true
	public var includeSignedApps: Bool = true
	public var includeImportedApps: Bool = true
	public var includeSources: Bool = true
	public var includeDefaultFrameworks: Bool = true

	public init() {}
}

// MARK: - Backup Document
public struct BackupDocument: FileDocument {
	public static var readableContentTypes: [UTType] { [.zip] }

	public var url: URL

	public init(url: URL) {
		self.url = url
	}

	public init(configuration: ReadConfiguration) throws {
		throw CocoaError(.fileReadUnknown)
	}

	public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		return try FileWrapper(url: url)
	}
}

// MARK: - Backup Manager
public final class BackupRestoreManager: ObservableObject {
	public static let shared = BackupRestoreManager()

	@Published public var isRestoring = false
	@Published public var restoreProgress: Double = 0.0
	@Published public var isVerifying = false

	private init() {}

	// MARK: - Backup Logic
	public func prepareBackup(with options: BackupOptions) async throws -> URL {
		// Create temporary directory for backup
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

		try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

		// 1. Backup certificates with full metadata (if selected)
		if options.includeCertificates {
			let certificatesDir = tempDir.appendingPathComponent("certificates")
			try? FileManager.default.createDirectory(at: certificatesDir, withIntermediateDirectories: true)
			let certificates = Storage.shared.getAllCertificates()
			var certMetadata: [[String: Any]] = []

			for cert in certificates {
				if let uuid = cert.uuid {
					var metadata: [String: Any] = ["uuid": uuid]

					// Save certificate file
					if let certURL = Storage.shared.getFile(.certificate, from: cert),
					   let certData = try? Data(contentsOf: certURL) {
						let destURL = certificatesDir.appendingPathComponent("\(uuid).p12")
						try certData.write(to: destURL)
						metadata["hasP12"] = true
					}

					// Save provisioning profile
					if let provisionURL = Storage.shared.getFile(.provision, from: cert),
					   let provisionData = try? Data(contentsOf: provisionURL) {
						let destURL = certificatesDir.appendingPathComponent("\(uuid).mobileprovision")
						try provisionData.write(to: destURL)
						metadata["hasProvision"] = true
					}

					// Save metadata
					if let provisionData = Storage.shared.getProvisionFileDecoded(for: cert) {
						metadata["name"] = provisionData.Name
						if let teamID = provisionData.TeamIdentifier.first {
							metadata["teamID"] = teamID
						}
						metadata["teamName"] = provisionData.TeamName
					}
					if let date = cert.date { metadata["date"] = date.timeIntervalSince1970 }
					metadata["ppQCheck"] = cert.ppQCheck
					if let password = cert.password { metadata["password"] = password }

					certMetadata.append(metadata)
				}
			}

			// Save certificate metadata
			let certMetadataFile = tempDir.appendingPathComponent("certificates_metadata.json")
			let jsonData = try JSONSerialization.data(withJSONObject: certMetadata)
			try jsonData.write(to: certMetadataFile)
		}

		// 2. Backup sources (if selected)
		if options.includeSources {
			let sourcesFile = tempDir.appendingPathComponent("sources.json")
			let sources = Storage.shared.getSources()
			let sourcesData = sources.compactMap { source -> [String: String]? in
				guard let urlString = source.sourceURL?.absoluteString,
					  let name = source.name,
					  let identifier = source.identifier else { return nil }
				return ["url": urlString, "name": name, "identifier": identifier]
			}
			let jsonData = try JSONSerialization.data(withJSONObject: sourcesData)
			try jsonData.write(to: sourcesFile)
		}

		// 3. Backup signed apps (if selected)
		if options.includeSignedApps {
			let signedAppsFile = tempDir.appendingPathComponent("signed_apps.json")
			let signedAppsDir = tempDir.appendingPathComponent("signed_apps")
			try? FileManager.default.createDirectory(at: signedAppsDir, withIntermediateDirectories: true)

			let fetchRequest = Signed.fetchRequest()
			if let signedApps = try? Storage.shared.context.fetch(fetchRequest) {
				var appsData: [[String: String]] = []

				for app in signedApps {
					guard let uuid = app.uuid else { continue }
					var data: [String: String] = ["uuid": uuid]
					if let name = app.name { data["name"] = name }
					if let identifier = app.identifier { data["identifier"] = identifier }
					if let version = app.version { data["version"] = version }

					// Copy actual IPA file if it exists
					let signedDir = FileManager.default.signed(uuid)
					if let ipaURL = FileManager.default.getPath(in: signedDir, for: "ipa"),
					   FileManager.default.fileExists(atPath: ipaURL.path) {
						let destURL = signedAppsDir.appendingPathComponent("\(uuid).ipa")
						try? FileManager.default.copyItem(at: ipaURL, to: destURL)
						data["hasIPA"] = "true"
					}

					appsData.append(data)
				}

				let jsonData = try JSONSerialization.data(withJSONObject: appsData)
				try jsonData.write(to: signedAppsFile)
			}
		}

		// 4. Backup imported apps (if selected)
		if options.includeImportedApps {
			let importedAppsFile = tempDir.appendingPathComponent("imported_apps.json")
			let importedAppsDir = tempDir.appendingPathComponent("imported_apps")
			try? FileManager.default.createDirectory(at: importedAppsDir, withIntermediateDirectories: true)

			let fetchRequest = Imported.fetchRequest()
			if let importedApps = try? Storage.shared.context.fetch(fetchRequest) {
				var appsData: [[String: String]] = []

				for app in importedApps {
					guard let uuid = app.uuid else { continue }
					var data: [String: String] = ["uuid": uuid]
					if let name = app.name { data["name"] = name }
					if let identifier = app.identifier { data["identifier"] = identifier }
					if let version = app.version { data["version"] = version }

					// Copy actual IPA file if it exists
					let importedDir = FileManager.default.unsigned(uuid)
					if let ipaURL = FileManager.default.getPath(in: importedDir, for: "ipa"),
					   FileManager.default.fileExists(atPath: ipaURL.path) {
						let destURL = importedAppsDir.appendingPathComponent("\(uuid).ipa")
						try? FileManager.default.copyItem(at: ipaURL, to: destURL)
						data["hasIPA"] = "true"
					}

					appsData.append(data)
				}

				let jsonData = try JSONSerialization.data(withJSONObject: appsData)
				try jsonData.write(to: importedAppsFile)
			}
		}

		// 4.5 Backup default frameworks (if selected)
		if options.includeDefaultFrameworks {
			let defaultFrameworksDir = tempDir.appendingPathComponent("default_frameworks")
			try? FileManager.default.createDirectory(at: defaultFrameworksDir, withIntermediateDirectories: true)

			let sourceDFDir = Storage.shared.documentsURL.appendingPathComponent("Feather/DefaultFrameworks")
			if FileManager.default.fileExists(atPath: sourceDFDir.path) {
				let contents = try? FileManager.default.contentsOfDirectory(at: sourceDFDir, includingPropertiesForKeys: nil)
				for fileURL in contents ?? [] {
					try? FileManager.default.copyItem(at: fileURL, to: defaultFrameworksDir.appendingPathComponent(fileURL.lastPathComponent))
				}
			}
		}

		// 4.6 Backup archives (if selected)
		if options.includeSignedApps {
			let archivesDir = tempDir.appendingPathComponent("archives")
			try? FileManager.default.createDirectory(at: archivesDir, withIntermediateDirectories: true)

			let sourceArchivesDir = FileManager.default.archives
			if FileManager.default.fileExists(atPath: sourceArchivesDir.path) {
				let contents = try? FileManager.default.contentsOfDirectory(at: sourceArchivesDir, includingPropertiesForKeys: nil)
				for fileURL in contents ?? [] {
					try? FileManager.default.copyItem(at: fileURL, to: archivesDir.appendingPathComponent(fileURL.lastPathComponent))
				}
			}
		}

		// 4.7 Backup pairing and SSL files (always included as part of state)
		let filesToBackup = ["pairingFile.plist", "server.pem", "server.crt", "commonName.txt"]
		let extraFilesDir = tempDir.appendingPathComponent("extra_files")
		try? FileManager.default.createDirectory(at: extraFilesDir, withIntermediateDirectories: true)

		for fileName in filesToBackup {
			let fileURL = Storage.shared.documentsURL.appendingPathComponent(fileName)
			if FileManager.default.fileExists(atPath: fileURL.path) {
				try? FileManager.default.copyItem(at: fileURL, to: extraFilesDir.appendingPathComponent(fileName))
			}
		}

		// 4.8 Backup Core Data database
		let databaseDir = tempDir.appendingPathComponent("database")
		try? FileManager.default.createDirectory(at: databaseDir, withIntermediateDirectories: true)

		if let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
			let baseName = storeURL.lastPathComponent
			let directory = storeURL.deletingLastPathComponent()
			let dbFiles = [baseName, "\(baseName)-shm", "\(baseName)-wal"]

			for dbFile in dbFiles {
				let fileURL = directory.appendingPathComponent(dbFile)
				if FileManager.default.fileExists(atPath: fileURL.path) {
					try? FileManager.default.copyItem(at: fileURL, to: databaseDir.appendingPathComponent(dbFile))
				}
			}
		}

		// 5. Backup ALL settings - always included
		let settingsFile = tempDir.appendingPathComponent("settings.plist")
		let defaults = UserDefaults.standard.dictionaryRepresentation()
		// Include all Feather and app-specific settings
		let filtered = defaults.filter { key, _ in
			!key.hasPrefix("NS") &&
			!key.hasPrefix("AK") &&
			!key.hasPrefix("Apple") &&
			!key.hasPrefix("WebKit") &&
			!key.hasPrefix("CPU") &&
			!key.hasPrefix("metal")
		}
		let settingsData = try PropertyListSerialization.data(fromPropertyList: filtered, format: .xml, options: 0)
		try settingsData.write(to: settingsFile)

		// 6. Create zip file with validation marker
		let tempBackupDir = FileManager.default.temporaryDirectory.appendingPathComponent("Backups")
		try? FileManager.default.createDirectory(at: tempBackupDir, withIntermediateDirectories: true)

		let backupFileName = "PortalBackup_\(UUID().uuidString).zip"
		let finalZipURL = tempBackupDir.appendingPathComponent(backupFileName)

		// Remove existing file if present
		try? FileManager.default.removeItem(at: finalZipURL)

		// Add a backup marker file to validate later
		let markerFile = tempDir.appendingPathComponent("PORTAL_BACKUP_MARKER.txt")
		let markerContent = "PORTAL_BACKUP_v1.0_\(Date().timeIntervalSince1970)"
		try markerContent.write(to: markerFile, atomically: true, encoding: .utf8)

		try FileManager.default.zipItem(at: tempDir, to: finalZipURL, shouldKeepParent: false)

		// Clean up temp directory
		try? FileManager.default.removeItem(at: tempDir)

		return finalZipURL
	}

	// MARK: - Restore Logic
	public func performRestore(from url: URL, restart: Bool) async throws {
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

		await MainActor.run {
			isRestoring = true
			restoreProgress = 0.0
		}

		defer {
			try? FileManager.default.removeItem(at: tempDir)
			Task { @MainActor in
				isRestoring = false
			}
		}

		try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

		await MainActor.run { restoreProgress = 0.1 }
		try FileManager.default.unzipItem(at: url, to: tempDir)

		await MainActor.run { restoreProgress = 0.2 }

		// VALIDATE BACKUP
		let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
		let hasMarker = markers.contains { marker in
			let path = tempDir.appendingPathComponent(marker).path
			if FileManager.default.fileExists(atPath: path) {
				if let content = try? String(contentsOfFile: path, encoding: .utf8),
				   (content.contains("PORTAL_BACKUP") || content.contains("FEATHER_BACKUP")) {
					return true
				}
			}
			return false
		}

		guard hasMarker else {
			throw NSError(domain: "BackupManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid backup file: Missing marker."])
		}

		let settingsFile = tempDir.appendingPathComponent("settings.plist")
		guard FileManager.default.fileExists(atPath: settingsFile.path) else {
			throw NSError(domain: "BackupManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid backup file: Missing settings."])
		}

		await MainActor.run { restoreProgress = 0.3 }

		// 1. Restore certificates with metadata
		let certificatesDir = tempDir.appendingPathComponent("certificates")
		let certMetadataFile = tempDir.appendingPathComponent("certificates_metadata.json")

		if FileManager.default.fileExists(atPath: certMetadataFile.path),
		   let jsonData = try? Data(contentsOf: certMetadataFile),
		   let metadata = try? JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] {

			for certInfo in metadata {
				guard let uuid = certInfo["uuid"] as? String else { continue }

				let p12URL = certificatesDir.appendingPathComponent("\(uuid).p12")
				let provisionURL = certificatesDir.appendingPathComponent("\(uuid).mobileprovision")

				if FileManager.default.fileExists(atPath: p12URL.path),
				   FileManager.default.fileExists(atPath: provisionURL.path) {

					let certStorageURL = Storage.shared.documentsURL.appendingPathComponent("certificates/\(uuid).p12")
					let provisionStorageURL = Storage.shared.documentsURL.appendingPathComponent("certificates/\(uuid).mobileprovision")

					try? FileManager.default.createDirectory(
						at: Storage.shared.documentsURL.appendingPathComponent("certificates"),
						withIntermediateDirectories: true
					)

					if FileManager.default.fileExists(atPath: certStorageURL.path) { try? FileManager.default.removeItem(at: certStorageURL) }
					if FileManager.default.fileExists(atPath: provisionStorageURL.path) { try? FileManager.default.removeItem(at: provisionStorageURL) }

					try FileManager.default.copyItem(at: p12URL, to: certStorageURL)
					try FileManager.default.copyItem(at: provisionURL, to: provisionStorageURL)

					let name = certInfo["name"] as? String ?? "Restored Certificate"
					Storage.shared.addCertificate(
						uuid: uuid,
						password: certInfo["password"] as? String,
						nickname: name,
						ppq: certInfo["ppQCheck"] as? Bool ?? false,
						expiration: Date(timeIntervalSince1970: certInfo["date"] as? Double ?? Date().timeIntervalSince1970),
						completion: { _ in }
					)
				}
			}
		}

		await MainActor.run { restoreProgress = 0.5 }

		// 2. Restore sources
		let sourcesFile = tempDir.appendingPathComponent("sources.json")
		if FileManager.default.fileExists(atPath: sourcesFile.path) {
			let jsonData = try Data(contentsOf: sourcesFile)
			if let sources = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]] {
				for source in sources {
					if let urlString = source["url"],
					   let sourceURL = URL(string: urlString),
					   let name = source["name"] {
						let identifier = source["identifier"] ?? sourceURL.absoluteString
						Storage.shared.addSource(
							sourceURL,
							name: name,
							identifier: identifier,
							completion: { _ in }
						)
					}
				}
			}
		}

		await MainActor.run { restoreProgress = 0.65 }

		// 3. Restore signed apps
		let signedAppsFile = tempDir.appendingPathComponent("signed_apps.json")
		let signedAppsDir = tempDir.appendingPathComponent("signed_apps")
		if FileManager.default.fileExists(atPath: signedAppsFile.path) {
			let jsonData = try Data(contentsOf: signedAppsFile)
			if let appsData = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]] {
				for appInfo in appsData {
					guard let uuid = appInfo["uuid"],
						  let hasIPA = appInfo["hasIPA"],
						  hasIPA == "true" else { continue }

					let ipaSourceURL = signedAppsDir.appendingPathComponent("\(uuid).ipa")
					if FileManager.default.fileExists(atPath: ipaSourceURL.path) {
						let signedStorageDir = Storage.shared.documentsURL.appendingPathComponent("signed")
						try? FileManager.default.createDirectory(at: signedStorageDir, withIntermediateDirectories: true)

						let ipaDestURL = signedStorageDir.appendingPathComponent("\(uuid).ipa")
						if FileManager.default.fileExists(atPath: ipaDestURL.path) { try? FileManager.default.removeItem(at: ipaDestURL) }
						try? FileManager.default.copyItem(at: ipaSourceURL, to: ipaDestURL)

						if let name = appInfo["name"] {
							Storage.shared.addSigned(
								uuid: uuid,
								appName: name,
								appIdentifier: appInfo["identifier"],
								appVersion: appInfo["version"],
								completion: { _ in }
							)
						}
					}
				}
			}
		}

		await MainActor.run { restoreProgress = 0.8 }

		// 4. Restore imported apps
		let importedAppsFile = tempDir.appendingPathComponent("imported_apps.json")
		let importedAppsDir = tempDir.appendingPathComponent("imported_apps")
		if FileManager.default.fileExists(atPath: importedAppsFile.path) {
			let jsonData = try Data(contentsOf: importedAppsFile)
			if let appsData = try JSONSerialization.jsonObject(with: jsonData) as? [[String: String]] {
				for appInfo in appsData {
					guard let uuid = appInfo["uuid"],
						  let hasIPA = appInfo["hasIPA"],
						  hasIPA == "true" else { continue }

					let ipaSourceURL = importedAppsDir.appendingPathComponent("\(uuid).ipa")
					if FileManager.default.fileExists(atPath: ipaSourceURL.path) {
						let importedStorageDir = Storage.shared.documentsURL.appendingPathComponent("imported")
						try? FileManager.default.createDirectory(at: importedStorageDir, withIntermediateDirectories: true)

						let ipaDestURL = importedStorageDir.appendingPathComponent("\(uuid).ipa")
						if FileManager.default.fileExists(atPath: ipaDestURL.path) { try? FileManager.default.removeItem(at: ipaDestURL) }
						try? FileManager.default.copyItem(at: ipaSourceURL, to: ipaDestURL)

						if let name = appInfo["name"] {
							Storage.shared.addImported(
								uuid: uuid,
								appName: name,
								appIdentifier: appInfo["identifier"],
								appVersion: appInfo["version"],
								completion: { _ in }
							)
						}
					}
				}
			}
		}

		// 4.5 Restore default frameworks
		let defaultFrameworksDir = tempDir.appendingPathComponent("default_frameworks")
		if FileManager.default.fileExists(atPath: defaultFrameworksDir.path) {
			let destDFDir = Storage.shared.documentsURL.appendingPathComponent("Feather/DefaultFrameworks")
			try? FileManager.default.createDirectory(at: destDFDir, withIntermediateDirectories: true)

			let contents = try? FileManager.default.contentsOfDirectory(at: defaultFrameworksDir, includingPropertiesForKeys: nil)
			for fileURL in contents ?? [] {
				let destURL = destDFDir.appendingPathComponent(fileURL.lastPathComponent)
				if FileManager.default.fileExists(atPath: destURL.path) {
					try? FileManager.default.removeItem(at: destURL)
				}
				try? FileManager.default.copyItem(at: fileURL, to: destURL)
			}
		}

		// 4.6 Restore archives
		let archivesDir = tempDir.appendingPathComponent("archives")
		if FileManager.default.fileExists(atPath: archivesDir.path) {
			let destArchivesDir = FileManager.default.archives
			try? FileManager.default.createDirectory(at: destArchivesDir, withIntermediateDirectories: true)

			let contents = try? FileManager.default.contentsOfDirectory(at: archivesDir, includingPropertiesForKeys: nil)
			for fileURL in contents ?? [] {
				let destURL = destArchivesDir.appendingPathComponent(fileURL.lastPathComponent)
				if FileManager.default.fileExists(atPath: destURL.path) {
					try? FileManager.default.removeItem(at: destURL)
				}
				try? FileManager.default.copyItem(at: fileURL, to: destURL)
			}
		}

		// 4.7 Restore pairing and SSL files
		let extraFilesDir = tempDir.appendingPathComponent("extra_files")
		if FileManager.default.fileExists(atPath: extraFilesDir.path) {
			let contents = try? FileManager.default.contentsOfDirectory(at: extraFilesDir, includingPropertiesForKeys: nil)
			for fileURL in contents ?? [] {
				let destURL = Storage.shared.documentsURL.appendingPathComponent(fileURL.lastPathComponent)
				if FileManager.default.fileExists(atPath: destURL.path) {
					try? FileManager.default.removeItem(at: destURL)
				}
				try? FileManager.default.copyItem(at: fileURL, to: destURL)
			}
		}

		// 4.8 Restore database
		let databaseDirInBackup = tempDir.appendingPathComponent("database")
		if FileManager.default.fileExists(atPath: databaseDirInBackup.path),
		   let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url {
			let baseName = storeURL.lastPathComponent
			let directory = storeURL.deletingLastPathComponent()
			let dbFiles = [baseName, "\(baseName)-shm", "\(baseName)-wal"]

			for dbFile in dbFiles {
				let srcURL = databaseDirInBackup.appendingPathComponent(dbFile)
				let destURL = directory.appendingPathComponent(dbFile)
				if FileManager.default.fileExists(atPath: srcURL.path) {
					if FileManager.default.fileExists(atPath: destURL.path) {
						try? FileManager.default.removeItem(at: destURL)
					}
					try? FileManager.default.copyItem(at: srcURL, to: destURL)
				}
			}
		}

		await MainActor.run { restoreProgress = 0.9 }

		// 5. Restore settings
		if FileManager.default.fileExists(atPath: settingsFile.path) {
			let settingsData = try Data(contentsOf: settingsFile)
			if let settings = try PropertyListSerialization.propertyList(from: settingsData, options: [], format: nil) as? [String: Any] {
				for (key, value) in settings {
					if !key.hasPrefix("NS") && !key.hasPrefix("AK") && !key.hasPrefix("Apple") {
						UserDefaults.standard.set(value, forKey: key)
					}
				}
				UserDefaults.standard.synchronize()
			}
		}

		await MainActor.run {
			restoreProgress = 1.0
		}

		if restart {
			try? await Task.sleep(nanoseconds: 500_000_000)
			await MainActor.run {
				UIApplication.shared.suspendAndReopen()
			}
		}
	}

	public func verifyBackup(at url: URL) async throws -> Bool {
		await MainActor.run { isVerifying = true }
		defer { Task { @MainActor in isVerifying = false } }

		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
		defer { try? FileManager.default.removeItem(at: tempDir) }

		try FileManager.default.unzipItem(at: url, to: tempDir)

		let markers = ["PORTAL_BACKUP_MARKER.txt", "FEATHER_BACKUP_MARKER.txt", "PORTAL_BACKUP_CHECKER.txt"]
		let hasMarker = markers.contains { marker in
			FileManager.default.fileExists(atPath: tempDir.appendingPathComponent(marker).path)
		}

		let hasSettings = FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("settings.plist").path)

		return hasMarker && hasSettings
	}

	public func exportFullDatabase() async throws -> URL {
		guard let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url else {
			throw NSError(domain: "BackupManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not find database location"])
		}

		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalDatabaseBackup_\(Date().timeIntervalSince1970).zip")

		try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

		// Copy SQLite files (including SHM and WAL)
		let baseName = storeURL.lastPathComponent
		let directory = storeURL.deletingLastPathComponent()

		let filesToCopy = [baseName, "\(baseName)-shm", "\(baseName)-wal"]
		for fileName in filesToCopy {
			let fileURL = directory.appendingPathComponent(fileName)
			if FileManager.default.fileExists(atPath: fileURL.path) {
				try FileManager.default.copyItem(at: fileURL, to: tempDir.appendingPathComponent(fileName))
			}
		}

		try FileManager.default.zipItem(at: tempDir, to: zipURL, shouldKeepParent: false)
		try? FileManager.default.removeItem(at: tempDir)

		return zipURL
	}
}
