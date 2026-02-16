import Foundation
import UIKit
import Zip

enum CustomSignAPIError: Error, LocalizedError {
    case appNotFound
    case missingCertificate
    case missingProvisioningProfile
    case invalidResponse
    case serverError(String)
    case zippingFailed
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .appNotFound: return String.localized("Unable to locate app file.")
        case .missingCertificate: return String.localized("Certificate file not found.")
        case .missingProvisioningProfile: return String.localized("Provisioning profile not found.")
        case .invalidResponse: return String.localized("Invalid response from server.")
        case .serverError(let message): return "\(String.localized("Server error")): \(message)"
        case .zippingFailed: return String.localized("Failed to package app into IPA.")
        case .invalidURL: return String.localized("Invalid API URL.")
        }
    }
}

struct CustomSignAPIResponse: Codable {
    let installLink: String?
    let directInstallLink: String?
    let error: String?
}

final class CustomSignAPIManager {
    static let shared = CustomSignAPIManager()
    private let _fileManager = FileManager.default

    private init() {}

    func sign(app: AppInfoPresentable, certificate: CertificatePair, options: Options) async throws -> String {
        AppLogManager.shared.info("Starting custom API signing for: \(app.name ?? "Unknown")", category: "RemoteSigning")

        let customAPI = UserDefaults.standard.string(forKey: "Feather.customSigningAPI") ?? ""
        guard let url = URL(string: customAPI) else {
            throw CustomSignAPIError.invalidURL
        }

        // Update Live Activity status if supported
        if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
            await LiveActivityManager.shared.updateActivity(
                progress: 0.2,
                bytesDownloaded: 0,
                totalBytes: 0,
                status: .preparing
            )
        }

        // 1. Prepare IPA
        let ipaURL = try await _prepareIPA(for: app)
        defer {
            // Only cleanup if it's a temporary IPA we created
            if ipaURL.path.contains("CustomSign_") {
                try? _fileManager.removeItem(at: ipaURL.deletingLastPathComponent())
            }
        }

        // Update Live Activity status if supported
        if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
            await LiveActivityManager.shared.updateActivity(
                progress: 0.4,
                bytesDownloaded: 0,
                totalBytes: 0,
                status: .signing
            )
        }

        // 2. Prepare Certificate and Provision
        return try await _withCertificateFiles(for: certificate) { p12URL, provisionURL in
            // 3. Perform Upload
            return try await _uploadAndSign(
                url: url,
                ipaURL: ipaURL,
                p12URL: p12URL,
                provisionURL: provisionURL,
                password: certificate.password ?? "",
                options: options
            )
        }
    }

    private func _prepareIPA(for app: AppInfoPresentable) async throws -> URL {
        if let archiveURL = app.archiveURL, _fileManager.fileExists(atPath: archiveURL.path) {
            return archiveURL
        }

        AppLogManager.shared.info("App not in IPA format, packaging...", category: "RemoteSigning")

        let uuid = UUID().uuidString
        let workDir = _fileManager.temporaryDirectory.appendingPathComponent("CustomSign_\(uuid)")
        try _fileManager.createDirectory(at: workDir, withIntermediateDirectories: true)

        guard let appDir = Storage.shared.getAppDirectory(for: app) else {
            throw CustomSignAPIError.appNotFound
        }

        let payloadDir = workDir.appendingPathComponent("Payload")
        try _fileManager.createDirectory(at: payloadDir, withIntermediateDirectories: true)

        let destAppDir = payloadDir.appendingPathComponent(appDir.lastPathComponent)
        try _fileManager.copyItem(at: appDir, to: destAppDir)

        let ipaURL = workDir.appendingPathComponent("app.ipa")
        let zipURL = workDir.appendingPathComponent("app.zip")

        do {
            try await Zip.zipFiles(
                paths: [payloadDir],
                zipFilePath: zipURL,
                password: nil,
                compression: ZipCompression.allCases[ArchiveHandler.getCompressionLevel()],
                progress: nil
            )
            try _fileManager.moveItem(at: zipURL, to: ipaURL)
        } catch {
            AppLogManager.shared.error("Zipping failed: \(error.localizedDescription)", category: "RemoteSigning")
            throw CustomSignAPIError.zippingFailed
        }

        return ipaURL
    }

    private func _withCertificateFiles<T>(for cert: CertificatePair, perform: (URL, URL) async throws -> T) async throws -> T {
        guard let p12URL = Storage.shared.getFile(.certificate, from: cert),
              let provisionURL = Storage.shared.getFile(.provision, from: cert) else {
            throw CustomSignAPIError.missingCertificate
        }
        return try await perform(p12URL, provisionURL)
    }

    private func _uploadAndSign(
        url: URL,
        ipaURL: URL,
        p12URL: URL,
        provisionURL: URL,
        password: String,
        options: Options
    ) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 600

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        // IPA
        try _appendFile(url: ipaURL, name: "ipa", fileName: "app.ipa", boundary: boundary, to: &data)
        // P12
        try _appendFile(url: p12URL, name: "p12", fileName: "cert.p12", boundary: boundary, to: &data)
        // Provision
        try _appendFile(url: provisionURL, name: "mobileprovision", fileName: "embedded.mobileprovision", boundary: boundary, to: &data)

        // Password
        _appendFormField(name: "p12_password", value: password, boundary: boundary, to: &data)

        // Optional: Bundle ID / Name if custom
        if let bundleId = options.appIdentifier {
            _appendFormField(name: "bundle_id", value: bundleId, boundary: boundary, to: &data)
        }
        if let name = options.appName {
            _appendFormField(name: "name", value: name, boundary: boundary, to: &data)
        }

        data.append("--\(boundary)--\r\n".data(using: .utf8)!)

        AppLogManager.shared.info("Uploading assets to custom API (\(data.count) bytes)...", category: "RemoteSigning")

        if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
            await LiveActivityManager.shared.updateActivity(
                progress: 0.6,
                bytesDownloaded: 0,
                totalBytes: Int64(data.count),
                status: .signing
            )
        }

        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CustomSignAPIError.invalidResponse
        }

        if !(200...299).contains(httpResponse.statusCode) {
            let errorMsg = String(data: responseData, encoding: .utf8) ?? "Unknown server error"
            AppLogManager.shared.error("Custom API returned error: \(httpResponse.statusCode)", category: "RemoteSigning")
            throw CustomSignAPIError.serverError("HTTP \(httpResponse.statusCode): \(errorMsg)")
        }

        if #available(iOS 16.2, *), UserDefaults.standard.bool(forKey: "Feather.liveActivityEnabled") {
            await LiveActivityManager.shared.updateActivity(
                progress: 0.9,
                bytesDownloaded: Int64(data.count),
                totalBytes: Int64(data.count),
                status: .verifying
            )
        }

        do {
            let decoded = try JSONDecoder().decode(CustomSignAPIResponse.self, from: responseData)
            if let error = decoded.error {
                throw CustomSignAPIError.serverError(error)
            }

            if let direct = decoded.directInstallLink {
                AppLogManager.shared.success("Custom API signing successful", category: "RemoteSigning")
                return direct
            } else if let link = decoded.installLink {
                AppLogManager.shared.success("Custom API signing successful", category: "RemoteSigning")
                return link
            } else {
                throw CustomSignAPIError.invalidResponse
            }
        } catch {
            // Fallback: Check if response is just a raw URL
            if let rawURL = String(data: responseData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               rawURL.hasPrefix("itms-services://") || rawURL.hasPrefix("https://") {
                AppLogManager.shared.success("Custom API signing successful (raw URL)", category: "RemoteSigning")
                return rawURL
            }
            AppLogManager.shared.error("Failed to decode custom API response", category: "RemoteSigning")
            throw CustomSignAPIError.invalidResponse
        }
    }

    private func _appendFile(url: URL, name: String, fileName: String, boundary: String, to data: inout Data) throws {
        let fileData = try Data(contentsOf: url)
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        data.append(fileData)
        data.append("\r\n".data(using: .utf8)!)
    }

    private func _appendFormField(name: String, value: String, boundary: String, to data: inout Data) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(value)\r\n".data(using: .utf8)!)
    }
}
