import CoreData
import AltSourceKit
import OSLog

// MARK: - Constants
private let kSourceOrderMigrationKey = "SourceOrderMigrationCompleted"

// MARK: - Class extension: Sources
extension Storage {
	/// Retrieve sources in an array, we don't normally need this in swiftUI but we have it for the copy sources action
	func getSources() -> [AltSource] {
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		return (try? context.fetch(request)) ?? []
	}
	
	/// Add a source from a URL string - fetches repository data automatically
	func addSource(url urlString: String) {
		guard let url = URL(string: urlString) else {
			Logger.misc.error("Invalid URL string: \(urlString)")
			return
		}
		
		// Check if source already exists
		if sourceExists(urlString) {
			Logger.misc.debug("Source already exists: \(urlString)")
			return
		}
		
		// Fetch repository data and add source
		Task {
			do {
				let (data, _) = try await URLSession.shared.data(from: url)
				let repository = try JSONDecoder().decode(ASRepository.self, from: data)
				
				await MainActor.run {
					self.addSource(url, repository: repository, id: urlString) { error in
						if let error = error {
							Logger.misc.error("Failed to add source: \(error.localizedDescription)")
						}
					}
				}
			} catch {
				// If fetching fails, add with minimal info
				await MainActor.run {
					self.addSource(url, name: "Unknown", identifier: urlString, iconURL: nil, deferSave: false) { error in
						if let error = error {
							Logger.misc.error("Failed to add source: \(error.localizedDescription)")
						}
					}
				}
			}
		}
	}
	
	func addSource(
		_ url: URL,
		name: String? = "Unknown",
		identifier: String,
		iconURL: URL? = nil,
		deferSave: Bool = false,
		completion: @escaping (Error?) -> Void
	) {
		if sourceExists(identifier) {
			completion(nil)
			Logger.misc.debug("ignoring \(identifier)")
			return
		}
		
		// Get the maximum order value from existing sources
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \AltSource.order, ascending: false)]
		request.fetchLimit = 1
		let maxOrder = (try? context.fetch(request).first?.order ?? -1) ?? -1
		
		let new = AltSource(context: context)
		new.name = name
		new.date = Date()
		new.identifier = identifier
		new.sourceURL = url
		new.iconURL = iconURL
		new.order = maxOrder + 1
		
		do {
			if !deferSave {
				try context.save()
				HapticsManager.shared.impact()
			}
			completion(nil)
		} catch {
			completion(error)
		}
	}
	
	func addSource(
		_ url: URL,
		repository: ASRepository,
		id: String = "",
		deferSave: Bool = false,
		completion: @escaping (Error?) -> Void
	) {
		addSource(
			url,
			name: repository.name,
			identifier: !id.isEmpty
						? id
						: (repository.id ?? url.absoluteString),
			iconURL: repository.currentIconURL,
			deferSave: deferSave,
			completion: completion
		)
	}

	func addSources(
		repos: [URL: ASRepository],
		completion: @escaping (Error?) -> Void
	) {
		
		for (url, repo) in repos {
			addSource(
				url,
				repository: repo,
				deferSave: true,
				completion: { error in
					if let error {
						completion(error)
					}
				}
			)
		}
		
		saveContext()
		HapticsManager.shared.impact()
		completion(nil)
	}

	func deleteSource(for source: AltSource) {
		context.delete(source)
		saveContext()
	}

	func sourceExists(_ identifier: String) -> Bool {
		let fetchRequest: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier)

		do {
			let count = try context.count(for: fetchRequest)
			return count > 0
		} catch {
			Logger.misc.error("Error checking if repository exists: \(error)")
			return false
		}
	}
	
	func reorderSources(_ sources: [AltSource]) {
		// Update the order
		for (index, source) in sources.enumerated() {
			source.order = Int16(index)
		}
		
		// Save with error handling
		do {
			try context.save()
		} catch {
			Logger.misc.error("Error reordering sources: \(error)")
			// Rollback to revert all changes
			context.rollback()
		}
	}
	
	/// Initialize order values for existing sources that don't have one
	/// This is called once on app launch to migrate existing data
	func initializeSourceOrders() {
		// Use a lock to prevent race conditions
		objc_sync_enter(self)
		defer { objc_sync_exit(self) }
		
		// Check if migration has already been done
		guard !UserDefaults.standard.bool(forKey: kSourceOrderMigrationKey) else { return }
		
		let request: NSFetchRequest<AltSource> = AltSource.fetchRequest()
		request.sortDescriptors = [NSSortDescriptor(keyPath: \AltSource.date, ascending: true)]
		
		do {
			let sources = try context.fetch(request)
			
			// Check if any source has order == -1 (uninitialized)
			let needsInitialization = sources.contains { $0.order == -1 }
			
			if needsInitialization {
				for (index, source) in sources.enumerated() {
					source.order = Int16(index)
				}
				try context.save()
			}
			
			// Mark migration as complete
			UserDefaults.standard.set(true, forKey: kSourceOrderMigrationKey)
		} catch {
			Logger.misc.error("Error initializing source orders: \(error)")
			// Don't set migration flag if it failed - we'll try again next time
		}
	}
}
