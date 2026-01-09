import CoreData

// MARK: - Class extension: Imported Apps
extension Storage {
	func addImported(
		uuid: String,
		source: URL? = nil,
		
		appName: String? = nil,
		appIdentifier: String? = nil,
		appVersion: String? = nil,
		appIcon: String? = nil,
		
		completion: @escaping (Error?) -> Void
	) {
		
		DispatchQueue.main.async {
			let new = Imported(context: self.context)
			
			new.uuid = uuid
			new.source = source
			new.date = Date()
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
	
	func getLatestImportedApp() -> Imported? {
		let fetchRequest: NSFetchRequest<Imported> = Imported.fetchRequest()
		fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Imported.date, ascending: false)]
		fetchRequest.fetchLimit = 1
		return (try? context.fetch(fetchRequest))?.first
	}
}
