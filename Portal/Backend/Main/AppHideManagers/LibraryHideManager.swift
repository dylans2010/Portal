import SwiftUI

class LibraryHideManager: BaseHideManager, AppHideManaging {
    static let shared = LibraryHideManager()

    init() {
        let items = [
            HideableItem(id: "library.importButton", title: "Import Button", description: "Show/Hide the plus button in the toolbar.", defaultValue: false),
            HideableItem(id: "library.filterChips", title: "Filter Chips", description: "Show/Hide the All/Imported/Signed filter chips.", defaultValue: false),
            HideableItem(id: "library.selectionButton", title: "Selection Mode Button", description: "Show/Hide the ellipsis/selection button.", defaultValue: false)
        ]
        super.init(storageKey: "hide.library", items: items)
    }
}
