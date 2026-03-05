
import Foundation
import IDevice
import OSLog

class PairingManager {
    static let shared = PairingManager()

    private init() {}

    var hasPairingFile: Bool {
        FileManager.default.fileExists(atPath: Self.pairingFilePath)
    }

    static var pairingFilePath: String {
        URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path()
    }

    func importPairingFile(from sourceURL: URL) throws {
        let fileManager = FileManager.default
        let destURL = URL(fileURLWithPath: Self.pairingFilePath)

        try? fileManager.removeItem(at: destURL)
        try fileManager.copyItem(at: sourceURL, to: destURL)

        guard validatePairingFile() else {
            try? fileManager.removeItem(at: destURL)
            throw JITError.pairingInvalid
        }

        Logger.jit.info("PairingManager: Successfully imported and validated pairing file")
    }

    func validatePairingFile() -> Bool {
        guard hasPairingFile else { return false }
        var pairingFile: OpaquePointer?
        let err = idevice_pairing_file_read(Self.pairingFilePath, &pairingFile)
        if let err = err {
            Logger.jit.error("PairingManager: Validation failed with error code \(err.pointee.code)")
            idevice_error_free(err)
            return false
        }
        if let pf = pairingFile {
            idevice_pairing_file_free(pf)
        }
        return true
    }

    func readPairingFile() throws -> OpaquePointer {
        guard hasPairingFile else {
            throw JITError.pairingMissing
        }
        var pairingFile: OpaquePointer?
        let err = idevice_pairing_file_read(Self.pairingFilePath, &pairingFile)
        if let err = err {
            idevice_error_free(err)
            throw JITError.pairingInvalid
        }
        guard let pf = pairingFile else {
            throw JITError.pairingInvalid
        }
        return pf
    }


    func removePairingFile() {
        try? FileManager.default.removeItem(atPath: Self.pairingFilePath)
        Logger.jit.info("PairingManager: Removed pairing file")
    }
}
