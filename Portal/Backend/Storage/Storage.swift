import CoreData

// MARK: - Class
final class Storage: ObservableObject {
	static let shared = Storage()
	static let appGroupID = "group.ayon1xw.PortalDev"

	let container: NSPersistentContainer
	
	private let _name: String = "Feather"
	
	init(inMemory: Bool = false) {
		container = NSPersistentContainer(name: _name)
		
		if inMemory {
			container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
		} else if UserDefaults.standard.bool(forKey: "Feather.saveDataToDevice") {
			if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Storage.appGroupID) {
				let storeURL = groupURL.appendingPathComponent("\(_name).sqlite")
				let description = NSPersistentStoreDescription(url: storeURL)
				container.persistentStoreDescriptions = [description]
			}
		}
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		
		container.viewContext.automaticallyMergesChangesFromParent = true
	}
	
	var context: NSManagedObjectContext {
		container.viewContext
	}
	
	func saveContext() {
		DispatchQueue.main.async {
			if self.context.hasChanges {
				try? self.context.save()
			}
		}
	}
	
	func clearContext<T: NSManagedObject>(request: NSFetchRequest<T>) {
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: (request as? NSFetchRequest<NSFetchRequestResult>)!)
		_ = try? context.execute(deleteRequest)
	}
	
	func countContent<T: NSManagedObject>(for type: T.Type) -> String {
		let request = T.fetchRequest()
		return "\((try? context.count(for: request)) ?? 0)"
	}
	
	var documentsURL: URL {
		URL.documentsDirectory
	}
}
