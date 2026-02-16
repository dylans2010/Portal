import Foundation
import Zip

enum IPAPackagerError: Error {
    case extractionFailed
    case packagingFailed
    case invalidStructure
}

class IPAPackager {
    private let fileManager = FileManager.default

    func extract(ipaURL: URL, to destinationURL: URL) throws -> URL {
        try fileManager.createDirectoryIfNeeded(at: destinationURL)

        try Zip.unzipFile(ipaURL, destination: destinationURL, overwrite: true, password: nil)

        let payloadURL = destinationURL.appendingPathComponent("Payload")
        guard fileManager.fileExists(atPath: payloadURL.path) else {
            throw IPAPackagerError.invalidStructure
        }

        let contents = try fileManager.contentsOfDirectory(at: payloadURL, includingPropertiesForKeys: nil)
        guard let appBundle = contents.first(where: { $0.pathExtension == "app" }) else {
            throw IPAPackagerError.invalidStructure
        }

        return appBundle
    }

    func package(payloadURL: URL, to outputURL: URL) throws {
        // Ensure we are zipping the Payload directory itself, not its parent
        // Zip.zipFiles(paths: [payloadURL], ...) usually creates an archive where 'Payload' is a top-level folder.

        try Zip.zipFiles(paths: [payloadURL], zipFilePath: outputURL, password: nil, progress: nil)
    }
}
