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
