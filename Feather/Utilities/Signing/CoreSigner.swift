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
              let bundleIdentifierFromProvision = entitlements["application-identifier"] as? String else {
            throw CoreSignerError.signingError("Invalid provisioning profile metadata")
        }

        AppLogManager.shared.verbose("Parsed Team ID: \(teamIdentifier)", category: "Signing")
        AppLogManager.shared.verbose("Parsed Bundle ID from Provision: \(bundleIdentifierFromProvision)", category: "Signing")
        AppLogManager.shared.verbose("Parsed Entitlements: \(entitlements)", category: "Signing")

        var cleanBundleID = bundleIdentifierFromProvision
        if cleanBundleID.hasPrefix(teamIdentifier + ".") {
            cleanBundleID = String(cleanBundleID.dropFirst(teamIdentifier.count + 1))
        }

        // Validate Bundle ID and Team ID
        if let infoBundleID = infoPlist["CFBundleIdentifier"] as? String, infoBundleID != cleanBundleID {
            AppLogManager.shared.warning("Bundle ID mismatch: Info.plist (\(infoBundleID)) vs Provisioning Profile (\(cleanBundleID)). Fixing Info.plist.", category: "Signing")
            let mutableInfoPlist = infoPlist.mutableCopy() as! NSMutableDictionary
            mutableInfoPlist["CFBundleIdentifier"] = cleanBundleID
            try mutableInfoPlist.write(to: infoPlistURL)
        }

        // 3. Rebuild CodeResources
        AppLogManager.shared.verbose("Generating CodeResources...", category: "Signing")
        let resourcesBuilder = CodeResourcesBuilder(bundleURL: bundleURL, executableName: executableName)
        let codeResourcesData = try resourcesBuilder.build()
        let codeSignatureDir = bundleURL.appendingPathComponent("_CodeSignature")
        try FileManager.default.createDirectory(at: codeSignatureDir, withIntermediateDirectories: true)
        try codeResourcesData.write(to: codeSignatureDir.appendingPathComponent("CodeResources"))
        AppLogManager.shared.verbose("CodeResources generated successfully", category: "Signing")

        // 4. Build CodeDirectory
        AppLogManager.shared.verbose("Generating CodeDirectory...", category: "Signing")
        let machoData = try Data(contentsOf: executableURL)
        let cdBuilder = CodeDirectoryBuilder(machoData: machoData, bundleIdentifier: cleanBundleID, teamIdentifier: teamIdentifier)
        cdBuilder.infoPlistData = try Data(contentsOf: infoPlistURL)
        cdBuilder.codeResourcesData = codeResourcesData
        cdBuilder.entitlementsData = entitlementsData

        let entitlementsDict = provisionPlist["Entitlements"] as? [String: Any] ?? [:]
        let entitlementsDerData = DEREncoder.encode(entitlementsDict)
        cdBuilder.entitlementsDerData = entitlementsDerData

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

        let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size

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
        AppLogManager.shared.verbose("CodeDirectory generated (SHA-256)", category: "Signing")

        // 5. Sign
        AppLogManager.shared.verbose("Creating CMS signature...", category: "Signing")
        let signer = CMSSigner(p12Data: p12Data, p12Password: p12Password)
        let cdHash256 = sha256Hash(data: cdData256)
        let cdHashesPlist = try createCDHashesPlist(hashes: [cdHash256])

        let signature = try signer.sign(cdData: cdData256, cdHashesPlist: cdHashesPlist, cdHashes: [cdHash256])
        AppLogManager.shared.verbose("CMS signature created successfully", category: "Signing")

        // 6. SuperBlob
        AppLogManager.shared.verbose("Building SuperBlob...", category: "Signing")
        let superBlob = try buildSuperBlob(cdData: cdData256, entitlementsData: entitlementsData, entitlementsDerData: entitlementsDerData, requirementsData: requirementsData, signature: signature)

        // 7. Insert
        AppLogManager.shared.verbose("Inserting signature into Mach-O...", category: "Signing")
        let stripper = MachOStripper(data: machoData)
        let signedMachoData = try stripper.appendSignature(superBlob)
        try signedMachoData.write(to: executableURL)

        // 8. Verify
        try verify(executableURL: executableURL, bundleID: cleanBundleID)

        // 9. Strict Internal Validation
        try strictValidate(executableURL: executableURL, expectedBundleID: cleanBundleID, expectedTeamID: teamIdentifier, expectedEntitlements: entitlementsData)
    }

    private static func strictValidate(executableURL: URL, expectedBundleID: String, expectedTeamID: String, expectedEntitlements: Data) throws {
        AppLogManager.shared.info("Starting strict internal validation", category: "Signing")
        let machoData = try Data(contentsOf: executableURL)

        // 1. Mach-O Structural Integrity
        let magic = machoData.withUnsafeBytes { $0.load(as: UInt32.self) }
        guard magic == MH_MAGIC_64 || magic == MH_CIGAM_64 else {
            throw CoreSignerError.signingError("Validation failed: Invalid Mach-O magic")
        }

        // 2. Find SuperBlob
        var currentOffset = MemoryLayout<mach_header_64>.size
        let ncmds: UInt32
        let header = machoData.withUnsafeBytes { $0.load(as: mach_header_64.self) }
        let isBigEndian = magic == MH_CIGAM_64
        ncmds = isBigEndian ? header.ncmds.byteSwapped : header.ncmds

        var sigOffset: UInt32 = 0
        var sigSize: UInt32 = 0
        for _ in 0..<Int(ncmds) {
            let cmd = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: load_command.self) }
            let cmdType = isBigEndian ? cmd.cmd.byteSwapped : cmd.cmd
            let cmdSize = isBigEndian ? cmd.cmdsize.byteSwapped : cmd.cmdsize

            if cmdType == LC_CODE_SIGNATURE {
                let sigCmd = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: linkedit_data_command.self) }
                sigOffset = isBigEndian ? sigCmd.dataoff.byteSwapped : sigCmd.dataoff
                sigSize = isBigEndian ? sigCmd.datasize.byteSwapped : sigCmd.datasize
                break
            }
            currentOffset += Int(cmdSize)
        }

        guard sigOffset > 0 else {
            throw CoreSignerError.signingError("Validation failed: LC_CODE_SIGNATURE not found")
        }

        let superBlobData = machoData.subdata(in: Int(sigOffset)..<Int(sigOffset + sigSize))
        let sbMagic = superBlobData.withUnsafeBytes { $0.load(as: UInt32.self) }.bigEndian
        guard sbMagic == 0xfade0cc0 else {
            throw CoreSignerError.signingError("Validation failed: Invalid SuperBlob magic")
        }

        // 3. Check Slots
        let sbCount = superBlobData.withUnsafeBytes { $0.load(fromByteOffset: 8, as: UInt32.self) }.bigEndian
        var foundEntitlements = false
        var foundCD = false

        for i in 0..<Int(sbCount) {
            let slotType = superBlobData.withUnsafeBytes { $0.load(fromByteOffset: 12 + i * 8, as: UInt32.self) }.bigEndian
            let slotOffset = superBlobData.withUnsafeBytes { $0.load(fromByteOffset: 12 + i * 8 + 4, as: UInt32.self) }.bigEndian

            if slotType == 0 { // CSSLOT_CODEDIRECTORY
                foundCD = true
                let cdBlobSize = superBlobData.withUnsafeBytes { $0.load(fromByteOffset: Int(slotOffset + 4), as: UInt32.self) }.bigEndian
                let cdData = superBlobData.subdata(in: Int(slotOffset)..<Int(slotOffset + cdBlobSize))

                let identOffset = cdData.withUnsafeBytes { $0.load(fromByteOffset: 20, as: UInt32.self) }.bigEndian
                let teamOffset = cdData.withUnsafeBytes { $0.load(fromByteOffset: 52, as: UInt32.self) }.bigEndian

                let ident = cdData.subdata(in: Int(identOffset)..<cdData.count).withUnsafeBytes { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
                if ident != expectedBundleID {
                    throw CoreSignerError.signingError("Validation failed: Bundle ID mismatch in CodeDirectory (\(ident) vs \(expectedBundleID))")
                }

                if teamOffset > 0 {
                    let team = cdData.subdata(in: Int(teamOffset)..<cdData.count).withUnsafeBytes { String(cString: $0.bindMemory(to: CChar.self).baseAddress!) }
                    if team != expectedTeamID {
                        throw CoreSignerError.signingError("Validation failed: Team ID mismatch in CodeDirectory (\(team) vs \(expectedTeamID))")
                    }
                }
            } else if slotType == 5 { // CSSLOT_ENTITLEMENTS
                let entBlobSize = superBlobData.withUnsafeBytes { $0.load(fromByteOffset: Int(slotOffset + 4), as: UInt32.self) }.bigEndian
                let entData = superBlobData.subdata(in: Int(slotOffset + 8)..<Int(slotOffset + entBlobSize))

                if entData != expectedEntitlements {
                    throw CoreSignerError.signingError("Validation failed: Entitlements mismatch in SuperBlob")
                }
                foundEntitlements = true
            }
        }

        if !foundCD {
            throw CoreSignerError.signingError("Validation failed: CodeDirectory slot not found in SuperBlob")
        }

        if !foundEntitlements {
            throw CoreSignerError.signingError("Validation failed: Entitlements slot not found in SuperBlob")
        }

        AppLogManager.shared.success("Strict internal validation passed", category: "Signing")
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

        let superBlob = try buildSuperBlob(cdData: cdData256, entitlementsData: nil, entitlementsDerData: nil, requirementsData: requirementsData, signature: signature)
        let stripper = MachOStripper(data: machoData)
        let signedMachoData = try stripper.appendSignature(superBlob)
        try signedMachoData.write(to: executableURL)

        try verify(executableURL: executableURL, bundleID: bundleID)
    }

    private static func buildSuperBlob(cdData: Data, entitlementsData: Data?, entitlementsDerData: Data?, requirementsData: Data, signature: Data) throws -> Data {
        let magic: UInt32 = 0xfade0cc0
        var count: UInt32 = 3 // CD, Req, Sig
        if entitlementsData != nil { count += 1 }
        if entitlementsDerData != nil { count += 1 }

        let headerSize = 12 + (count * 8)

        let cdOffset = headerSize
        let reqOffset = cdOffset + UInt32(cdData.count)

        var entOffset: UInt32 = 0
        var entBlob = Data()
        if let entitlementsData = entitlementsData {
            entOffset = reqOffset + UInt32(requirementsData.count)
            entBlob.append(uint32BE(0xfade7171))
            entBlob.append(uint32BE(UInt32(entitlementsData.count + 8)))
            entBlob.append(entitlementsData)
        }

        var derOffset: UInt32 = 0
        var derBlob = Data()
        if let entitlementsDerData = entitlementsDerData {
            derOffset = (entitlementsData != nil) ? entOffset + UInt32(entBlob.count) : reqOffset + UInt32(requirementsData.count)
            derBlob.append(uint32BE(0xfade7172))
            derBlob.append(uint32BE(UInt32(entitlementsDerData.count + 8)))
            derBlob.append(entitlementsDerData)
        }

        let sigOffset = (entitlementsDerData != nil) ? derOffset + UInt32(derBlob.count) : ((entitlementsData != nil) ? entOffset + UInt32(entBlob.count) : reqOffset + UInt32(requirementsData.count))

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

        if entitlementsDerData != nil {
            // CSSLOT_DER_ENTITLEMENTS
            data.append(uint32BE(7))
            data.append(uint32BE(derOffset))
        }

        // CSSLOT_SIGNATURESLOT
        data.append(uint32BE(0x10000))
        data.append(uint32BE(sigOffset))

        data.append(cdData)
        data.append(requirementsData)
        if entitlementsData != nil {
            data.append(entBlob)
        }
        if entitlementsDerData != nil {
            data.append(derBlob)
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
