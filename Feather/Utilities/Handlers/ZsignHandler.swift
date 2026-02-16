import Foundation
import ZsignSwift
import UIKit
import CommonCrypto

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

		let logObserver = NotificationCenter.default.addObserver(
			forName: NSNotification.Name("ZsignLogNotification"),
			object: nil,
			queue: .main
		) { notification in
			if let message = notification.object as? String {
				AppLogManager.shared.debug(message.trimmingCharacters(in: .whitespacesAndNewlines), category: "Zsign")
			}
		}

		defer {
			NotificationCenter.default.removeObserver(logObserver)
		}

		AppLogManager.shared.info("Starting signing process for: \(_appUrl.lastPathComponent)", category: "Signing")
		AppLogManager.shared.debug("Using certificate: \(cert.nickname ?? "Unknown")", category: "Signing")

		// 1. Initial Certificate and Provision Checks
		if let expiryDate = cert.expiryDate, expiryDate < Date() {
			AppLogManager.shared.error("Certificate is expired: \(expiryDate)", category: "Signing")
			throw SigningFileHandlerError.signFailed
		}

		let p12Path = Storage.shared.getFile(.certificate, from: cert)?.path ?? ""
		let provisionPath = Storage.shared.getFile(.provision, from: cert)?.path ?? ""
		try await _performSign(p12Path: p12Path, provisionPath: provisionPath, cert: cert)
	}

	private func _performSign(p12Path: String, provisionPath: String, cert: CertificatePair) async throws {
		AppLogManager.shared.info("Performing sign with assets using new Swift CoreSigner:", category: "Signing")
		AppLogManager.shared.debug("- App Path: \(_appUrl.relativePath)", category: "Signing")

		let p12Data = try Data(contentsOf: URL(fileURLWithPath: p12Path))
		let provisionData = try Data(contentsOf: URL(fileURLWithPath: provisionPath))

		try await Task.detached {
			try CoreSigner.sign(bundleURL: self._appUrl, p12Data: p12Data, p12Password: cert.password ?? "", provisionData: provisionData)
		}.value

		AppLogManager.shared.success("Signing completed successfully using new Swift pipeline", category: "Signing")
	}
	
	func adhocSign() async throws {
		let _ = Zsign.sign(
			appPath: _appUrl.relativePath,
			entitlementsPath: _options.appEntitlementsFile?.path ?? "",
			adhoc: true,
			removeProvision: _options.removeProvisioning,
			completion: { _, error in
				self.hadError = error
			}
		)
	}
}
