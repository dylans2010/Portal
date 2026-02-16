import Foundation
import CommonCrypto

enum CodeResourcesBuilderError: Error {
    case hashingError
    case bundleError
}

class CodeResourcesBuilder {
    private let bundleURL: URL
    private let executableName: String

    init(bundleURL: URL, executableName: String) {
        self.bundleURL = bundleURL
        self.executableName = executableName
    }

    func build() throws -> Data {
        let fileManager = FileManager.default
        var files: [String: Any] = [:]
        var files2: [String: Any] = [:]

        guard let enumerator = fileManager.enumerator(at: bundleURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            throw CodeResourcesBuilderError.bundleError
        }

        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if resourceValues.isDirectory == true { continue }

            let relativePath = fileURL.path.replacingOccurrences(of: bundleURL.path + "/", with: "")

            // Exclude rules
            if relativePath == "_CodeSignature/CodeResources" { continue }
            if relativePath == executableName { continue }

            let fileData = try Data(contentsOf: fileURL)
            let sha1 = sha1Hash(data: fileData)
            let sha256 = sha256Hash(data: fileData)

            let isOptional = relativePath.contains(".lproj/")
            let isOmit = relativePath.contains("locversion.plist") || relativePath.contains(".DS_Store")

            if !isOmit {
                if isOptional {
                    files[relativePath] = ["hash": sha1, "optional": true]
                } else {
                    files[relativePath] = sha1
                }
            }

            if !isOmit || relativePath.contains(".DS_Store") { // DS_Store is omitted in files2 too but with a rule
                 // Actually zsign omits DS_Store from files2 too.
            }

            var f2entry: [String: Any] = ["hash": sha1, "hash2": sha256]
            if isOptional {
                f2entry["optional"] = true
            }

            if !isOmit {
                files2[relativePath] = f2entry
            }
        }

        let rules: [String: Any] = [
            "^.*": true,
            "^.*\\.lproj/": ["optional": true, "weight": 1000.0],
            "^.*\\.lproj/locversion.plist$": ["omit": true, "weight": 1100.0],
            "^Base\\.lproj/": ["weight": 1010.0],
            "^version.plist$": true
        ]

        let rules2: [String: Any] = [
            "^.*": true,
            ".*\\.dSYM($|/)": ["weight": 11.0],
            "^(.*/)?\\.DS_Store$": ["omit": true, "weight": 2000.0],
            "^.*\\.lproj/": ["optional": true, "weight": 1000.0],
            "^.*\\.lproj/locversion.plist$": ["omit": true, "weight": 1100.0],
            "^Base\\.lproj/": ["weight": 1010.0],
            "^Info\\.plist$": ["weight": 20.0],
            "^PkgInfo$": ["weight": 20.0],
            "^embedded\\.mobileprovision$": ["weight": 20.0],
            "^version\\.plist$": ["weight": 20.0]
        ]

        let codeResources: [String: Any] = [
            "files": files,
            "files2": files2,
            "rules": rules,
            "rules2": rules2
        ]

        return try PropertyListSerialization.data(fromPropertyList: codeResources, format: .xml, options: 0)
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
