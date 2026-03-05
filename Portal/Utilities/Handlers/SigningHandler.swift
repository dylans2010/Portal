import Foundation
import Zsign
import UIKit
import OSLog

final class SigningHandler: NSObject {
	private let _fileManager = FileManager.default
	private let _uuid = UUID().uuidString
	private var _movedAppPath: URL?
	// using uuid string is the best way to find the
	// app we want to sign, it does not matter what
	// type of app it is
	private var _app: AppInfoPresentable
	private var _options: Options
	private let _uniqueWorkDir: URL
	// the options struct is not gonna decode these so
	// we're just going to do this. If appicon is not
	// specified, we're not going to modify the app
	// icon. If the cert pair is not there, fallback
	// to adhoc signing (if the option is on, otherwise
	// throw an error
	var appIcon: UIImage?
	var appCertificate: CertificatePair?
	
	// Static thresholds for risk analysis and app size detection
	private static let executableSizeLargeThreshold: Int64 = 50 * 1_000_000    // 50 MB
	private static let executableSizeMediumThreshold: Int64 = 15 * 1_000_000   // 15 MB
	private static let minimumRecentIOSVersion: Int = 16
	private static let riskScoreHighThreshold: Int = 60
	private static let riskScoreMediumThreshold: Int = 40
	private static let riskScoreLowThreshold: Int = 20
	
	// Static character set for PPQ protection - reused across instances for efficiency
	private static let ppqCharacterSet: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
	
	// Common App Store bundle ID prefixes for Dynamic Protection
	private static let appStoreBundleIDPrefixes: Set<String> = [
		"com.apple.",
		"com.facebook.",
		"com.burbn.", // Instagram
		"com.google.",
		"com.microsoft.",
		"com.amazon.",
		"com.netflix.",
		"com.spotify.",
		"com.twitter.",
		"com.snapchat.",
		"com.zhiliaoapp.", // TikTok
		"com.reddit.",
		"com.discord.",
		"com.whatsapp.",
		"com.telegram.",
		"com.zoom.",
		"com.skype.",
		"com.linkedin.",
		"com.pinterest.",
		"com.yelp.",
		"com.uber.",
		"com.lyft.",
		"com.airbnb.",
		"com.paypal.",
		"com.venmo.",
		"com.squareup.", // Cash App
		"com.robinhood.",
		"com.coinbase.",
		"com.dropbox.",
		"com.evernote.",
		"com.adobe.",
		"com.canva.",
		"com.grammarly.",
		"com.duolingo.",
		"com.khanacademy.",
		"com.coursera.",
		"com.udemy.",
		"com.twitch.",
		"com.google.ios.youtube", // YouTube (specific)
		"com.hulu.",
		"com.disneyplus.",
		"com.hbomax.",
		"com.paramount.",
		"com.peacock.",
		"com.espn.",
		"com.mlb.",
		"com.nba.",
		"com.nfl.",
		"com.ea.",
		"com.roblox.",
		"com.epicgames.",
		"com.minecraft.",
		"com.supercell.",
		"com.rovio.",
		"com.zynga.",
		"com.king.",
		"com.niantic.",
		"com.activision.",
		"com.blizzard."
	]
	
	// Helper method to check if a bundle ID matches App Store apps
	private static func isAppStoreBundleID(_ bundleID: String) -> Bool {
		return appStoreBundleIDPrefixes.contains { bundleID.hasPrefix($0) }
	}
	
	init(app: AppInfoPresentable, options: Options = OptionsManager.shared.options) {
		self._app = app
		self._options = options
		self._uniqueWorkDir = _fileManager.temporaryDirectory
			.appendingPathComponent("FeatherSigning_\(_uuid)", isDirectory: true)
		super.init()
	}
	
	func copy() async throws {
		AppLogManager.shared.info("Starting copy operation for app: \(_app.name ?? "Unknown")", category: "Signing")
		
		guard let appUrl = Storage.shared.getAppDirectory(for: _app) else {
			AppLogManager.shared.error("App not found in storage", category: "Signing", errorCode: .APP_NOT_FOUND)
			throw SigningFileHandlerError.appNotFound
		}

		try _fileManager.createDirectoryIfNeeded(at: _uniqueWorkDir)
		
		let movedAppURL = _uniqueWorkDir.appendingPathComponent(appUrl.lastPathComponent)
		
		try _fileManager.copyItem(at: appUrl, to: movedAppURL)
		_movedAppPath = movedAppURL
		Logger.misc.info("[\(self._uuid)] Moved Payload to: \(movedAppURL.path)")
		AppLogManager.shared.success("Successfully copied app to working directory", category: "Signing")
	}
	
	func modify() async throws {
		AppLogManager.shared.info("Starting modification phase", category: "Signing")
		
		// Start Live Activity if enabled
		if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
			let iconData = appIcon?.pngData()
			LiveActivityManager.shared.startActivity(
				appName: _options.appName ?? _app.name ?? "App",
				bundleId: _options.appIdentifier ?? _app.identifier ?? "unknown",
				appVersion: _options.appVersion ?? _app.version,
				iconData: iconData
			)

			// Update status to preparing
			Task {
				await LiveActivityManager.shared.updateActivity(
					progress: 0.1,
					bytesDownloaded: 0,
					totalBytes: 0,
					status: .preparing
				)
			}
		}

		guard let movedAppPath = _movedAppPath else {
			AppLogManager.shared.error("App path not found during modification", category: "Signing", errorCode: .APP_NOT_FOUND)
			throw SigningFileHandlerError.appNotFound
		}
		
		guard
			let infoDictionary = NSDictionary(
				contentsOf: movedAppPath.appendingPathComponent("Info.plist")
			)!.mutableCopy() as? NSMutableDictionary
		else {
			AppLogManager.shared.error("Info.plist not found or invalid", category: "Signing", errorCode: .MISSING_PLIST)
			throw SigningFileHandlerError.infoPlistNotFound
		}
		
		AppLogManager.shared.info("Applying modifications to app bundle", category: "Signing")
		
		if _options.supportBigApps {
			AppLogManager.shared.info("Large App Support enabled: Optimizing for 3GB+ IPA...", category: "Signing")
			// NOTE: Large app support ensures that the signing process can handle
			// binaries larger than 3GB by using optimized file handling and
			// providing additional memory headroom where possible.
		}

		// Get the original bundle identifier before any modifications
		let originalIdentifier = infoDictionary["CFBundleIdentifier"] as? String
		
		// Apply PPQ Protection or Dynamic Protection if enabled
		// These options are mutually exclusive in the UI, but we check both for defensive programming
		var modifiedIdentifier = _options.appIdentifier
		var shouldApplyProtection = false
		
		if _options.dynamicProtection {
			// Dynamic Protection: only apply to App Store bundle IDs
			if let baseIdentifier = modifiedIdentifier ?? originalIdentifier {
				if Self.isAppStoreBundleID(baseIdentifier) {
					shouldApplyProtection = true
					AppLogManager.shared.info("Dynamic Protection: Bundle ID matches App Store pattern, applying protection", category: "Signing")
				} else {
					AppLogManager.shared.info("Dynamic Protection: Bundle ID does not match App Store pattern, skipping protection", category: "Signing")
				}
			}
		} else if _options.ppqProtection {
			// Regular PPQ Protection: apply to all apps
			shouldApplyProtection = true
		}
		
		if shouldApplyProtection, let baseIdentifier = modifiedIdentifier ?? originalIdentifier {
			// Generate a 7-character random string using static character set
			let randomSuffix = String((0..<7).compactMap { _ in Self.ppqCharacterSet.randomElement() })
			modifiedIdentifier = "\(baseIdentifier).\(randomSuffix)"
			AppLogManager.shared.info("PPQ Protection enabled: Appending random suffix to Bundle ID: \(randomSuffix)", category: "Signing")
		}
		
		// Apply Dynamic Protection if enabled
		if _options.dynamicProtection,
		   let analysisIdentifier = originalIdentifier ?? modifiedIdentifier {
			// Use the original bundle identifier for analysis (not the modified one)
			// to ensure high-profile apps are correctly detected
			let protectionLevel = try _analyzeBundleForProtection(infoDictionary: infoDictionary, bundleIdentifier: analysisIdentifier, appPath: movedAppPath)
			
			// Apply protection to the current identifier (which may already be modified by PPQ)
			let baseIdentifier = modifiedIdentifier ?? originalIdentifier
			
			switch protectionLevel {
			case .high:
				// High-risk apps get full randomization with timestamp component
				// Use modulo to get a unique 32-bit value without Y2038 overflow concerns
				if let base = baseIdentifier {
					let timeValue = UInt64(Date().timeIntervalSince1970) % 0x100000000
					let timestamp = String(format: "%08X", timeValue)
					let randomSuffix = String((0..<8).compactMap { _ in Self.ppqCharacterSet.randomElement() })
					modifiedIdentifier = "\(base).\(timestamp).\(randomSuffix)"
					AppLogManager.shared.info("Dynamic Protection (HIGH): Applied timestamp and randomization to Bundle ID", category: "Signing")
				}
				
			case .medium:
				// Medium-risk apps get moderate randomization
				if let base = baseIdentifier {
					let randomSuffix = String((0..<10).compactMap { _ in Self.ppqCharacterSet.randomElement() })
					modifiedIdentifier = "\(base).\(randomSuffix)"
					AppLogManager.shared.info("Dynamic Protection (MEDIUM): Applied extended randomization to Bundle ID", category: "Signing")
				}
				
			case .low:
				// Low-risk apps get basic randomization
				if let base = baseIdentifier {
					let randomSuffix = String((0..<6).compactMap { _ in Self.ppqCharacterSet.randomElement() })
					modifiedIdentifier = "\(base).\(randomSuffix)"
					AppLogManager.shared.info("Dynamic Protection (LOW): Applied basic randomization to Bundle ID", category: "Signing")
				}
				
			case .none:
				// No protection needed
				AppLogManager.shared.info("Dynamic Protection: No additional protection required for this app", category: "Signing")
			}
		} else if _options.dynamicProtection {
			// Dynamic Protection enabled but no bundle identifier available
			AppLogManager.shared.warning("Dynamic Protection: No bundle identifier available for analysis", category: "Signing")
		}
		
		if
			let identifier = modifiedIdentifier,
			let oldIdentifier = originalIdentifier
		{
			AppLogManager.shared.info("Changing bundle identifier from \(oldIdentifier) to \(identifier)", category: "Signing")
			try await _modifyPluginIdentifiers(old: oldIdentifier, new: identifier, for: movedAppPath)
		}
		
		// Update options with the modified identifier for further processing
		var updatedOptions = _options
		if let identifier = modifiedIdentifier {
			updatedOptions.appIdentifier = identifier
		}
		
		try await _modifyDict(using: infoDictionary, with: updatedOptions, to: movedAppPath)
		
		if let icon = appIcon {
			AppLogManager.shared.info("Applying custom app icon", category: "Signing")
			try await _modifyDict(using: infoDictionary, for: icon, to: movedAppPath)
		}
		
		if let name = _options.appName {
			AppLogManager.shared.info("Changing app name to \(name)", category: "Signing")
			try await _modifyLocalesForName(name, for: movedAppPath)
		}
		
		if !_options.removeFiles.isEmpty {
			AppLogManager.shared.info("Removing \(_options.removeFiles.count) files", category: "Signing")
			try await _removeFiles(for: movedAppPath, from: _options.removeFiles)
		}
		
		try await _removePresetFiles(for: movedAppPath)
		try await _removeWatchIfNeeded(for: movedAppPath)
		
		if _options.experiment_supportLiquidGlass {
			AppLogManager.shared.info("Applying LiquidGlass support", category: "Signing")

			if #available(iOS 16.2, *) {
				await LiveActivityManager.shared.updateActivity(
					progress: 0.4,
					bytesDownloaded: 0,
					totalBytes: 0,
					status: .verifying
				)
			}

			try await _locateMachosAndChangeToSDK26(for: movedAppPath)
		}
		
		if _options.experiment_replaceSubstrateWithEllekit {
			AppLogManager.shared.info("Replacing Substrate with Ellekit", category: "Signing")
			try await _inject(for: movedAppPath, with: _options)
		} else {
			if !_options.injectionFiles.isEmpty {
				AppLogManager.shared.info("Injecting \(_options.injectionFiles.count) files", category: "Signing")
				try await _inject(for: movedAppPath, with: _options)
			}
		}
		
		// iOS "26" (19) needs special treatment
		if #available(iOS 19, *) {
			AppLogManager.shared.info("Applying iOS 19 arm64e fixups", category: "Signing")
			try await _locateMachosAndFixupArm64eSlice(for: movedAppPath)
		}
		
		let handler = ZsignHandler(appUrl: movedAppPath, options: _options, cert: appCertificate)
		try await handler.disinject()
		
		if
			_options.signingOption == .default,
			appCertificate != nil
		{
			AppLogManager.shared.info("Starting code signing with certificate", category: "Signing")

			if #available(iOS 16.2, *) {
				await LiveActivityManager.shared.updateActivity(
					progress: 0.6,
					bytesDownloaded: 0,
					totalBytes: 0,
					status: .signing
				)
			}

			try await handler.sign()
			AppLogManager.shared.success("Code signing completed successfully", category: "Signing")
//		} else if _options.signingOption == .adhoc {
//			try await handler.adhocSign()
		} else if _options.signingOption == .onlyModify {
			AppLogManager.shared.info("Skipping signing (only modify mode)", category: "Signing")
		} else {
			AppLogManager.shared.error("No certificate available for signing", category: "Signing", errorCode: .MISSING_CERT)
			throw SigningFileHandlerError.missingCertifcate
		}
		
		if #available(iOS 16.2, *) {
			await LiveActivityManager.shared.updateActivity(
				progress: 0.9,
				bytesDownloaded: 0,
				totalBytes: 0,
				status: .rezipping
			)
		}

		try await self.move()
		try await self.addToDatabase()
		
		// End Live Activity with success
		if #available(iOS 16.2, *) {
			LiveActivityManager.shared.endActivityWithSuccess()
		}

		if let error = handler.hadError {
			AppLogManager.shared.error("Signing failed: \(error.localizedDescription)", category: "Signing", errorCode: .SIGN_FAILED)
			throw error
		}
		
		AppLogManager.shared.success("App modification and signing completed successfully", category: "Signing", errorCode: .SIGN_SUCCESS)
	}
	
	func move() async throws {
		AppLogManager.shared.info("Moving signed app to final location", category: "Signing")
		
		guard let movedAppPath = _movedAppPath else {
			AppLogManager.shared.error("App path not found during move", category: "Signing", errorCode: .APP_NOT_FOUND)
			throw SigningFileHandlerError.appNotFound
		}
		
		var destinationURL = try await _directory()
		
		try _fileManager.createDirectoryIfNeeded(at: destinationURL)
		
		destinationURL = destinationURL.appendingPathComponent(movedAppPath.lastPathComponent)
		
		try _fileManager.moveItem(at: movedAppPath, to: destinationURL)
		Logger.misc.info("[\(self._uuid)] Moved App to: \(destinationURL.path)")
		AppLogManager.shared.success("App moved to: \(destinationURL.lastPathComponent)", category: "Signing")
		
		try? _fileManager.removeItem(at: _uniqueWorkDir)
	}
	
	func addToDatabase() async throws {
		AppLogManager.shared.info("Adding signed app to database", category: "Signing")
		
		let app = try await _directory()
		
		guard let appUrl = _fileManager.getPath(in: app, for: "app") else {
			AppLogManager.shared.warning("Could not find app path in signed directory", category: "Signing")
			return
		}
		
		await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
			let bundle = Bundle(url: appUrl)
			
			Storage.shared.addSigned(
				uuid: _uuid,
				certificate: _options.signingOption != .default ? nil : appCertificate,
				appName: bundle?.name,
				appIdentifier: bundle?.bundleIdentifier,
				appVersion: bundle?.version,
				appIcon: bundle?.iconFileName
			) { _ in
				Logger.signing.info("[\(self._uuid)] Added to database")
				AppLogManager.shared.success("App successfully added to library: \(bundle?.name ?? "Unknown")", category: "Signing")
				continuation.resume()
			}
		}
	}
	
	private func _directory() async throws -> URL {
		// Documents/Feather/Signed/\(UUID)
		_fileManager.signed(_uuid)
	}
	
	func clean() async throws {
		try _fileManager.removeFileIfNeeded(at: _uniqueWorkDir)
	}
	
	// Main sign method that orchestrates the signing process
	func sign() async throws -> URL {
		AppLogManager.shared.info("Starting signing process for: \(_app.name ?? "Unknown")", category: "Signing")
		
		do {
			try await copy()
			try await modify()
			
			// Return the signed app URL
			guard let signedAppPath = try await _getSignedAppURL() else {
				AppLogManager.shared.error("Failed to get signed app URL", category: "Signing", errorCode: .APP_NOT_FOUND)
				throw SigningFileHandlerError.appNotFound
			}
			
			AppLogManager.shared.success("Successfully signed app: \(_app.name ?? "Unknown")", category: "Signing", errorCode: .SIGN_SUCCESS)
			return signedAppPath
		} catch {
			AppLogManager.shared.error("Signing process failed: \(error.localizedDescription)", category: "Signing", errorCode: .SIGN_FAILED)
			throw error
		}
	}
	
	private func _getSignedAppURL() async throws -> URL? {
		let signedDir = try await _directory()
		return _fileManager.getPath(in: signedDir, for: "ipa")
	}
}

extension SigningHandler {
	private func _modifyDict(using infoDictionary: NSMutableDictionary, with options: Options, to app: URL) async throws {
		if options.fileSharing { infoDictionary.setObject(true, forKey: "UISupportsDocumentBrowser" as NSCopying) }
		if options.itunesFileSharing { infoDictionary.setObject(true, forKey: "UIFileSharingEnabled" as NSCopying) }
		if options.proMotion { infoDictionary.setObject(true, forKey: "CADisableMinimumFrameDurationOnPhone" as NSCopying) }
		if options.gameMode { infoDictionary.setObject(true, forKey: "GCSupportsGameMode" as NSCopying)}
		if options.ipadFullscreen { infoDictionary.setObject(true, forKey: "UIRequiresFullScreen" as NSCopying) }
		if options.removeURLScheme {
			infoDictionary.removeObject(forKey: "CFBundleURLTypes")
		} else if !options.customURLSchemes.isEmpty {
			var urlTypes = (infoDictionary["CFBundleURLTypes"] as? [[String: Any]]) ?? []

			if urlTypes.isEmpty {
				urlTypes.append([
					"CFBundleURLName": options.appIdentifier ?? "Custom Schemes",
					"CFBundleURLSchemes": options.customURLSchemes
				])
			} else {
				// Add to the first one or create new one? Usually adding to first one is fine
				var firstType = urlTypes[0]
				var schemes = (firstType["CFBundleURLSchemes"] as? [String]) ?? []
				for newScheme in options.customURLSchemes {
					if !schemes.contains(newScheme) {
						schemes.append(newScheme)
					}
				}
				firstType["CFBundleURLSchemes"] = schemes
				urlTypes[0] = firstType
			}

			infoDictionary["CFBundleURLTypes"] = urlTypes
		}

		if !options.removedCapabilities.isEmpty {
			if let capabilities = infoDictionary["UIRequiredDeviceCapabilities"] as? [String] {
				let filtered = capabilities.filter { !options.removedCapabilities.contains($0) }
				infoDictionary["UIRequiredDeviceCapabilities"] = filtered
			} else if let capabilities = infoDictionary["UIRequiredDeviceCapabilities"] as? [String: Bool] {
				let mutableCapabilities = NSMutableDictionary(dictionary: capabilities)
				for key in options.removedCapabilities {
					mutableCapabilities.removeObject(forKey: key)
				}
				infoDictionary["UIRequiredDeviceCapabilities"] = mutableCapabilities
			}
		}
		
		if options.appAppearance != .default {
			infoDictionary.setObject(options.appAppearance.rawValue, forKey: "UIUserInterfaceStyle" as NSCopying)
		}
		if options.minimumAppRequirement != .default {
			infoDictionary.setObject(options.minimumAppRequirement.rawValue, forKey: "MinimumOSVersion" as NSCopying)
		}
		
		// useless crap
		if infoDictionary["UISupportedDevices"] != nil {
			infoDictionary.removeObject(forKey: "UISupportedDevices")
		}
		
		// MARK: Prominant values
		
		if let customIdentifier = options.appIdentifier {
			infoDictionary.setObject(customIdentifier, forKey: "CFBundleIdentifier" as NSCopying)
		}
		if let customName = options.appName {
			infoDictionary.setObject(customName, forKey: "CFBundleDisplayName" as NSCopying)
			infoDictionary.setObject(customName, forKey: "CFBundleName" as NSCopying)
		}
		if let customVersion = options.appVersion {
			infoDictionary.setObject(customVersion, forKey: "CFBundleShortVersionString" as NSCopying)
			infoDictionary.setObject(customVersion, forKey: "CFBundleVersion" as NSCopying)
		}
		
		// MARK: Custom Info.plist Entries
		
		// Apply custom Info.plist entries from options
		for (key, anyCodableValue) in options.customInfoPlistEntries {
			infoDictionary.setObject(anyCodableValue.value, forKey: key as NSCopying)
			AppLogManager.shared.info("Applied custom Info.plist entry: \(key) = \(anyCodableValue.value)", category: "Signing")
		}
		
		// Import from custom Info.plist file if provided
		if let customPlistURL = options.customInfoPlistFile {
			if let customPlist = NSDictionary(contentsOf: customPlistURL) {
				for (key, value) in customPlist {
					if let stringKey = key as? String {
						infoDictionary.setObject(value, forKey: stringKey as NSCopying)
						AppLogManager.shared.info("Applied custom Info.plist entry from file: \(stringKey)", category: "Signing")
					}
				}
			}
		}
		
		try infoDictionary.write(to: app.appendingPathComponent("Info.plist"))
	}
	
	private func _modifyDict(using infoDictionary: NSMutableDictionary, for image: UIImage, to app: URL) async throws {
		let imageSizes = [
			(width: 120, height: 120, name: "FRIcon60x60@2x.png"),
			(width: 152, height: 152, name: "FRIcon76x76@2x~ipad.png")
		]
		
		for imageSize in imageSizes {
			let resizedImage = image.resize(imageSize.width, imageSize.height)
			let imageData = resizedImage.pngData()
			let fileURL = app.appendingPathComponent(imageSize.name)
			
			try imageData?.write(to: fileURL)
		}
		
		let cfBundleIcons: [String: Any] = [
			"CFBundlePrimaryIcon": [
				"CFBundleIconFiles": ["FRIcon60x60"],
				"CFBundleIconName": "FRIcon"
			]
		]
		
		let cfBundleIconsIpad: [String: Any] = [
			"CFBundlePrimaryIcon": [
				"CFBundleIconFiles": ["FRIcon60x60", "FRIcon76x76"],
				"CFBundleIconName": "FRIcon"
			]
		]
		
		infoDictionary["CFBundleIcons"] = cfBundleIcons
		infoDictionary["CFBundleIcons~ipad"] = cfBundleIconsIpad
		
		try infoDictionary.write(to: app.appendingPathComponent("Info.plist"))
	}
	
	private func _modifyLocalesForName(_ name: String, for app: URL) async throws {
		let localizationBundles = try _fileManager
			.contentsOfDirectory(at: app, includingPropertiesForKeys: nil)
			.filter { $0.pathExtension == "lproj" }
		
		localizationBundles.forEach { bundleURL in
			let plistURL = bundleURL.appendingPathComponent("InfoPlist.strings")
			
			guard
				_fileManager.fileExists(atPath: plistURL.path),
				let dictionary = NSMutableDictionary(contentsOf: plistURL)
			else {
				return
			}
			
			dictionary["CFBundleDisplayName"] = name
			dictionary.write(toFile: plistURL.path, atomically: true)
		}
	}
	
	private func _modifyPluginIdentifiers(
		old oldIdentifier: String,
		new newIdentifier: String,
		for app: URL
	) async throws {
		let pluginBundles = _enumerateFiles(at: app) {
			$0.hasSuffix(".app") || $0.hasSuffix(".appex")
		}
		
		for bundleURL in pluginBundles {
			let infoPlistURL = bundleURL.appendingPathComponent("Info.plist")
			
			guard let infoDict = NSDictionary(contentsOf: infoPlistURL)?.mutableCopy() as? NSMutableDictionary else {
				continue
			}
			
			var didChange = false
			
			// CFBundleIdentifier
			if let oldValue = infoDict["CFBundleIdentifier"] as? String {
				let newValue = oldValue.replacingOccurrences(of: oldIdentifier, with: newIdentifier)
				if oldValue != newValue {
					infoDict["CFBundleIdentifier"] = newValue
					didChange = true
				}
			}
			
			// WKCompanionAppBundleIdentifier
			if let oldValue = infoDict["WKCompanionAppBundleIdentifier"] as? String {
				let newValue = oldValue.replacingOccurrences(of: oldIdentifier, with: newIdentifier)
				if oldValue != newValue {
					infoDict["WKCompanionAppBundleIdentifier"] = newValue
					didChange = true
				}
			}
			if let extensionDict = (infoDict["NSExtension"] as? NSDictionary)?.mutableCopy() as? NSMutableDictionary {
				// NSExtension → NSExtensionAttributes → WKAppBundleIdentifier
				if
					let attributes = extensionDict["NSExtensionAttributes"] as? NSMutableDictionary,
					let oldValue = attributes["WKAppBundleIdentifier"] as? String
				{
					let newValue = oldValue.replacingOccurrences(of: oldIdentifier, with: newIdentifier)
					if oldValue != newValue {
						attributes["WKAppBundleIdentifier"] = newValue
						didChange = true
					}
				}
                
				// NSExtension → NSExtensionFileProviderDocumentGroup
				if
					let oldValue = extensionDict["NSExtensionFileProviderDocumentGroup"] as? String
				{
					let newValue = oldValue.replacingOccurrences(of: oldIdentifier, with: newIdentifier)
					if oldValue != newValue {
						extensionDict["NSExtensionFileProviderDocumentGroup"] = newValue
						didChange = true
					}
				}
                
                infoDict["NSExtension"] = extensionDict
			}
			
			if didChange {
				infoDict.write(to: infoPlistURL, atomically: true)
			}
		}
	}
	
	private func _removePresetFiles(for app: URL) async throws {
		var files = [
			"embedded.mobileprovision", // Remove this because zsign doesn't replace it
			"com.apple.WatchPlaceholder", // Useless
			"SignedByEsign" // Useless
		].map {
			app.appendingPathComponent($0)
		}
		
		await files += try _locateCodeSignatureDirectories(for: app)
		
		for file in files {
			try _fileManager.removeFileIfNeeded(at: file)
		}
	}
	
	// horrible edge-case
	private func _removeWatchIfNeeded(for app: URL) async throws {
		let watchDir = app.appendingPathComponent("Watch")
		guard _fileManager.fileExists(atPath: watchDir.path) else { return }
		
		let contents = try _fileManager.contentsOfDirectory(at: watchDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
		
		for app in contents where app.pathExtension == "app" {
			let infoPlist = app.appendingPathComponent("Info.plist")
			if !_fileManager.fileExists(atPath: infoPlist.path) {
				try? _fileManager.removeItem(at: app)
			}
		}
	}
	
	private func _removeFiles(for app: URL, from appendingComponent: [String]) async throws {
		let filesToRemove = appendingComponent.map {
			app.appendingPathComponent($0)
		}
		
		for url in filesToRemove {
			try _fileManager.removeFileIfNeeded(at: url)
		}
	}
	
	private func _inject(for app: URL, with options: Options) async throws {
		let handler = TweakHandler(app: app, options: options)
		try await handler.getInputFiles()
	}
	
	private func _locateMachosAndChangeToSDK26(for app: URL) async throws {
		if let url = Bundle(url: app)?.executableURL {
			LCPatchMachOForSDK26(app.appendingPathComponent(url.relativePath).relativePath)
		}
	}
	
	private func _locateCodeSignatureDirectories(for app: URL) async throws -> [URL] {
		_enumerateFiles(at: app) { $0.hasSuffix("_CodeSignature") }
	}
	
	@available(iOS 16.0, *)
	private func _locateMachosAndFixupArm64eSlice(for app: URL) async throws {
		let machoFiles = _enumerateFiles(at: app) {
			$0.hasSuffix(".dylib") || $0.hasSuffix(".framework")
		}
		
		for fileURL in machoFiles {
			switch fileURL.pathExtension {
			case "dylib":
				LCPatchMachOFixupARM64eSlice(fileURL.path)
			case "framework":
				if
					let bundle = Bundle(url: fileURL),
					let execURL = bundle.executableURL
				{
					LCPatchMachOFixupARM64eSlice(execURL.path)
				}
			default:
				continue
			}
		}
	}
	
	private func _enumerateFiles(at base: URL, where predicate: (String) -> Bool) -> [URL] {
		guard let fileEnum = _fileManager.enumerator(atPath: base.path()) else {
			return []
		}
		
		var results: [URL] = []
		
		while let file = fileEnum.nextObject() as? String {
			if predicate(file) {
				results.append(base.appendingPathComponent(file))
			}
		}
		
		return results
	}
	
	// MARK: - Dynamic Protection Analysis
	
	/// Protection levels for Dynamic Protection
	private enum ProtectionLevel {
		case high    // Popular/high-profile apps requiring maximum protection
		case medium  // Apps with moderate risk characteristics
		case low     // Basic apps with minimal risk
		case none    // Apps that don't need additional protection
	}
	
	/// Analyzes an app bundle to determine the appropriate protection level
	/// Uses multiple heuristics instead of hardcoded bundle IDs for more flexibility
	private func _analyzeBundleForProtection(infoDictionary: NSDictionary, bundleIdentifier: String, appPath: URL) throws -> ProtectionLevel {
		var riskScore = 0
		
		// 1. Analyze bundle identifier patterns (high-profile domains)
		let popularDomains = [
			"com.google", "com.facebook", "com.apple", "com.twitter", "com.instagram",
			"com.tiktok", "com.snapchat", "com.spotify", "com.netflix", "com.amazon",
			"com.microsoft", "com.discord", "com.reddit", "com.youtube", "com.whatsapp",
			"com.telegram", "com.uber", "com.lyft", "com.paypal", "com.venmo",
			"com.linkedin", "com.pinterest", "com.tumblr", "com.twitch", "com.slack"
		]
		
		for domain in popularDomains {
			if bundleIdentifier.lowercased().contains(domain) {
				riskScore += 30
				AppLogManager.shared.debug("High-profile domain detected: \(domain)", category: "Signing")
				break
			}
		}
		
		// 2. Check for social media indicators in bundle display name
		if let displayName = infoDictionary["CFBundleDisplayName"] as? String ?? infoDictionary["CFBundleName"] as? String {
			let socialKeywords = ["social", "chat", "messenger", "message", "video", "photo", "camera", "share"]
			let lowercaseDisplayName = displayName.lowercased()
			
			for keyword in socialKeywords {
				if lowercaseDisplayName.contains(keyword) {
					riskScore += 5
				}
			}
		}
		
		// 3. Analyze URL schemes - apps with many URL schemes are often high-profile
		if let urlTypes = infoDictionary["CFBundleURLTypes"] as? [[String: Any]] {
			// Count total schemes across all URL types (not just URL type count)
			var totalSchemes = 0
			for urlType in urlTypes {
				if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
					totalSchemes += schemes.count
				}
			}
			
			if totalSchemes > 5 {
				riskScore += 15
				AppLogManager.shared.debug("High URL scheme count detected: \(totalSchemes)", category: "Signing")
			} else if totalSchemes > 2 {
				riskScore += 8
			}
		}
		
		// 4. Check for entitlements that indicate high-profile apps
		// Extract entitlements from the app's embedded.mobileprovision (if present)
		// or fall back to user-supplied entitlements file
		var entitlements: [String: Any]?
		
		// First, try to extract from embedded.mobileprovision in the app bundle
		let provisioningPath = appPath.appendingPathComponent("embedded.mobileprovision")
		if _fileManager.fileExists(atPath: provisioningPath.path) {
			do {
				let provisioningData = try Data(contentsOf: provisioningPath)
				// Find XML content within the provisioning profile (between <?xml and </plist>)
				if let xmlStart = provisioningData.range(of: Data("<?xml".utf8)),
				   let plistEnd = provisioningData.range(of: Data("</plist>".utf8)) {
					let xmlEndIndex = plistEnd.upperBound
					let xmlData = provisioningData.subdata(in: xmlStart.lowerBound..<xmlEndIndex)
					
					do {
						if let plist = try PropertyListSerialization.propertyList(from: xmlData, format: nil) as? [String: Any],
						   let embeddedEntitlements = plist["Entitlements"] as? [String: Any] {
							entitlements = embeddedEntitlements
							AppLogManager.shared.debug("Extracted entitlements from embedded.mobileprovision", category: "Signing")
						}
					} catch {
						AppLogManager.shared.debug("Could not parse embedded.mobileprovision plist: \(error.localizedDescription)", category: "Signing")
					}
				}
			} catch {
				AppLogManager.shared.debug("Could not read embedded.mobileprovision: \(error.localizedDescription)", category: "Signing")
			}
		}
		
		// Fall back to user-supplied entitlements file if no embedded entitlements found
		if entitlements == nil,
		   let entitlementsPath = _options.appEntitlementsFile,
		   let entitlementsData = try? Data(contentsOf: entitlementsPath),
		   let userEntitlements = try? PropertyListSerialization.propertyList(from: entitlementsData, format: nil) as? [String: Any] {
			entitlements = userEntitlements
			AppLogManager.shared.debug("Using user-supplied entitlements file", category: "Signing")
		}
		
		// Analyze entitlements if we have them
		if let entitlements = entitlements {
			// Apps with iCloud, push notifications, or associated domains are often popular
			let significantEntitlements = [
				"com.apple.developer.icloud-services",
				"aps-environment",
				"com.apple.developer.associated-domains",
				"com.apple.developer.applesignin"
			]
			
			for entitlement in significantEntitlements {
				if entitlements[entitlement] != nil {
					riskScore += 5
				}
			}
		}
		
		// 5. Check bundle size and complexity
		// Use main executable size as a proxy instead of recursively traversing the entire bundle
		// to avoid signing-time latency for large apps
		if let executableName = infoDictionary["CFBundleExecutable"] as? String {
			let executableURL = appPath.appendingPathComponent(executableName)
			do {
				let attributes = try _fileManager.attributesOfItem(atPath: executableURL.path)
				if let fileSize = attributes[.size] as? NSNumber {
					let executableSize = fileSize.int64Value
					if executableSize > Self.executableSizeLargeThreshold {
						riskScore += 10
						let sizeInMB = Double(executableSize) / 1_000_000.0
						AppLogManager.shared.debug("Large executable size detected: \(String(format: "%.1f", sizeInMB)) MB", category: "Signing")
					} else if executableSize > Self.executableSizeMediumThreshold {
						riskScore += 5
					}
				}
			} catch {
				AppLogManager.shared.warning("Could not determine executable size (attributes failed)", category: "Signing")
			}
		} else {
			AppLogManager.shared.warning("Could not determine executable size (missing CFBundleExecutable)", category: "Signing")
		}
		
		// 6. Check for embedded frameworks - more frameworks = more complex app
		let frameworksPath = appPath.appendingPathComponent("Frameworks")
		if _fileManager.fileExists(atPath: frameworksPath.path) {
			do {
				let frameworks = try _fileManager.contentsOfDirectory(atPath: frameworksPath.path)
				if frameworks.count > 10 {
					riskScore += 10
				} else if frameworks.count > 5 {
					riskScore += 5
				}
			} catch {
				// Ignore errors
			}
		}
		
		// 7. Check for recent minimum OS version requirements
		if let minimumOSVersion = infoDictionary["MinimumOSVersion"] as? String {
			// Apps requiring recent iOS versions might indicate active development and higher profile
			// Extract major version number
			if let majorVersion = Int(minimumOSVersion.components(separatedBy: ".").first ?? "0") {
				if majorVersion >= Self.minimumRecentIOSVersion {
					riskScore += 3
					AppLogManager.shared.debug("Recent iOS requirement detected: \(minimumOSVersion)", category: "Signing")
				}
			}
		}
		
		// 8. Check for analytics/tracking SDKs by looking for common framework names
		let analyticsFrameworks = ["GoogleAnalytics", "Firebase", "Crashlytics", "Adjust", "AppsFlyer", "Amplitude"]
		for framework in analyticsFrameworks {
			let frameworkPath = frameworksPath.appendingPathComponent("\(framework).framework")
			if _fileManager.fileExists(atPath: frameworkPath.path) {
				riskScore += 3
			}
		}
		
		// Determine protection level based on accumulated risk score
		let protectionLevel: ProtectionLevel
		if riskScore >= Self.riskScoreHighThreshold {
			protectionLevel = .high
		} else if riskScore >= Self.riskScoreMediumThreshold {
			protectionLevel = .medium
		} else if riskScore >= Self.riskScoreLowThreshold {
			protectionLevel = .low
		} else {
			protectionLevel = .none
		}
		
		AppLogManager.shared.info("Protection analysis complete - Risk Score: \(riskScore), Level: \(protectionLevel)", category: "Signing")
		return protectionLevel
	}
}

enum SigningFileHandlerError: Error, LocalizedError {
	case appNotFound
	case infoPlistNotFound
	case missingCertifcate
	case disinjectFailed
	case signFailed
	
	var errorDescription: String? {
		switch self {
		case .appNotFound: "Unable to locate bundle path."
		case .infoPlistNotFound: "Unable to locate info.plist path."
		case .missingCertifcate: "No certificate was specified."
		case .disinjectFailed: "Removing mach-O load paths failed."
		case .signFailed: "Signing failed."
		}
	}
}
