import SwiftUI

class GuidesHideManager: BaseHideManager, AppHideManaging {
    static let shared = GuidesHideManager()

    init() {
        let items = [
            HideableItem(id: "guides.guidesList", title: "Guides List", description: "Show/Hide the list of available guides.", defaultValue: false),
            HideableItem(id: "guides.placeholderView", title: "Placeholder View", description: "Show/Hide the placeholder view when guides are hidden.", defaultValue: false)
        ]
        super.init(storageKey: "hide.guides", items: items)
    }
}
