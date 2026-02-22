import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct QuickActionsDevView: View {
    @State private var showConfirmation = false
    @State private var selectedAction: QuickAction?

    enum QuickAction: String, CaseIterable {
        case clearAllCaches = "Clear All Caches"
        case resetOnboarding = "Reset Onboarding"
        case reloadSources = "Reload All Sources"
        case exportLogs = "Export All Logs"
        case resetUserDefaults = "Reset UserDefaults"
        case simulateCrash = "Simulate Crash Log"
        case triggerMemoryWarning = "Trigger Memory Warning"
        case clearImageCache = "Clear Image Cache"

        var icon: String {
            switch self {
            case .clearAllCaches: return "trash.circle.fill"
            case .resetOnboarding: return "arrow.counterclockwise.circle.fill"
            case .reloadSources: return "arrow.clockwise.circle.fill"
            case .exportLogs: return "square.and.arrow.up.circle.fill"
            case .resetUserDefaults: return "gear.badge.xmark"
            case .simulateCrash: return "exclamationmark.triangle.fill"
            case .triggerMemoryWarning: return "memorychip.fill"
            case .clearImageCache: return "photo.badge.arrow.down.fill"
            }
        }

        var color: Color {
            switch self {
            case .clearAllCaches: return .orange
            case .resetOnboarding: return .blue
            case .reloadSources: return .green
            case .exportLogs: return .purple
            case .resetUserDefaults: return .red
            case .simulateCrash: return .red
            case .triggerMemoryWarning: return .yellow
            case .clearImageCache: return .cyan
            }
        }

        var isDestructive: Bool {
            switch self {
            case .clearAllCaches, .resetOnboarding, .resetUserDefaults, .simulateCrash:
                return true
            default:
                return false
            }
        }
    }

    var body: some View {
        List {
            Section(header: Text("Cache Actions")) {
                quickActionButton(.clearAllCaches)
                quickActionButton(.clearImageCache)
            }

            Section(header: Text("State Actions")) {
                quickActionButton(.resetOnboarding)
                quickActionButton(.resetUserDefaults)
            }

            Section(header: Text("Data Actions")) {
                quickActionButton(.reloadSources)
                quickActionButton(.exportLogs)
            }

            Section(header: Text("Debug Actions")) {
                quickActionButton(.simulateCrash)
                quickActionButton(.triggerMemoryWarning)
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Quick Actions")
        .alert("Confirm Action", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(selectedAction?.isDestructive == true ? "Confirm" : "Execute", role: selectedAction?.isDestructive == true ? .destructive : nil) {
                if let action = selectedAction {
                    executeAction(action)
                }
            }
        } message: {
            Text("Are you sure you want to \(selectedAction?.rawValue.lowercased() ?? "perform this action")?")
        }
    }

    private func quickActionButton(_ action: QuickAction) -> some View {
        Button {
            selectedAction = action
            if action.isDestructive {
                showConfirmation = true
            } else {
                executeAction(action)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(action.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: action.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(action.color)
                }

                Text(action.rawValue)
                    .foregroundStyle(.primary)

                Spacer()
            }
        }
    }

    private func executeAction(_ action: QuickAction) {
        switch action {
        case .clearAllCaches:
            URLCache.shared.removeAllCachedResponses()
            if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ All caches cleared", type: .success)
            AppLogManager.shared.info("All caches cleared via Quick Actions", category: "Developer")

        case .resetOnboarding:
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Onboarding reset. Restart app to see changes.", type: .success)
            AppLogManager.shared.info("Onboarding reset via Quick Actions", category: "Developer")

        case .reloadSources:
            NotificationCenter.default.post(name: Notification.Name("Feather.reloadSources"), object: nil)
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Source Reload Triggered", type: .success)
            AppLogManager.shared.info("Sources reload triggered via Quick Actions", category: "Developer")

        case .exportLogs:
            let logs = AppLogManager.shared.exportLogs()
            UIPasteboard.general.string = logs
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)

        case .resetUserDefaults:
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("⚠️ UserDefaults reset. Restart app.", type: .warning)
            AppLogManager.shared.warning("UserDefaults reset via Quick Actions", category: "Developer")

        case .simulateCrash:
            AppLogManager.shared.critical("Simulated crash log entry for testing purposes", category: "Developer")
            HapticsManager.shared.error()
            ToastManager.shared.show("⚠️ Crash log entry created", type: .warning)

        case .triggerMemoryWarning:
            // Post a simulated memory warning notification
            NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
            HapticsManager.shared.warning()
            ToastManager.shared.show("⚠️ Memory warning triggered", type: .warning)
            AppLogManager.shared.warning("Memory warning triggered via Quick Actions", category: "Developer")

        case .clearImageCache:
            if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Image Cache Cleared", type: .success)
            AppLogManager.shared.info("Image cache cleared via Quick Actions", category: "Developer")
        }
    }
}
