import SwiftUI
import Combine
import AltSourceKit
// MARK: - Gesture Types
enum GestureType: String, CaseIterable, Codable, Identifiable {
    case singleTap = "Single Tap"
    case doubleTap = "Double Tap"
    case tripleTap = "Triple Tap"
    case longPress = "Long Press"
    case leftSwipe = "Left Swipe"
    case rightSwipe = "Right Swipe"

    var id: String { rawValue }
}

// MARK: - Gesture Actions
enum GestureAction: String, CaseIterable, Codable, Identifiable {
    case none = "None"
    case openDetails = "Open Details"
    case signApp = "Sign App"
    case resignApp = "Resign App"
    case installApp = "Install App"
    case deleteApp = "Delete App"
    case shareApp = "Share App"
    case openRepository = "Open Repository"
    case refresh = "Refresh"
    case pin = "Pin/Unpin"
    case copyURL = "Copy URL"
    case unlockSourceMaster = "Unlock Source Master"
    case rotateTip = "Rotate Tip"
    case showHomeInfo = "Show Home Info"
    case toggleInversion = "Toggle Inversion"
    case authenticateDeveloper = "Authenticate Developer"
    case rename = "Rename"
    case duplicate = "Duplicate"
    case move = "Move"
    case viewPermissions = "View Permissions"
    case exportEntitlements = "Export Entitlements"
    case select = "Select"

    var id: String { rawValue }

    var isDestructive: Bool {
        switch self {
        case .deleteApp: return true
        default: return false
        }
    }
}

// MARK: - App Sections
enum AppSection: String, CaseIterable, Codable, Identifiable {
    case dashboard = "Home"
    case sources = "Sources"
    case library = "Library"
    case allApps = "All Apps"
    case files = "Files"
    case guides = "Guides"
    case settings = "Settings"
    case certificates = "Certificates"

    var id: String { rawValue }

    var tabKey: String {
        switch self {
        case .dashboard: return "Feather.tabBar.dashboard"
        case .sources: return "Feather.tabBar.sources"
        case .library: return "Feather.tabBar.library"
        case .allApps: return "Feather.tabBar.allApps"
        case .files: return "Feather.tabBar.files"
        case .guides: return "Feather.tabBar.guides"
        case .settings: return "Feather.tabBar.settings"
        case .certificates: return "Feather.tabBar.certificates"
        }
    }
}

// MARK: - Gesture Manager
class GestureManager: ObservableObject {
    static let shared = GestureManager()

    @Published var mappings: [AppSection: [GestureType: GestureAction]] = [:]

    private let storageKey = "Feather.gestureMappings"

    private init() {
        loadMappings()
    }

    func loadMappings() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AppSection: [GestureType: GestureAction]].self, from: data) {
            mappings = decoded
        } else {
            // Default mappings
            mappings = [
                .library: [
                    .singleTap: .openDetails,
                    .leftSwipe: .deleteApp,
                    .rightSwipe: .installApp,
                    .doubleTap: .signApp,
                    .longPress: .shareApp
                ],
                .sources: [
                    .singleTap: .openDetails,
                    .leftSwipe: .deleteApp,
                    .doubleTap: .openRepository,
                    .longPress: .pin,
                    .tripleTap: .unlockSourceMaster
                ],
                .dashboard: [
                    .singleTap: .rotateTip,
                    .doubleTap: .showHomeInfo,
                    .longPress: .toggleInversion
                ],
                .settings: [
                    .tripleTap: .authenticateDeveloper
                ]
            ]
        }
    }

    func saveMappings() {
        if let encoded = try? JSONEncoder().encode(mappings) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    func setMapping(for gesture: GestureType, in section: AppSection, action: GestureAction) {
        if mappings[section] == nil {
            mappings[section] = [:]
        }
        mappings[section]?[gesture] = action
        saveMappings()
    }

    func getAction(for gesture: GestureType, in section: AppSection) -> GestureAction {
        return mappings[section]?[gesture] ?? .none
    }

    func performAction(for gesture: GestureType, in section: AppSection, context: Any? = nil) async {
        let action = getAction(for: gesture, in: section)
        await execute(action: action, in: section, context: context)
    }
@MainActor
    func execute(action: GestureAction, in section: AppSection? = nil, context: Any? = nil) {
        guard action != .none else { return }

        // Destructive actions confirmation
        if action.isDestructive {
            NotificationCenter.default.post(name: .gestureRequireConfirmation, object: nil, userInfo: [
                "action": action,
                "section": section as Any,
                "context": context as Any
            ])
            return
        }

        // Execute the action
        switch action {
        case .openDetails:
            if let app = context as? AppInfoPresentable {
                NotificationCenter.default.post(name: .gestureOpenDetails, object: app)
            } else if let source = context as? AltSource {
                NotificationCenter.default.post(name: .gestureOpenSourceDetails, object: source)
            } else if let app = context as? ASRepository.App {
                NotificationCenter.default.post(name: .gestureOpenDetails, object: app)
            } else if let file = context as? FileItem {
                NotificationCenter.default.post(name: .gestureOpenFileDetails, object: file)
            } else if let guide = context as? Guide {
                NotificationCenter.default.post(name: .gestureOpenGuideDetails, object: guide)
            } else if let cert = context as? CertificatePair {
                NotificationCenter.default.post(name: .gestureOpenCertDetails, object: cert)
            } else if section == .dashboard {
                 NotificationCenter.default.post(name: .gestureShowHomeInfo, object: nil)
            }
        case .signApp, .resignApp:
            if let app = context as? AppInfoPresentable {
                NotificationCenter.default.post(name: .gestureSignApp, object: app)
            }
        case .installApp:
            if let app = context as? AppInfoPresentable {
                NotificationCenter.default.post(name: .gestureInstallApp, object: app)
            }
        case .shareApp:
            if let app = context as? AppInfoPresentable {
                NotificationCenter.default.post(name: .gestureShareApp, object: app)
            } else if let file = context as? FileItem {
                NotificationCenter.default.post(name: .gestureShareFile, object: file)
            }
        case .openRepository:
             if let source = context as? AltSource {
                 NotificationCenter.default.post(name: .gestureOpenSourceDetails, object: source)
             }
        case .refresh:
            NotificationCenter.default.post(name: .gestureRefresh, object: nil)
        case .pin:
            if let source = context as? AltSource {
                SourcesViewModel.shared.togglePin(for: source)
            }
        case .copyURL:
            if let source = context as? AltSource {
                UIPasteboard.general.string = source.sourceURL?.absoluteString
                HapticsManager.shared.success()
            }
        case .rename:
            if let file = context as? FileItem {
                NotificationCenter.default.post(name: .gestureRenameFile, object: file)
            }
        case .duplicate:
            if let file = context as? FileItem {
                NotificationCenter.default.post(name: .gestureDuplicateFile, object: file)
            }
        case .move:
            if let file = context as? FileItem {
                NotificationCenter.default.post(name: .gestureMoveFile, object: file)
            }
        case .viewPermissions:
            if let file = context as? FileItem {
                NotificationCenter.default.post(name: .gestureViewFilePermissions, object: file)
            }
        case .exportEntitlements:
            if let cert = context as? CertificatePair {
                NotificationCenter.default.post(name: .gestureExportCertEntitlements, object: cert)
            }
        case .select:
            if let cert = context as? CertificatePair {
                NotificationCenter.default.post(name: .gestureSelectCert, object: cert)
            }
        case .unlockSourceMaster:
            ToastManager.shared.show("🛠️ Source Master Unlocked!", type: .success)
            HapticsManager.shared.success()
        case .rotateTip:
            NotificationCenter.default.post(name: .gestureRotateTip, object: nil)
        case .showHomeInfo:
            NotificationCenter.default.post(name: .gestureShowHomeInfo, object: nil)
        case .toggleInversion:
            EasterEggManager.shared.toggleInversion()
        case .authenticateDeveloper:
            NotificationCenter.default.post(name: .gestureAuthenticateDeveloper, object: nil)
        default:
            break
        }

        HapticsManager.shared.softImpact()
    }
}

// MARK: - Notifications
extension NSNotification.Name {
    static let gestureOpenDetails = NSNotification.Name("Feather.gesture.openDetails")
    static let gestureSignApp = NSNotification.Name("Feather.gesture.signApp")
    static let gestureInstallApp = NSNotification.Name("Feather.gesture.installApp")
    static let gestureShareApp = NSNotification.Name("Feather.gesture.shareApp")
    static let gestureOpenSourceDetails = NSNotification.Name("Feather.gesture.openSourceDetails")
    static let gestureRefresh = NSNotification.Name("Feather.gesture.refresh")
    static let gestureRequireConfirmation = NSNotification.Name("Feather.gesture.requireConfirmation")
    static let gestureRotateTip = NSNotification.Name("Feather.gesture.rotateTip")
    static let gestureShowHomeInfo = NSNotification.Name("Feather.gesture.showHomeInfo")
    static let gestureAuthenticateDeveloper = NSNotification.Name("Feather.gesture.authenticateDeveloper")
    static let gestureOpenFileDetails = NSNotification.Name("Feather.gesture.openFileDetails")
    static let gestureRenameFile = NSNotification.Name("Feather.gesture.renameFile")
    static let gestureDuplicateFile = NSNotification.Name("Feather.gesture.duplicateFile")
    static let gestureMoveFile = NSNotification.Name("Feather.gesture.moveFile")
    static let gestureShareFile = NSNotification.Name("Feather.gesture.shareFile")
    static let gestureViewFilePermissions = NSNotification.Name("Feather.gesture.viewFilePermissions")
    static let gestureOpenGuideDetails = NSNotification.Name("Feather.gesture.openGuideDetails")
    static let gestureOpenCertDetails = NSNotification.Name("Feather.gesture.openCertDetails")
    static let gestureExportCertEntitlements = NSNotification.Name("Feather.gesture.exportCertEntitlements")
    static let gestureSelectCert = NSNotification.Name("Feather.gesture.selectCert")
}
