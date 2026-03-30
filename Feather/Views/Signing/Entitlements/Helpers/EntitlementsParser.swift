import Foundation

final class EntitlementsParser {
    static func extractFromProvisioning(at url: URL) throws -> [String: Any]? {
        let provisioningData = try Data(contentsOf: url)

        guard let xmlStart = provisioningData.range(of: Data("<?xml".utf8)),
              let plistEnd = provisioningData.range(of: Data("</plist>".utf8)) else {
            return nil
        }

        let xmlEndIndex = plistEnd.upperBound
        let xmlData = provisioningData.subdata(in: xmlStart.lowerBound..<xmlEndIndex)

        guard let plist = try PropertyListSerialization.propertyList(from: xmlData, format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any] else {
            return nil
        }

        return entitlements
    }

    static func parsePlist(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        return plist
    }
}
