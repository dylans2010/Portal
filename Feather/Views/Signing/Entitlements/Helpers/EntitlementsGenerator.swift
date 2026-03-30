import Foundation

final class EntitlementsGenerator {
    static func generate(from items: [EntitlementItem]) -> [String: Any] {
        var dict: [String: Any] = [:]
        for item in items where item.isEnabled {
            dict[item.key] = item.value
        }
        return dict
    }

    static func writeToTempFile(entitlements: [String: Any], fileName: String = "custom.entitlements") -> URL? {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: entitlements, format: .xml, options: 0)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try data.write(to: tempURL)
            return tempURL
        } catch {
            AppLogManager.shared.error("Failed to generate entitlements: \(error.localizedDescription)", category: "Entitlements")
            return nil
        }
    }
}
