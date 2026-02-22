import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication
import OSLog
import CoreData

struct MachOAnalyzer {
    // Mach-O Magic Numbers
    static let MH_MAGIC: UInt32 = 0xfeedface
    static let MH_CIGAM: UInt32 = 0xcefaedfe
    static let MH_MAGIC_64: UInt32 = 0xfeedfacf
    static let MH_CIGAM_64: UInt32 = 0xcffaedfe
    static let FAT_MAGIC: UInt32 = 0xcafebabe
    static let FAT_CIGAM: UInt32 = 0xbebafeca

    // CPU Types
    static let CPU_TYPE_ARM: Int32 = 12
    static let CPU_TYPE_ARM64: Int32 = 0x0100000C
    static let CPU_TYPE_X86: Int32 = 7
    static let CPU_TYPE_X86_64: Int32 = 0x01000007

    // Load Commands
    static let LC_SEGMENT: UInt32 = 0x1
    static let LC_SEGMENT_64: UInt32 = 0x19
    static let LC_LOAD_DYLIB: UInt32 = 0xc
    static let LC_ID_DYLIB: UInt32 = 0xd
    static let LC_LOAD_WEAK_DYLIB: UInt32 = 0x80000018
    static let LC_REEXPORT_DYLIB: UInt32 = 0x8000001f
    static let LC_CODE_SIGNATURE: UInt32 = 0x1d
    static let LC_ENCRYPTION_INFO: UInt32 = 0x21
    static let LC_ENCRYPTION_INFO_64: UInt32 = 0x2c
    static let LC_RPATH: UInt32 = 0x8000001c

    struct BinaryInfo {
        let architectures: [String]
        let isUniversal: Bool
        let is64Bit: Bool
        let linkedLibraries: [String]
        let rpaths: [String]
        let hasCodeSignature: Bool
        let isEncrypted: Bool
        let encryptionInfo: String?
        let segments: [SegmentInfo]
        let minOSVersion: String?
        let sdkVersion: String?
        let buildVersion: String?
    }

    struct SegmentInfo {
        let name: String
        let vmAddress: UInt64
        let vmSize: UInt64
        let fileOffset: UInt64
        let fileSize: UInt64
        let sections: [String]
    }

    static func analyze(data: Data) -> BinaryInfo? {
        guard data.count >= 4 else { return nil }

        let magic = data.withUnsafeBytes { $0.load(as: UInt32.self) }

        var architectures: [String] = []
        var isUniversal = false
        var is64Bit = false
        var linkedLibraries: [String] = []
        var rpaths: [String] = []
        var hasCodeSignature = false
        var isEncrypted = false
        var encryptionInfo: String? = nil
        var segments: [SegmentInfo] = []
        var minOSVersion: String? = nil
        var sdkVersion: String? = nil
        var buildVersion: String? = nil

        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            isUniversal = true
            let swapped = magic == FAT_CIGAM

            guard data.count >= 8 else { return nil }
            var nfat_arch = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self) }
            if swapped { nfat_arch = nfat_arch.byteSwapped }

            for i in 0..<min(Int(nfat_arch), 10) {
                let offset = 8 + i * 20
                guard data.count >= offset + 8 else { break }

                var cputype = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: Int32.self) }
                if swapped { cputype = cputype.byteSwapped }

                architectures.append(cpuTypeToString(cputype))
                if cputype == CPU_TYPE_ARM64 || cputype == CPU_TYPE_X86_64 {
                    is64Bit = true
                }
            }
        } else if magic == MH_MAGIC_64 || magic == MH_CIGAM_64 {
            is64Bit = true
            let result = parseMachO64(data: data, swapped: magic == MH_CIGAM_64)
            architectures = result.architectures
            linkedLibraries = result.linkedLibraries
            rpaths = result.rpaths
            hasCodeSignature = result.hasCodeSignature
            isEncrypted = result.isEncrypted
            encryptionInfo = result.encryptionInfo
            segments = result.segments
            minOSVersion = result.minOSVersion
            sdkVersion = result.sdkVersion
            buildVersion = result.buildVersion
        } else if magic == MH_MAGIC || magic == MH_CIGAM {
            let result = parseMachO32(data: data, swapped: magic == MH_CIGAM)
            architectures = result.architectures
            linkedLibraries = result.linkedLibraries
            rpaths = result.rpaths
            hasCodeSignature = result.hasCodeSignature
            isEncrypted = result.isEncrypted
            encryptionInfo = result.encryptionInfo
        }

        return BinaryInfo(
            architectures: architectures,
            isUniversal: isUniversal,
            is64Bit: is64Bit,
            linkedLibraries: linkedLibraries,
            rpaths: rpaths,
            hasCodeSignature: hasCodeSignature,
            isEncrypted: isEncrypted,
            encryptionInfo: encryptionInfo,
            segments: segments,
            minOSVersion: minOSVersion,
            sdkVersion: sdkVersion,
            buildVersion: buildVersion
        )
    }

    private static func parseMachO64(data: Data, swapped: Bool) -> BinaryInfo {
        var architectures: [String] = []
        var linkedLibraries: [String] = []
        var rpaths: [String] = []
        var hasCodeSignature = false
        var isEncrypted = false
        var encryptionInfo: String? = nil
        var segments: [SegmentInfo] = []
        var minOSVersion: String? = nil
        var sdkVersion: String? = nil
        let buildVersion: String? = nil

        guard data.count >= 32 else {
            return BinaryInfo(architectures: [], isUniversal: false, is64Bit: true, linkedLibraries: [], rpaths: [], hasCodeSignature: false, isEncrypted: false, encryptionInfo: nil, segments: [], minOSVersion: nil, sdkVersion: nil, buildVersion: nil)
        }

        var cputype = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self) }
        var ncmds = data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: UInt32.self) }

        if swapped {
            cputype = cputype.byteSwapped
            ncmds = ncmds.byteSwapped
        }

        architectures.append(cpuTypeToString(cputype))

        var offset = 32 // mach_header_64 size

        for _ in 0..<min(Int(ncmds), 1000) {
            guard data.count >= offset + 8 else { break }

            var cmd = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            var cmdsize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) }

            if swapped {
                cmd = cmd.byteSwapped
                cmdsize = cmdsize.byteSwapped
            }

            switch cmd {
            case LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB:
                if let name = extractDylibName(data: data, offset: offset, swapped: swapped) {
                    linkedLibraries.append(name)
                }
            case LC_RPATH:
                if let path = extractRpath(data: data, offset: offset, swapped: swapped) {
                    rpaths.append(path)
                }
            case LC_CODE_SIGNATURE:
                hasCodeSignature = true
            case LC_ENCRYPTION_INFO_64:
                let cryptid = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 16, as: UInt32.self) }
                isEncrypted = (swapped ? cryptid.byteSwapped : cryptid) != 0
                encryptionInfo = isEncrypted ? "Encrypted (FairPlay DRM)" : "Not Encrypted"
            case LC_SEGMENT_64:
                if let segment = parseSegment64(data: data, offset: offset, swapped: swapped) {
                    segments.append(segment)
                }
            case 0x32: // LC_BUILD_VERSION
                if data.count >= offset + 24 {
                    var minOS = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 12, as: UInt32.self) }
                    var sdk = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 16, as: UInt32.self) }
                    if swapped {
                        minOS = minOS.byteSwapped
                        sdk = sdk.byteSwapped
                    }
                    minOSVersion = formatVersion(minOS)
                    sdkVersion = formatVersion(sdk)
                }
            case 0x24, 0x25: // LC_VERSION_MIN_IPHONEOS, LC_VERSION_MIN_MACOSX
                if data.count >= offset + 16 {
                    var version = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self) }
                    var sdk = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 12, as: UInt32.self) }
                    if swapped {
                        version = version.byteSwapped
                        sdk = sdk.byteSwapped
                    }
                    minOSVersion = formatVersion(version)
                    sdkVersion = formatVersion(sdk)
                }
            default:
                break
            }

            offset += Int(cmdsize)
        }

        return BinaryInfo(
            architectures: architectures,
            isUniversal: false,
            is64Bit: true,
            linkedLibraries: linkedLibraries,
            rpaths: rpaths,
            hasCodeSignature: hasCodeSignature,
            isEncrypted: isEncrypted,
            encryptionInfo: encryptionInfo,
            segments: segments,
            minOSVersion: minOSVersion,
            sdkVersion: sdkVersion,
            buildVersion: buildVersion
        )
    }

    private static func parseMachO32(data: Data, swapped: Bool) -> BinaryInfo {
        var architectures: [String] = []
        var linkedLibraries: [String] = []
        var rpaths: [String] = []
        var hasCodeSignature = false
        var isEncrypted = false
        var encryptionInfo: String? = nil

        guard data.count >= 28 else {
            return BinaryInfo(architectures: [], isUniversal: false, is64Bit: false, linkedLibraries: [], rpaths: [], hasCodeSignature: false, isEncrypted: false, encryptionInfo: nil, segments: [], minOSVersion: nil, sdkVersion: nil, buildVersion: nil)
        }

        var cputype = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: Int32.self) }
        var ncmds = data.withUnsafeBytes { $0.load(fromByteOffset: 16, as: UInt32.self) }

        if swapped {
            cputype = cputype.byteSwapped
            ncmds = ncmds.byteSwapped
        }

        architectures.append(cpuTypeToString(cputype))

        var offset = 28 // mach_header size

        for _ in 0..<min(Int(ncmds), 1000) {
            guard data.count >= offset + 8 else { break }

            var cmd = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            var cmdsize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 4, as: UInt32.self) }

            if swapped {
                cmd = cmd.byteSwapped
                cmdsize = cmdsize.byteSwapped
            }

            switch cmd {
            case LC_LOAD_DYLIB, LC_LOAD_WEAK_DYLIB, LC_REEXPORT_DYLIB:
                if let name = extractDylibName(data: data, offset: offset, swapped: swapped) {
                    linkedLibraries.append(name)
                }
            case LC_RPATH:
                if let path = extractRpath(data: data, offset: offset, swapped: swapped) {
                    rpaths.append(path)
                }
            case LC_CODE_SIGNATURE:
                hasCodeSignature = true
            case LC_ENCRYPTION_INFO:
                let cryptid = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 12, as: UInt32.self) }
                isEncrypted = (swapped ? cryptid.byteSwapped : cryptid) != 0
                encryptionInfo = isEncrypted ? "Encrypted (FairPlay DRM)" : "Not Encrypted"
            default:
                break
            }

            offset += Int(cmdsize)
        }

        return BinaryInfo(
            architectures: architectures,
            isUniversal: false,
            is64Bit: false,
            linkedLibraries: linkedLibraries,
            rpaths: rpaths,
            hasCodeSignature: hasCodeSignature,
            isEncrypted: isEncrypted,
            encryptionInfo: encryptionInfo,
            segments: [],
            minOSVersion: nil,
            sdkVersion: nil,
            buildVersion: nil
        )
    }

    private static func parseSegment64(data: Data, offset: Int, swapped: Bool) -> SegmentInfo? {
        guard data.count >= offset + 72 else { return nil }

        let nameData = data.subdata(in: (offset + 8)..<(offset + 24))
        let name = String(data: nameData, encoding: .utf8)?.trimmingCharacters(in: .controlCharacters) ?? ""

        var vmaddr = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 24, as: UInt64.self) }
        var vmsize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 32, as: UInt64.self) }
        var fileoff = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 40, as: UInt64.self) }
        var filesize = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 48, as: UInt64.self) }

        if swapped {
            vmaddr = vmaddr.byteSwapped
            vmsize = vmsize.byteSwapped
            fileoff = fileoff.byteSwapped
            filesize = filesize.byteSwapped
        }

        return SegmentInfo(
            name: name,
            vmAddress: vmaddr,
            vmSize: vmsize,
            fileOffset: fileoff,
            fileSize: filesize,
            sections: []
        )
    }

    private static func extractDylibName(data: Data, offset: Int, swapped: Bool) -> String? {
        guard data.count >= offset + 24 else { return nil }

        var nameOffset = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self) }
        if swapped { nameOffset = nameOffset.byteSwapped }

        let nameStart = offset + Int(nameOffset)
        guard nameStart < data.count else { return nil }

        var nameEnd = nameStart
        while nameEnd < data.count && data[nameEnd] != 0 {
            nameEnd += 1
        }

        let nameData = data.subdata(in: nameStart..<nameEnd)
        return String(data: nameData, encoding: .utf8)
    }

    private static func extractRpath(data: Data, offset: Int, swapped: Bool) -> String? {
        guard data.count >= offset + 12 else { return nil }

        var pathOffset = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt32.self) }
        if swapped { pathOffset = pathOffset.byteSwapped }

        let pathStart = offset + Int(pathOffset)
        guard pathStart < data.count else { return nil }

        var pathEnd = pathStart
        while pathEnd < data.count && data[pathEnd] != 0 {
            pathEnd += 1
        }

        let pathData = data.subdata(in: pathStart..<pathEnd)
        return String(data: pathData, encoding: .utf8)
    }

    private static func cpuTypeToString(_ cputype: Int32) -> String {
        switch cputype {
        case CPU_TYPE_ARM: return "arm"
        case CPU_TYPE_ARM64: return "arm64"
        case CPU_TYPE_X86: return "i386"
        case CPU_TYPE_X86_64: return "x86_64"
        default: return "unknown (\(cputype))"
        }
    }

    private static func formatVersion(_ version: UInt32) -> String {
        let major = (version >> 16) & 0xFFFF
        let minor = (version >> 8) & 0xFF
        let patch = version & 0xFF
        return "\(major).\(minor).\(patch)"
    }
}

// MARK: - Pure Swift Code Signature Analyzer
struct CodeSignatureAnalyzer {
    static let CSMAGIC_EMBEDDED_SIGNATURE: UInt32 = 0xfade0cc0
    static let CSMAGIC_CODEDIRECTORY: UInt32 = 0xfade0c02
    static let CSMAGIC_REQUIREMENTS: UInt32 = 0xfade0c01
    static let CSMAGIC_ENTITLEMENTS: UInt32 = 0xfade7171
    static let CSMAGIC_BLOBWRAPPER: UInt32 = 0xfade0b01

    struct SignatureInfo {
        let hasSignature: Bool
        let signatureSize: Int
        let teamID: String?
        let signingIdentity: String?
        let entitlements: [String: Any]?
        let codeDirectoryVersion: String?
        let hashType: String?
        let pageSize: Int?
        let flags: [String]
        let requirements: String?
    }

    static func analyzeSignature(data: Data, signatureOffset: UInt32, signatureSize: UInt32) -> SignatureInfo? {
        let offset = Int(signatureOffset)
        let size = Int(signatureSize)

        guard data.count >= offset + size, size > 8 else { return nil }

        let sigData = data.subdata(in: offset..<(offset + size))

        let magic = sigData.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard magic == CSMAGIC_EMBEDDED_SIGNATURE else { return nil }

        var teamID: String? = nil
        var signingIdentity: String? = nil
        var entitlements: [String: Any]? = nil
        var codeDirectoryVersion: String? = nil
        var hashType: String? = nil
        var pageSize: Int? = nil
        var flags: [String] = []
        var requirements: String? = nil

        let count = sigData.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt32.self).bigEndian }

        var blobOffset = 8
        for _ in 0..<min(Int(count), 20) {
            guard sigData.count >= blobOffset + 8 else { break }

            let _ = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobOffset, as: UInt32.self).bigEndian } // blobType - not used but part of structure
            let blobDataOffset = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobOffset + 4, as: UInt32.self).bigEndian }

            let blobStart = Int(blobDataOffset)
            guard sigData.count > blobStart + 8 else {
                blobOffset += 8
                continue
            }

            let blobMagic = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart, as: UInt32.self).bigEndian }
            let blobLength = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 4, as: UInt32.self).bigEndian }

            switch blobMagic {
            case CSMAGIC_CODEDIRECTORY:
                if sigData.count >= blobStart + 44 {
                    let version = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 8, as: UInt32.self).bigEndian }
                    codeDirectoryVersion = "0x\(String(version, radix: 16))"

                    let flagsValue = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 12, as: UInt32.self).bigEndian }
                    flags = parseCodeDirectoryFlags(flagsValue)

                    let hashTypeValue = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 36, as: UInt8.self) }
                    hashType = hashTypeToString(hashTypeValue)

                    let pageSizeLog2 = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 39, as: UInt8.self) }
                    pageSize = 1 << Int(pageSizeLog2)

                    // Extract team ID if present
                    if version >= 0x20200 && sigData.count >= blobStart + 52 {
                        let teamOffset = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 48, as: UInt32.self).bigEndian }
                        if teamOffset > 0 {
                            let teamStart = blobStart + Int(teamOffset)
                            if let extracted = extractNullTerminatedString(from: sigData, at: teamStart) {
                                teamID = extracted
                            }
                        }
                    }

                    // Extract signing identity
                    let identOffset = sigData.withUnsafeBytes { $0.load(fromByteOffset: blobStart + 28, as: UInt32.self).bigEndian }
                    if identOffset > 0 {
                        let identStart = blobStart + Int(identOffset)
                        if let extracted = extractNullTerminatedString(from: sigData, at: identStart) {
                            signingIdentity = extracted
                        }
                    }
                }

            case CSMAGIC_ENTITLEMENTS:
                let entStart = blobStart + 8
                let entLength = Int(blobLength) - 8
                if sigData.count >= entStart + entLength && entLength > 0 {
                    let entData = sigData.subdata(in: entStart..<(entStart + entLength))
                    if let plist = try? PropertyListSerialization.propertyList(from: entData, format: nil) as? [String: Any] {
                        entitlements = plist
                    }
                }

            case CSMAGIC_REQUIREMENTS:
                requirements = "Present (binary format)"

            default:
                break
            }

            blobOffset += 8
        }

        return SignatureInfo(
            hasSignature: true,
            signatureSize: size,
            teamID: teamID,
            signingIdentity: signingIdentity,
            entitlements: entitlements,
            codeDirectoryVersion: codeDirectoryVersion,
            hashType: hashType,
            pageSize: pageSize,
            flags: flags,
            requirements: requirements
        )
    }

    private static func extractNullTerminatedString(from data: Data, at offset: Int) -> String? {
        guard offset < data.count else { return nil }
        var end = offset
        while end < data.count && data[end] != 0 {
            end += 1
        }
        guard end > offset else { return nil }
        let strData = data.subdata(in: offset..<end)
        return String(data: strData, encoding: .utf8)
    }

    private static func hashTypeToString(_ type: UInt8) -> String {
        switch type {
        case 1: return "SHA-1"
        case 2: return "SHA-256"
        case 3: return "SHA-256 Truncated"
        case 4: return "SHA-384"
        case 5: return "SHA-512"
        default: return "Unknown (\(type))"
        }
    }

    private static func parseCodeDirectoryFlags(_ flags: UInt32) -> [String] {
        var result: [String] = []
        if flags & 0x0001 != 0 { result.append("Host") }
        if flags & 0x0002 != 0 { result.append("Ad-Hoc") }
        if flags & 0x0004 != 0 { result.append("Force Hard") }
        if flags & 0x0008 != 0 { result.append("Force Kill") }
        if flags & 0x0010 != 0 { result.append("Force Expiration") }
        if flags & 0x0020 != 0 { result.append("Restrict") }
        if flags & 0x0040 != 0 { result.append("Enforcement") }
        if flags & 0x0080 != 0 { result.append("Library Validation") }
        if flags & 0x0100 != 0 { result.append("Entitlements Validated") }
        if flags & 0x0200 != 0 { result.append("NVRAM Unrestricted") }
        if flags & 0x0400 != 0 { result.append("Runtime") }
        if flags & 0x0800 != 0 { result.append("Linker Signed") }
        return result
    }
}
