import CoreData

// MARK: - Class extension: Apps (Shared)
extension Storage {
	func getUuidDirectory(for app: AppInfoPresentable) -> URL? {
		guard let uuid = app.uuid else { return nil }
		return app.isSigned
		? FileManager.default.signed(uuid)
		: FileManager.default.unsigned(uuid)
	}
	
	func getAppDirectory(for app: AppInfoPresentable) -> URL? {
		guard let url = getUuidDirectory(for: app) else { return nil }
		return FileManager.default.getPath(in: url, for: "app")
	}
	
	func getAppIconFile(for app: AppInfoPresentable) -> URL? {
		guard let appDirectory = getAppDirectory(for: app),
			  let iconFileName = app.icon else { return nil }
		return appDirectory.appendingPathComponent(iconFileName)
	}
	
	func deleteApp(for app: AppInfoPresentable) {
		do {
			if let url = getUuidDirectory(for: app) {
				try? FileManager.default.removeItem(at: url)
			}
			if let object = app as? NSManagedObject {
				context.delete(object)
			}
			saveContext()
		}
	}
	
	func getCertificate(from app: AppInfoPresentable) -> CertificatePair? {
		if let signed = app as? Signed {
			return signed.certificate
		}
		return nil
	}
}

// MARK: - Helpers
struct AnyApp: Identifiable {
	let base: AppInfoPresentable
	var archive: Bool = false
	
	var id: String {
		base.uuid ?? UUID().uuidString
	}
}

protocol AppInfoPresentable {
	var name: String? { get }
	var version: String? { get }
	var identifier: String? { get }
	var date: Date? { get }
	var icon: String? { get }
	var iconURL: URL? { get }
	var uuid: String? { get }
	var isSigned: Bool { get }
	var archiveURL: URL? { get }
	
}

extension Signed: AppInfoPresentable {
	var isSigned: Bool { true }
	var iconURL: URL? {
		Storage.shared.getAppIconFile(for: self)
	}
	var archiveURL: URL? {
		guard let uuid = uuid else { return nil }
		let signedDir = FileManager.default.signed(uuid)
		return FileManager.default.getPath(in: signedDir, for: "ipa")
	}
}

extension Imported: AppInfoPresentable {
	var isSigned: Bool { false }
	var iconURL: URL? {
		Storage.shared.getAppIconFile(for: self)
	}
	var archiveURL: URL? {
		return nil
	}
}
