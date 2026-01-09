import CoreData

// MARK: - Class extension: Signed Apps
extension Storage {
	func addSigned(
		uuid: String,
		source: URL? = nil,
		certificate: CertificatePair? = nil,
		
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		
		completion: @escaping (Error?) -> Void
	) {
		
		DispatchQueue.main.async {
			let new = Signed(context: self.context)
			
			new.uuid = uuid
			new.source = source
			new.date = Date()
			// if nil, we assume adhoc or certificate was deleted afterwards
			new.certificate = certificate
			// could possibly be nil, but thats fine.
			new.identifier = appIdentifier
			new.name = appName
			new.icon = appIcon
			new.version = appVersion
			
			// Save context synchronously on main queue
			if self.context.hasChanges {
				do {
					try self.context.save()
					HapticsManager.shared.impact()
					completion(nil)
				} catch {
					completion(error)
				}
			} else {
				HapticsManager.shared.impact()
				completion(nil)
			}
		}
	}
	
	func getSignedApps() -> [Signed] {
		let request: NSFetchRequest<Signed> = Signed.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \Signed.date, ascending: false)]
		return (try? context.fetch(request)) ?? []
	}
}
