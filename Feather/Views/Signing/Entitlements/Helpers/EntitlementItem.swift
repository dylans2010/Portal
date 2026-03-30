import Foundation

struct EntitlementItem: Identifiable {
    let id = UUID()
    var name: String
    var key: String
    var value: Any
    var isEnabled: Bool
    var symbol: String
}
