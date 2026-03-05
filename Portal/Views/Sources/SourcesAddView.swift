import SwiftUI
import NimbleViews
import AltSourceKit
import NimbleJSON
import OSLog
import CoreData

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

	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
	) private var _sources: FetchedResults<AltSource>

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
	@State private var _showQRMode = false
	@State private var _showWirelessMode = false
	@State private var _portalExportData = ""
	@State private var _showManageSources = false
	
	// MARK: Body
	var body: some View {
		NavigationStack {
			List {
				_mainContent
			}
			.listStyle(.insetGrouped)
			.navigationTitle(.localized("Add Source"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				_toolbarContent
			}
			.animation(.default, value: _filteredRecommendedSourcesData.map { $0.data.id ?? "" })
			.task {
				await _fetchRecommendedRepositories()
			}
			.sheet(isPresented: $_showPortalExport) {
				PortalTransferView(exportData: $_portalExportData)
			}
			.sheet(isPresented: $_showQRMode) {
				SourcesQRView(data: _portalExportData)
			}
			.sheet(isPresented: $_showWirelessMode) {
				TransferSourcesMP(sourceURLs: _getSelectedURLs())
			}
			.sheet(isPresented: $_showManageSources) {
				EditSourcesView(sources: _sources)
					.presentationDetents([.large])
					.presentationDragIndicator(.visible)
			}
			.onChange(of: _showManageSources) { newValue in
				if !newValue {
					_refreshFilteredRecommendedSourcesData()
				}
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
				Menu {
					Button {
						_exportThroughPortal()
					} label: {
						Label(.localized("Portal Transfer"), systemImage: "arrow.up.doc.fill")
					}

					Button {
						_exportThroughQR()
					} label: {
						Label(.localized("QR Code (Beta)"), systemImage: "qrcode")
					}

					Button {
						_exportAsPlainURLs()
					} label: {
						Label(.localized("Plain URLs"), systemImage: "link")
					}

					Button {
						_showWirelessMode = true
					} label: {
						Label(.localized("Share Wirelessly"), systemImage: "antenna.radiowaves.left.and.right")
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
			ToolbarItem(placement: .cancellationAction) {
				Button {
					dismiss()
				} label: {
					Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(Circle())
				}
			}
			
			ToolbarItem(placement: .confirmationAction) {
				HStack(spacing: 8) {
					if _isImporting {
						ProgressView()
					}

					Menu {
						Button {
							_showManageSources = true
						} label: {
							Label(.localized("Manage Sources"), systemImage: "list.bullet.rectangle.portrait")
						}

						Button {
							_isImporting = true
							_fetchImportedRepositories(UIPasteboard.general.string) { }
						} label: {
							Label(.localized("Import From Clipboard"), systemImage: "square.and.arrow.down")
						}

						Button {
							_isExportMode = true
							let sources = Storage.shared.getSources()
							guard !sources.isEmpty else {
								UIAlertController.showAlertWithOk(
									title: .localized("No Sources"),
									message: .localized("No Sources To Export")
								)
								_isExportMode = false
								return
							}
							_selectedSourcesForExport = Set(sources.compactMap { $0.identifier })
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
							.font(.system(size: 18))
					}
				}
			}
		}
	}
	
	// MARK: - Source URL Section
	@ViewBuilder
	private var _sourceURLSection: some View {
		Section {
			VStack(spacing: 16) {
				HStack(spacing: 12) {
					Image(systemName: "link")
						.font(.system(size: 18, weight: .bold))
						.foregroundStyle(Color.accentColor)
						.frame(width: 44, height: 44)
						.background(Color.accentColor.opacity(0.12))
						.clipShape(Circle())
					
					TextField(.localized("Repository URL"), text: $_sourceURL)
						.keyboardType(.URL)
						.textInputAutocapitalization(.never)
						.font(.system(.body, design: .rounded, weight: .medium))
                        .onSubmit {
                            FR.handleSource(_sourceURL) {
                                dismiss()
                            }
                        }
					
					if !_sourceURL.isEmpty {
						Button {
							_sourceURL = ""
						} label: {
							Image(systemName: "xmark.circle.fill")
								.foregroundStyle(.secondary.opacity(0.6))
								.font(.system(size: 20))
						}
						.buttonStyle(.plain)
					}
				}
				.padding(4)
			}
			
			VStack(alignment: .leading, spacing: 6) {
				Label(.localized("Only AltStore repositories are supported."), systemImage: "info.circle.fill")
				Label(.localized("Supports AltStore and ESign imports."), systemImage: "arrow.triangle.2.circlepath")
			}
			.font(.system(size: 12, weight: .semibold, design: .rounded))
			.foregroundStyle(.secondary.opacity(0.8))
		} header: {
			Text(.localized("Add Source"))
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
		Section {
			VStack(spacing: 12) {
				ProgressView()
					.scaleEffect(1.2)
				Text(.localized("Loading Featured Sources"))
					.font(.subheadline)
					.foregroundStyle(.secondary)
			}
			.frame(maxWidth: .infinity)
			.padding(.vertical, 40)
		} header: {
			Text(.localized("Featured"))
		}
	}
	
	// MARK: - Featured Sources List
	@ViewBuilder
	private var _featuredSourcesList: some View {
		Section {
			ForEach(_filteredRecommendedSourcesData, id: \.url) { (url, source) in
				_featuredSourceRow(url: url, source: source)
			}
		} header: {
			HStack {
				Text(.localized("Featured Sources"))
				Spacer()
				Text(.localized("Recommended"))
					.font(.caption.bold())
					.foregroundStyle(.secondary)
					.padding(.horizontal, 8)
					.padding(.vertical, 4)
					.background(Color.secondary.opacity(0.1))
					.clipShape(Capsule())
			}
		} footer: {
			Text(.localized("More sources will be added soon!"))
				.font(.system(size: 12, weight: .medium, design: .rounded))
				.frame(maxWidth: .infinity, alignment: .center)
				.padding(.top, 8)
		}
	}
	
	// MARK: - Featured Source Row
	@ViewBuilder
	private func _featuredSourceRow(url: URL, source: ASRepository) -> some View {
		HStack(spacing: 12) {
			FRIconCellView(
				title: source.name ?? .localized("Unknown"),
				subtitle: url.host ?? url.absoluteString,
				iconUrl: source.currentIconURL
			)
			
			Spacer()
			
			Button {
				Storage.shared.addSource(url, repository: source) { _ in
					withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
						_refreshFilteredRecommendedSourcesData()
					}
				}
			} label: {
				Text(.localized("Add"))
					.font(.system(size: 14, weight: .bold, design: .rounded))
					.foregroundStyle(.white)
					.padding(.horizontal, 16)
					.padding(.vertical, 6)
					.background(Color.accentColor)
					.clipShape(Capsule())
			}
			.buttonStyle(.plain)
		}
		.padding(.vertical, 4)
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
				.background(Color.clear)
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
	private func _exportSectionHeader() -> some View {
		VStack(alignment: .leading, spacing: 6) {
			Text(.localized("Select Sources To Export"))
				.font(.system(.title2, design: .rounded).bold())
				.foregroundStyle(.primary)

			Text(.localized("Choose the repositories you want to share"))
				.font(.system(.subheadline, design: .rounded, weight: .medium))
				.foregroundStyle(.secondary)
		}
		.padding(.horizontal, 16)
	}

	@ViewBuilder
	private func _exportSectionSelectButtons(sources: [AltSource]) -> some View {
		HStack(spacing: 12) {
			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
					_selectedSourcesForExport = Set(sources.compactMap { $0.identifier })
				}
				HapticsManager.shared.impact()
			} label: {
				HStack(spacing: 6) {
					Image(systemName: "checkmark.circle.fill")
					Text(.localized("Select All"))
				}
				.font(.system(size: 13, weight: .bold, design: .rounded))
				.foregroundStyle(.blue)
				.padding(.horizontal, 16)
				.padding(.vertical, 10)
				.background(Color.blue.opacity(0.1))
				.clipShape(Capsule())
			}

			Button {
				withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
					_selectedSourcesForExport.removeAll()
				}
				HapticsManager.shared.softImpact()
			} label: {
				HStack(spacing: 6) {
					Image(systemName: "circle")
					Text(.localized("Deselect All"))
				}
				.font(.system(size: 13, weight: .bold, design: .rounded))
				.foregroundStyle(.secondary)
				.padding(.horizontal, 16)
				.padding(.vertical, 10)
				.background(Color.secondary.opacity(0.1))
				.clipShape(Capsule())
			}
		}
		.padding(.horizontal, 16)
	}

	@ViewBuilder
	private func _exportSectionSourceList(sources: [AltSource]) -> some View {
		VStack(spacing: 0) {
			ForEach(sources, id: \.identifier) { source in
				if let identifier = source.identifier {
					ExportSourceRow(
						source: source,
						isSelected: _selectedSourcesForExport.contains(identifier),
						toggleSelect: {
							if _selectedSourcesForExport.contains(identifier) {
								_selectedSourcesForExport.remove(identifier)
							} else {
								_selectedSourcesForExport.insert(identifier)
							}
							HapticsManager.shared.selectionChanged()
						}
					)

					if sources.last?.identifier != identifier {
						Divider()
							.padding(.leading, 56)
					}
				}
			}
		}
		.background(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.fill(Color.clear)
				.shadow(color: .black.opacity(0.03), radius: 15, x: 0, y: 5)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(Color.primary.opacity(0.05), lineWidth: 1)
		)
	}

	@ViewBuilder
	private func _exportSelectionSection() -> some View {
		let sources = Storage.shared.getSources()

		VStack(alignment: .leading, spacing: 20) {
			Menu {
				Button {
					_exportThroughPortal()
				} label: {
					Label(.localized("Portal Transfer"), systemImage: "arrow.up.doc.fill")
				}

				Button {
					_exportThroughQR()
				} label: {
					Label(.localized("QR Code"), systemImage: "qrcode")
				}

				Button {
					_exportAsPlainURLs()
				} label: {
					Label(.localized("Plain URLs"), systemImage: "link")
				}

				Button {
					_showWirelessMode = true
				} label: {
					Label(.localized("Share Wirelessly"), systemImage: "antenna.radiowaves.left.and.right")
				}
			} label: {
				HStack(spacing: 12) {
					Image(systemName: "square.and.arrow.up")
						.font(.system(size: 18, weight: .bold))
					Text(.localized("Export Options"))
						.font(.system(.headline, design: .rounded).bold())
				}
				.foregroundStyle(.white)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 18)
				.background(
					LinearGradient(
						colors: [Color.purple, Color.indigo.opacity(0.9)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
				.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
				.shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
			}
			.disabled(_selectedSourcesForExport.isEmpty)
			.opacity(_selectedSourcesForExport.isEmpty ? 0.5 : 1)
			.scaleEffect(_selectedSourcesForExport.isEmpty ? 0.98 : 1.0)
			.animation(.spring(), value: _selectedSourcesForExport.isEmpty)
			.padding(.horizontal, 16)

			_exportSectionHeader()
			_exportSectionSelectButtons(sources: sources)
			_exportSectionSourceList(sources: sources)
				.padding(.horizontal, 16)
		}
		.padding(.top, 8)
	}

struct PlainGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            configuration.label
            configuration.content
                .padding()
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
	
	private func _getSelectedURLs() -> [String] {
		let sources = Storage.shared.getSources()
		return sources
			.filter { _selectedSourcesForExport.contains($0.identifier ?? "") }
			.compactMap { $0.sourceURL?.absoluteString }
	}

	// MARK: - Export through Portal
	private func _exportThroughPortal() {
		let selectedUrls = _getSelectedURLs()

		let exportData = PortalSourceExport.encode(urls: selectedUrls)
		_portalExportData = exportData
		_showPortalExport = true
		
		Logger.misc.info("[Portal Export] Encoded \(selectedUrls.count) sources to Base64")
	}

	private func _exportThroughQR() {
		let selectedUrls = _getSelectedURLs()

		let exportData = PortalSourceExport.encode(urls: selectedUrls)
		_portalExportData = exportData
		_showQRMode = true
	}

	private func _exportAsPlainURLs() {
		let selectedUrls = _getSelectedURLs()
			.joined(separator: "\n")

		UIPasteboard.general.string = selectedUrls
		UIAlertController.showAlertWithOk(
			title: .localized("Success"),
			message: .localized("Sources Copied To Clipboard")
		) {
			_isExportMode = false
			_selectedSourcesForExport.removeAll()
		}
	}
	
	// MARK: - Open Portal Export Directly
	private func _openPortalExportDirectly() {
		// Open Portal Export view directly and encode all sources automatically
		let sources = Storage.shared.getSources().compactMap { $0.sourceURL?.absoluteString }
		_portalExportData = PortalSourceExport.encode(urls: sources)
		_showPortalExport = true
		
		Logger.misc.info("[Portal Export] Opening Portal Export view directly and encoded \(sources.count) sources")
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
	
	enum ImportResult {
		case success(count: Int)
		case error(message: String)
	}
	
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(spacing: 24) {
					headerSection

					Picker("Mode", selection: $isImportMode) {
						Label(.localized("Export"), systemImage: "arrow.up.circle").tag(false)
						Label(.localized("Import"), systemImage: "arrow.down.circle").tag(true)
					}
					.pickerStyle(.segmented)
					.padding(.horizontal)
					.onChange(of: isImportMode) { _ in
						importResult = nil
						HapticsManager.shared.softImpact()
					}

					if isImportMode {
						importSection
					} else {
						exportSection
					}

					quickTipsSection
				}
				.padding(.vertical, 20)
			}
			.background(Color.clear)
			.navigationTitle(.localized("Portal Transfer"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button(.localized("Done")) { dismiss() }
				}
			}
		}
	}
	
	private var headerSection: some View {
		VStack(spacing: 12) {
				Image(systemName: isImportMode ? "arrow.down.doc.fill" : "arrow.up.doc.fill")
					.font(.system(size: 48))
					.foregroundStyle(isImportMode ? .cyan : .purple)
					.bounceEffect(isImportMode)
			
			Text(isImportMode ? .localized("Import Sources") : .localized("Export Sources"))
				.font(.title2.bold())

			Text(isImportMode ? .localized("Paste your Portal Transfer code to import.") : .localized("Share your sources with a Portal Transfer code."))
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal)
		}
		.padding(.top)
	}
	
	private var exportSection: some View {
		VStack(spacing: 16) {
			GroupBox {
				VStack(alignment: .leading, spacing: 12) {
					HStack {
						Label(.localized("Transfer Code"), systemImage: "key.fill")
							.font(.headline)
							.foregroundStyle(.purple)
						Spacer()
						if !exportData.isEmpty {
							Button {
								UIPasteboard.general.string = exportData
								HapticsManager.shared.success()
								withAnimation { showCopiedFeedback = true }
								DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
									withAnimation { showCopiedFeedback = false }
								}
							} label: {
								Label(showCopiedFeedback ? .localized("Copied") : .localized("Copy"), systemImage: showCopiedFeedback ? "checkmark" : "doc.on.doc")
									.font(.caption.bold())
							}
							.buttonStyle(.bordered)
							.tint(.purple)
						}
					}
					
					if !exportData.isEmpty {
						Text(exportData)
							.font(.system(.caption2, design: .monospaced))
							.textSelection(.enabled)
							.padding(12)
							.frame(maxWidth: .infinity, alignment: .leading)
							.background(Color.clear)
							.cornerRadius(12)
					} else {
						if #available(iOS 17.0, *) {
							ContentUnavailableView(.localized("No Data"), systemImage: "exclamationmark.triangle")
						} else {
							VStack(spacing: 16) {
								Image(systemName: "exclamationmark.triangle")
									.font(.system(size: 48))
									.foregroundStyle(.secondary)
								Text(.localized("No Data"))
									.font(.headline)
									.foregroundStyle(.secondary)
							}
							.padding()
							.frame(maxWidth: .infinity)
						}
					}
				}
			}
			.padding(.horizontal)
			.groupBoxStyle(ModernGroupBoxStyle())
		}
	}
	
	private var importSection: some View {
		VStack(spacing: 16) {
			GroupBox {
				VStack(alignment: .leading, spacing: 12) {
					HStack {
						Label(.localized("Portal Code"), systemImage: "square.and.pencil")
							.font(.headline)
							.foregroundStyle(.cyan)
						Spacer()
						Button {
							if let clipboard = UIPasteboard.general.string {
								importText = clipboard
								HapticsManager.shared.softImpact()
							}
						} label: {
							Label(.localized("Paste"), systemImage: "doc.on.clipboard.fill")
								.font(.caption.bold())
						}
						.buttonStyle(.bordered)
						.tint(.cyan)
					}
					
					TextEditor(text: $importText)
						.font(.system(.caption, design: .monospaced))
						.frame(minHeight: 120)
						.padding(8)
						.background(Color.clear)
						.cornerRadius(12)
				}
			}
			.padding(.horizontal)
			.groupBoxStyle(ModernGroupBoxStyle())
			
			Button {
				performImport()
			} label: {
				Label(.localized("Import Sources"), systemImage: "arrow.down.circle.fill")
					.frame(maxWidth: .infinity)
			}
			.buttonStyle(.borderedProminent)
			.controlSize(.large)
			.padding(.horizontal)
			.disabled(importText.isEmpty)
			
			if let result = importResult {
				resultCard(result: result)
					.padding(.horizontal)
			}
		}
	}
	
	private func resultCard(result: ImportResult) -> some View {
		GroupBox {
			HStack {
				switch result {
				case .success(let count):
					Label(.localized("\(count) Sources Added"), systemImage: "checkmark.circle.fill")
						.foregroundStyle(.green)
				case .error(let message):
					Label(message, systemImage: "xmark.circle.fill")
						.foregroundStyle(.red)
				}
				Spacer()
			}
		}
		.groupBoxStyle(ModernGroupBoxStyle())
	}
	
	private var quickTipsSection: some View {
		GroupBox {
			VStack(alignment: .leading, spacing: 10) {
				Label(.localized("Quick Tips"), systemImage: "lightbulb.fill")
					.font(.headline)
					.foregroundStyle(.orange)

				VStack(alignment: .leading, spacing: 8) {
					tipRow(icon: "1.circle.fill", text: isImportMode ? .localized("Paste the Portal code you received") : .localized("Copy the transfer code to share"))
					tipRow(icon: "2.circle.fill", text: isImportMode ? .localized("Tap Import to add the sources") : .localized("Send it to friends or save it"))
				}
			}
		}
		.padding(.horizontal)
		.groupBoxStyle(ModernGroupBoxStyle())
	}
	
	private func tipRow(icon: String, text: String) -> some View {
		HStack(spacing: 8) {
			Image(systemName: icon).foregroundStyle(.orange)
			Text(text).font(.caption).foregroundStyle(.secondary)
		}
	}
	
	private func performImport() {
		guard let urls = PortalSourceExport.decode(importText) else {
			withAnimation { importResult = .error(message: .localized("Invalid Portal Transfer Code")) }
			return
		}
		
		var addedCount = 0
		for urlString in urls {
			if !Storage.shared.sourceExists(urlString) {
				Storage.shared.addSource(url: urlString)
				addedCount += 1
			}
		}
		
		withAnimation { importResult = .success(count: addedCount) }
		HapticsManager.shared.success()
	}
}

struct ModernGroupBoxStyle: GroupBoxStyle {
	func makeBody(configuration: Configuration) -> some View {
		VStack(alignment: .leading) {
			configuration.label
			configuration.content
		}
		.padding()
		.background(Color.clear)
		.cornerRadius(16)
	}
}

// MARK: - Subviews
private struct ExportSourceRow: View {
    let source: AltSource
    let isSelected: Bool
    let toggleSelect: () -> Void

    var body: some View {
        Button(action: toggleSelect) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.accentColor))
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(source.name ?? .localized("Unknown"))
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)

                    Text(source.sourceURL?.absoluteString ?? "")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
