import SwiftUI

class FilesHideManager: BaseHideManager, AppHideManaging {
    static let shared = FilesHideManager()

    init() {
        let items = [
            HideableItem(id: "files.plusButton", title: "Add Button", description: "Show/Hide the plus button in the toolbar.", defaultValue: false),
            HideableItem(id: "files.downloadsPortalButton", title: "Downloads Portal", description: "Show/Hide the downloads button in the toolbar.", defaultValue: false),
            HideableItem(id: "files.ellipsisMenuButton", title: "Menu Button", description: "Show/Hide the ellipsis menu button.", defaultValue: false),
            HideableItem(id: "files.breadcrumbView", title: "Breadcrumbs", description: "Show/Hide the breadcrumb navigation bar.", defaultValue: false),
            HideableItem(id: "files.certBanner", title: "Certificate Banner", description: "Show/Hide the certificate detection banner.", defaultValue: false),
            HideableItem(id: "files.emptyStateImportButton", title: "Empty State Import", description: "Show/Hide the import button in empty state.", defaultValue: false)
        ]
        super.init(storageKey: "hide.files", items: items)
    }
}
