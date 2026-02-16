import Foundation

enum EntitlementExtractorError: Error {
    case invalidProvisioningProfile
    case entitlementsNotFound
}

class EntitlementExtractor {
    static func extractEntitlements(from provisionData: Data) throws -> Data {
        // Find the XML plist within the CMS data
        guard let xmlStartRange = provisionData.range(of: "<?xml".data(using: .utf8)!),
              let xmlEndRange = provisionData.range(of: "</plist>".data(using: .utf8)!, options: .backwards) else {
            throw EntitlementExtractorError.invalidProvisioningProfile
        }

        let xmlData = provisionData.subdata(in: xmlStartRange.lowerBound..<xmlEndRange.upperBound)

        // Use PropertyListSerialization to find the Entitlements key if we want to be precise,
        // but the user wants it extracted "exactly as-is" from the raw XML if possible.
        // However, we need to find the specific <dict> for entitlements.

        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            throw EntitlementExtractorError.invalidProvisioningProfile
        }

        let entitlementsKey = "<key>Entitlements</key>"
        guard let keyRange = xmlString.range(of: entitlementsKey) else {
            throw EntitlementExtractorError.entitlementsNotFound
        }

        let searchRange = keyRange.upperBound..<xmlString.endIndex
        guard let dictStartRange = xmlString.range(of: "<dict>", range: searchRange) else {
            throw EntitlementExtractorError.entitlementsNotFound
        }

        // Find matching </dict>
        var level = 0
        var currentIndex = dictStartRange.lowerBound
        var entitlementsEndIndex: String.Index?

        while currentIndex < xmlString.endIndex {
            if let nextOpen = xmlString.range(of: "<dict", range: currentIndex..<xmlString.endIndex) {
                if let nextClose = xmlString.range(of: "</dict>", range: currentIndex..<xmlString.endIndex) {
                    if nextOpen.lowerBound < nextClose.lowerBound {
                        level += 1
                        currentIndex = nextOpen.upperBound
                    } else {
                        level -= 1
                        if level == 0 {
                            entitlementsEndIndex = nextClose.upperBound
                            break
                        }
                        currentIndex = nextClose.upperBound
                    }
                } else {
                    break
                }
            } else if let nextClose = xmlString.range(of: "</dict>", range: currentIndex..<xmlString.endIndex) {
                level -= 1
                if level == 0 {
                    entitlementsEndIndex = nextClose.upperBound
                    break
                }
                currentIndex = nextClose.upperBound
            } else {
                break
            }
        }

        guard let endIndex = entitlementsEndIndex else {
            throw EntitlementExtractorError.entitlementsNotFound
        }

        let entitlementsString: String = String(xmlString[dictStartRange.lowerBound..<endIndex])
        guard let entitlementsData = entitlementsString.data(using: .utf8) else {
            throw EntitlementExtractorError.entitlementsNotFound
        }

        return entitlementsData
    }

    static func parseFullPlist(from provisionData: Data) throws -> [String: Any] {
        guard let xmlStartRange = provisionData.range(of: "<?xml".data(using: .utf8)!),
              let xmlEndRange = provisionData.range(of: "</plist>".data(using: .utf8)!, options: .backwards) else {
            throw EntitlementExtractorError.invalidProvisioningProfile
        }

        let xmlData = provisionData.subdata(in: xmlStartRange.lowerBound..<xmlEndRange.upperBound)

        guard let plist = try PropertyListSerialization.propertyList(from: xmlData, options: [], format: nil) as? [String: Any] else {
            throw EntitlementExtractorError.invalidProvisioningProfile
        }

        return plist
    }
}
