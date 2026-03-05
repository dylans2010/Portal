import Foundation
import UIKit

// MARK: - OptionsManager
class OptionsManager: ObservableObject {
	static let shared = OptionsManager()
	
	@Published var options: Options
	private let _key = "signing_options"
	
	init() {
		if
			let data = UserDefaults.standard.data(forKey: _key),
			let savedOptions = try? JSONDecoder().decode(Options.self, from: data)
		{
			self.options = savedOptions
		} else {
			self.options = Options.defaultOptions
			self.saveOptions()
		}
	}
	
	/// Saves options
	func saveOptions() {
		if let encoded = try? JSONEncoder().encode(options) {
			UserDefaults.standard.set(encoded, forKey: _key)
			objectWillChange.send()
		}
	}
	
	/// Resets options to default
	func resetToDefaults() {
		options = Options.defaultOptions
		saveOptions()
	}
}

// MARK: - Signing Button Type
enum SigningButtonType: Int, CaseIterable {
    case button = 0
    case swipe = 1
    case hold = 2
    case slide = 3
    case doubleTap = 4

    var label: String {
        switch self {
        case .button: return .localized("Button")
        case .swipe: return .localized("Swipe")
        case .hold: return .localized("Hold (5s)")
        case .slide: return .localized("Slide")
        case .doubleTap: return .localized("Double Tap")
        }
    }

    var icon: String {
        switch self {
        case .button: return "hand.tap.fill"
        case .swipe: return "arrow.right.to.line"
        case .hold: return "hand.tap"
        case .slide: return "arrow.right.square.fill"
        case .doubleTap: return "hand.tap.fill"
        }
    }
}

// MARK: - Options
struct Options: Codable, Equatable {
	
	// MARK: Pre Modifications
	
	/// App name
	var appName: String?
	/// App version
	var appVersion: String?
	/// App bundle identifer
	var appIdentifier: String?
	/// App entitlements
	var appEntitlementsFile: URL?
	/// App apparence (i.e. Light/Dark/Default)
	var appAppearance: AppAppearance
	/// App minimum iOS requirement (i.e. iOS 11.0)
	var minimumAppRequirement: MinimumAppRequirement
	/// Signing options
	var signingOption: SigningOption
	
	// MARK: Options
	
	/// Inject path (i.e. `@rpath`)
	var injectPath: InjectPath
	/// Inject folder (i.e. `Frameworks/`)
	var injectFolder: InjectFolder
	/// Random string appended to the app identifier
	var ppqString: String
	/// Basic protection against PPQ
	var ppqProtection: Bool
	/// (Better) protection against PPQ
	var dynamicProtection: Bool
	/// App identifiers list which matches and replaces
	var identifiers: [String: String]
	/// App name list which matches and replaces
	var displayNames: [String: String]
	/// Array of files (`.dylib`, `.deb` ) to extract and inject
	var injectionFiles: [URL]
	/// Mach-o load paths to remove (i.e. `@executable_path/demo1.dylib`)
	var disInjectionFiles: [String]
	/// App files to remove from (i.e. `Frameworks/CydiaSubstrate.framework`)
	var removeFiles: [String]
	/// If app should have filesharing forcefully enabled
	var fileSharing: Bool
	/// If app should have iTunes filesharing forcefully enabled
	var itunesFileSharing: Bool
	/// If app should have Pro Motion enabled (may not be needed)
	var proMotion: Bool
	/// If app should have Game Mode enabled
	var gameMode: Bool
	/// If app should use fullscreen (iPad mainly)
	var ipadFullscreen: Bool
	/// If app shouldn't have URL Schemes
	var removeURLScheme: Bool
	/// If app should not include a `embedded.mobileprovision` (useful for JB detection)
	var removeProvisioning: Bool
	/// Forcefully rename string files for App name
	var changeLanguageFilesForCustomDisplayName: Bool
	/// Custom Info.plist entries (key-value pairs to be added to Info.plist)
	var customInfoPlistEntries: [String: AnyCodable]
	/// URL to custom Info.plist file to import
	var customInfoPlistFile: URL?
	/// App capabilities to remove
	var removedCapabilities: [String]
	/// Custom URL schemes to add
	var customURLSchemes: [String]
	/// If app should be cloned with a random string
	var cloneApp: Bool
	/// Random string for app cloning
	var cloneString: String
	/// Support for large applications (3GB+)
	var supportBigApps: Bool
	
	// MARK: Experiments
	
	/// Modifies app to support liquid glass
	var experiment_supportLiquidGlass: Bool
	/// Modifies application to use ElleKit instead of CydiaSubstrate
	var experiment_replaceSubstrateWithEllekit: Bool
	
	// MARK: Post Modifications
	
	var post_installAppAfterSigned: Bool
	/// This will delete your imported application after signing, to save on using unneeded space.
	var post_deleteAppAfterSigned: Bool
	
	enum CodingKeys: String, CodingKey {
		case appName, appVersion, appIdentifier, appEntitlementsFile, appAppearance, minimumAppRequirement, signingOption
		case injectPath, injectFolder, ppqString, ppqProtection, dynamicProtection, identifiers, displayNames, injectionFiles
		case disInjectionFiles, removeFiles, fileSharing, itunesFileSharing, proMotion, gameMode, ipadFullscreen, removeURLScheme
		case removeProvisioning, changeLanguageFilesForCustomDisplayName, customInfoPlistEntries, customInfoPlistFile
		case removedCapabilities, customURLSchemes, cloneApp, cloneString
		case experiment_supportLiquidGlass, experiment_replaceSubstrateWithEllekit
		case post_installAppAfterSigned, post_deleteAppAfterSigned, supportBigApps
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		appName = try container.decodeIfPresent(String.self, forKey: .appName)
		appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion)
		appIdentifier = try container.decodeIfPresent(String.self, forKey: .appIdentifier)
		appEntitlementsFile = try container.decodeIfPresent(URL.self, forKey: .appEntitlementsFile)
		appAppearance = try container.decode(AppAppearance.self, forKey: .appAppearance)
		minimumAppRequirement = try container.decode(MinimumAppRequirement.self, forKey: .minimumAppRequirement)
		signingOption = try container.decode(SigningOption.self, forKey: .signingOption)
		injectPath = try container.decode(InjectPath.self, forKey: .injectPath)
		injectFolder = try container.decode(InjectFolder.self, forKey: .injectFolder)
		ppqString = try container.decode(String.self, forKey: .ppqString)
		ppqProtection = try container.decode(Bool.self, forKey: .ppqProtection)
		dynamicProtection = try container.decode(Bool.self, forKey: .dynamicProtection)
		identifiers = try container.decode([String: String].self, forKey: .identifiers)
		displayNames = try container.decode([String: String].self, forKey: .displayNames)
		injectionFiles = try container.decode([URL].self, forKey: .injectionFiles)
		disInjectionFiles = try container.decode([String].self, forKey: .disInjectionFiles)
		removeFiles = try container.decode([String].self, forKey: .removeFiles)
		fileSharing = try container.decode(Bool.self, forKey: .fileSharing)
		itunesFileSharing = try container.decode(Bool.self, forKey: .itunesFileSharing)
		proMotion = try container.decode(Bool.self, forKey: .proMotion)
		gameMode = try container.decode(Bool.self, forKey: .gameMode)
		ipadFullscreen = try container.decode(Bool.self, forKey: .ipadFullscreen)
		removeURLScheme = try container.decode(Bool.self, forKey: .removeURLScheme)
		removeProvisioning = try container.decode(Bool.self, forKey: .removeProvisioning)
		changeLanguageFilesForCustomDisplayName = try container.decode(Bool.self, forKey: .changeLanguageFilesForCustomDisplayName)
		customInfoPlistEntries = try container.decode([String: AnyCodable].self, forKey: .customInfoPlistEntries)
		customInfoPlistFile = try container.decodeIfPresent(URL.self, forKey: .customInfoPlistFile)
		removedCapabilities = try container.decode([String].self, forKey: .removedCapabilities)
		customURLSchemes = try container.decode([String].self, forKey: .customURLSchemes)
		cloneApp = try container.decodeIfPresent(Bool.self, forKey: .cloneApp) ?? false
		cloneString = try container.decodeIfPresent(String.self, forKey: .cloneString) ?? Options.randomCloneString()
		supportBigApps = try container.decodeIfPresent(Bool.self, forKey: .supportBigApps) ?? false
		experiment_supportLiquidGlass = try container.decode(Bool.self, forKey: .experiment_supportLiquidGlass)
		experiment_replaceSubstrateWithEllekit = try container.decode(Bool.self, forKey: .experiment_replaceSubstrateWithEllekit)
		post_installAppAfterSigned = try container.decode(Bool.self, forKey: .post_installAppAfterSigned)
		post_deleteAppAfterSigned = try container.decode(Bool.self, forKey: .post_deleteAppAfterSigned)
	}

	init(
		appName: String? = nil, appVersion: String? = nil, appIdentifier: String? = nil, appEntitlementsFile: URL? = nil,
		appAppearance: AppAppearance = .default, minimumAppRequirement: MinimumAppRequirement = .default, signingOption: SigningOption = .default,
		injectPath: InjectPath = .executable_path, injectFolder: InjectFolder = .frameworks, ppqString: String = randomString(),
		ppqProtection: Bool = false, dynamicProtection: Bool = false, identifiers: [String: String] = [:], displayNames: [String: String] = [:],
		injectionFiles: [URL] = [], disInjectionFiles: [String] = [], removeFiles: [String] = [], fileSharing: Bool = false,
		itunesFileSharing: Bool = false, proMotion: Bool = false, gameMode: Bool = false, ipadFullscreen: Bool = false,
		removeURLScheme: Bool = false, removeProvisioning: Bool = false, changeLanguageFilesForCustomDisplayName: Bool = false,
		customInfoPlistEntries: [String: AnyCodable] = [:], customInfoPlistFile: URL? = nil, removedCapabilities: [String] = [],
		customURLSchemes: [String] = [], cloneApp: Bool = false, cloneString: String = randomCloneString(),
		supportBigApps: Bool = false,
		experiment_supportLiquidGlass: Bool = false, experiment_replaceSubstrateWithEllekit: Bool = false,
		post_installAppAfterSigned: Bool = false, post_deleteAppAfterSigned: Bool = false
	) {
		self.appName = appName
		self.appVersion = appVersion
		self.appIdentifier = appIdentifier
		self.appEntitlementsFile = appEntitlementsFile
		self.appAppearance = appAppearance
		self.minimumAppRequirement = minimumAppRequirement
		self.signingOption = signingOption
		self.injectPath = injectPath
		self.injectFolder = injectFolder
		self.ppqString = ppqString
		self.ppqProtection = ppqProtection
		self.dynamicProtection = dynamicProtection
		self.identifiers = identifiers
		self.displayNames = displayNames
		self.injectionFiles = injectionFiles
		self.disInjectionFiles = disInjectionFiles
		self.removeFiles = removeFiles
		self.fileSharing = fileSharing
		self.itunesFileSharing = itunesFileSharing
		self.proMotion = proMotion
		self.gameMode = gameMode
		self.ipadFullscreen = ipadFullscreen
		self.removeURLScheme = removeURLScheme
		self.removeProvisioning = removeProvisioning
		self.changeLanguageFilesForCustomDisplayName = changeLanguageFilesForCustomDisplayName
		self.customInfoPlistEntries = customInfoPlistEntries
		self.customInfoPlistFile = customInfoPlistFile
		self.removedCapabilities = removedCapabilities
		self.customURLSchemes = customURLSchemes
		self.cloneApp = cloneApp
		self.cloneString = cloneString
		self.supportBigApps = supportBigApps
		self.experiment_supportLiquidGlass = experiment_supportLiquidGlass
		self.experiment_replaceSubstrateWithEllekit = experiment_replaceSubstrateWithEllekit
		self.post_installAppAfterSigned = post_installAppAfterSigned
		self.post_deleteAppAfterSigned = post_deleteAppAfterSigned
	}

	// MARK: - Defaults
	static let defaultOptions = Options(
		
		// MARK: Pre Modifications
		
		appAppearance: .default,
		minimumAppRequirement: .default,
		signingOption: .default,
		
		// MARK: Options
		
		injectPath: .executable_path,
		injectFolder: .frameworks,
		ppqString: randomString(),
		ppqProtection: false,
		dynamicProtection: false,
		identifiers: [:],
		displayNames: [:],
		injectionFiles: [],
		disInjectionFiles: [],
		removeFiles: [],
		fileSharing: false,
		itunesFileSharing: false,
		proMotion: false,
		gameMode: false,
		ipadFullscreen: false,
		removeURLScheme: false,
		removeProvisioning: false,
		changeLanguageFilesForCustomDisplayName: false,
		customInfoPlistEntries: [:],
		customInfoPlistFile: nil,
		removedCapabilities: [],
		customURLSchemes: [],
		cloneApp: false,
		cloneString: randomCloneString(),
		supportBigApps: false,
		
		// MARK: Experiments
		
		experiment_supportLiquidGlass: false,
		experiment_replaceSubstrateWithEllekit: false,
		
		// MARK: Post Modifications
		
		post_installAppAfterSigned: false,
		post_deleteAppAfterSigned: false
	)
	
	// MARK: duplicate values are not recommended!

	enum AppAppearance: String, Codable, CaseIterable, LocalizedDescribable {
		case `default`
		case light = "Light"
		case dark = "Dark"

		var localizedDescription: String {
			switch self {
			case .default: .localized("Default")
			case .light: .localized("Light")
			case .dark: .localized("Dark")
			}
		}
	}

	enum MinimumAppRequirement: String, Codable, CaseIterable, LocalizedDescribable {
		case `default`
		case v16 = "16.0"
		case v15 = "15.0"
		case v14 = "14.0"
		case v13 = "13.0"
		case v12 = "12.0"

		var localizedDescription: String {
			switch self {
			case .default: .localized("Default")
			case .v16: "16.0"
			case .v15: "15.0"
			case .v14: "14.0"
			case .v13: "13.0"
			case .v12: "12.0"
			}
		}
	}
	
	enum SigningOption: String, Codable, CaseIterable, LocalizedDescribable {
		case `default`
		case onlyModify
//		case adhoc

		var localizedDescription: String {
			switch self {
			case .default: .localized("Default")
			case .onlyModify: .localized("Modify")
//			case .adhoc: .localized("Ad-hoc")
			}
		}
	}
	
	enum InjectPath: String, Codable, CaseIterable, LocalizedDescribable {
		case executable_path = "@executable_path"
		case rpath = "@rpath"
	}
	
	enum InjectFolder: String, Codable, CaseIterable, LocalizedDescribable {
		case root = "/"
		case frameworks = "/Frameworks/"
	}
	
	/// Default random value for `ppqString`
	static func randomString() -> String {
		String((0..<6).compactMap { _ in UUID().uuidString.randomElement() })
	}

	/// Default random value for `cloneString`
	static func randomCloneString() -> String {
		let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		return String((0..<5).compactMap { _ in letters.randomElement() })
	}
}

// MARK: - LocalizedDescribable

protocol LocalizedDescribable {
	var localizedDescription: String { get }
}

extension LocalizedDescribable where Self: RawRepresentable, RawValue == String {
	var localizedDescription: String {
		let localized = NSLocalizedString(self.rawValue, comment: "")
		return localized == self.rawValue ? self.rawValue : localized
	}
}
