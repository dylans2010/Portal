import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog

// MARK: - Import Result Model
struct ImportedSource: Identifiable {
	let id = UUID()
	let url: URL
	let data: ASRepository?
	let error: Error?
	var isValid: Bool { data != nil && error == nil }
}

// MARK: - View
struct SourcesAddView: View {
	typealias RepositoryDataHandler = Result<ASRepository, Error>
	@Environment(\.dismiss) var dismiss

	private let _dataService = NBFetchService()
	
	@State private var _filteredRecommendedSourcesData: [(url: URL, data: ASRepository)] = []
	private func _refreshFilteredRecommendedSourcesData() {
		let filtered = recommendedSourcesData
			.filter { (url, data) in
				let id = data.id ?? url.absoluteString
				return !Storage.shared.sourceExists(id)
			}
			.sorted { lhs, rhs in
				let lhsName = lhs.data.name ?? ""
				let rhsName = rhs.data.name ?? ""
				return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
			}
		_filteredRecommendedSourcesData = filtered
	}
	
	@State var recommendedSourcesData: [(url: URL, data: ASRepository)] = []
	let recommendedSources: [URL] = [
		"https://raw.githubusercontent.com/khcrysalis/Feather/refs/heads/main/app-repo.json",
		"https://raw.githubusercontent.com/Aidoku/Aidoku/altstore/apps.json",
		"https://flyinghead.github.io/flycast-builds/altstore.json",
		"https://xitrix.github.io/iTorrent/AltStore.json",
		"https://altstore.oatmealdome.me/",
		"https://raw.githubusercontent.com/LiveContainer/LiveContainer/refs/heads/main/apps.json",
		"https://alt.crystall1ne.dev/",
		"https://pokemmo.com/altstore/",
		"https://provenance-emu.com/apps.json",
		"https://community-apps.sidestore.io/sidecommunity.json",
		"https://alt.getutm.app"
	].map { URL(string: $0)! }
	
	@State private var _isImporting = false
	@State private var _sourceURL = ""
	@State private var _isFetchingRecommended = true
	@State private var _importedSources: [ImportedSource] = []
	@State private var _showImportResults = false
	@State private var _isProcessingImport = false
	@State private var _currentImportProgress = 0
	@State private var _totalImportCount = 0
	
	// Export mode states
	@State private var _isExportMode = false
	@State private var _selectedSourcesForExport: Set<String> = []
	@State private var _showPortalExport = false
	@State private var _portalExportData = ""
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Add Source"), displayMode: .inline) {
			ScrollView {
				_mainContent
			}
			.background(Color(.systemGroupedBackground))
			.toolbar {
				_toolbarContent
			}
			.animation(.default, value: _filteredRecommendedSourcesData.map { $0.data.id ?? "" })
			.task {
				await _fetchRecommendedRepositories()
			}
			.sheet(isPresented: $_showPortalExport) {
				PortalExportView(exportData: $_portalExportData)
			}
		}
	}
	
	// MARK: - Main Content
	@ViewBuilder
	private var _mainContent: some View {
		VStack(spacing: 16) {
			// Import Results Section (shown after bulk import)
			if _showImportResults {
				_importResultsSection()
			}
			
			// Regular UI when not showing import results
			_sourceURLSection
			
			// Export mode UI
			if _isExportMode {
				_exportSelectionSection()
			}
		}
		.padding(.bottom, 20)
	}
	
	// MARK: - Toolbar Content
	@ToolbarContentBuilder
	private var _toolbarContent: some ToolbarContent {
		if _isExportMode {
			ToolbarItem(placement: .cancellationAction) {
				Button(role: .cancel) {
					_isExportMode = false
					_selectedSourcesForExport.removeAll()
				} label: {
					Text(.localized("Cancel"))
				}
			}
			
			ToolbarItem(placement: .confirmationAction) {
				Button {
					let selectedUrls = _selectedSourcesForExport.joined(separator: "\n")
					UIPasteboard.general.string = selectedUrls
					UIAlertController.showAlertWithOk(
						title: .localized("Success"),
						message: .localized("Sources Copied To Clipboard")
					) {
						_isExportMode = false
						_selectedSourcesForExport.removeAll()
					}
				} label: {
					Text(.localized("Export Selected"))
				}
				.disabled(_selectedSourcesForExport.isEmpty)
			}
		} else if _showImportResults {
			ToolbarItem(placement: .confirmationAction) {
				Button {
					_showImportResults = false
					_importedSources.removeAll()
					_isImporting = false
				} label: {
					Text(.localized("Done"))
				}
			}
		} else {
			NBToolbarButton(role: .cancel)
			
			if !_isImporting {
				NBToolbarButton(
					.localized("Save"),
					style: .text,
					placement: .confirmationAction,
					isDisabled: _sourceURL.isEmpty
				) {
					FR.handleSource(_sourceURL) {
						dismiss()
					}
				}
			} else {
				ToolbarItem(placement: .confirmationAction) {
					ProgressView()
				}
			}
		}
	}
	
	// MARK: - Source URL Section
	@ViewBuilder
	private var _sourceURLSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(.localized("Source URL"))
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 4)
			
			VStack(spacing: 0) {
				HStack(spacing: 12) {
					Image(systemName: "link.circle.fill")
						.font(.title2)
						.foregroundStyle(
							LinearGradient(
								colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					
					TextField(.localized("Enter Source URL"), text: $_sourceURL)
						.keyboardType(.URL)
						.textInputAutocapitalization(.never)
						.font(.body)
					
					// Import button icon
					Button {
						_isImporting = true
						_fetchImportedRepositories(UIPasteboard.general.string) {
							// Don't dismiss anymore - show results instead
						}
					} label: {
						Image(systemName: "square.and.arrow.down")
							.font(.title3)
							.foregroundStyle(.blue)
					}
					.buttonStyle(.plain)
					
					// Export button icon
					Button {
						_isExportMode = true
						let sources = Storage.shared.getSources()
						guard !sources.isEmpty else {
							UIAlertController.showAlertWithOk(
								title: .localized("Error"),
								message: .localized("No Sources To Export")
							)
							_isExportMode = false
							return
						}
						// Initialize selection with all sources
						_selectedSourcesForExport = Set(sources.compactMap { $0.sourceURL?.absoluteString })
					} label: {
						Image(systemName: "doc.on.doc")
							.font(.title3)
							.foregroundStyle(.green)
					}
					.buttonStyle(.plain)
				}
				.padding()
			}
			
			VStack(alignment: .leading, spacing: 8) {
				Text(.localized("The only supported repositories are AltStore repositories."))
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(.localized("Supports importing from KravaShit/MapleSign and ESign."))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.padding(.horizontal, 4)
		}
		.padding(.horizontal)
	}
	// KravaShit lmaoo
	// MARK: - Featured Sources Section
	@ViewBuilder
	private var _featuredSourcesSection: some View {
		if _isFetchingRecommended {
			_loadingFeaturedSection
		} else if !_filteredRecommendedSourcesData.isEmpty {
			_featuredSourcesList
		}
	}
	
	// MARK: - Loading Featured Section
	@ViewBuilder
	private var _loadingFeaturedSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(.localized("Featured"))
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 4)
			
			VStack(spacing: 0) {
				HStack {
					Spacer()
					VStack(spacing: 12) {
						ProgressView()
							.scaleEffect(1.2)
						Text(.localized("Loading Featured Sources..."))
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					.padding(.vertical, 20)
					Spacer()
				}
				.padding()
			}
		}
		.padding(.horizontal)
	}
	
	// MARK: - Featured Sources List
	@ViewBuilder
	private var _featuredSourcesList: some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(.localized("Featured"))
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 4)
			
			VStack(spacing: 0) {
				ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
					_featuredSourceRow(url: url, source: source)
					
					if _filteredRecommendedSourcesData.last?.url != url {
						Divider()
							.padding(.leading, 16)
					}
				}
			}
			
			VStack(alignment: .leading, spacing: 8) {
				Text(.localized("More will get added soon!"))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.padding(.horizontal, 4)
		}
		.padding(.horizontal)
	}
	
	// MARK: - Featured Source Row
	@ViewBuilder
	private func _featuredSourceRow(url: URL, source: ASRepository) -> some View {
		HStack(spacing: 16) {
			FRIconCellView(
				title: source.name ?? .localized("Unknown"),
				subtitle: url.absoluteString,
				iconUrl: source.currentIconURL
			)
			
			Spacer()
			
			Button {
				Storage.shared.addSource(url, repository: source) { _ in
					_refreshFilteredRecommendedSourcesData()
				}
			} label: {
				Text(.localized("Add"))
					.font(.subheadline.bold())
					.foregroundStyle(.white)
					.padding(.horizontal, 24)
					.padding(.vertical, 10)
					.background(
						ZStack {
							// Shadow layer
							Capsule()
								.fill(Color.accentColor.opacity(0.3))
								.blur(radius: 4)
								.offset(y: 3)
							
							// Main gradient
							Capsule()
								.fill(
									LinearGradient(
										colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
						}
					)
					.shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
			}
			.buttonStyle(.borderless)
		}
		.padding()
	}
	
	// MARK: - Import Results Section
	@ViewBuilder
	private func _importResultsSection() -> some View {
		VStack(spacing: 16) {
			// Processing indicator
			if _isProcessingImport {
				VStack(spacing: 12) {
					ProgressView()
						.scaleEffect(1.2)
					Text(.localized("Processing \(_currentImportProgress) of \(_totalImportCount)..."))
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
				.padding()
				.frame(maxWidth: .infinity)
				.background(Color(UIColor.secondarySystemGroupedBackground))
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				.padding(.horizontal)
			}
			
			// Valid Sources Section
			let validSources = _importedSources.filter { $0.isValid }
			if !validSources.isEmpty {
				VStack(alignment: .leading, spacing: 12) {
					Text(.localized("Valid Sources"))
						.font(.headline)
						.foregroundStyle(.white)
						.padding(.horizontal, 4)
					
					VStack(spacing: 0) {
						ForEach(validSources) { source in
							HStack(spacing: 12) {
								Image(systemName: "checkmark.circle.fill")
									.font(.title3)
									.foregroundStyle(.white)
								
								VStack(alignment: .leading, spacing: 2) {
									Text(source.data?.name ?? .localized("Unknown"))
										.font(.body)
										.fontWeight(.medium)
										.foregroundStyle(.white)
									Text(source.url.absoluteString)
										.font(.caption)
										.foregroundStyle(.white.opacity(0.8))
										.lineLimit(1)
								}
								
								Spacer()
							}
							.padding()
							
							if validSources.last?.id != source.id {
								Divider()
									.background(.white.opacity(0.3))
									.padding(.leading, 56)
							}
						}
					}
					.background(
						LinearGradient(
							colors: [
								Color.green,
								Color.green.opacity(0.85),
								Color.green.opacity(0.7)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
					.shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 6)
				}
				.padding(.horizontal)
			}
			
			// Malformed Sources Section
			let malformedSources = _importedSources.filter { !$0.isValid }
			if !malformedSources.isEmpty {
				VStack(alignment: .leading, spacing: 12) {
					Text(.localized("Sources With Errors"))
						.font(.headline)
						.foregroundStyle(.white)
						.padding(.horizontal, 4)
					
					VStack(spacing: 0) {
						ForEach(malformedSources) { source in
							HStack(spacing: 12) {
								Image(systemName: "xmark.circle.fill")
									.font(.title3)
									.foregroundStyle(.white)
								
								VStack(alignment: .leading, spacing: 2) {
									Text(source.url.absoluteString)
										.font(.body)
										.fontWeight(.medium)
										.foregroundStyle(.white)
										.lineLimit(1)
									if let error = source.error {
										Text(error.localizedDescription)
											.font(.caption)
											.foregroundStyle(.white.opacity(0.8))
											.lineLimit(2)
									}
								}
								
								Spacer()
							}
							.padding()
							
							if malformedSources.last?.id != source.id {
								Divider()
									.background(.white.opacity(0.3))
									.padding(.leading, 56)
							}
						}
					}
					.background(
						LinearGradient(
							colors: [
								Color.red,
								Color.red.opacity(0.85),
								Color.red.opacity(0.7)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
					.shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
				}
				.padding(.horizontal)
			}
		}
	}
	
	// MARK: - Export Selection Section
	@ViewBuilder
	private func _exportSelectionSection() -> some View {
		let sources = Storage.shared.getSources()
		
		VStack(alignment: .leading, spacing: 16) {
			Text(.localized("Select Sources To Export"))
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 4)
			
			// Select All / Deselect All buttons
			HStack(spacing: 12) {
				Button {
					_selectedSourcesForExport = Set(sources.compactMap { $0.sourceURL?.absoluteString })
				} label: {
					Text(.localized("Select All"))
						.font(.subheadline.bold())
						.foregroundStyle(.white)
						.padding(.horizontal, 20)
						.padding(.vertical, 10)
						.background(
							LinearGradient(
								colors: [Color.blue, Color.blue.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.clipShape(Capsule())
						.shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
				}
				
				Button {
					_selectedSourcesForExport.removeAll()
				} label: {
					Text(.localized("Deselect All"))
						.font(.subheadline.bold())
						.foregroundStyle(.white)
						.padding(.horizontal, 20)
						.padding(.vertical, 10)
						.background(
							LinearGradient(
								colors: [Color.gray, Color.gray.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.clipShape(Capsule())
						.shadow(color: Color.gray.opacity(0.3), radius: 6, x: 0, y: 3)
				}
				
				Spacer()
			}
			.padding(.horizontal)
			
			// Export through Portal button
			Button {
				_exportThroughPortal()
			} label: {
				HStack(spacing: 10) {
					Image(systemName: "arrow.up.doc.fill")
						.font(.system(size: 16, weight: .semibold))
					Text(.localized("Export through Portal"))
						.font(.subheadline.bold())
				}
				.foregroundStyle(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(
					LinearGradient(
						colors: [Color.purple, Color.indigo.opacity(0.8)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				.shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
			}
			.disabled(_selectedSourcesForExport.isEmpty)
			.opacity(_selectedSourcesForExport.isEmpty ? 0.6 : 1)
			.padding(.horizontal)
			
			// Sources list with checkmarks
			VStack(spacing: 0) {
				ForEach(sources, id: \.sourceURL?.absoluteString) { source in
					if let urlString = source.sourceURL?.absoluteString {
						Button {
							if _selectedSourcesForExport.contains(urlString) {
								_selectedSourcesForExport.remove(urlString)
							} else {
								_selectedSourcesForExport.insert(urlString)
							}
						} label: {
							HStack(spacing: 12) {
								Image(systemName: _selectedSourcesForExport.contains(urlString) ? "checkmark.circle.fill" : "circle")
									.font(.title3)
									.foregroundStyle(_selectedSourcesForExport.contains(urlString) ? Color.accentColor : Color.secondary)
								
								VStack(alignment: .leading, spacing: 2) {
									Text(source.name ?? .localized("Unknown"))
										.font(.body)
										.foregroundStyle(.primary)
									Text(urlString)
										.font(.caption)
										.foregroundStyle(.secondary)
										.lineLimit(1)
								}
								
								Spacer()
							}
							.padding()
						}
						.buttonStyle(.plain)
						
						if sources.last?.sourceURL?.absoluteString != urlString {
							Divider()
								.padding(.leading, 56)
						}
					}
				}
			}
			.background(Color(UIColor.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
		}
		.padding(.horizontal)
	}
	
	// MARK: - Export through Portal
	private func _exportThroughPortal() {
		let selectedUrls = Array(_selectedSourcesForExport)
		let exportData = PortalSourceExport.encode(urls: selectedUrls)
		_portalExportData = exportData
		_showPortalExport = true
		
		Logger.misc.info("[Portal Export] Encoded \(selectedUrls.count) sources to Base64")
	}
	
	private func _fetchRecommendedRepositories() async {
		await MainActor.run { _isFetchingRecommended = true }
		let fetched = await _concurrentFetchRepositories(from: recommendedSources)
		await MainActor.run {
			withAnimation {
				recommendedSourcesData = fetched
				_refreshFilteredRecommendedSourcesData()
				_isFetchingRecommended = false
			}
		}
	}
	
	private func _fetchImportedRepositories(
		_ code: String?,
		competion: @escaping () -> Void
	) {
		guard let code else { return }
		
		let handler = ASDeobfuscator(with: code)
		let repoUrls = handler.decode().compactMap { URL(string: $0) }
		guard !repoUrls.isEmpty else { return }
		
		// Reset states
		_importedSources.removeAll()
		_isProcessingImport = true
		_currentImportProgress = 0
		_totalImportCount = repoUrls.count
		
		Task {
			for url in repoUrls {
				await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
					_dataService.fetch<ASRepository>(from: url) { (result: RepositoryDataHandler) in
						Task { @MainActor in
							_currentImportProgress += 1
							
							switch result {
							case .success(let repo):
								_importedSources.append(ImportedSource(url: url, data: repo, error: nil))
								// Add valid sources immediately
								Storage.shared.addSource(url, repository: repo) { _ in }
							case .failure(let error):
								Logger.misc.error("Failed to fetch \(url): \(error.localizedDescription)")
								_importedSources.append(ImportedSource(url: url, data: nil, error: error))
							}
						}
						continuation.resume()
					}
				}
			}
			
			await MainActor.run {
				_isProcessingImport = false
				_showImportResults = true
				_isImporting = false
				competion()
			}
		}
	}
	
	private func _concurrentFetchRepositories(
		from urls: [URL]
	) async -> [(url: URL, data: ASRepository)] {
		var results: [(url: URL, data: ASRepository)] = []
		
		let dataService = _dataService
		
		await withTaskGroup(of: Void.self) { group in
			for url in urls {
				group.addTask {
					await withCheckedContinuation { continuation in
						dataService.fetch<ASRepository>(from: url) { (result: RepositoryDataHandler) in
							switch result {
							case .success(let repo):
								Task { @MainActor in
									results.append((url: url, data: repo))
								}
							case .failure(let error):
								Logger.misc.error("Failed to fetch \(url): \(error.localizedDescription)")
							}
							continuation.resume()
						}
					}
				}
			}
			await group.waitForAll()
		}
		
		return results
	}

}

// MARK: - Portal Source Export Utility
struct PortalSourceExport {
	/// Portal export format version for compatibility
	static let formatVersion = "1.0"
	
	/// Encodes source URLs to a Portal-compatible Base64 string
	/// Format: PORTAL:v1.0:<base64_encoded_json>
	static func encode(urls: [String]) -> String {
		let exportData = PortalExportData(
			version: formatVersion,
			timestamp: Date().timeIntervalSince1970,
			sources: urls
		)
		
		guard let jsonData = try? JSONEncoder().encode(exportData),
			  let jsonString = String(data: jsonData, encoding: .utf8) else {
			Logger.misc.error("[Portal Export] Failed to encode sources to JSON")
			return ""
		}
		
		let base64 = Data(jsonString.utf8).base64EncodedString()
		let portalString = "PORTAL:v\(formatVersion):\(base64)"
		
		Logger.misc.info("[Portal Export] Successfully encoded \(urls.count) sources")
		Logger.misc.debug("[Portal Export] Format: PORTAL:v\(formatVersion):<base64>")
		
		return portalString
	}
	
	/// Decodes a Portal-compatible Base64 string to source URLs
	static func decode(_ portalString: String) -> [String]? {
		Logger.misc.info("[Portal Import] Attempting to decode Portal string")
		
		// Check for Portal format prefix
		guard portalString.hasPrefix("PORTAL:") else {
			Logger.misc.warning("[Portal Import] Invalid format: missing PORTAL prefix")
			return nil
		}
		
		let components = portalString.split(separator: ":", maxSplits: 2)
		guard components.count == 3 else {
			Logger.misc.warning("[Portal Import] Invalid format: expected 3 components, got \(components.count)")
			return nil
		}
		
		let versionString = String(components[1])
		let base64String = String(components[2])
		
		Logger.misc.debug("[Portal Import] Version: \(versionString)")
		
		guard let data = Data(base64Encoded: base64String),
			  let jsonString = String(data: data, encoding: .utf8),
			  let jsonData = jsonString.data(using: .utf8),
			  let exportData = try? JSONDecoder().decode(PortalExportData.self, from: jsonData) else {
			Logger.misc.error("[Portal Import] Failed to decode Base64 or parse JSON")
			return nil
		}
		
		Logger.misc.info("[Portal Import] Successfully decoded \(exportData.sources.count) sources")
		Logger.misc.debug("[Portal Import] Export timestamp: \(Date(timeIntervalSince1970: exportData.timestamp))")
		
		return exportData.sources
	}
}

/// Data structure for Portal export format
struct PortalExportData: Codable {
	let version: String
	let timestamp: TimeInterval
	let sources: [String]
}

// MARK: - Portal Export View
struct PortalExportView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme
	@Binding var exportData: String
	@State private var showCopiedFeedback = false
	@State private var importText = ""
	@State private var isImportMode = false
	@State private var importResult: ImportResult?
	
	enum ImportResult {
		case success(count: Int)
		case error(message: String)
	}
	
	private var gradientColors: [Color] {
		[Color.purple.opacity(0.8), Color.indigo.opacity(0.6)]
	}
	
	var body: some View {
		NavigationStack {
			ZStack {
				Color(UIColor.systemGroupedBackground)
					.ignoresSafeArea()
				
				ScrollView {
					VStack(spacing: 20) {
						headerSection
						modeSelector
						
						if isImportMode {
							importSection
						} else {
							exportSection
						}
					}
					.padding(.horizontal, 16)
					.padding(.vertical, 20)
				}
			}
			.navigationTitle(.localized("Portal Export"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(.localized("Done")) { dismiss() }
				}
			}
		}
	}
	
	// MARK: - Header Section
	private var headerSection: some View {
		VStack(spacing: 12) {
			ZStack {
				Circle()
					.fill(
						RadialGradient(
							colors: [Color.purple.opacity(0.2), Color.clear],
							center: .center,
							startRadius: 20,
							endRadius: 50
						)
					)
					.frame(width: 100, height: 100)
				
				Circle()
					.fill(
						LinearGradient(
							colors: gradientColors,
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 70, height: 70)
					.shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
				
				Image(systemName: isImportMode ? "arrow.down.doc.fill" : "arrow.up.doc.fill")
					.font(.system(size: 28, weight: .semibold))
					.foregroundStyle(.white)
			}
			
			Text(isImportMode ? .localized("Import sources using Base64") : .localized("Export sources using Base64"))
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.padding(.bottom, 8)
	}
	
	// MARK: - Mode Selector
	private var modeSelector: some View {
		HStack(spacing: 12) {
			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
					isImportMode = false
					importResult = nil
				}
			} label: {
				HStack(spacing: 8) {
					Image(systemName: "arrow.up.doc.fill")
						.font(.system(size: 14, weight: .semibold))
					Text(.localized("Export"))
						.font(.system(size: 15, weight: .semibold))
				}
				.foregroundStyle(!isImportMode ? .white : .primary)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(
							!isImportMode
							? AnyShapeStyle(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
							: AnyShapeStyle(Color(UIColor.tertiarySystemBackground))
						)
				)
				.shadow(color: !isImportMode ? Color.purple.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
			}
			.buttonStyle(.plain)
			
			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
					isImportMode = true
					importResult = nil
				}
			} label: {
				HStack(spacing: 8) {
					Image(systemName: "arrow.down.doc.fill")
						.font(.system(size: 14, weight: .semibold))
					Text(.localized("Import"))
						.font(.system(size: 15, weight: .semibold))
				}
				.foregroundStyle(isImportMode ? .white : .primary)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 14)
				.background(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(
							isImportMode
							? AnyShapeStyle(LinearGradient(colors: [.cyan, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
							: AnyShapeStyle(Color(UIColor.tertiarySystemBackground))
						)
				)
				.shadow(color: isImportMode ? Color.cyan.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
			}
			.buttonStyle(.plain)
		}
		.padding(20)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(Color(UIColor.secondarySystemGroupedBackground))
				.shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
		)
	}
	
	// MARK: - Export Section
	private var exportSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack {
				Label(.localized("Encoded Data"), systemImage: "lock.fill")
					.font(.headline)
					.foregroundStyle(.primary)
				
				Spacer()
				
				Button {
					UIPasteboard.general.string = exportData
					HapticsManager.shared.success()
					withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
						showCopiedFeedback = true
					}
					DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
						withAnimation {
							showCopiedFeedback = false
						}
					}
				} label: {
					HStack(spacing: 6) {
						Image(systemName: showCopiedFeedback ? "checkmark.circle.fill" : "doc.on.doc")
						if showCopiedFeedback {
							Text(.localized("Copied!"))
								.font(.caption)
						}
					}
					.foregroundStyle(showCopiedFeedback ? .green : .purple)
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.background(
						Capsule()
							.fill(showCopiedFeedback ? Color.green.opacity(0.15) : Color.purple.opacity(0.15))
					)
				}
			}
			
			Text(exportData)
				.font(.system(.caption, design: .monospaced))
				.textSelection(.enabled)
				.padding(12)
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.fill(Color(UIColor.tertiarySystemBackground))
				)
				.overlay(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.stroke(Color.purple.opacity(0.3), lineWidth: 1)
				)
			
			// Info section
			VStack(alignment: .leading, spacing: 8) {
				Label(.localized("How to use"), systemImage: "info.circle.fill")
					.font(.subheadline.bold())
					.foregroundStyle(.purple)
				
				Text(.localized("1. Copy the encoded data above"))
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(.localized("2. Share it with others or save it"))
					.font(.caption)
					.foregroundStyle(.secondary)
				Text(.localized("3. They can import using the Import tab"))
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			.padding(12)
			.background(
				RoundedRectangle(cornerRadius: 10, style: .continuous)
					.fill(Color.purple.opacity(0.08))
			)
		}
		.padding(20)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(Color(UIColor.secondarySystemGroupedBackground))
				.shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
		)
	}
	
	// MARK: - Import Section
	private var importSection: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack {
				Label(.localized("Paste Portal Data"), systemImage: "doc.on.clipboard")
					.font(.headline)
					.foregroundStyle(.primary)
				
				Spacer()
				
				Button {
					if let clipboard = UIPasteboard.general.string {
						importText = clipboard
						HapticsManager.shared.softImpact()
					}
				} label: {
					Image(systemName: "doc.on.clipboard")
						.foregroundStyle(.cyan)
				}
			}
			
			TextEditor(text: $importText)
				.font(.system(.caption, design: .monospaced))
				.frame(minHeight: 100)
				.padding(12)
				.background(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.fill(Color(UIColor.tertiarySystemBackground))
				)
				.overlay(
					RoundedRectangle(cornerRadius: 12, style: .continuous)
						.stroke(Color.cyan.opacity(0.2), lineWidth: 1)
				)
			
			// Import button
			Button {
				performImport()
			} label: {
				HStack(spacing: 12) {
					Image(systemName: "arrow.down.circle.fill")
						.font(.system(size: 18, weight: .semibold))
					Text(.localized("Import Sources"))
						.font(.system(size: 17, weight: .bold))
				}
				.foregroundStyle(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 18)
				.background(
					RoundedRectangle(cornerRadius: 16, style: .continuous)
						.fill(
							importText.isEmpty
							? AnyShapeStyle(Color.gray.opacity(0.5))
							: AnyShapeStyle(LinearGradient(colors: [.cyan, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
						)
				)
				.shadow(color: importText.isEmpty ? .clear : .cyan.opacity(0.3), radius: 10, x: 0, y: 5)
			}
			.disabled(importText.isEmpty)
			
			// Import result
			if let result = importResult {
				switch result {
				case .success(let count):
					HStack(spacing: 8) {
						Image(systemName: "checkmark.circle.fill")
							.foregroundStyle(.green)
						Text(.localized("Successfully imported \(count) sources"))
							.font(.subheadline)
							.foregroundStyle(.green)
					}
					.padding(12)
					.frame(maxWidth: .infinity)
					.background(
						RoundedRectangle(cornerRadius: 10, style: .continuous)
							.fill(Color.green.opacity(0.1))
					)
					
				case .error(let message):
					HStack(spacing: 8) {
						Image(systemName: "xmark.circle.fill")
							.foregroundStyle(.red)
						Text(message)
							.font(.subheadline)
							.foregroundStyle(.red)
					}
					.padding(12)
					.frame(maxWidth: .infinity)
					.background(
						RoundedRectangle(cornerRadius: 10, style: .continuous)
							.fill(Color.red.opacity(0.1))
					)
				}
			}
		}
		.padding(20)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(Color(UIColor.secondarySystemGroupedBackground))
				.shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 15, x: 0, y: 8)
		)
	}
	
	private func performImport() {
		Logger.misc.info("[Portal Import] Starting import process")
		
		guard let urls = PortalSourceExport.decode(importText) else {
			Logger.misc.error("[Portal Import] Failed to decode Portal data")
			withAnimation {
				importResult = .error(message: .localized("Invalid Portal data format"))
			}
			return
		}
		
		Logger.misc.info("[Portal Import] Decoded \(urls.count) URLs, adding to sources")
		
		var addedCount = 0
		for urlString in urls {
			if !Storage.shared.sourceExists(urlString) {
				Storage.shared.addSource(url: urlString)
				addedCount += 1
				Logger.misc.debug("[Portal Import] Added source: \(urlString)")
			} else {
				Logger.misc.debug("[Portal Import] Skipped existing source: \(urlString)")
			}
		}
		
		Logger.misc.info("[Portal Import] Import complete. Added \(addedCount) new sources")
		
		withAnimation {
			importResult = .success(count: addedCount)
		}
		HapticsManager.shared.success()
	}
}
