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
	
	@State private var _showAlert = false
	@State private var _alertTitle = ""
	@State private var _alertMessage = ""

	// MARK: Body
	var body: some View {
		NavigationStack {
			Form {
				_mainContent
			}
			.navigationTitle(.localized("Add Source"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar(content: {
				_toolbarContent
			})
			.animation(.default, value: _filteredRecommendedSourcesData.map { $0.data.id ?? "" })
			.task {
				await _fetchRecommendedRepositories()
			}
			.sheet(isPresented: $_showPortalExport) {
				PortalExportView(exportData: $_portalExportData)
			}
			.alert(_alertTitle, isPresented: $_showAlert) {
				Button(.localized("OK"), role: .cancel) { }
			} message: {
				Text(_alertMessage)
			}
		}
	}
	
	// MARK: - Main Content
	@ViewBuilder
	private var _mainContent: some View {
		// Import Results Section (shown after bulk import)
		if _showImportResults {
			_importResultsSection()
		}

		// Regular UI when not showing import results
		if !_showImportResults {
			_sourceURLSection

			if !_isExportMode {
				_featuredSourcesSection
			}
		}

		// Export mode UI
		if _isExportMode {
			_exportSelectionSection()
		}
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
					_alertTitle = .localized("Success")
					_alertMessage = .localized("Sources Copied To Clipboard")
					_showAlert = true
					_isExportMode = false
					_selectedSourcesForExport.removeAll()
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
			ToolbarItem(placement: .cancellationAction) {
				Button(.localized("Cancel"), role: .cancel) {
					dismiss()
				}
			}
			
			if !_isImporting {
				ToolbarItem(placement: .confirmationAction) {
					Button {
						FR.handleSource(_sourceURL) {
							dismiss()
						}
					} label: {
						Text(.localized("Save"))
							.fontWeight(.semibold)
					}
					.disabled(_sourceURL.isEmpty)
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
		Section {
			HStack(spacing: 12) {
				Image(systemName: "link")
					.foregroundStyle(Color.accentColor)

				TextField(.localized("Repository URL"), text: $_sourceURL)
					.keyboardType(.URL)
					.textInputAutocapitalization(.never)

				if !_sourceURL.isEmpty {
					Button {
						_sourceURL = ""
					} label: {
						Image(systemName: "xmark.circle.fill")
							.foregroundStyle(.secondary)
					}
					.buttonStyle(.plain)
				}
			}

			HStack(spacing: 0) {
				Button {
					_isImporting = true
					_fetchImportedRepositories(UIPasteboard.general.string) { }
				} label: {
					Label(.localized("Import"), systemImage: "square.and.arrow.down")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)

				Divider().padding(.horizontal, 8)

				Button {
					_isExportMode = true
					let sources = Storage.shared.getSources()
					guard !sources.isEmpty else {
						_alertTitle = .localized("No Sources")
						_alertMessage = .localized("No Sources To Export")
						_showAlert = true
						_isExportMode = false
						return
					}
					_selectedSourcesForExport = Set(sources.compactMap { $0.sourceURL?.absoluteString })
				} label: {
					Label(.localized("Export"), systemImage: "doc.on.doc")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)

				Divider().padding(.horizontal, 8)

				Button {
					_openPortalExportDirectly()
				} label: {
					Label(.localized("Transfer"), systemImage: "square.and.arrow.down.on.square.fill")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.bordered)
			}
			.listRowBackground(Color.clear)
			.listRowInsets(EdgeInsets())
		} header: {
			Text(.localized("Add Source"))
		} footer: {
			VStack(alignment: .leading, spacing: 4) {
				Label(.localized("Only AltStore repositories are supported."), systemImage: "info.circle")
				Label(.localized("Supports KravaShit/MapleSign and ESign imports."), systemImage: "arrow.triangle.2.circlepath")
			}
			.font(.caption)
		}
	}

	@ViewBuilder
	private func _actionButton(title: LocalizedStringKey, icon: String, color: Color, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			VStack(spacing: 8) {
				Image(systemName: icon)
					.font(.system(size: 20, weight: .semibold))
				Text(title)
					.font(.system(size: 12, weight: .bold, design: .rounded))
			}
			.foregroundStyle(color)
			.frame(maxWidth: .infinity)
			.padding(.vertical, 14)
			.background(color.opacity(0.1))
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
		}
		.buttonStyle(.plain)
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
						Text(.localized("Loading Featured Sources"))
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
		Section {
			ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
				_featuredSourceRow(url: url, source: source)
			}
		} header: {
			Text(.localized("Featured Sources"))
		} footer: {
			Text(.localized("More sources will be added soon!"))
		}
	}
	
	// MARK: - Featured Source Row
	@ViewBuilder
	private func _featuredSourceRow(url: URL, source: ASRepository) -> some View {
		HStack(spacing: 12) {
			if let iconURL = source.currentIconURL {
				AsyncImage(url: iconURL) { image in
					image.resizable()
						.aspectRatio(contentMode: .fill)
				} placeholder: {
					Color.accentColor.opacity(0.1)
				}
				.frame(width: 32, height: 32)
				.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
			} else {
				Image(systemName: "globe")
					.font(.system(size: 18))
					.foregroundStyle(Color.accentColor)
					.frame(width: 32, height: 32)
					.background(Color.accentColor.opacity(0.1))
					.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
			}

			VStack(alignment: .leading, spacing: 2) {
				Text(source.name ?? .localized("Unknown"))
					.font(.body.bold())
					.foregroundStyle(.primary)
				Text(url.host ?? url.absoluteString)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer()
			
			Button {
				Storage.shared.addSource(url, repository: source) { _ in
					withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
						_refreshFilteredRecommendedSourcesData()
					}
				}
			} label: {
				Text(.localized("Add"))
					.font(.subheadline.bold())
			}
			.buttonStyle(.bordered)
		}
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
					Text(.localized("Processing \(_currentImportProgress) Of \(_totalImportCount)..."))
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
		
		Section {
			// Select All / Deselect All buttons
			HStack {
				Button {
					withAnimation {
						_selectedSourcesForExport = Set(sources.compactMap { $0.sourceURL?.absoluteString })
					}
				} label: {
					Text(.localized("Select All"))
				}
				
				Spacer()

				Button {
					withAnimation {
						_selectedSourcesForExport.removeAll()
					}
				} label: {
					Text(.localized("Deselect All"))
				}
			}
			.buttonStyle(.borderless)

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
								.foregroundStyle(_selectedSourcesForExport.contains(urlString) ? Color.accentColor : Color.secondary)

							VStack(alignment: .leading, spacing: 2) {
								Text(source.name ?? .localized("Unknown"))
									.font(.body.bold())
									.foregroundStyle(.primary)
								Text(urlString)
									.font(.caption.monospaced())
									.foregroundStyle(.secondary)
									.lineLimit(1)
							}
						}
					}
					.buttonStyle(.plain)
				}
			}
		} header: {
			Text(.localized("Select Sources To Export"))
		}

		Section {
			Button {
				_exportThroughPortal()
			} label: {
				Label(.localized("Portal Transfer"), systemImage: "arrow.up.doc.fill")
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.borderedProminent)
			.disabled(_selectedSourcesForExport.isEmpty)
		}
	}

struct PlainGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
            configuration.content
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
	
	// MARK: - Export through Portal
	private func _exportThroughPortal() {
		let selectedUrls = Array(_selectedSourcesForExport)
		let exportData = PortalSourceExport.encode(urls: selectedUrls)
		_portalExportData = exportData
		_showPortalExport = true
		
		Logger.misc.info("[Portal Export] Encoded \(selectedUrls.count) sources to Base64")
	}
	
	// MARK: - Open Portal Export Directly
	private func _openPortalExportDirectly() {
		// Open Portal Export view directly for import/export
		_portalExportData = ""
		_showPortalExport = true
		
		Logger.misc.info("[Portal Export] Opening Portal Export view directly")
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
	@State private var isEncodedDataExpanded = true
	@State private var iconRotation: Double = 0
	
	enum ImportResult {
		case success(count: Int)
		case error(message: String)
	}
	
	private var gradientColors: [Color] {
		isImportMode ? [Color.cyan.opacity(0.8), Color.blue.opacity(0.6)] : [Color.purple.opacity(0.8), Color.indigo.opacity(0.6)]
	}
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					modeSelector
				}
				.listRowBackground(Color.clear)
				.listRowInsets(EdgeInsets())

				headerSection

				if isImportMode {
					importSection
				} else {
					exportSection
				}

				quickTipsSection
			}
			.navigationTitle(.localized("Portal Transfer"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar(content: {
				ToolbarItem(placement: .cancellationAction) {
					Button(.localized("Done")) { dismiss() }
				}
			})
		}
	}
	
	// MARK: - Header Section
	private var headerSection: some View {
		Section {
			VStack(spacing: 12) {
				Image(systemName: isImportMode ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
					.font(.system(size: 48))
					.foregroundStyle(isImportMode ? .cyan : .purple)

				Text(isImportMode ? .localized("Import Sources") : .localized("Export Sources"))
					.font(.headline)
				
				Text(isImportMode ? .localized("Paste your Portal Transfer code from another device to import sources.") : .localized("Share your sources with a Portal Transfer code."))
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical)
		}
	}
	
	// MARK: - Mode Selector
	private var modeSelector: some View {
		Picker(.localized("Mode"), selection: $isImportMode) {
			Text(.localized("Export")).tag(false)
			Text(.localized("Import")).tag(true)
		}
		.pickerStyle(.segmented)
		.padding(.horizontal)
	}
	
	// MARK: - Export Section
	private var exportSection: some View {
		Group {
			if !exportData.isEmpty {
				Section {
					Text(exportData)
						.font(.caption.monospaced())
						.textSelection(.enabled)
						.listRowBackground(Color(UIColor.secondarySystemGroupedBackground))

					Button {
						UIPasteboard.general.string = exportData
						HapticsManager.shared.success()
						showCopiedFeedback = true
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
							showCopiedFeedback = false
						}
					} label: {
						Label(showCopiedFeedback ? .localized("Copied") : .localized("Copy Code"), systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc")
					}
				} header: {
					Text(.localized("Transfer Code"))
				}
			} else {
				Section {
					Text(.localized("Select sources from the Export Mode to generate the source data."))
						.foregroundStyle(.secondary)
				}
			}
		}
	}
	
	// MARK: - Import Section
	private var importSection: some View {
		Group {
			Section {
				TextEditor(text: $importText)
					.font(.caption.monospaced())
					.frame(minHeight: 100)
				
				Button {
					if let clipboard = UIPasteboard.general.string {
						importText = clipboard
						HapticsManager.shared.softImpact()
					}
				} label: {
					Label(.localized("Paste Code"), systemImage: "doc.on.clipboard")
				}
			} header: {
				Text(.localized("Portal Code"))
			}

			Section {
				Button {
					performImport()
				} label: {
					Label(.localized("Import Sources"), systemImage: "arrow.down.circle.fill")
						.frame(maxWidth: .infinity)
				}
				.buttonStyle(.borderedProminent)
				.disabled(importText.isEmpty)
			}

			if let result = importResult {
				Section {
					resultCard(result: result)
				}
			}
		}
	}
	
	// MARK: - Result Card
	private func resultCard(result: ImportResult) -> some View {
		HStack(spacing: 12) {
			switch result {
			case .success(let count):
				Image(systemName: "checkmark.circle.fill")
					.foregroundStyle(.green)
				
				VStack(alignment: .leading, spacing: 2) {
					Text(.localized("Import Successful"))
						.font(.subheadline.bold())
					Text(.localized("\(count) Sources Added"))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				
			case .error(let message):
				Image(systemName: "xmark.circle.fill")
					.foregroundStyle(.red)
				
				VStack(alignment: .leading, spacing: 2) {
					Text(.localized("Import Failed"))
						.font(.subheadline.bold())
					Text(message)
						.font(.caption)
						.foregroundStyle(.secondary)
				}
			}
		}
	}
	
	// MARK: - Quick Tips Section
	private var quickTipsSection: some View {
		Section {
			Label(isImportMode ? .localized("Paste the Portal code you received") : .localized("Copy the transfer code to share"), systemImage: "1.circle.fill")
			Label(isImportMode ? .localized("Tap Import to add the sources") : .localized("Send it to friends or save it"), systemImage: "2.circle.fill")
			Label(isImportMode ? .localized("Sources will be added automatically") : .localized("They can import using this view"), systemImage: "3.circle.fill")
		} header: {
			Label(.localized("Portal Transfer Info"), systemImage: "lightbulb.fill")
		}
		.foregroundStyle(.secondary)
	}
	
	
	private func performImport() {
		Logger.misc.info("[Portal Import] Starting import process")
		
		guard let urls = PortalSourceExport.decode(importText) else {
			Logger.misc.error("[Portal Import] Failed to decode Portal data")
			withAnimation {
				importResult = .error(message: .localized("Invalid Portal Transfer Code"))
			}
			return
		}
		
		Logger.misc.info("[Portal Import] Decoded \(urls.count) URLs, adding to Sources")
		
		var addedCount = 0
		for urlString in urls {
			if !Storage.shared.sourceExists(urlString) {
				Storage.shared.addSource(url: urlString)
				addedCount += 1
				Logger.misc.debug("[Portal Import] Added Source: \(urlString)")
			} else {
				Logger.misc.debug("[Portal Import] Skipped existing source: \(urlString)")
			}
		}
		
		Logger.misc.info("[Portal Import] Import complete. Added \(addedCount) new sources.")
		
		withAnimation {
			importResult = .success(count: addedCount)
		}
		HapticsManager.shared.success()
	}
}
