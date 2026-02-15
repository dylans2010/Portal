import Foundation
import ZsignSwift
import UIKit

final class ZsignHandler {
	var hadError: Error?
	
	private var _appUrl: URL
	private var _options: Options
	private var _certificate: CertificatePair?
	
	init(
		appUrl: URL,
		options: Options = OptionsManager.shared.options,
		cert: CertificatePair? = nil
	) {
		self._appUrl = appUrl
		self._options = options
		self._certificate = cert
	}
	
	func disinject() async throws {
		guard !_options.disInjectionFiles.isEmpty else {
			return
		}
		
		let bundle = Bundle(url: _appUrl)
		let execPath = _appUrl.appendingPathComponent(bundle?.exec ?? "").relativePath
		
		if !Zsign.removeDylibs(appExecutable: execPath, using: _options.disInjectionFiles) {
			throw SigningFileHandlerError.disinjectFailed
		}
	}
	
	func sign() async throws {
		guard let cert = _certificate else {
			throw SigningFileHandlerError.missingCertifcate
		}

		AppLogManager.shared.info("Starting signing process for: \(_appUrl.lastPathComponent)", category: "Signing")
		AppLogManager.shared.debug("Using certificate: \(cert.nickname ?? "Unknown")", category: "Signing")

		if cert.isPortalCert {
			guard let certDir = Storage.shared.getUuidDirectory(for: cert) else {
				throw SigningFileHandlerError.missingCertifcate
			}

			try await PortalEncryptManager.shared.withDecryptedFiles(from: certDir) { p12URL, provisionURL in
				try await _performSign(p12Path: p12URL.path, provisionPath: provisionURL.path, cert: cert)
			}
		} else {
			let p12Path = Storage.shared.getFile(.certificate, from: cert)?.path ?? ""
			let provisionPath = Storage.shared.getFile(.provision, from: cert)?.path ?? ""
			try await _performSign(p12Path: p12Path, provisionPath: provisionPath, cert: cert)
		}
	}

	private func _performSign(p12Path: String, provisionPath: String, cert: CertificatePair) async throws {
		return try await withCheckedThrowingContinuation { continuation in
			let _ = Zsign.sign(
				appPath: _appUrl.relativePath,
				provisionPath: provisionPath,
				p12Path: p12Path,
				p12Password: cert.password ?? "",
				entitlementsPath: _options.appEntitlementsFile?.path ?? "",
				removeProvision: !_options.removeProvisioning,
				completion: { success, error in
					self.hadError = error
					if let error = error {
						AppLogManager.shared.error("Signing failed: \(error.localizedDescription)", category: "Signing")
						continuation.resume(throwing: error)
					} else {
						AppLogManager.shared.success("Signing completed successfully", category: "Signing")
						continuation.resume()
					}
				}
			)
		}
	}
	
	func adhocSign() async throws {
		let _ = Zsign.sign(
			appPath: _appUrl.relativePath,
			entitlementsPath: _options.appEntitlementsFile?.path ?? "",
			adhoc: true,
			removeProvision: !_options.removeProvisioning,
			completion: { _, error in
				self.hadError = error
			}
		)
	}
}
