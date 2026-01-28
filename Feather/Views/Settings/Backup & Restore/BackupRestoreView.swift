// (TODO) Fix full functionality then add to SettingsView. Update lready added but beta

import SwiftUI
import NimbleViews
import ZIPFoundation
import UniformTypeIdentifiers
import CoreData

// MARK: - Backup Options
struct BackupOptions {
	var includeCertificates: Bool = true
	var includeSignedApps: Bool = true
	var includeImportedApps: Bool = true
	var includeSources: Bool = true
}

// MARK: - View
struct BackupRestoreView: View {
	@Environment(\.dismiss) var dismiss
	@State private var isImporting = false
	@State private var showRestoreDialog = false
	@State private var pendingRestoreURL: URL?
	@State private var showBackupOptions = false
	@State private var backupOptions = BackupOptions()
	@State private var isRestoring = false
	@State private var restoreProgress: Double = 0.0
	@State private var showInvalidBackupError = false
	@State private var backupDocument: BackupDocument?
	@State private var showExporter = false
	@State private var isVerifying = false
	@AppStorage("feature_advancedBackupTools") var advancedBackupTools = false
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Backup & Restore")) {
			// Modernized Header Card
			Section {
				VStack(spacing: 0) {
					HStack(spacing: 12) {
						// Backup Card
						VStack(spacing: 16) {
							ZStack {
								Circle()
									.fill(Color.blue.opacity(0.1))
									.frame(width: 64, height: 64)
								
								Image(systemName: "arrow.up.doc.fill")
									.font(.system(size: 28, weight: .bold))
									.foregroundStyle(
										LinearGradient(
											colors: [.blue, .cyan],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							VStack(spacing: 4) {
								Text(.localized("Backup"))
									.font(.headline)
								Text(.localized("Save your data"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							
							Button {
								showBackupOptions = true
							} label: {
								Text(.localized("Create"))
									.font(.subheadline.bold())
									.foregroundStyle(.white)
									.frame(maxWidth: .infinity)
									.padding(.vertical, 10)
									.background(
										LinearGradient(
											colors: [.blue, .cyan],
											startPoint: .leading,
											endPoint: .trailing
										)
									)
									.clipShape(RoundedRectangle(cornerRadius: 12))
									.shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 3)
							}
						}
						.padding(20)
						.background(
							RoundedRectangle(cornerRadius: 24)
								.fill(.ultraThinMaterial)
								.overlay(
									RoundedRectangle(cornerRadius: 24)
										.stroke(Color.blue.opacity(0.1), lineWidth: 1)
								)
						)
						
						// Restore Card
						VStack(spacing: 16) {
							ZStack {
								Circle()
									.fill(Color.green.opacity(0.1))
									.frame(width: 64, height: 64)
								
								Image(systemName: "arrow.down.doc.fill")
									.font(.system(size: 28, weight: .bold))
									.foregroundStyle(
										LinearGradient(
											colors: [.green, .mint],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							VStack(spacing: 4) {
								Text(.localized("Restore"))
									.font(.headline)
								Text(.localized("Load a backup"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							
							Button {
								isImporting = true
							} label: {
								Text(.localized("Import"))
									.font(.subheadline.bold())
									.foregroundStyle(.white)
									.frame(maxWidth: .infinity)
									.padding(.vertical, 10)
									.background(
										LinearGradient(
											colors: [.green, .mint],
											startPoint: .leading,
											endPoint: .trailing
										)
									)
									.clipShape(RoundedRectangle(cornerRadius: 12))
									.shadow(color: .green.opacity(0.3), radius: 5, x: 0, y: 3)
							}
						}
						.padding(20)
						.background(
							RoundedRectangle(cornerRadius: 24)
								.fill(.ultraThinMaterial)
								.overlay(
									RoundedRectangle(cornerRadius: 24)
										.stroke(Color.green.opacity(0.1), lineWidth: 1)
								)
						)
					}
				}
				.listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
			}
			.listRowBackground(Color.clear)
			
			// Advanced Tools Section
			if advancedBackupTools {
				NBSection(.localized("Advanced Tools")) {
					Button {
						exportFullDatabase()
					} label: {
						Label(.localized("Export Full Database"), systemImage: "cylinder.split.1x2.fill")
					}

					Button {
						isVerifying = true
						isImporting = true
					} label: {
						Label(.localized("Verify Backup Integrity"), systemImage: "shield.checkerboard")
					}
				}
			}

			// Information sections with modern cards
			NBSection(.localized("About Backups (Beta)")) {
				infoCard(
					icon: "checkmark.shield.fill",
					iconColor: .blue,
					title: .localized("What's Included"),
					description: .localized("Backups can include certificates, provisioning profiles, signed apps, imported apps, sources, and all app settings.")
				)
				
				infoCard(
					icon: "exclamationmark.triangle.fill",
					iconColor: .orange,
					title: .localized("Important"),
					description: .localized("Restoring requires the app to restart. Certificate restoration preserves files for manual re-import if needed.")
				)
			}
		}
		.sheet(isPresented: $showBackupOptions) {
			BackupOptionsView(
				options: $backupOptions,
				onConfirm: {
					showBackupOptions = false
					if let url = prepareBackup(with: backupOptions) {
						backupDocument = BackupDocument(url: url)
						showExporter = true
					}
				}
			)
		}
		.fileExporter(
			isPresented: $showExporter,
			document: backupDocument,
			contentType: .zip,
			defaultFilename: "PortalBackup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
		) { result in
			switch result {
			case .success(let url):
				AppLogManager.shared.success("Backup exported successfully to: \(url.path)", category: "Backup & Restore")
				HapticsManager.shared.success()
			case .failure(let error):
				AppLogManager.shared.error("Failed to export backup: \(error.localizedDescription)", category: "Backup & Restore")
				HapticsManager.shared.error()
			}
			// Clean up the temporary zip file after export attempt
			if let tempURL = backupDocument?.url {
				try? FileManager.default.removeItem(at: tempURL)
			}
			backupDocument = nil
		}
		.fileImporter(
			isPresented: $isImporting,
			allowedContentTypes: [.zip],
			allowsMultipleSelection: false
		) { result in
			switch result {
			case .success(let urls):
				guard let url = urls.first else { return }
				if isVerifying {
					verifyBackup(at: url)
					isVerifying = false
				} else {
					pendingRestoreURL = url
					showRestoreDialog = true
				}
			case .failure(let error):
				AppLogManager.shared.error("Failed to import: \(error.localizedDescription)", category: "Backup & Restore")
				isVerifying = false
			}
		}
		.alert(.localized("Restart Required"), isPresented: $showRestoreDialog) {
			Button(.localized("No"), role: .cancel) {
				if let url = pendingRestoreURL {
					// Mark for deferred restore
					UserDefaults.standard.set(url.path, forKey: "pendingRestorePath")
					pendingRestoreURL = nil
				}
			}
			Button(.localized("Yes")) {
				if let url = pendingRestoreURL {
					performRestore(from: url, restart: true)
				}
			}
		} message: {
			Text(.localized("Portal has to restart in order to apply this backup, do you want to proceed?"))
		}
		.alert(.localized("Invalid Backup File"), isPresented: $showInvalidBackupError) {
			Button(.localized("OK"), role: .cancel) { }
		} message: {
			Text(.localized("Not a valid Backup file because Portal couldn't find the checker inside the file. Please upload an actual .zip file of a backup."))
		}
		.overlay {
			if isRestoring {
				RestoreLoadingOverlay(progress: restoreProgress)
			}
		}
	}
	
	// MARK: - Info Card View
	@ViewBuilder
	private func infoCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 22, weight: .semibold))
				.foregroundStyle(iconColor)
				.frame(width: 36)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.headline)
					.foregroundStyle(.primary)
				
				Text(description)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.padding(.vertical, 4)
	}
	
	// MARK: - Advanced Tools Functions
	private func verifyBackup(at url: URL) {
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

		do {
			guard url.startAccessingSecurityScopedResource() else {
				UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Permission denied for the selected file."))
				return
			}
			defer { url.stopAccessingSecurityScopedResource() }

			try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
			try FileManager.default.unzipItem(at: url, to: tempDir)

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

			let hasSettings = FileManager.default.fileExists(atPath: tempDir.appendingPathComponent("settings.plist").path)

			try? FileManager.default.removeItem(at: tempDir)

			if hasMarker && hasSettings {
				UIAlertController.showAlertWithOk(title: .localized("Verification Successful"), message: .localized("This backup file is valid and can be restored."))
			} else {
				showInvalidBackupError = true
			}
		} catch {
			UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to verify backup: \(error.localizedDescription)"))
		}
	}

	private func exportFullDatabase() {
		guard let storeURL = Storage.shared.container.persistentStoreDescriptions.first?.url else {
			UIAlertController.showAlertWithOk(title: "Error", message: "Could not find database location")
			return
		}

		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent("PortalDatabaseBackup_\(Date().timeIntervalSince1970).zip")

		do {
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

			backupDocument = BackupDocument(url: zipURL)
			showExporter = true

		} catch {
			UIAlertController.showAlertWithOk(title: "Error", message: "Failed to export database: \(error.localizedDescription)")
		}
	}

	// MARK: - Backup Functions
	private func prepareBackup(with options: BackupOptions) -> URL? {
		// Create temporary directory for backup
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		
		do {
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
				if let jsonData = try? JSONSerialization.data(withJSONObject: certMetadata) {
					try jsonData.write(to: certMetadataFile)
				}
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
				if let jsonData = try? JSONSerialization.data(withJSONObject: sourcesData) {
					try jsonData.write(to: sourcesFile)
				}
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
					
					if let jsonData = try? JSONSerialization.data(withJSONObject: appsData) {
						try jsonData.write(to: signedAppsFile)
					}
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
					
					if let jsonData = try? JSONSerialization.data(withJSONObject: appsData) {
						try jsonData.write(to: importedAppsFile)
					}
				}
			}
			
			// 5. Backup ALL settings - always included
			let settingsFile = tempDir.appendingPathComponent("settings.plist")
			let defaults = UserDefaults.standard.dictionaryRepresentation()
			// Include all Feather and app-specific settings
			let filtered = defaults.filter { key, _ in
				key.hasPrefix("Feather.") ||
				key.hasPrefix("com.apple.") ||
				(Bundle.main.bundleIdentifier.map { key.hasPrefix($0) } ?? false) ||
				// Include other common setting prefixes
				key.contains("filesTabEnabled") ||
				key.contains("showNews") ||
				key.contains("serverMethod") ||
				key.contains("customSigningAPI") ||
				key.contains("selectedCert")
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
			
		} catch {
			UIAlertController.showAlertWithOk(
				title: .localized("Error"),
				message: .localized("Failed to prepare backup: \(error.localizedDescription)")
			)
			return nil
		}
	}
	
	private func performRestore(from url: URL, restart: Bool) {
		let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
		
		// Start restore animation
		isRestoring = true
		restoreProgress = 0.0
		
		do {
			guard url.startAccessingSecurityScopedResource() else {
				isRestoring = false
				UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Permission denied for the selected file."))
				return
			}
			defer { url.stopAccessingSecurityScopedResource() }
			
			try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
			
			// Unzip backup
			withAnimation {
				restoreProgress = 0.1
			}
			try FileManager.default.unzipItem(at: url, to: tempDir)
			
			withAnimation {
				restoreProgress = 0.2
			}
			
			// VALIDATE BACKUP: Check for marker file (including legacy ones)
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
				// Clean up
				try? FileManager.default.removeItem(at: tempDir)
				isRestoring = false
				showInvalidBackupError = true
				return
			}
			
			// Additional validation: check for at least one expected file
			let settingsFile = tempDir.appendingPathComponent("settings.plist")
			let hasValidContent = FileManager.default.fileExists(atPath: settingsFile.path)
			
			if !hasValidContent {
				// Clean up
				try? FileManager.default.removeItem(at: tempDir)
				isRestoring = false
				showInvalidBackupError = true
				return
			}
			
			withAnimation {
				restoreProgress = 0.3
			}
			
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
					
					// Only restore if both files exist
					if FileManager.default.fileExists(atPath: p12URL.path),
					   FileManager.default.fileExists(atPath: provisionURL.path) {
						
						// Copy certificates to the proper storage location
						let certStorageURL = Storage.shared.documentsURL.appendingPathComponent("certificates/\(uuid).p12")
						let provisionStorageURL = Storage.shared.documentsURL.appendingPathComponent("certificates/\(uuid).mobileprovision")
						
						// Ensure certificates directory exists
						try? FileManager.default.createDirectory(
							at: Storage.shared.documentsURL.appendingPathComponent("certificates"),
							withIntermediateDirectories: true
						)
						
						try? FileManager.default.copyItem(at: p12URL, to: certStorageURL)
						try? FileManager.default.copyItem(at: provisionURL, to: provisionStorageURL)
						
						let name = certInfo["name"] as? String ?? "Restored Certificate"
						Storage.shared.addCertificate(
							uuid: uuid,
							password: certInfo["password"] as? String,
							nickname: name,
							ppq: certInfo["ppQCheck"] as? Bool ?? false,
							expiration: Date(timeIntervalSince1970: certInfo["date"] as? Double ?? Date().timeIntervalSince1970),
							completion: { _ in }
						)
						AppLogManager.shared.info("Restored certificate: \(name)", category: "Backup & Restore")
					}
				}
			}
			
			withAnimation {
				restoreProgress = 0.5
			}
			
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
			
			withAnimation {
				restoreProgress = 0.65
			}
			
			// 3. Restore signed apps with actual IPA files
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
							// Ensure signed apps directory exists
							let signedStorageDir = Storage.shared.documentsURL.appendingPathComponent("signed")
							try? FileManager.default.createDirectory(at: signedStorageDir, withIntermediateDirectories: true)
							
							let ipaDestURL = signedStorageDir.appendingPathComponent("\(uuid).ipa")
							try? FileManager.default.copyItem(at: ipaSourceURL, to: ipaDestURL)
							
							if let name = appInfo["name"] {
								Storage.shared.addSigned(
									uuid: uuid,
									appName: name,
									appIdentifier: appInfo["identifier"],
									appVersion: appInfo["version"],
									completion: { _ in }
								)
								AppLogManager.shared.info("Restored signed app: \(name)", category: "Backup & Restore")
							}
						}
					}
				}
			}
			
			withAnimation {
				restoreProgress = 0.8
			}
			
			// 4. Restore imported apps with actual IPA files
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
							// Ensure imported apps directory exists
							let importedStorageDir = Storage.shared.documentsURL.appendingPathComponent("imported")
							try? FileManager.default.createDirectory(at: importedStorageDir, withIntermediateDirectories: true)
							
							let ipaDestURL = importedStorageDir.appendingPathComponent("\(uuid).ipa")
							try? FileManager.default.copyItem(at: ipaSourceURL, to: ipaDestURL)
							
							if let name = appInfo["name"] {
								Storage.shared.addImported(
									uuid: uuid,
									appName: name,
									appIdentifier: appInfo["identifier"],
									appVersion: appInfo["version"],
									completion: { _ in }
								)
								AppLogManager.shared.info("Restored imported app: \(name)", category: "Backup & Restore")
							}
						}
					}
				}
			}
			
			withAnimation {
				restoreProgress = 0.9
			}
			
			// 5. Restore ALL settings
			if FileManager.default.fileExists(atPath: settingsFile.path) {
				let settingsData = try Data(contentsOf: settingsFile)
				if let settings = try PropertyListSerialization.propertyList(from: settingsData, options: [], format: nil) as? [String: Any] {
					for (key, value) in settings {
						// Restore all settings except system-specific ones
						if !key.hasPrefix("NS") && !key.hasPrefix("AK") && !key.hasPrefix("Apple") {
							UserDefaults.standard.set(value, forKey: key)
						}
					}
					UserDefaults.standard.synchronize()
				}
			}
			
			withAnimation {
				restoreProgress = 1.0
			}
			
			// Clean up
			try? FileManager.default.removeItem(at: tempDir)
			
			// Small delay to show completion
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				isRestoring = false
				
				if restart {
					// Restart the app
					UIAlertController.showAlertWithOk(
						title: .localized("Restore Complete"),
						message: .localized("The app will now restart to apply changes.")
					) {
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
							UIApplication.shared.suspendAndReopen()
						}
					}
				} else {
					UIAlertController.showAlertWithOk(
						title: .localized("Success"),
						message: .localized("Backup restored successfully. Changes will be applied on next restart.")
					)
				}
			}
			
		} catch {
			isRestoring = false
			UIAlertController.showAlertWithOk(
				title: .localized("Error"),
				message: .localized("Failed to restore backup: \(error.localizedDescription)")
			)
		}
	}
}

// MARK: - BackupDocument
struct BackupDocument: FileDocument {
	static var readableContentTypes: [UTType] { [.zip] }
	
	var url: URL
	
	init(url: URL) {
		self.url = url
	}
	
	init(configuration: ReadConfiguration) throws {
		// For reading, we don't need to handle this as we're only exporting
		throw CocoaError(.fileReadUnknown)
	}
	
	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		return try FileWrapper(url: url)
	}
}

// MARK: - BackupOptionsView
struct BackupOptionsView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var options: BackupOptions
	let onConfirm: () -> Void
	
	var body: some View {
		NavigationView {
			ScrollView {
				VStack(spacing: 24) {
					// Header
					VStack(spacing: 16) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 80, height: 80)
							
							Image(systemName: "square.and.arrow.up.fill")
								.font(.system(size: 40, weight: .semibold))
								.foregroundStyle(
									LinearGradient(
										gradient: Gradient(colors: [.blue, .purple]),
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
						}
						
						Text(.localized("What would you like in this Portal Backup?"))
							.font(.title2.bold())
							.multilineTextAlignment(.center)
							.padding(.horizontal)
						
						Text(.localized("Select the data you want to include in your backup"))
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal)
					}
					.padding(.top, 20)
					
					// Options
					VStack(spacing: 12) {
						backupOptionToggle(
							icon: "checkmark.seal.fill",
							iconColor: .blue,
							title: .localized("Certificates"),
							description: .localized("Your signing certificates and provisioning profiles"),
							isOn: $options.includeCertificates
						)
						
						backupOptionToggle(
							icon: "app.badge.fill",
							iconColor: .green,
							title: .localized("Signed Apps"),
							description: .localized("Apps you have signed with your certificates"),
							isOn: $options.includeSignedApps
						)
						
						backupOptionToggle(
							icon: "square.and.arrow.down.fill",
							iconColor: .orange,
							title: .localized("Imported Apps"),
							description: .localized("Apps imported from files or other sources"),
							isOn: $options.includeImportedApps
						)
						
						backupOptionToggle(
							icon: "globe.fill",
							iconColor: .purple,
							title: .localized("Sources"),
							description: .localized("Your configured app sources and repositories"),
							isOn: $options.includeSources
						)
					}
					.padding(.horizontal, 20)
					
					// Warning notice
					if options.includeSignedApps || options.includeImportedApps {
						HStack(alignment: .top, spacing: 12) {
							Image(systemName: "exclamationmark.triangle.fill")
								.font(.system(size: 20))
								.foregroundStyle(.orange)
							
							VStack(alignment: .leading, spacing: 4) {
								Text(.localized("Large Backup Size"))
									.font(.headline)
									.foregroundStyle(.primary)
								
								Text(.localized("If you include Signed and Imported Apps, this backup will be large."))
									.font(.subheadline)
									.foregroundStyle(.secondary)
									.fixedSize(horizontal: false, vertical: true)
							}
						}
						.padding(16)
						.background(Color.orange.opacity(0.1))
						.cornerRadius(12)
						.padding(.horizontal, 20)
					}
					
					// Create button
					Button {
						onConfirm()
					} label: {
						HStack {
							Image(systemName: "checkmark.circle.fill")
							Text(.localized("Create Backup"))
								.font(.headline)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(
							LinearGradient(
								gradient: Gradient(colors: [.blue, .purple]),
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.foregroundStyle(.white)
						.cornerRadius(12)
					}
					.padding(.horizontal, 20)
					.padding(.top, 8)
					
					// Cancel button
					Button {
						dismiss()
					} label: {
						Text(.localized("Cancel"))
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					.padding(.bottom, 20)
				}
			}
			.navigationTitle(.localized("Backup Options"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.system(size: 20))
							.foregroundStyle(.secondary)
					}
				}
			}
		}
		.presentationDetents([.large])
		.presentationDragIndicator(.visible)
	}
	
	@ViewBuilder
	private func backupOptionToggle(
		icon: String,
		iconColor: Color,
		title: LocalizedStringKey,
		description: LocalizedStringKey,
		isOn: Binding<Bool>
	) -> some View {
		Button {
			isOn.wrappedValue.toggle()
			HapticsManager.shared.softImpact()
		} label: {
			HStack(alignment: .top, spacing: 12) {
				ZStack {
					Circle()
						.fill(iconColor.opacity(0.15))
						.frame(width: 44, height: 44)
					
					Image(systemName: icon)
						.font(.system(size: 20, weight: .semibold))
						.foregroundStyle(iconColor)
				}
				
				VStack(alignment: .leading, spacing: 4) {
					Text(title)
						.font(.headline)
						.foregroundStyle(.primary)
					
					Text(description)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}
				
				Spacer()
				
				Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
					.font(.system(size: 24))
					.foregroundStyle(isOn.wrappedValue ? .blue : .gray.opacity(0.3))
			}
			.padding(16)
			.background(Color(uiColor: .secondarySystemGroupedBackground))
			.cornerRadius(12)
		}
		.buttonStyle(.plain)
	}
}

// MARK: - RestoreLoadingOverlay
struct RestoreLoadingOverlay: View {
	let progress: Double
	@State private var rotation: Double = 0
	
	var body: some View {
		ZStack {
			// Blurred background
			Color.black.opacity(0.5)
				.ignoresSafeArea()
			
			// Card
			VStack(spacing: 24) {
				// Animated icon
				ZStack {
					Circle()
						.fill(
							LinearGradient(
								colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 100, height: 100)
					
					Circle()
						.stroke(Color.green.opacity(0.3), lineWidth: 4)
						.frame(width: 100, height: 100)
						.rotationEffect(.degrees(rotation))
					
					Image(systemName: "arrow.down.circle.fill")
						.font(.system(size: 50))
						.foregroundStyle(
							LinearGradient(
								colors: [.green, .green.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
				}
				
				// Text
				VStack(spacing: 8) {
					Text("Restoring Backup")
						.font(.title2.bold())
						.foregroundStyle(.white)
					
					Text("Please wait while we restore your data...")
						.font(.subheadline)
						.foregroundStyle(.white.opacity(0.8))
						.multilineTextAlignment(.center)
				}
				
				// Progress bar
				VStack(spacing: 8) {
					GeometryReader { geometry in
						ZStack(alignment: .leading) {
							// Background
							RoundedRectangle(cornerRadius: 8)
								.fill(Color.white.opacity(0.2))
								.frame(height: 8)
							
							// Progress
							RoundedRectangle(cornerRadius: 8)
								.fill(
									LinearGradient(
										colors: [.green, .green.opacity(0.8)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.frame(width: geometry.size.width * progress, height: 8)
								.animation(.easeInOut(duration: 0.3), value: progress)
						}
					}
					.frame(height: 8)
					
					Text("\(Int(progress * 100))%")
						.font(.caption)
						.foregroundStyle(.white.opacity(0.8))
				}
			}
			.padding(32)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.fill(Color(uiColor: .systemBackground))
					.opacity(0.95)
			)
			.padding(.horizontal, 40)
			.shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
		}
		.onAppear {
			withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
				rotation = 360
			}
		}
	}
}

