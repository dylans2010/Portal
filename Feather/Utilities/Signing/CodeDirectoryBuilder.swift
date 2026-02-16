import Foundation
import CommonCrypto

enum CodeDirectoryBuilderError: Error {
    case dataError
}

class CodeDirectoryBuilder {
    private let machoData: Data
    private let bundleIdentifier: String
    private let teamIdentifier: String?

    // Data for special slots (will be hashed using the correct algorithm)
    var infoPlistData: Data?
    var requirementsData: Data?
    var codeResourcesData: Data?
    var entitlementsData: Data?
    var entitlementsDerData: Data?

    var execSegLimit: UInt64 = 0
    var execSegFlags: UInt64 = 0

    init(machoData: Data, bundleIdentifier: String, teamIdentifier: String?) {
        self.machoData = machoData
        self.bundleIdentifier = bundleIdentifier
        self.teamIdentifier = teamIdentifier
    }

    func build(hashType: UInt8) throws -> Data {
        let isSHA256 = hashType == 2
        let hashSize = isSHA256 ? 32 : 20

        // 1. Prepare special slots
        var specialSlots: [Data] = []
        let emptyHash = Data(repeating: 0, count: hashSize)

        let hasher: (Data) -> Data = isSHA256 ? sha256Hash : sha1Hash

        // Slot -7: DER Entitlements
        specialSlots.append(entitlementsDerData.map(hasher) ?? emptyHash)
        // Slot -6: Unused
        specialSlots.append(emptyHash)
        // Slot -5: Entitlements
        specialSlots.append(entitlementsData.map(hasher) ?? emptyHash)
        // Slot -4: Application Specific (Unused)
        specialSlots.append(emptyHash)
        // Slot -3: CodeResources
        specialSlots.append(codeResourcesData.map(hasher) ?? emptyHash)
        // Slot -2: Requirements
        specialSlots.append(requirementsData.map(hasher) ?? emptyHash)
        // Slot -1: Info.plist
        specialSlots.append(infoPlistData.map(hasher) ?? emptyHash)

        // Trim trailing unused special slots (which are at the beginning of our array)
        while specialSlots.count > 0 && specialSlots.first == emptyHash {
            specialSlots.removeFirst()
        }

        let nSpecialSlots = UInt32(specialSlots.count)

        // 2. Prepare code slots
        let pageSize: UInt32 = 4096
        let nCodeSlots = UInt32((machoData.count + Int(pageSize) - 1) / Int(pageSize))

        var codeSlots: [Data] = []
        for i in 0..<Int(nCodeSlots) {
            let start = i * Int(pageSize)
            let end = min(start + Int(pageSize), machoData.count)
            let pageData = machoData.subdata(in: start..<end)

            if isSHA256 {
                codeSlots.append(sha256Hash(data: pageData))
            } else {
                codeSlots.append(sha1Hash(data: pageData))
            }
        }

        // 3. Build CodeDirectory header
        let version: UInt32 = 0x20400
        let headerSize: UInt32 = 88 // Size for version 0x20400

        let identData = (bundleIdentifier + "\0").data(using: .utf8)!
        let teamIdData = teamIdentifier != nil ? (teamIdentifier! + "\0").data(using: .utf8)! : Data()

        let identOffset = headerSize
        let teamOffset = teamIdentifier != nil ? identOffset + UInt32(identData.count) : 0
        let hashOffset = identOffset + UInt32(identData.count) + UInt32(teamIdData.count) + (nSpecialSlots * UInt32(hashSize))

        let totalLength = hashOffset + (nCodeSlots * UInt32(hashSize))

        var cdData = Data(capacity: Int(totalLength))

        // Header
        cdData.append(uint32BE(0xfade0c02)) // magic
        cdData.append(uint32BE(totalLength))
        cdData.append(uint32BE(version))
        cdData.append(uint32BE(0)) // flags
        cdData.append(uint32BE(hashOffset))
        cdData.append(uint32BE(identOffset))
        cdData.append(uint32BE(nSpecialSlots))
        cdData.append(uint32BE(nCodeSlots))
        cdData.append(uint32BE(UInt32(machoData.count))) // codeLimit
        cdData.append(UInt8(hashSize))
        cdData.append(hashType)
        cdData.append(0) // platform
        cdData.append(12) // pageSize (log2(4096) = 12)
        cdData.append(uint32BE(0)) // spare2

        // V0x20100
        cdData.append(uint32BE(0)) // scatterOffset

        // V0x20200
        cdData.append(uint32BE(teamOffset))

        // V0x20300
        cdData.append(uint32BE(0)) // spare3
        cdData.append(uint64BE(UInt64(machoData.count))) // codeLimit64

        // V0x20400
        cdData.append(uint64BE(0)) // execSegBase
        cdData.append(uint64BE(execSegLimit))
        cdData.append(uint64BE(execSegFlags))

        // Identifier
        cdData.append(identData)

        // Team ID
        if teamIdentifier != nil {
            cdData.append(teamIdData)
        }

        // Special Slots (in reverse order: -n to -1)
        for hash in specialSlots {
            cdData.append(hash)
        }

        // Code Slots (0 to n-1)
        for hash in codeSlots {
            cdData.append(hash)
        }

        return cdData
    }

    private func uint32BE(_ val: UInt32) -> Data {
        return withUnsafeBytes(of: val.bigEndian) { Data($0) }
    }

    private func uint64BE(_ val: UInt64) -> Data {
        return withUnsafeBytes(of: val.bigEndian) { Data($0) }
    }

    private func sha1Hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }

    private func sha256Hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}
