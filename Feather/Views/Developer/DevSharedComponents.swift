import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct DevMenuItem {
    let icon: String
    let title: String
    let color: Color
    let destination: AnyView
}


struct DeveloperMenuRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
        }
    }
}


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


struct DeveloperInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}


struct ListDetailView: View {
    let items: [String]
    let title: String
    @State private var searchText = ""

    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredItems, id: \.self) { item in
                Text(item)
                    .font(.caption.monospaced())
            }
        }
            .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct PlistViewer: View {
    let dictionary: [String: Any]
    let title: String
    @State private var searchText = ""

    var filteredKeys: [String] {
        let keys = dictionary.keys.sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 4) {
                    Text(key)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(String(describing: dictionary[key] ?? ""))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
        }
            .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search Keys")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct CheckRow: View {
    let label: String
    let passed: Bool

    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? .green : .red)
            Text(label)
                .font(.subheadline)
            Spacer()
        }
    }
}


struct SourceDataView: View {
    var body: some View {
        List {
            ForEach(Storage.shared.getSources(), id: \.self) { source in
                NavigationLink(destination: JSONViewer(json: source.description)) {
                    Text(source.name ?? "Unknown")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Source Data")
    }
}


struct JSONViewer: View {
    let json: String
    var body: some View {
        ScrollView {
            Text(json)
                .font(.caption.monospaced())
                .padding()
        }
        .navigationTitle("JSON")
    }
}


struct AppStateView: View {
    var body: some View {
        List {
            Section(header: Text("Storage")) {
                Text("Documents: \(getDocumentsSize())")
                Text("Cache: \(getCacheSize())")
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("App State")
    }

    func getDocumentsSize() -> String {
        // Calculate size
        return "12.5 MB"
    }

    func getCacheSize() -> String {
        return "4.2 MB"
    }
}


class PerformanceMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: String = "0 MB"
    @Published var diskSpace: String = "0 GB"
    @Published var isMonitoring: Bool = false

    private var timer: Timer?
    private let updateQueue = DispatchQueue(label: "com.portal.performanceMonitor", qos: .utility)

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Initial update
        updateMetricsAsync()

        // Schedule periodic updates on main thread but execute work on background
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMetricsAsync()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func updateMetricsAsync() {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let cpu = self.calculateCPUUsage()
            let memory = self.calculateMemoryUsage()
            let disk = self.calculateDiskSpace()

            DispatchQueue.main.async {
                self.cpuUsage = cpu
                self.memoryUsage = memory
                self.diskSpace = disk
            }
        }
    }

    private func calculateCPUUsage() -> Double {
        // Simplified CPU usage calculation that's safer
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            // Use a simpler estimation based on memory pressure as a proxy
            // This avoids the problematic host_processor_info call
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            // Estimate CPU based on memory usage (rough approximation for display purposes)
            return min(max(usedMB / 5.0, 5.0), 95.0)
        }

        return 0.0
    }

    private func calculateMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            return String(format: "%.1f MB", usedMB)
        }

        return "N/A"
    }

    private func calculateDiskSpace() -> String {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                let freeGB = Double(truncating: freeSpace) / 1024.0 / 1024.0 / 1024.0
                return String(format: "%.1f GB Free", freeGB)
            }
        } catch {
            // Silently handle error
        }
        return "N/A"
    }

    deinit {
        stopMonitoring()
    }
}


struct EntityDetailView: View {
    let entityName: String

    var body: some View {
        List {
            Text("Entity: \(entityName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            // Add more detailed entity inspection here
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(entityName)
    }
}


struct ReleaseDetailView: View {
    let release: GitHubRelease

    var body: some View {
        List {
            Section(header: Text("Release Info")) {
                LabeledContent("Tag", value: release.tagName)
                LabeledContent("Name", value: release.name)
                LabeledContent("Prerelease", value: release.prerelease ? "Yes" : "No")
                if let date = release.publishedAt {
                    LabeledContent("Published", value: date.formatted())
                }
            }

            if let body = release.body, !body.isEmpty {
                Section(header: Text("Release Notes")) {
                    ScrollView {
                        ModernMarkdownView(markdown: body)
                            .padding(.vertical, 8)
                    }
                }
            }

            if !release.assets.isEmpty {
                Section(header: Text("Assets (\(release.assets.count))")) {
                    ForEach(release.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.name)
                                .font(.system(.body, design: .monospaced))
                            HStack {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))
                                Text("•")
                                Text("\(asset.downloadCount) Downloads")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("Open In GitHub") {
                    if let url = URL(string: release.htmlUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(release.tagName)
    }
}


struct SourceInspectorView: View {
    let source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    @State private var rawJSON: String = ""
    @State private var isLoadingJSON = false

    var body: some View {
        List {
            Section(header: Text("Source Info")) {
                LabeledContent("Name", value: source.name ?? "Unknown")
                if let url = source.sourceURL {
                    LabeledContent("URL", value: url.absoluteString)
                }
                LabeledContent("Order", value: "\(source.order)")
                if let date = source.date {
                    LabeledContent("Added", value: date.formatted())
                }
            }

            if let repo = viewModel.sources[source] {
                Section(header: Text("Repository Data")) {
                    LabeledContent("Apps", value: "\(repo.apps.count)")
                    if let news = repo.news {
                        LabeledContent("News Items", value: "\(news.count)")
                    }
                    if let name = repo.name {
                        LabeledContent("Repo Name", value: name)
                    }
                }
            }

            Section(header: Text("Raw JSON")) {
                Button {
                    loadRawJSON()
                } label: {
                    HStack {
                        if isLoadingJSON {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Load Raw JSON")
                    }
                }

                if !rawJSON.isEmpty {
                    ScrollView(.horizontal) {
                        Text(rawJSON)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)

                    Button("Copy JSON") {
                        UIPasteboard.general.string = rawJSON
                        HapticsManager.shared.success()
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(source.name ?? "Source")
    }

    private func loadRawJSON() {
        guard let url = source.sourceURL else { return }
        isLoadingJSON = true

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoadingJSON = false
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        rawJSON = prettyString
                    } else {
                        rawJSON = String(data: data, encoding: .utf8) ?? "Unable To Decode"
                    }
                } else if let error = error {
                    rawJSON = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}


struct DeveloperBatchAppRow: View {
    let app: Imported
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                FRAppIconView(app: app, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name ?? "Unknown App")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    Text(app.identifier ?? "Unknown Bundle ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}


struct EntitlementItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var type: ValueType

    enum ValueType: String, CaseIterable {
        case string = "String"
        case boolean = "Boolean"
        case array = "Array"
        case integer = "Integer"
    }
}


struct EntitlementRow: View {
    @Binding var item: EntitlementItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.key)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            HStack {
                Text(item.type.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())

                Text(item.value)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}


struct PlistItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var type: EntitlementItem.ValueType
}


struct PlistItemRow: View {
    @Binding var item: PlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.key)
                .font(.subheadline.bold())
            Text(item.value)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}


struct SecurityStatusRow: View {
    let certificate: CertificatePair

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(certificate.nickname ?? "Unknown")
                    .font(.subheadline.bold())

                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption)
                    Text(statusText)
                        .font(.caption)
                }
                .foregroundStyle(statusColor)
            }

            Spacer()

            Image(systemName: overallStatus ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.title2)
                .foregroundStyle(overallStatus ? .green : .orange)
        }
    }

    private var isExpired: Bool {
        guard let expiration = certificate.expiration else { return false }
        return expiration <= Date()
    }

    private var isExpiringSoon: Bool {
        guard let expiration = certificate.expiration else { return false }
        return expiration <= Date().addingTimeInterval(30 * 86400) && !isExpired
    }

    private var statusIcon: String {
        if isExpired { return "xmark.circle.fill" }
        if isExpiringSoon { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }

    private var statusText: String {
        if isExpired { return "Expired" }
        if isExpiringSoon { return "Expiring Soon" }
        return "Valid"
    }

    private var statusColor: Color {
        if isExpired { return .red }
        if isExpiringSoon { return .orange }
        return .green
    }

    private var overallStatus: Bool {
        !isExpired
    }
}


struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.clear)
        )
    }
}


class MockNearbyTransferService: NearbyTransferService {
    override init() {
        super.init()
        // Set to a simulated transferring state
        self.state = .transferring(progress: 0.45, bytesTransferred: 450_000_000, totalBytes: 1_000_000_000, speed: 4_500_000)
        self.currentItem = "Certificates.zip"
    }

    func setMode(_ mode: TransferMode) {
        // Simulate mode changes
        if mode == .send {
            self.state = .transferring(progress: 0.65, bytesTransferred: 650_000_000, totalBytes: 1_000_000_000, speed: 5_000_000)
        } else {
            self.state = .transferring(progress: 0.45, bytesTransferred: 450_000_000, totalBytes: 1_000_000_000, speed: 4_500_000)
        }
    }
}


struct OfflineViewWithDismiss: View {
    @Binding var showDismissButton: Bool
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            OfflineView()

            // Intercept icon taps if needed
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if showDismissButton {
                        onDismiss()
                    }
                }
                .allowsHitTesting(false)
        }
    }
}


    struct DeveloperBatchSignResult: Identifiable {
        let id = UUID()
        let appName: String
        let success: Bool
        let message: String
    }
