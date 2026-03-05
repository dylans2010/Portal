// made by dylan, if you are doing a fork, DO NOT REMOVE THIS
// this was hard to make so please leave the credits, or idc what yall do atp
import Foundation
import CryptoKit
import UniformTypeIdentifiers

/// Pure Swift implementation for file analysis and operations because fuck C++
class FileAnalysisEngine {
    
    // MARK: - File Type Enum
    enum FileType: String {
        case unknown = "Unknown"
        case text = "Text"
        case image = "Image"
        case video = "Video"
        case audio = "Audio"
        case archive = "Archive"
        case ipa = "IPA"
        case machO = "Mach-O"
        case plist = "Property List"
        case json = "JSON"
        case xml = "XML"
        case pdf = "PDF"
        case p12 = "Certificate"
        case mobileProvision = "Provisioning Profile"
        case dylib = "Dynamic Library"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    // MARK: - File Information
    struct FileInformation {
        let path: String
        let name: String
        let type: FileType
        let size: UInt64
        let magicSignature: String
        let isDirectory: Bool
        let isExecutable: Bool
        let isSigned: Bool
    }
    
    // MARK: - Hash Information
    struct HashInformation {
        let md5: String
        let sha1: String
        let sha256: String
    }
    
    // MARK: - IPA Information
    struct IPAInformation {
        let bundleId: String
        let version: String
        let minOSVersion: String
        let displayName: String
        let hasProvisioning: Bool
        let isSigned: Bool
        let numberOfExecutables: Int
    }
    
    // MARK: - Mach-O Information
    struct MachOInformation {
        let isValid: Bool
        let is64Bit: Bool
        let isArm64e: Bool
        let architectureCount: Int
        let architectures: String
        let hasEncryption: Bool
        let isPIE: Bool
        let numberOfLoadCommands: Int
    }
    
    // MARK: - Magic Signatures
    private static let magicSignatures: [(bytes: [UInt8], type: FileType)] = [
        // Mach-O magic numbers
        ([0xFE, 0xED, 0xFA, 0xCE], .machO), // 32-bit
        ([0xFE, 0xED, 0xFA, 0xCF], .machO), // 64-bit
        ([0xCE, 0xFA, 0xED, 0xFE], .machO), // 32-bit reverse
        ([0xCF, 0xFA, 0xED, 0xFE], .machO), // 64-bit reverse
        ([0xCA, 0xFE, 0xBA, 0xBE], .machO), // Fat binary
        ([0xBE, 0xBA, 0xFE, 0xCA], .machO), // Fat binary reverse
        
        // Archives
        ([0x50, 0x4B, 0x03, 0x04], .archive), // ZIP/IPA - "PK\x03\x04"
        ([0x50, 0x4B, 0x05, 0x06], .archive), // ZIP empty
        ([0x50, 0x4B, 0x07, 0x08], .archive), // ZIP spanned
        
        // Images
        ([0xFF, 0xD8, 0xFF], .image), // JPEG
        ([0x89, 0x50, 0x4E, 0x47], .image), // PNG - "\x89PNG"
        
        // PDF
        ([0x25, 0x50, 0x44, 0x46], .pdf), // "%PDF"
        
        // Binary plist
        ([0x62, 0x70, 0x6C, 0x69, 0x73, 0x74], .plist), // "bplist"
    ]
    
    // MARK: - File Type Detection
    static func detectFileType(at path: String) -> FileType {
        let url = URL(fileURLWithPath: path)
        
        // Try to read magic bytes
        guard let fileHandle = try? FileHandle(forReadingFrom: url),
              let magicData = try? fileHandle.read(upToCount: 32) else {
            return detectByExtension(path)
        }
        
        try? fileHandle.close()
        
        let bytes = [UInt8](magicData)
        
        // Check magic signatures
        for (magicBytes, type) in magicSignatures {
            if bytes.count >= magicBytes.count {
                let prefix = Array(bytes.prefix(magicBytes.count))
                if prefix == magicBytes {
                    // Special handling for IPA (ZIP with .ipa extension)
                    if type == .archive && url.pathExtension.lowercased() == "ipa" {
                        return .ipa
                    }
                    return type
                }
            }
        }
        
        // Check for video files (ftyp at offset 4)
        if bytes.count >= 12 {
            let ftypBytes: [UInt8] = [0x66, 0x74, 0x79, 0x70] // "ftyp"
            let slice = Array(bytes[4..<8])
            if slice == ftypBytes {
                return .video
            }
        }
        
        // Check XML/Plist header
        if bytes.count >= 5 {
            let xmlHeader = "<?xml".data(using: .utf8)!
            if magicData.prefix(5) == xmlHeader {
                return .xml
            }
        }
        
        // Check if it's plain text
        let isText = bytes.allSatisfy { byte in
            byte >= 32 || byte == 0x09 || byte == 0x0A || byte == 0x0D
        }
        
        if isText {
            return detectByExtension(path) == .unknown ? .text : detectByExtension(path)
        }
        
        // Fallback to extension-based detection
        return detectByExtension(path)
    }
    
    private static func detectByExtension(_ path: String) -> FileType {
        let url = URL(fileURLWithPath: path)
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "json": return .json
        case "plist": return .plist
        case "xml": return .xml
        case "txt", "text", "md", "log": return .text
        case "p12", "pfx": return .p12
        case "mobileprovision": return .mobileProvision
        case "dylib": return .dylib
        case "mp3", "m4a", "wav": return .audio
        case "mp4", "mov", "m4v": return .video
        case "png", "jpg", "jpeg", "gif", "heic": return .image
        case "pdf": return .pdf
        case "zip": return .archive
        case "ipa", "tipa": return .ipa
        default: return .unknown
        }
    }
    
    // MARK: - File Information
    static func getFileInformation(at path: String) -> FileInformation? {
        let url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: path) else {
            return nil
        }
        
        let isDirectory = (attributes[.type] as? FileAttributeType) == .typeDirectory
        let size = attributes[.size] as? UInt64 ?? 0
        let permissions = attributes[.posixPermissions] as? Int ?? 0
        let isExecutable = (permissions & 0o111) != 0
        
        // Read magic signature
        var magicSignature = ""
        if !isDirectory, let fileHandle = try? FileHandle(forReadingFrom: url),
           let magicData = try? fileHandle.read(upToCount: 16) {
            let bytes = [UInt8](magicData)
            magicSignature = bytes.prefix(8).map { String(format: "%02X", $0) }.joined(separator: " ")
            try? fileHandle.close()
        }
        
        let fileType = isDirectory ? .unknown : detectFileType(at: path)
        
        // Check if signed (basic check for code signature)
        let isSigned = checkIfSigned(at: path)
        
        return FileInformation(
            path: path,
            name: url.lastPathComponent,
            type: fileType,
            size: size,
            magicSignature: magicSignature,
            isDirectory: isDirectory,
            isExecutable: isExecutable,
            isSigned: isSigned
        )
    }
    
    private static func checkIfSigned(at path: String) -> Bool {
        #if os(macOS)
        // Check for code signature using codesign command
        let task = Process()
        task.launchPath = "/usr/bin/codesign"
        task.arguments = ["-v", path]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
        #else
        // Code signature verification not supported on non-macOS platforms
        return false
        #endif
    }
    
    // MARK: - Hash Calculation
    static func computeHashes(for path: String) -> HashInformation? {
        guard let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)) else {
            return nil
        }
        
        defer { try? fileHandle.close() }
        
        var md5Context = Insecure.MD5()
        var sha1Context = Insecure.SHA1()
        var sha256Context = SHA256()
        
        let bufferSize = 8192
        while autoreleasepool(invoking: {
            guard let data = try? fileHandle.read(upToCount: bufferSize), !data.isEmpty else {
                return false
            }
            
            md5Context.update(data: data)
            sha1Context.update(data: data)
            sha256Context.update(data: data)
            
            return true
        }) {}
        
        let md5 = md5Context.finalize()
        let sha1 = sha1Context.finalize()
        let sha256 = sha256Context.finalize()
        
        return HashInformation(
            md5: md5.map { String(format: "%02x", $0) }.joined(),
            sha1: sha1.map { String(format: "%02x", $0) }.joined(),
            sha256: sha256.map { String(format: "%02x", $0) }.joined()
        )
    }
    
    // MARK: - IPA Analysis
    static func analyzeIPAFile(at path: String) -> IPAInformation? {
        let url = URL(fileURLWithPath: path)
        
        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }
            
            #if os(macOS)
            // Unzip IPA
            let task = Process()
            task.launchPath = "/usr/bin/unzip"
            task.arguments = ["-q", url.path, "-d", tempDir.path]
            task.standardOutput = Pipe()
            task.standardError = Pipe()
            
            try task.run()
            task.waitUntilExit()
            
            guard task.terminationStatus == 0 else {
                return createStubIPAInfo()
            }
            #else
            // IPA extraction not supported on non-macOS platforms
            return createStubIPAInfo()
            #endif
            
            // Find app bundle
            let payloadDir = tempDir.appendingPathComponent("Payload")
            guard let contents = try? FileManager.default.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil),
                  let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
                return createStubIPAInfo()
            }
            
            // Read Info.plist
            let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
            guard let plistData = try? Data(contentsOf: infoPlistURL),
                  let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
                return createStubIPAInfo()
            }
            
            let bundleId = plist["CFBundleIdentifier"] as? String ?? "com.unknown.app"
            let version = plist["CFBundleShortVersionString"] as? String ?? "1.0"
            let minOSVersion = plist["MinimumOSVersion"] as? String ?? "13.0"
            let displayName = plist["CFBundleDisplayName"] as? String ?? plist["CFBundleName"] as? String ?? "Unknown App"
            
            // Check for provisioning profile
            let provisioningPath = appBundle.appendingPathComponent("embedded.mobileprovision")
            let hasProvisioning = FileManager.default.fileExists(atPath: provisioningPath.path)
            
            // Check if signed
            let isSigned = checkIfSigned(at: appBundle.path)
            
            // Count executables
            let executableName = plist["CFBundleExecutable"] as? String
            var numberOfExecutables = 0
            if let execName = executableName {
                let execPath = appBundle.appendingPathComponent(execName)
                if FileManager.default.fileExists(atPath: execPath.path) {
                    numberOfExecutables = 1
                }
            }
            
            return IPAInformation(
                bundleId: bundleId,
                version: version,
                minOSVersion: minOSVersion,
                displayName: displayName,
                hasProvisioning: hasProvisioning,
                isSigned: isSigned,
                numberOfExecutables: numberOfExecutables
            )
        } catch {
            return createStubIPAInfo()
        }
    }
    
    private static func createStubIPAInfo() -> IPAInformation {
        return IPAInformation(
            bundleId: "com.unknown.app",
            version: "1.0",
            minOSVersion: "13.0",
            displayName: "Unknown App",
            hasProvisioning: false,
            isSigned: false,
            numberOfExecutables: 1
        )
    }
    
    // MARK: - Mach-O Analysis
    static func analyzeMachOFile(at path: String) -> MachOInformation? {
        let url = URL(fileURLWithPath: path)
        
        guard let fileHandle = try? FileHandle(forReadingFrom: url),
              let magicData = try? fileHandle.read(upToCount: 4) else {
            return nil
        }
        
        try? fileHandle.close()
        
        guard magicData.count >= 4 else { return nil }
        
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
        
        var isValid = true
        var is64Bit = false
        var archs: [String] = []
        var architectureCount = 1
        
        switch magic {
        case 0xFEEDFACE, 0xCEFAEDFE: // MH_MAGIC, MH_CIGAM (32-bit)
            is64Bit = false
            archs = ["armv7"]
            
        case 0xFEEDFACF, 0xCFFAEDFE: // MH_MAGIC_64, MH_CIGAM_64 (64-bit)
            is64Bit = true
            archs = [detectSingleArch(at: path)]
            
        case 0xCAFEBABE, 0xBEBAFECA: // FAT_MAGIC, FAT_CIGAM (fat binary)
            let fatArchs = detectFatArchs(at: path)
            archs = fatArchs
            architectureCount = fatArchs.count
            is64Bit = fatArchs.contains { $0.contains("64") }
            
        case 0xCAFEBABF, 0xBFBAFECA: // FAT_MAGIC_64, FAT_CIGAM_64
            let fatArchs = detectFatArchs(at: path)
            archs = fatArchs
            architectureCount = fatArchs.count
            is64Bit = true
            
        default:
            isValid = false
        }
        
        let architectures = archs.joined(separator: ", ")
        let isArm64e = archs.contains("arm64e")

        // On iOS we can't easily use otool, but we can read some load commands manually if needed.
        // For now, let's keep the existing logic for macOS and stub for iOS.
        let hasEncryption = checkMachOEncryption(at: path)
        let isPIE = checkMachOPIE(at: path)
        let loadCommands = getMachOLoadCommandCount(at: path)
        
        return MachOInformation(
            isValid: isValid,
            is64Bit: is64Bit,
            isArm64e: isArm64e,
            architectureCount: architectureCount,
            architectures: architectures,
            hasEncryption: hasEncryption,
            isPIE: isPIE,
            numberOfLoadCommands: loadCommands
        )
    }

    private static func detectSingleArch(at path: String) -> String {
        guard let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)),
              let headerData = try? fileHandle.read(upToCount: 32) else {
            return "arm64"
        }
        try? fileHandle.close()

        guard headerData.count >= 12 else { return "arm64" }

        let cpuType = headerData[4..<8].withUnsafeBytes { $0.load(as: Int32.self) }
        let cpuSubtype = headerData[8..<12].withUnsafeBytes { $0.load(as: Int32.self) }

        return cpuTypeToString(cputype: cpuType, cpusubtype: cpuSubtype)
    }

    private static func detectFatArchs(at path: String) -> [String] {
        guard let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)),
              let headerData = try? fileHandle.read(upToCount: 8) else {
            return ["universal"]
        }

        let nfatArch = headerData[4..<8].withUnsafeBytes {
            UInt32(bigEndian: $0.load(as: UInt32.self))
        }

        var archs: [String] = []
        for i in 0..<Int(nfatArch) {
            let offset = 8 + (i * 20) // fat_arch is 20 bytes
            try? fileHandle.seek(toOffset: UInt64(offset))
            guard let archData = try? fileHandle.read(upToCount: 8) else { continue }

            let cpuType = archData[0..<4].withUnsafeBytes { Int32(bigEndian: $0.load(as: Int32.self)) }
            let cpuSubtype = archData[4..<8].withUnsafeBytes { Int32(bigEndian: $0.load(as: Int32.self)) }

            archs.append(cpuTypeToString(cputype: cpuType, cpusubtype: cpuSubtype))
        }

        try? fileHandle.close()
        return archs.isEmpty ? ["universal"] : archs
    }

    private static func cpuTypeToString(cputype: Int32, cpusubtype: Int32) -> String {
        if cputype == 12 { // CPU_TYPE_ARM
            return "armv7"
        } else if cputype == 0x0100000c { // CPU_TYPE_ARM64
            if (cpusubtype & 0x00FFFFFF) == 2 { // CPU_SUBTYPE_ARM64E
                return "arm64e"
            }
            return "arm64"
        }
        return "unknown(\(cputype))"
    }
    
    private static func checkMachOEncryption(at path: String) -> Bool {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/bin/otool"
        task.arguments = ["-l", path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("LC_ENCRYPTION_INFO") && output.contains("cryptid 1")
            }
        } catch {
            return false
        }
        
        return false
        #else
        // Manual check for iOS
        guard let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)),
              let data = try? fileHandle.read(upToCount: 1024 * 64) else { return false }
        try? fileHandle.close()

        // LC_ENCRYPTION_INFO = 0x21, LC_ENCRYPTION_INFO_64 = 0x2C
        // This is a very rough check, but better than nothing
        return data.range(of: Data([0x21, 0x00, 0x00, 0x00])) != nil ||
               data.range(of: Data([0x2C, 0x00, 0x00, 0x00])) != nil
        #endif
    }
    
    private static func checkMachOPIE(at path: String) -> Bool {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/bin/otool"
        task.arguments = ["-hv", path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains("PIE")
            }
        } catch {
            return false
        }
        
        return false
        #else
        // MH_PIE = 0x00200000
        guard let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)),
              let headerData = try? fileHandle.read(upToCount: 32) else { return false }
        try? fileHandle.close()

        guard headerData.count >= 28 else { return false }
        let flags = headerData[24..<28].withUnsafeBytes { $0.load(as: UInt32.self) }
        return (flags & 0x00200000) != 0
        #endif
    }
    
    private static func getMachOLoadCommandCount(at path: String) -> Int {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/bin/otool"
        task.arguments = ["-l", path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                let loadCommandLines = lines.filter { $0.contains("Load command") }
                return loadCommandLines.count
            }
        } catch {
            return 0
        }
        
        return 0
        #else
        guard let fileHandle = try? FileHandle(forReadingFrom: URL(fileURLWithPath: path)),
              let headerData = try? fileHandle.read(upToCount: 20) else { return 0 }
        try? fileHandle.close()

        guard headerData.count >= 20 else { return 0 }
        let ncmds = headerData[16..<20].withUnsafeBytes { $0.load(as: UInt32.self) }
        return Int(ncmds)
        #endif
    }
    
    private static func checkIfArm64e(at path: String) -> Bool {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/bin/file"
        task.arguments = [path]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.lowercased().contains("arm64e")
            }
        } catch {
            return false
        }
        
        return false
        #else
        return detectSingleArch(at: path) == "arm64e"
        #endif
    }
    
    // MARK: - Directory Scanning
    static func scanDirectory(at path: String, recursive: Bool = false) -> [FileInformation] {
        let url = URL(fileURLWithPath: path)
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: recursive ? [] : [.skipsSubdirectoryDescendants]
        ) else {
            return []
        }
        
        var results: [FileInformation] = []
        
        for case let fileURL as URL in enumerator {
            // Skip hidden files
            if fileURL.lastPathComponent.hasPrefix(".") {
                continue
            }
            
            if let info = getFileInformation(at: fileURL.path) {
                results.append(info)
            }
        }
        
        return results
    }
    
    // MARK: - File Comparison
    static func compareFiles(_ file1: String, _ file2: String) -> (identical: Bool, diffSize: UInt64) {
        guard let handle1 = try? FileHandle(forReadingFrom: URL(fileURLWithPath: file1)),
              let handle2 = try? FileHandle(forReadingFrom: URL(fileURLWithPath: file2)) else {
            return (false, 0)
        }
        
        defer {
            try? handle1.close()
            try? handle2.close()
        }
        
        // Check file sizes first
        let size1 = (try? handle1.seekToEnd()) ?? 0
        let size2 = (try? handle2.seekToEnd()) ?? 0
        
        if size1 != size2 {
            return (false, UInt64(abs(Int64(size1) - Int64(size2))))
        }
        
        // Reset to beginning
        try? handle1.seek(toOffset: 0)
        try? handle2.seek(toOffset: 0)
        
        // Compare byte by byte
        var differences: UInt64 = 0
        let bufferSize = 8192
        
        while true {
            guard let data1 = try? handle1.read(upToCount: bufferSize),
                  let data2 = try? handle2.read(upToCount: bufferSize) else {
                break
            }
            
            if data1.isEmpty && data2.isEmpty {
                break
            }
            
            if data1.count != data2.count {
                differences += UInt64(abs(data1.count - data2.count))
                break
            }
            
            for i in 0..<data1.count {
                if data1[i] != data2[i] {
                    differences += 1
                }
            }
        }
        
        return (differences == 0, differences)
    }
    
    // MARK: - Integrity Check
    static func verifyFileIntegrity(at path: String, expectedHash: String) -> Bool {
        guard let hashes = computeHashes(for: path) else {
            return false
        }
        
        // Compare with SHA256 (most common)
        return hashes.sha256.lowercased() == expectedHash.lowercased()
    }
}
