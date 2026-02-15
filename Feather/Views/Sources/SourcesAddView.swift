import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog
import NukeUI

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
		NavigationStack {
			List {
				if _showImportResults {
					_importResultsSection
				}

				if _isExportMode {
					_exportSelectionSection
				} else {
					_sourceURLSection
					_featuredSourcesSection
				}
			}
			.navigationTitle(.localized("Add Source"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				_toolbarContent
			}
			.task {
				await _fetchRecommendedRepositories()
			}
			.sheet(isPresented: $_showPortalExport) {
				PortalExportView(exportData: $_portalExportData)
			}
		}
	}
	
	// MARK: - Sections
	
	@ViewBuilder
	private var _importResultsSection: some View {
		Section {
			if _isProcessingImport {
				HStack {
					ProgressView()
					Text(.localized("Processing \(_currentImportProgress) Of \(_totalImportCount)..."))
						.font(.subheadline)
						.foregroundStyle(.secondary)
				}
			}
			
			let validSources = _importedSources.filter { $0.isValid }
			if !validSources.isEmpty {
				ForEach(validSources) { source in
					Label {
						VStack(alignment: .leading) {
							Text(source.data?.name ?? .localized("Unknown"))
								.font(.headline)
							Text(source.url.absoluteString)
								.font(.caption)
								.foregroundStyle(.secondary)
						}
					} icon: {
						Image(systemName: "checkmark.circle.fill")
							.foregroundStyle(.green)
					}
				}
			}
			
			let malformedSources = _importedSources.filter { !$0.isValid }
			if !malformedSources.isEmpty {
				ForEach(malformedSources) { source in
					Label {
						VStack(alignment: .leading) {
							Text(source.url.absoluteString)
								.font(.headline)
							if let error = source.error {
								Text(error.localizedDescription)
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
					} icon: {
						Image(systemName: "xmark.circle.fill")
							.foregroundStyle(.red)
					}
				}
			}
		} header: {
			Text(.localized("Import Results"))
		}
	}
	
	@ViewBuilder
	private var _sourceURLSection: some View {
		Section {
			HStack {
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
	private var _featuredSourcesSection: some View {
		Section {
			if _isFetchingRecommended {
				HStack {
					Spacer()
					ProgressView(.localized("Loading Featured Sources"))
					Spacer()
				}
			} else {
				ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
					HStack(spacing: 16) {
						if let iconURL = source.currentIconURL {
							LazyImage(url: iconURL) { state in
								if let image = state.image {
									image.resizable()
										.aspectRatio(contentMode: .fit)
										.frame(width: 40, height: 40)
										.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
								} else {
									_defaultSourceIcon
								}
							}
						} else {
							_defaultSourceIcon
						}

						VStack(alignment: .leading) {
							Text(source.name ?? .localized("Unknown"))
								.font(.headline)
							Text(url.host ?? url.absoluteString)
								.font(.subheadline)
								.foregroundStyle(.secondary)
						}

						Spacer()

						Button(.localized("Add")) {
							Storage.shared.addSource(url, repository: source) { _ in
								withAnimation {
									_refreshFilteredRecommendedSourcesData()
								}
							}
						}
						.buttonStyle(.bordered)
						.tint(.accentColor)
						.font(.subheadline.bold())
					}
					.padding(.vertical, 4)
				}
			}
		} header: {
			Text(.localized("Featured Sources"))
		}
	}
	
	@ViewBuilder
	private var _defaultSourceIcon: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 8, style: .continuous)
				.fill(Color.accentColor.opacity(0.1))
				.frame(width: 40, height: 40)
			Image(systemName: "globe")
				.foregroundStyle(Color.accentColor)
		}
	}
	
	@ViewBuilder
	private var _exportSelectionSection: some View {
		let sources = Storage.shared.getSources()
		Section {
			ForEach(sources, id: \.sourceURL?.absoluteString) { source in
				if let urlString = source.sourceURL?.absoluteString {
					Button {
						if _selectedSourcesForExport.contains(urlString) {
							_selectedSourcesForExport.remove(urlString)
						} else {
							_selectedSourcesForExport.insert(urlString)
						}
					} label: {
						HStack {
							Image(systemName: _selectedSourcesForExport.contains(urlString) ? "checkmark.circle.fill" : "circle")
								.foregroundStyle(_selectedSourcesForExport.contains(urlString) ? Color.accentColor : Color.secondary)
							
							VStack(alignment: .leading) {
								Text(source.name ?? .localized("Unknown"))
									.font(.headline)
									.foregroundStyle(.primary)
								Text(urlString)
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
					}
					.buttonStyle(.plain)
				}
			}
		} header: {
			Text(.localized("Select Sources To Export"))
		}
	}
	
	// MARK: - Toolbar
	@ToolbarContentBuilder
	private var _toolbarContent: some ToolbarContent {
		if _isExportMode {
			ToolbarItem(placement: .cancellationAction) {
				Button(.localized("Cancel")) {
					_isExportMode = false
					_selectedSourcesForExport.removeAll()
				}
			}
			
			ToolbarItem(placement: .confirmationAction) {
				Button(.localized("Export")) {
					let selectedUrls = _selectedSourcesForExport.joined(separator: "\n")
					UIPasteboard.general.string = selectedUrls
					UIAlertController.showAlertWithOk(
						title: .localized("Success"),
						message: .localized("Sources Copied To Clipboard")
					) {
						_isExportMode = false
						_selectedSourcesForExport.removeAll()
					}
				}
				.disabled(_selectedSourcesForExport.isEmpty)
			}

			ToolbarItem(placement: .primaryAction) {
				Menu {
					Button {
						_exportThroughPortal()
					} label: {
						Label(.localized("Portal Transfer"), systemImage: "arrow.up.doc.fill")
					}
					.disabled(_selectedSourcesForExport.isEmpty)

					Button {
						_selectedSourcesForExport = Set(Storage.shared.getSources().compactMap { $0.sourceURL?.absoluteString })
					} label: {
						Label(.localized("Select All"), systemImage: "checkmark.circle")
					}

					Button {
						_selectedSourcesForExport.removeAll()
					} label: {
						Label(.localized("Deselect All"), systemImage: "circle")
					}
				} label: {
					Image(systemName: "ellipsis.circle")
				}
			}
		} else if _showImportResults {
			ToolbarItem(placement: .confirmationAction) {
				Button(.localized("Done")) {
					_showImportResults = false
					_importedSources.removeAll()
					_isImporting = false
				}
			}
		} else {
			ToolbarItem(placement: .cancellationAction) {
				Button(.localized("Cancel")) { dismiss() }
			}
			
			ToolbarItem(placement: .confirmationAction) {
				if _isImporting {
					ProgressView()
				} else {
					Button(.localized("Add")) {
						FR.handleSource(_sourceURL) {
							dismiss()
						}
					}
					.disabled(_sourceURL.isEmpty)
				}
			}

			ToolbarItem(placement: .primaryAction) {
				Menu {
					Button {
						_isImporting = true
						_fetchImportedRepositories(UIPasteboard.general.string) { }
					} label: {
						Label(.localized("Import from Clipboard"), systemImage: "square.and.arrow.down")
					}

					Button {
						let sources = Storage.shared.getSources()
						guard !sources.isEmpty else {
							UIAlertController.showAlertWithOk(
								title: .localized("No Sources"),
								message: .localized("No Sources To Export")
							)
							return
						}
						_isExportMode = true
						_selectedSourcesForExport = Set(sources.compactMap { $0.sourceURL?.absoluteString })
					} label: {
						Label(.localized("Export Mode"), systemImage: "doc.on.doc")
					}

					Button {
						_openPortalExportDirectly()
					} label: {
						Label(.localized("Portal Transfer"), systemImage: "square.and.arrow.down.on.square.fill")
					}
				} label: {
					Image(systemName: "ellipsis.circle")
				}
			}
		}
	}
	
	// MARK: - Logic

	private func _exportThroughPortal() {
		let selectedUrls = Array(_selectedSourcesForExport)
		let exportData = PortalSourceExport.encode(urls: selectedUrls)
		_portalExportData = exportData
		_showPortalExport = true
		
		Logger.misc.info("[Portal Export] Encoded \(selectedUrls.count) sources to Base64")
	}
	
	private func _openPortalExportDirectly() {
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
	static let formatVersion = "1.0"
	
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
		return portalString
	}
	
	static func decode(_ portalString: String) -> [String]? {
		guard portalString.hasPrefix("PORTAL:") else { return nil }
		
		let components = portalString.split(separator: ":", maxSplits: 2)
		guard components.count == 3 else { return nil }
		
		let base64String = String(components[2])
		
		guard let data = Data(base64Encoded: base64String),
			  let jsonString = String(data: data, encoding: .utf8),
			  let jsonData = jsonString.data(using: .utf8),
			  let exportData = try? JSONDecoder().decode(PortalExportData.self, from: jsonData) else {
			return nil
		}
		
		return exportData.sources
	}
}

struct PortalExportData: Codable {
	let version: String
	let timestamp: TimeInterval
	let sources: [String]
}

// MARK: - Portal Export View
struct PortalExportView: View {
	@Environment(\.dismiss) private var dismiss
	@Binding var exportData: String
	@State private var showCopiedFeedback = false
	@State private var importText = ""
	@State private var isImportMode = false
	@State private var importResult: ImportResult?
	
	enum ImportResult {
		case success(count: Int)
		case error(message: String)
	}
	
	var body: some View {
		NavigationStack {
			List {
				Section {
					Picker("", selection: $isImportMode) {
						Text(.localized("Export")).tag(false)
						Text(.localized("Import")).tag(true)
					}
					.pickerStyle(.segmented)
				}

				if isImportMode {
					_importSection
				} else {
					_exportSection
				}

				_quickTipsSection
			}
			.navigationTitle(.localized("Portal Transfer"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button(.localized("Done")) { dismiss() }
				}
			}
		}
	}
	
	@ViewBuilder
	private var _exportSection: some View {
		Section {
			if !exportData.isEmpty {
				VStack(alignment: .leading, spacing: 12) {
					Text(exportData)
						.font(.system(.caption2, design: .monospaced))
						.textSelection(.enabled)

					Button {
						UIPasteboard.general.string = exportData
						HapticsManager.shared.success()
						withAnimation { showCopiedFeedback = true }
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
							withAnimation { showCopiedFeedback = false }
						}
					} label: {
						Label(showCopiedFeedback ? .localized("Copied") : .localized("Copy Code"),
							  systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc")
					}
					.buttonStyle(.bordered)
				}
				.padding(.vertical, 4)
			} else {
				Text(.localized("No Export Data. Select sources from Export Mode first."))
					.foregroundStyle(.secondary)
			}
		} header: {
			Text(.localized("Transfer Code"))
		}
	}
	
	@ViewBuilder
	private var _importSection: some View {
		Section {
			TextEditor(text: $importText)
				.frame(minHeight: 120)
				.font(.system(.caption, design: .monospaced))

			Button {
				if let clipboard = UIPasteboard.general.string {
					importText = clipboard
					HapticsManager.shared.softImpact()
				}
			} label: {
				Label(.localized("Paste from Clipboard"), systemImage: "doc.on.clipboard")
			}
			
			Button {
				performImport()
			} label: {
				Text(.localized("Import Sources"))
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.borderedProminent)
			.disabled(importText.isEmpty)
			
			if let result = importResult {
				switch result {
				case .success(let count):
					Label(.localized("\(count) Sources Added"), systemImage: "checkmark.circle.fill")
						.foregroundStyle(.green)
				case .error(let message):
					Label(message, systemImage: "exclamationmark.triangle.fill")
						.foregroundStyle(.red)
				}
			}
		} header: {
			Text(.localized("Portal Code"))
		}
	}
	
	@ViewBuilder
	private var _quickTipsSection: some View {
		Section {
			Label(isImportMode ? .localized("Paste the Portal code you received") : .localized("Copy the transfer code to share"), systemImage: "1.circle.fill")
			Label(isImportMode ? .localized("Tap Import to add the sources") : .localized("Send it to friends or save it"), systemImage: "2.circle.fill")
			Label(isImportMode ? .localized("Sources will be added automatically") : .localized("They can import using this view"), systemImage: "3.circle.fill")
		} header: {
			Label(.localized("Portal Transfer Info"), systemImage: "lightbulb.fill")
				.foregroundStyle(.orange)
		}
	}
	
	private func performImport() {
		guard let urls = PortalSourceExport.decode(importText) else {
			withAnimation {
				importResult = .error(message: .localized("Invalid Portal Transfer Code"))
			}
			return
		}
		
		var addedCount = 0
		for urlString in urls {
			if !Storage.shared.sourceExists(urlString) {
				Storage.shared.addSource(url: urlString)
				addedCount += 1
			}
		}
		
		withAnimation {
			importResult = .success(count: addedCount)
		}
		HapticsManager.shared.success()
	}
}
