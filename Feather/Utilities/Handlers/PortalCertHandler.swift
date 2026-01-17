import Foundation
import OSLog
import ZIPFoundation

/// Handler for .portalcert file format
/// .portalcert is a bundled certificate format that contains both P12 and mobileprovision files
/// encoded in a single file for easy sharing and backup
struct PortalCertHandler {
    
    // MARK: - Constants
    static let fileExtension = "portalcert"
    static let formatVersion = "1.0"
    
    // MARK: - Error Types
    enum PortalCertError: LocalizedError {
        case invalidFormat
        case missingP12
        case missingProvision
        case encodingFailed
        case decodingFailed
        case fileNotFound
        case zipCreationFailed
        case zipExtractionFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat:
                return "Invalid .portalcert file format"
            case .missingP12:
                return "P12 certificate file not found in bundle"
            case .missingProvision:
                return "Provisioning profile not found in bundle"
            case .encodingFailed:
                return "Failed to encode certificate bundle"
            case .decodingFailed:
                return "Failed to decode certificate bundle"
            case .fileNotFound:
                return "Certificate file not found"
            case .zipCreationFailed:
                return "Failed to create certificate bundle"
            case .zipExtractionFailed:
                return "Failed to extract certificate bundle"
            }
        }
    }
    
    // MARK: - Metadata Structure
    struct PortalCertMetadata: Codable {
        let version: String
        let createdAt: TimeInterval
        let p12Filename: String
        let provisionFilename: String
        let nickname: String?
        let hasPassword: Bool
    }
    
    // MARK: - Export Certificate to .portalcert
    
    /// Creates a .portalcert file from P12 and mobileprovision files
    /// - Parameters:
    ///   - p12URL: URL to the P12 certificate file
    ///   - provisionURL: URL to the mobileprovision file
    ///   - password: Optional password for the P12 (stored as flag, not actual password)
    ///   - nickname: Optional nickname for the certificate
    ///   - outputURL: URL where the .portalcert file should be saved
    /// - Returns: URL to the created .portalcert file
    static func createPortalCert(
        p12URL: URL,
        provisionURL: URL,
        hasPassword: Bool,
        nickname: String?,
        outputURL: URL
    ) throws -> URL {
        Logger.misc.info("[PortalCert] Creating .portalcert bundle")
        Logger.misc.debug("[PortalCert] P12: \(p12URL.lastPathComponent)")
        Logger.misc.debug("[PortalCert] Provision: \(provisionURL.lastPathComponent)")
        
        // Verify source files exist
        guard FileManager.default.fileExists(atPath: p12URL.path) else {
            Logger.misc.error("[PortalCert] P12 file not found at: \(p12URL.path)")
            throw PortalCertError.missingP12
        }
        
        guard FileManager.default.fileExists(atPath: provisionURL.path) else {
            Logger.misc.error("[PortalCert] Provision file not found at: \(provisionURL.path)")
            throw PortalCertError.missingProvision
        }
        
        // Create metadata
        let metadata = PortalCertMetadata(
            version: formatVersion,
            createdAt: Date().timeIntervalSince1970,
            p12Filename: p12URL.lastPathComponent,
            provisionFilename: provisionURL.lastPathComponent,
            nickname: nickname,
            hasPassword: hasPassword
        )
        
        // Create temporary directory for bundling
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("portalcert-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Copy files to temp directory
        let tempP12 = tempDir.appendingPathComponent(p12URL.lastPathComponent)
        let tempProvision = tempDir.appendingPathComponent(provisionURL.lastPathComponent)
        let metadataURL = tempDir.appendingPathComponent("metadata.json")
        
        try FileManager.default.copyItem(at: p12URL, to: tempP12)
        try FileManager.default.copyItem(at: provisionURL, to: tempProvision)
        
        // Write metadata
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: metadataURL)
        
        Logger.misc.debug("[PortalCert] Metadata written: \(String(data: metadataData, encoding: .utf8) ?? "N/A")")
        
        // Create ZIP archive
        let finalURL = outputURL.pathExtension == fileExtension ? outputURL : outputURL.appendingPathExtension(fileExtension)
        
        // Remove existing file if present
        if FileManager.default.fileExists(atPath: finalURL.path) {
            try FileManager.default.removeItem(at: finalURL)
        }
        
        // Create the archive
        try FileManager.default.zipItem(at: tempDir, to: finalURL, shouldKeepParent: false)
        
        Logger.misc.info("[PortalCert] Successfully created .portalcert at: \(finalURL.path)")
        
        return finalURL
    }
    
    // MARK: - Import Certificate from .portalcert
    
    /// Extracts P12 and mobileprovision files from a .portalcert bundle
    /// - Parameter portalCertURL: URL to the .portalcert file
    /// - Returns: Tuple containing URLs to extracted P12 and provision files, plus metadata
    static func extractPortalCert(
        from portalCertURL: URL
    ) throws -> (p12URL: URL, provisionURL: URL, metadata: PortalCertMetadata) {
        Logger.misc.info("[PortalCert] Extracting .portalcert bundle from: \(portalCertURL.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: portalCertURL.path) else {
            Logger.misc.error("[PortalCert] File not found: \(portalCertURL.path)")
            throw PortalCertError.fileNotFound
        }
        
        // Create extraction directory
        let extractDir = FileManager.default.temporaryDirectory.appendingPathComponent("portalcert-extract-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)
        
        // Extract ZIP
        do {
            try FileManager.default.unzipItem(at: portalCertURL, to: extractDir)
            Logger.misc.debug("[PortalCert] Extracted to: \(extractDir.path)")
        } catch {
            Logger.misc.error("[PortalCert] Failed to extract ZIP: \(error.localizedDescription)")
            throw PortalCertError.zipExtractionFailed
        }
        
        // Read metadata
        let metadataURL = extractDir.appendingPathComponent("metadata.json")
        guard FileManager.default.fileExists(atPath: metadataURL.path) else {
            Logger.misc.error("[PortalCert] Metadata file not found")
            throw PortalCertError.invalidFormat
        }
        
        let metadataData = try Data(contentsOf: metadataURL)
        let metadata = try JSONDecoder().decode(PortalCertMetadata.self, from: metadataData)
        
        Logger.misc.debug("[PortalCert] Metadata version: \(metadata.version)")
        Logger.misc.debug("[PortalCert] P12 filename: \(metadata.p12Filename)")
        Logger.misc.debug("[PortalCert] Provision filename: \(metadata.provisionFilename)")
        
        // Locate extracted files
        let p12URL = extractDir.appendingPathComponent(metadata.p12Filename)
        let provisionURL = extractDir.appendingPathComponent(metadata.provisionFilename)
        
        guard FileManager.default.fileExists(atPath: p12URL.path) else {
            Logger.misc.error("[PortalCert] P12 file not found in bundle")
            throw PortalCertError.missingP12
        }
        
        guard FileManager.default.fileExists(atPath: provisionURL.path) else {
            Logger.misc.error("[PortalCert] Provision file not found in bundle")
            throw PortalCertError.missingProvision
        }
        
        Logger.misc.info("[PortalCert] Successfully extracted .portalcert bundle")
        
        return (p12URL, provisionURL, metadata)
    }
    
    // MARK: - Validation
    
    /// Validates if a file is a valid .portalcert bundle
    /// - Parameter url: URL to the file to validate
    /// - Returns: True if valid, false otherwise
    static func isValidPortalCert(at url: URL) -> Bool {
        Logger.misc.debug("[PortalCert] Validating file: \(url.lastPathComponent)")
        
        guard url.pathExtension.lowercased() == fileExtension else {
            Logger.misc.debug("[PortalCert] Invalid extension: \(url.pathExtension)")
            return false
        }
        
        do {
            let (_, _, _) = try extractPortalCert(from: url)
            Logger.misc.debug("[PortalCert] File is valid")
            return true
        } catch {
            Logger.misc.debug("[PortalCert] Validation failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Export from Certificate Pair
    
    /// Creates a .portalcert file from an existing CertificatePair
    /// - Parameters:
    ///   - certificate: The CertificatePair to export
    ///   - outputDirectory: Directory where the .portalcert should be saved
    /// - Returns: URL to the created .portalcert file
    static func exportCertificate(
        _ certificate: CertificatePair,
        to outputDirectory: URL
    ) throws -> URL {
        Logger.misc.info("[PortalCert] Exporting certificate: \(certificate.nickname ?? "Unknown")")
        
        guard let p12URL = Storage.shared.getFile(.certificate, from: certificate) else {
            Logger.misc.error("[PortalCert] P12 file not found for certificate")
            throw PortalCertError.missingP12
        }
        
        guard let provisionURL = Storage.shared.getFile(.provision, from: certificate) else {
            Logger.misc.error("[PortalCert] Provision file not found for certificate")
            throw PortalCertError.missingProvision
        }
        
        let filename = (certificate.nickname ?? "certificate").replacingOccurrences(of: " ", with: "_")
        let outputURL = outputDirectory.appendingPathComponent(filename).appendingPathExtension(fileExtension)
        
        return try createPortalCert(
            p12URL: p12URL,
            provisionURL: provisionURL,
            hasPassword: certificate.password != nil && !certificate.password!.isEmpty,
            nickname: certificate.nickname,
            outputURL: outputURL
        )
    }
}

// MARK: - UTType Extension for .portalcert
import UniformTypeIdentifiers

extension UTType {
    static var portalCert: UTType {
        UTType(exportedAs: "dev.portal.portalcert", conformingTo: .data)
    }
}
