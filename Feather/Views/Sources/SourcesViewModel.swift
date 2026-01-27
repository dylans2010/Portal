import Foundation
import AltSourceKit
import SwiftUI
import NimbleJSON

// MARK: - Default Required Source Configuration
struct DefaultSourceConfig {
    static let wsfSourceURL = "https://raw.githubusercontent.com/WSF-Team/WSF/refs/heads/main/Repo/app-repo.json"
    static let wsfSourceName = "WSF Repository"
    
    static var requiredSourceURLs: [String] {
        [wsfSourceURL]
    }
    
    static func isRequiredSource(_ url: String?) -> Bool {
        guard let url = url else { return false }
        return requiredSourceURLs.contains(url)
    }
    
    static func isRequiredSource(_ source: AltSource) -> Bool {
        isRequiredSource(source.sourceURL?.absoluteString)
    }
}

// MARK: - Fetch State
enum SourceFetchState {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - Class
final class SourcesViewModel: ObservableObject {
    static let shared = SourcesViewModel()
    
    typealias RepositoryDataHandler = Result<ASRepository, Error>
    
    private let _dataService = NBFetchService()
    private let _cacheManager = RepositoryCacheManager.shared
    private var _fetchTask: Task<Void, Never>?
    private var _lastFetchTime: Date?
    private let _minimumRefreshInterval: TimeInterval = 30 // 30 seconds minimum between refreshes
    
    var isFinished = true
    @Published var sources: [AltSource: ASRepository] = [:]
    @Published var fetchState: SourceFetchState = .idle
    @Published var fetchProgress: Double = 0
    @Published var failedSources: Set<String> = []
    @Published var errorMessage: String? = nil
    
    @Published var pinnedSourceIDs: [String] = UserDefaults.standard.stringArray(forKey: "pinnedSources") ?? [] {
        didSet {
            UserDefaults.standard.set(pinnedSourceIDs, forKey: "pinnedSources")
        }
    }
    
    // MARK: - Source Statistics
    var totalAppsCount: Int {
        sources.values.reduce(0) { $0 + $1.apps.count }
    }
    
    var totalNewsCount: Int {
        sources.values.reduce(0) { $0 + ($1.news?.count ?? 0) }
    }
    
    var loadedSourcesCount: Int {
        sources.count
    }
    
    // MARK: - Pin Management
    func togglePin(for source: AltSource) {
        guard let id = source.sourceURL?.absoluteString else { return }
        if pinnedSourceIDs.contains(id) {
            pinnedSourceIDs.removeAll { $0 == id }
        } else {
            pinnedSourceIDs.append(id)
        }
        HapticsManager.shared.softImpact()
    }
    
    func isPinned(_ source: AltSource) -> Bool {
        guard let id = source.sourceURL?.absoluteString else { return false }
        return pinnedSourceIDs.contains(id)
    }
    
    /// Check if a source is a required default source that cannot be removed
    func isRequiredSource(_ source: AltSource) -> Bool {
        return DefaultSourceConfig.isRequiredSource(source)
    }
    
    /// Ensure the default required source exists
    func ensureDefaultSourceExists() {
        AppLogManager.shared.info("Checking for default required source...", category: "Sources")
        
        let defaultURL = DefaultSourceConfig.wsfSourceURL
        
        // Check if source already exists in CoreData
        let context = Storage.shared.container.viewContext
        let fetchRequest = AltSource.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "sourceURL == %@", defaultURL)
        
        do {
            let existingSources = try context.fetch(fetchRequest)
            if existingSources.isEmpty {
                AppLogManager.shared.info("Adding default WSF source...", category: "Sources")
                Storage.shared.addSource(url: defaultURL)
                AppLogManager.shared.success("Default WSF source added successfully", category: "Sources")
            } else {
                AppLogManager.shared.debug("Default WSF source already exists", category: "Sources")
            }
        } catch {
            AppLogManager.shared.error("Failed to check for default source: \(error.localizedDescription)", category: "Sources")
        }
    }
    
    // MARK: - Full Manual Fetch
    func forceFetchAllSources(_ sources: FetchedResults<AltSource>) async {
        await MainActor.run {
            _cacheManager.clearCache()
            errorMessage = nil
        }
        await fetchSources(sources, refresh: true)
    }

    // MARK: - Optimized Fetch with Cancellation Support
    func fetchSources(_ sources: FetchedResults<AltSource>, refresh: Bool = false, batchSize: Int = 4) async {
        // Cancel any existing fetch task
        _fetchTask?.cancel()
        
        guard isFinished else { return }
        
        // Rate limiting - prevent too frequent refreshes
        if refresh, let lastFetch = _lastFetchTime,
           Date().timeIntervalSince(lastFetch) < _minimumRefreshInterval {
            AppLogManager.shared.debug("Skipping refresh - too soon since last fetch", category: "Sources")
            return
        }
        
        // Check if sources to be fetched are the same as before
        if !refresh, sources.allSatisfy({ self.sources[$0] != nil }) { return }
        
        isFinished = false
        await MainActor.run {
            fetchState = .loading
            fetchProgress = 0
            failedSources = []
            errorMessage = nil
        }
        
        defer {
            isFinished = true
            _lastFetchTime = Date()
        }
        
        // Load from cache first if not refreshing
        if !refresh {
            await MainActor.run {
                self.sources = [:]
            }
            
            // Load cached data in parallel
            await withTaskGroup(of: (AltSource, ASRepository?).self) { group in
                for source in sources {
                    group.addTask {
                        if let url = source.sourceURL, let cachedRepo = self._cacheManager.getCachedRepository(for: url) {
                            return (source, cachedRepo)
                        }
                        return (source, nil)
                    }
                }
                
                for await (source, repo) in group {
                    if let repo = repo {
                        await MainActor.run {
                            self.sources[source] = repo
                        }
                    }
                }
            }
        } else {
            await MainActor.run {
                self.sources = [:]
            }
        }
        
        let sourcesArray = Array(sources)
        let totalSources = sourcesArray.count
        
        // Use adaptive batch size based on source count
        let adaptiveBatchSize = min(batchSize, max(2, totalSources / 4))
        
        var currentProcessedCount = 0
        
        for startIndex in stride(from: 0, to: sourcesArray.count, by: adaptiveBatchSize) {
            // Check for cancellation
            if Task.isCancelled { break }
            
            let endIndex = min(startIndex + adaptiveBatchSize, sourcesArray.count)
            let batch = sourcesArray[startIndex..<endIndex]
            
            let batchResults = await withTaskGroup(of: (AltSource, ASRepository?, Error?).self, returning: [(AltSource, ASRepository?, Error?)].self) { group in
                for source in batch {
                    group.addTask {
                        guard let url = source.sourceURL else {
                            return (source, nil, nil)
                        }
                        
                        return await withCheckedContinuation { continuation in
                            self._dataService.fetch(from: url) { (result: RepositoryDataHandler) in
                                switch result {
                                case .success(let repo):
                                    // Cache the successful repository
                                    self._cacheManager.cacheRepository(repo, for: url)
                                    continuation.resume(returning: (source, repo, nil))
                                case .failure(let error):
                                    continuation.resume(returning: (source, nil, error))
                                }
                            }
                        }
                    }
                }
                
                var results: [(AltSource, ASRepository?, Error?)] = []
                for await result in group {
                    results.append(result)
                }
                return results
            }
            
            // Update processed count after batch completes
            currentProcessedCount += batchResults.count
            let progressValue = Double(currentProcessedCount) / Double(totalSources)
            
            await MainActor.run {
                for (source, repo, error) in batchResults {
                    if let repo = repo {
                        self.sources[source] = repo
                    } else if error != nil, let urlString = source.sourceURL?.absoluteString {
                        self.failedSources.insert(urlString)
                    }
                }
                self.fetchProgress = progressValue
            }
        }
        
        await MainActor.run {
            if !failedSources.isEmpty {
                errorMessage = "\(failedSources.count) sources failed to load"
                fetchState = .error(errorMessage!)
            } else {
                fetchState = .loaded
                errorMessage = nil
            }
            fetchProgress = 1.0
        }
    }
    
    // MARK: - Single Source Refresh
    func refreshSource(_ source: AltSource) async {
        guard let url = source.sourceURL else { return }
        
        await withCheckedContinuation { continuation in
            _dataService.fetch(from: url) { [weak self] (result: RepositoryDataHandler) in
                guard let self = self else {
                    continuation.resume()
                    return
                }
                
                switch result {
                case .success(let repo):
                    self._cacheManager.cacheRepository(repo, for: url)
                    DispatchQueue.main.async {
                        self.sources[source] = repo
                        self.failedSources.remove(url.absoluteString)
                    }
                case .failure(_):
                    DispatchQueue.main.async {
                        self.failedSources.insert(url.absoluteString)
                    }
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Prefetch Apps for Source
    func prefetchApps(for source: AltSource) {
        guard let repo = sources[source] else { return }
        
        // Prefetch app icons in background
        Task.detached(priority: .background) {
            for app in repo.apps.prefix(20) {
                if let iconURL = app.iconURL {
                    _ = try? Data(contentsOf: iconURL)
                }
            }
        }
    }
    
    // MARK: - Search Across All Sources
    func searchApps(query: String) -> [(source: ASRepository, app: ASRepository.App)] {
        guard !query.isEmpty else { return [] }
        
        var results: [(source: ASRepository, app: ASRepository.App)] = []
        
        for (_, repo) in sources {
            let matchingApps = repo.apps.filter { app in
                (app.name?.localizedCaseInsensitiveContains(query) ?? false) ||
                (app.developer?.localizedCaseInsensitiveContains(query) ?? false) ||
                (app.localizedDescription?.localizedCaseInsensitiveContains(query) ?? false)
            }
            
            for app in matchingApps {
                results.append((source: repo, app: app))
            }
        }
        
        return results.sorted { ($0.app.name ?? "") < ($1.app.name ?? "") }
    }
    
    // MARK: - Get Recently Updated Apps
    func getRecentlyUpdatedApps(limit: Int = 20) -> [(source: ASRepository, app: ASRepository.App)] {
        var allApps: [(source: ASRepository, app: ASRepository.App, date: Date)] = []
        
        for (_, repo) in sources {
            for app in repo.apps {
                if let date = app.currentDate?.date {
                    allApps.append((source: repo, app: app, date: date))
                }
            }
        }
        
        return allApps
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { (source: $0.source, app: $0.app) }
    }
}

// MARK: - Repository Cache Manager
final class RepositoryCacheManager {
	static let shared = RepositoryCacheManager()
	
	private let cacheDirectory: URL
	private let fileManager = FileManager.default
	private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
	
	private init() {
		let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
		cacheDirectory = cachesDirectory.appendingPathComponent("RepositoryCache", isDirectory: true)
		
		// Create cache directory if it doesn't exist
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
	}
	
	private func cacheFilePath(for url: URL) -> URL {
		let fileName = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? "unknown"
		return cacheDirectory.appendingPathComponent(fileName).appendingPathExtension("json")
	}
	
	func cacheRepository(_ repository: ASRepository, for url: URL) {
		let filePath = cacheFilePath(for: url)
		
		do {
			let encoder = JSONEncoder()
			let data = try encoder.encode(repository)
			try data.write(to: filePath)
		} catch {
			print("Failed to cache repository: \(error)")
		}
	}
	
	func getCachedRepository(for url: URL) -> ASRepository? {
		let filePath = cacheFilePath(for: url)
		
		guard fileManager.fileExists(atPath: filePath.path) else {
			return nil
		}
		
		// Check if cache is expired
		if let attributes = try? fileManager.attributesOfItem(atPath: filePath.path),
		   let modificationDate = attributes[.modificationDate] as? Date {
			if Date().timeIntervalSince(modificationDate) > cacheExpirationInterval {
				// if the cache expired, remove it to save space
				try? fileManager.removeItem(at: filePath)
				return nil
			}
		}
		
		do {
			let data = try Data(contentsOf: filePath)
			let decoder = JSONDecoder()
			let repository = try decoder.decode(ASRepository.self, from: data)
			return repository
		} catch {
			print("Failed to load cached repository: \(error)")
			// If decoding fails, remove the corrupted cache file
			try? fileManager.removeItem(at: filePath)
			return nil
		}
	}
	
	func clearCache() {
		try? fileManager.removeItem(at: cacheDirectory)
		try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
	}
}
