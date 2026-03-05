import SwiftUI
import Combine

struct HideableItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let defaultValue: Bool
}

protocol AppHideManaging: ObservableObject {
    var hideableItems: [HideableItem] { get }
    func isHidden(_ key: String) -> Bool
    func setHidden(_ key: String, value: Bool)
    func allKeys() -> [String]
    func resetToDefaults()
}

class BaseHideManager: ObservableObject {
    @Published var itemsState: [String: Bool] = [:]
    let storageKey: String
    let hideableItems: [HideableItem]

    init(storageKey: String, items: [HideableItem]) {
        self.storageKey = storageKey
        self.hideableItems = items
        self.itemsState = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Bool] ?? [:]

        // Initialize missing items with their default values
        var updated = false
        for item in items {
            if itemsState[item.id] == nil {
                itemsState[item.id] = item.defaultValue
                updated = true
            }
        }
        if updated {
            save()
        }
    }

    func isHidden(_ key: String) -> Bool {
        return itemsState[key] ?? hideableItems.first(where: { $0.id == key })?.defaultValue ?? false
    }

    func setHidden(_ key: String, value: Bool) {
        itemsState[key] = value
        save()
    }

    func allKeys() -> [String] {
        return hideableItems.map { $0.id }
    }

    func resetToDefaults() {
        for item in hideableItems {
            itemsState[item.id] = item.defaultValue
        }
        save()
    }

    private func save() {
        UserDefaults.standard.set(itemsState, forKey: storageKey)
    }
}
