import SwiftUI

class SourcesHideManager: BaseHideManager, AppHideManaging {
    static let shared = SourcesHideManager()

    init() {
        let items = [
            HideableItem(id: "sources.allAppsCard", title: "All Apps Card", description: "Show/Hide the 'See All' apps card at the top.", defaultValue: false),
            HideableItem(id: "sources.sparklesButton", title: "Developer Certificates Button", description: "Show/Hide the sparkles button in the navigation bar.", defaultValue: false),
            HideableItem(id: "sources.editButton", title: "Edit Button", description: "Show/Hide the pencil button in the navigation bar.", defaultValue: false),
            HideableItem(id: "sources.addButton", title: "Add Button", description: "Show/Hide the plus button in the navigation bar.", defaultValue: false),
            HideableItem(id: "sources.headerSubtitle", title: "Header Subtitle", description: "Show/Hide the 'View All Your Sources' text.", defaultValue: false)
        ]
        super.init(storageKey: "hide.sources", items: items)
    }
}
