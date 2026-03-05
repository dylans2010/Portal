import Foundation
import CryptoKit

// MARK: - Backup Payload
struct BackupPayload: Codable {
    let version: String
    let timestamp: TimeInterval
    let data: Data
    
    init(backupDirectory: URL) throws {
        self.version = "1.0"
        self.timestamp = Date().timeIntervalSince1970
        
        // Create an archive of the backup directory contents
        let fileManager = FileManager.default
        
        // Collect all files in the backup directory
        let enumerator = fileManager.enumerator(at: backupDirectory, includingPropertiesForKeys: [.isRegularFileKey])
        var files: [(path: String, data: Data)] = []
        
        while let fileURL = enumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if resourceValues.isRegularFile == true {
                let relativePath = fileURL.path.replacingOccurrences(of: backupDirectory.path + "/", with: "")
                if let fileData = try? Data(contentsOf: fileURL) {
                    files.append((path: relativePath, data: fileData))
                }
            }
        }
        
        // Serialize files into a single data structure
        let encoder = JSONEncoder()
        let filesDict = files.reduce(into: [String: Data]()) { dict, file in
            dict[file.path] = file.data
        }
        self.data = try encoder.encode(filesDict)
    }
    
    func extract(to destinationDirectory: URL) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        
        // Deserialize the files
        let decoder = JSONDecoder()
        let filesDict = try decoder.decode([String: Data].self, from: data)
        
        for (relativePath, fileData) in filesDict {
            let fileURL = destinationDirectory.appendingPathComponent(relativePath)
            let fileDirectory = fileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: fileDirectory, withIntermediateDirectories: true)
            try fileData.write(to: fileURL)
        }
    }
    
    func encrypted(with password: String) throws -> Data {
        let encoder = JSONEncoder()
        let payloadData = try encoder.encode(self)
        
        // Use AES-GCM encryption
        let key = SymmetricKey(data: SHA256.hash(data: password.data(using: .utf8)!))
        let sealedBox = try AES.GCM.seal(payloadData, using: key)
        return sealedBox.combined!
    }
    
    static func decrypted(from encryptedData: Data, password: String) throws -> BackupPayload {
        let key = SymmetricKey(data: SHA256.hash(data: password.data(using: .utf8)!))
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        let decoder = JSONDecoder()
        return try decoder.decode(BackupPayload.self, from: decryptedData)
    }
}
