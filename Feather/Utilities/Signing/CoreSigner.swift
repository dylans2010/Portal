import Foundation
import CommonCrypto

enum CoreSignerError: Error {
    case signingError(String)
}

class CoreSigner {
    static func sign(bundleURL: URL, p12Data: Data, p12Password: String, provisionData: Data) throws {
        // 0. Recursively sign nested dylibs (bundles will be handled by recursive sign call later)
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                if fileURL.pathExtension == "dylib" {
                    try signBinary(fileURL, p12Data: p12Data, p12Password: p12Password, teamID: nil, bundleID: fileURL.lastPathComponent)
                }
            }
        }

        let infoPlistURL = bundleURL.appendingPathComponent("Info.plist")
        guard let infoPlist = NSDictionary(contentsOf: infoPlistURL),
              let executableName = infoPlist["CFBundleExecutable"] as? String else {
            throw CoreSignerError.signingError("Info.plist or CFBundleExecutable not found")
        }
        let executableURL = bundleURL.appendingPathComponent(executableName)

        // 1. Strip previous signature
        try MachOStripper.strip(at: executableURL)

        // 2. Embed provision
        let embeddedProvisionURL = bundleURL.appendingPathComponent("embedded.mobileprovision")
        try provisionData.write(to: embeddedProvisionURL)

        let entitlementsData = try EntitlementExtractor.extractEntitlements(from: provisionData)
        let provisionPlist = try EntitlementExtractor.parseFullPlist(from: provisionData)

        guard let teamIdentifier = (provisionPlist["TeamIdentifier"] as? [String])?.first,
              let entitlements = provisionPlist["Entitlements"] as? [String: Any],
              let bundleIdentifier = entitlements["application-identifier"] as? String else {
            throw CoreSignerError.signingError("Invalid provisioning profile metadata")
        }

        var cleanBundleID = bundleIdentifier
        if cleanBundleID.hasPrefix(teamIdentifier + ".") {
            cleanBundleID = String(cleanBundleID.dropFirst(teamIdentifier.count + 1))
        }

        // 3. Rebuild CodeResources
        let resourcesBuilder = CodeResourcesBuilder(bundleURL: bundleURL, executableName: executableName)
        let codeResourcesData = try resourcesBuilder.build()
        let codeSignatureDir = bundleURL.appendingPathComponent("_CodeSignature")
        try FileManager.default.createDirectory(at: codeSignatureDir, withIntermediateDirectories: true)
        try codeResourcesData.write(to: codeSignatureDir.appendingPathComponent("CodeResources"))

        // 4. Build CodeDirectory
        let machoData = try Data(contentsOf: executableURL)
        let cdBuilder = CodeDirectoryBuilder(machoData: machoData, bundleIdentifier: cleanBundleID, teamIdentifier: teamIdentifier)
        cdBuilder.infoPlistData = try Data(contentsOf: infoPlistURL)
        cdBuilder.codeResourcesData = codeResourcesData
        cdBuilder.entitlementsData = entitlementsData

        let requirementsData = createRequirementsBlob(bundleID: cleanBundleID)
        cdBuilder.requirementsData = requirementsData

        // Use MH_EXECUTE flag if it is an executable
        let magic = machoData.withUnsafeBytes { $0.load(as: UInt32.self) }
        let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
        let isBigEndian = magic == MH_CIGAM || magic == MH_CIGAM_64

        var fileType: UInt32 = 0
        if is64Bit {
            let header = machoData.withUnsafeBytes { $0.load(as: mach_header_64.self) }
            fileType = isBigEndian ? header.filetype.byteSwapped : header.filetype
        } else {
            let header = machoData.withUnsafeBytes { $0.load(as: mach_header.self) }
            fileType = isBigEndian ? header.filetype.byteSwapped : header.filetype
        }

        if fileType == MH_EXECUTE {
            cdBuilder.execSegFlags = 0x1 // CS_EXECSEG_MAIN_BINARY
        }

        // Find __TEXT segment vmsize for execSegLimit
        var currentOffset = headerSize
        let ncmds: UInt32
        if is64Bit {
            let header = machoData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: mach_header_64.self) }
            ncmds = isBigEndian ? header.ncmds.byteSwapped : header.ncmds
        } else {
            let header = machoData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: mach_header.self) }
            ncmds = isBigEndian ? header.ncmds.byteSwapped : header.ncmds
        }

        for _ in 0..<Int(ncmds) {
            let cmd = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: load_command.self) }
            let cmdType = isBigEndian ? cmd.cmd.byteSwapped : cmd.cmd
            let cmdSize = isBigEndian ? cmd.cmdsize.byteSwapped : cmd.cmdsize

            if cmdType == LC_SEGMENT_64 {
                let seg = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: segment_command_64.self) }
                let segName = withUnsafeBytes(of: seg.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__TEXT" {
                    cdBuilder.execSegLimit = isBigEndian ? seg.vmsize.byteSwapped : seg.vmsize
                }
            } else if cmdType == LC_SEGMENT {
                let seg = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: segment_command.self) }
                let segName = withUnsafeBytes(of: seg.segname) { String(cString: $0.baseAddress!.assumingMemoryBound(to: CChar.self)) }
                if segName == "__TEXT" {
                    cdBuilder.execSegLimit = UInt64(isBigEndian ? seg.vmsize.byteSwapped : seg.vmsize)
                }
            }
            currentOffset += Int(cmdSize)
        }

        let cdData256 = try cdBuilder.build(hashType: 2)

        // 5. Sign
        let signer = CMSSigner(p12Data: p12Data, p12Password: p12Password)
        let cdHash256 = sha256Hash(data: cdData256)
        let cdHashesPlist = try createCDHashesPlist(hashes: [cdHash256])

        let signature = try signer.sign(cdData: cdData256, cdHashesPlist: cdHashesPlist, cdHashes: [cdHash256])

        // 6. SuperBlob
        let superBlob = try buildSuperBlob(cdData: cdData256, entitlementsData: entitlementsData, requirementsData: requirementsData, signature: signature)

        // 7. Insert
        let stripper = MachOStripper(data: machoData)
        let signedMachoData = try stripper.appendSignature(superBlob)
        try signedMachoData.write(to: executableURL)

        // 8. Verify
        try verify(executableURL: executableURL, bundleID: cleanBundleID)
    }

    private static func sha1Hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &hash) }
        return Data(hash)
    }

    private static func sha256Hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash) }
        return Data(hash)
    }

    private static func createRequirementsBlob(bundleID: String) -> Data {
        // Minimal requirements: designated => identifier "bundleID"
        let identData = bundleID.data(using: .utf8)!
        let identLen = UInt32(identData.count)

        var req = Data()
        req.append(uint32BE(0xfade0c00)) // opDesignated
        req.append(uint32BE(1)) // opAppleGeneric
        req.append(uint32BE(6)) // opIdent
        req.append(uint32BE(identLen))
        req.append(identData)
        // Padding for 4-byte alignment
        let padding = (4 - (req.count % 4)) % 4
        req.append(Data(repeating: 0, count: padding))

        var data = Data()
        data.append(uint32BE(0xfade0c01)) // magic (Requirements)
        data.append(uint32BE(UInt32(req.count + 20))) // total length: header(12) + index(8) + req
        data.append(uint32BE(1)) // count
        data.append(uint32BE(3)) // type: Designated Requirement
        data.append(uint32BE(20)) // offset to blob
        data.append(req)

        return data
    }

    private static func createCDHashesPlist(hashes: [Data]) throws -> Data {
        let plist: [String: Any] = ["cdhashes": hashes]
        return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }

    static func signBinary(_ executableURL: URL, p12Data: Data, p12Password: String, teamID: String?, bundleID: String) throws {
        try MachOStripper.strip(at: executableURL)
        let machoData = try Data(contentsOf: executableURL)
        let cdBuilder = CodeDirectoryBuilder(machoData: machoData, bundleIdentifier: bundleID, teamIdentifier: teamID)

        let requirementsData = createRequirementsBlob(bundleID: bundleID)
        cdBuilder.requirementsData = requirementsData

        let cdData256 = try cdBuilder.build(hashType: 2)
        let signer = CMSSigner(p12Data: p12Data, p12Password: p12Password)
        let cdHash256 = sha256Hash(data: cdData256)
        let cdHashesPlist = try createCDHashesPlist(hashes: [cdHash256])
        let signature = try signer.sign(cdData: cdData256, cdHashesPlist: cdHashesPlist, cdHashes: [cdHash256])

        let superBlob = try buildSuperBlob(cdData: cdData256, entitlementsData: nil, requirementsData: requirementsData, signature: signature)
        let stripper = MachOStripper(data: machoData)
        let signedMachoData = try stripper.appendSignature(superBlob)
        try signedMachoData.write(to: executableURL)
    }

    private static func buildSuperBlob(cdData: Data, entitlementsData: Data?, requirementsData: Data, signature: Data) throws -> Data {
        let magic: UInt32 = 0xfade0cc0
        let count: UInt32 = entitlementsData != nil ? 4 : 3
        let headerSize = 12 + (count * 8)

        let cdOffset = headerSize
        let reqOffset = cdOffset + UInt32(cdData.count)
        let entOffset = reqOffset + UInt32(requirementsData.count)

        var entBlob = Data()
        if let entitlementsData = entitlementsData {
            entBlob.append(uint32BE(0xfade7171))
            entBlob.append(uint32BE(UInt32(entitlementsData.count + 8)))
            entBlob.append(entitlementsData)
        }

        let sigOffset = entOffset + UInt32(entBlob.count)

        var sigBlob = Data()
        sigBlob.append(uint32BE(0xfade0b01))
        sigBlob.append(uint32BE(UInt32(signature.count + 8)))
        sigBlob.append(signature)

        let totalLength = sigOffset + UInt32(sigBlob.count)

        var data = Data()
        data.append(uint32BE(magic))
        data.append(uint32BE(totalLength))
        data.append(uint32BE(count))

        // CSSLOT_CODEDIRECTORY
        data.append(uint32BE(0))
        data.append(uint32BE(cdOffset))

        // CSSLOT_REQUIREMENTS
        data.append(uint32BE(2))
        data.append(uint32BE(reqOffset))

        if entitlementsData != nil {
            // CSSLOT_ENTITLEMENTS
            data.append(uint32BE(5))
            data.append(uint32BE(entOffset))
        }

        // CSSLOT_SIGNATURESLOT
        data.append(uint32BE(0x10000))
        data.append(uint32BE(sigOffset))

        data.append(cdData)
        data.append(requirementsData)
        if entitlementsData != nil {
            data.append(entBlob)
        }
        data.append(sigBlob)

        return data
    }

    private static func verify(executableURL: URL, bundleID: String) throws {
        let machoData = try Data(contentsOf: executableURL)
        let magic = machoData.withUnsafeBytes { $0.load(as: UInt32.self) }
        let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
        let isBigEndian = magic == MH_CIGAM || magic == MH_CIGAM_64

        let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size
        var ncmds: UInt32 = 0

        if is64Bit {
            let header = machoData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: mach_header_64.self) }
            ncmds = isBigEndian ? header.ncmds.byteSwapped : header.ncmds
        } else {
            let header = machoData.withUnsafeBytes { $0.load(fromByteOffset: 0, as: mach_header.self) }
            ncmds = isBigEndian ? header.ncmds.byteSwapped : header.ncmds
        }

        var currentOffset = headerSize
        var foundSignature = false
        for _ in 0..<Int(ncmds) {
            let cmd = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: load_command.self) }
            let cmdType = isBigEndian ? cmd.cmd.byteSwapped : cmd.cmd
            let cmdSize = isBigEndian ? cmd.cmdsize.byteSwapped : cmd.cmdsize

            if cmdType == LC_CODE_SIGNATURE {
                foundSignature = true
                break
            }
            currentOffset += Int(cmdSize)
        }

        guard foundSignature else {
            throw CoreSignerError.signingError("Verification failed: LC_CODE_SIGNATURE not found")
        }
    }

    private static func uint32BE(_ val: UInt32) -> Data {
        return withUnsafeBytes(of: val.bigEndian) { Data($0) }
    }
}
