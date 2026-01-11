import CoreData

// MARK: - Class extension: Signed Apps
extension Storage {
	/// Notification posted when a signed app is added to the library
	static let signedAppDidAddNotification = Notification.Name("Feather.signedAppDidAdd")
	
	func addSigned(
		uuid: String,
		source: URL? = nil,
		certificate: CertificatePair? = nil,
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		size: Int64? = nil,
		completion: @escaping (Error?) -> Void
	) {
		DispatchQueue.main.async { [weak self] in
			guard let self = self else {
				completion(NSError(domain: "Storage", code: -1, userInfo: [NSLocalizedDescriptionKey: "Storage instance deallocated"]))
				return
			}
			
			let new = Signed(context: self.context)
			
			new.uuid = uuid
			new.source = source
			let now = Date()
			new.date = now
			new.dateAdded = now
			new.certificate = certificate
			new.identifier = appIdentifier ?? ""
			new.name = appName ?? "Unknown"
			new.icon = appIcon
			new.version = appVersion ?? ""
			
			// Calculate file size if not provided
			if let size = size {
				new.size = size
			} else {
				// Try to get size from the IPA file if available
				let ipaPath = FileManager.default.signed(uuid).appendingPathComponent("\(uuid).ipa")
				if let attributes = try? FileManager.default.attributesOfItem(atPath: ipaPath.path),
				   let fileSize = attributes[.size] as? UInt64 {
					new.size = Int64(fileSize)
				}
			}
			
			do {
				// Force save to ensure changes are persisted
				try self.context.save()
				
				// Ensure the context processes pending changes
				self.context.processPendingChanges()
				
				HapticsManager.shared.impact()
				AppLogManager.shared.success("Successfully added signed app to database: \(appName ?? "Unknown")", category: "Storage")
				
				// Post notification that signed app was added
				NotificationCenter.default.post(
					name: Storage.signedAppDidAddNotification,
					object: nil,
					userInfo: ["uuid": uuid, "name": appName ?? "Unknown"]
				)
				
				completion(nil)
			} catch {
				AppLogManager.shared.error("Failed to save signed app to database: \(error.localizedDescription)", category: "Storage")
				completion(error)
			}
		}
	}
	
	func getSignedApps() -> [Signed] {
		let request: NSFetchRequest<Signed> = Signed.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]
		return (try? context.fetch(request)) ?? []
	}
	
	func getLatestSignedApp() -> Signed? {
		let fetchRequest: NSFetchRequest<Signed> = Signed.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]
		fetchRequest.fetchLimit = 1
		return (try? context.fetch(fetchRequest))?.first
	}
}
