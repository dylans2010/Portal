import SwiftUI

class SettingsHideManager: BaseHideManager, AppHideManaging {
    static let shared = SettingsHideManager()

    init() {
        let items = [
            // Preferences
            HideableItem(id: "settings.home", title: "Home", description: "Show/Hide Home row", defaultValue: false),
            HideableItem(id: "settings.appearance", title: "Appearance", description: "Show/Hide Appearance row.", defaultValue: false),
            HideableItem(id: "settings.notifications", title: "Notifications", description: "Show/Hide Notifications row.", defaultValue: false),
            HideableItem(id: "settings.liveActivities", title: "Live Activities", description: "Show/Hide Live Activities row.", defaultValue: false),
            HideableItem(id: "settings.language", title: "Language", description: "Show/Hide Language row.", defaultValue: false),

            // Signing
            HideableItem(id: "settings.certificates", title: "Certificates", description: "Show/Hide Certificates row.", defaultValue: false),
            HideableItem(id: "settings.signing", title: "Signing", description: "Show/Hide Signing row.", defaultValue: false),

            // Data
            HideableItem(id: "settings.files", title: "Files", description: "Show/Hide Files row.", defaultValue: false),
            HideableItem(id: "settings.storage", title: "Storage", description: "Show/Hide Storage row.", defaultValue: false),
            HideableItem(id: "settings.backupRestore", title: "Backup & Restore", description: "Show/Hide Backup & Restore row.", defaultValue: false),
            HideableItem(id: "settings.logs", title: "Logs", description: "Show/Hide Logs row.", defaultValue: false),
            HideableItem(id: "settings.repoBuilder", title: "Repository Builder", description: "Show/Hide Repository Builder row.", defaultValue: false),
            HideableItem(id: "settings.fetchData", title: "Fetch Full Data", description: "Show/Hide Fetch Full Data button.", defaultValue: false),

            // Resources
            HideableItem(id: "settings.guides", title: "Guides With AI", description: "Show/Hide Guides row.", defaultValue: false),
            HideableItem(id: "settings.credits", title: "Credits", description: "Show/Hide Credits row.", defaultValue: false),
            HideableItem(id: "settings.feedback", title: "Feedback", description: "Show/Hide Feedback row.", defaultValue: false),

            // App
            HideableItem(id: "settings.appIcons", title: "App Icons", description: "Show/Hide App Icons row.", defaultValue: false),
            HideableItem(id: "settings.updates", title: "Check For Updates", description: "Show/Hide Check For Updates row.", defaultValue: false),

            // Internal
            HideableItem(id: "settings.debug", title: "Debug", description: "Show/Hide Debug row.", defaultValue: false)
        ]
        super.init(storageKey: "hide.settings", items: items)
    }
}
