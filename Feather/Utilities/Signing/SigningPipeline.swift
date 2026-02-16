import Foundation
import CommonCrypto

enum SigningPipelineError: Error {
    case processError(String)
}

class SigningPipeline {
    private let fileManager = FileManager.default
    private let workDir: URL

    init(workDir: URL) {
        self.workDir = workDir
    }

    func sign(ipaURL: URL, p12Data: Data, p12Password: String, provisionData: Data, outputURL: URL) throws {
        let packager = IPAPackager()

        // 1. Extract IPA
        let extractionDir = workDir.appendingPathComponent("Extraction")
        let appBundleURL = try packager.extract(ipaURL: ipaURL, to: extractionDir)

        // 2. Sign the bundle
        try CoreSigner.sign(bundleURL: appBundleURL, p12Data: p12Data, p12Password: p12Password, provisionData: provisionData)

        // 3. Repackage IPA
        let payloadURL = extractionDir.appendingPathComponent("Payload")
        try packager.package(payloadURL: payloadURL, to: outputURL)
    }

    func verify(executableURL: URL, entitlements: Data, teamID: String, bundleID: String) throws {
        let machoData = try Data(contentsOf: executableURL)
        // Basic validation of Mach-O structure and signature presence
        // This is a simplified internal verification

        let magic = machoData.withUnsafeBytes { $0.load(as: uint32_t.self) }
        let is64Bit = magic == MH_MAGIC_64 || magic == MH_CIGAM_64
        let isBigEndian = magic == MH_CIGAM || magic == MH_CIGAM_64

        let headerSize = is64Bit ? MemoryLayout<mach_header_64>.size : MemoryLayout<mach_header>.size
        var ncmds: uint32_t = 0
        var sizeofcmds: uint32_t = 0

        if is64Bit {
            let header = machoData.withUnsafeBytes { $0.load(as: mach_header_64.self) }
            ncmds = isBigEndian ? OSSwapInt32(header.ncmds) : header.ncmds
            sizeofcmds = isBigEndian ? OSSwapInt32(header.sizeofcmds) : header.sizeofcmds
        } else {
            let header = machoData.withUnsafeBytes { $0.load(as: mach_header.self) }
            ncmds = isBigEndian ? OSSwapInt32(header.ncmds) : header.ncmds
            sizeofcmds = isBigEndian ? OSSwapInt32(header.sizeofcmds) : header.sizeofcmds
        }

        var currentOffset = headerSize
        var foundSignature = false
        for _ in 0..<Int(ncmds) {
            let cmd = machoData.withUnsafeBytes { $0.load(fromByteOffset: currentOffset, as: load_command.self) }
            let cmdType = isBigEndian ? OSSwapInt32(cmd.cmd) : cmd.cmd
            let cmdSize = isBigEndian ? OSSwapInt32(cmd.cmdsize) : cmd.cmdsize

            if cmdType == LC_CODE_SIGNATURE {
                foundSignature = true
                break
            }
            currentOffset += Int(cmdSize)
        }

        guard foundSignature else {
            throw SigningPipelineError.processError("Verification failed: LC_CODE_SIGNATURE not found")
        }

        // Further validations could be added here (parsing SuperBlob, checking hashes, etc.)
        print("Internal verification passed for \(bundleID)")
    }

    private func sha1Hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &hash) }
        return Data(hash)
    }

    private func sha256Hash(data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash) }
        return Data(hash)
    }

    private func createRequirementsBlob(bundleID: String) -> Data {
        // Minimal empty requirements blob
        var data = Data()
        data.append(uint32BE(0xfade0c01)) // magic
        data.append(uint32BE(12)) // length
        data.append(uint32BE(0)) // count
        return data
    }

    private func createCDHashesPlist(hashes: [Data]) throws -> Data {
        let plist: [String: Any] = ["cdhashes": hashes]
        return try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
    }

    private func buildSuperBlob(cdData: Data, entitlementsData: Data, requirementsData: Data, signature: Data) throws -> Data {
        // Build a SuperBlob containing CD, Entitlements, Requirements, and Signature
        let magic: UInt32 = 0xfade0cc0
        let count: UInt32 = 4
        let headerSize = 12 + (count * 8)

        let cdOffset = headerSize
        let reqOffset = cdOffset + UInt32(cdData.count)
        let entOffset = reqOffset + UInt32(requirementsData.count)

        // Entitlements blob header (magic + length)
        var entBlob = Data()
        entBlob.append(uint32BE(0xfade7171))
        entBlob.append(uint32BE(UInt32(entitlementsData.count + 8)))
        entBlob.append(entitlementsData)

        let sigOffset = entOffset + UInt32(entBlob.count)

        // Signature blob wrapper (magic + length)
        var sigBlob = Data()
        sigBlob.append(uint32BE(0xfade0b01))
        sigBlob.append(uint32BE(UInt32(signature.count + 8)))
        sigBlob.append(signature)

        let totalLength = sigOffset + UInt32(sigBlob.count)

        var data = Data()
        data.append(uint32BE(magic))
        data.append(uint32BE(totalLength))
        data.append(uint32BE(count))

        // Indices
        data.append(uint32BE(0)) // CSSLOT_CODEDIRECTORY
        data.append(uint32BE(cdOffset))

        data.append(uint32BE(2)) // CSSLOT_REQUIREMENTS
        data.append(uint32BE(reqOffset))

        data.append(uint32BE(5)) // CSSLOT_ENTITLEMENTS
        data.append(uint32BE(entOffset))

        data.append(uint32BE(0x10000)) // CSSLOT_SIGNATURESLOT
        data.append(uint32BE(sigOffset))

        data.append(cdData)
        data.append(requirementsData)
        data.append(entBlob)
        data.append(sigBlob)

        return data
    }

    private func uint32BE(_ val: UInt32) -> Data {
        return withUnsafeBytes(of: val.bigEndian) { Data($0) }
    }
}
