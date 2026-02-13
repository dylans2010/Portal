import SwiftUI
import AltSourceKit
import NimbleViews
import Combine

// MARK: - Did You Know Facts
struct DidYouKnowFacts {
	static let facts = [
		"Portal is fully open source and made by the Feather team and tweaked by the WSF Team!",
		"You can sign apps with your own Apple Developer certificate.",
		"Portal supports multiple app sources for easy discovery.",
		"Apps signed with Portal can be installed directly on your device.",
		"You can import apps from URLs or local files.",
		"Portal respects your privacy, all signing happens on your device.",
		"Regular certificate rotation helps avoid revocations.",
		"You can manage multiple certificates in Portal.",
		"Source repositories can be added from any compatible URL.",
		"Portal uses modern SwiftUI for a native iOS experience.",
		"App entitlements control what permissions an app has.",
		"Provisioning profiles contain your app signing information.",
		"Free developer accounts can sign apps for 7 days.",
		"Paid developer accounts provide 1-year certificates.",
		"The PPQ check helps identify at-risk certificates.",
		"You can backup your certificates to Files app.",
		"Portal supports both IPA and TIPA file formats.",
		"App icons can be customized before installation.",
		"Bundle IDs should be unique to avoid conflicts.",
		"Portal can resign previously signed apps."
	]
	
	static func random() -> String {
		facts.randomElement() ?? facts[0]
	}
}

// MARK: - All Apps View (Modern Integrated Style)
struct AllAppsView: View {
    var isTab: Bool = false
    @Environment(\.dismiss) private var dismiss
    @AppStorage("Feather.useGradients") private var _useGradients: Bool = true
    @AppStorage("Feather.allApps.showSorting") private var _showSorting: Bool = true
    @AppStorage("Feather.allApps.rowSpacing") private var _rowSpacing: Double = 0
    @AppStorage("Feather.allApps.rowStyle") private var _rowStyle: AllAppsRowStyle = .minimal
    @AppStorage("Feather.allApps.rowHorizontalPadding") private var _rowHorizontalPadding: Double = 20.0
    @AppStorage("Feather.allApps.useSpringAnimations") private var _useSpringAnimations: Bool = true

    // Advanced Customization
    @AppStorage("Feather.allApps.useGrid") private var _useGrid: Bool = false
    @AppStorage("Feather.allApps.gridColumns") private var _gridColumns: Int = 3
    @AppStorage("Feather.allApps.gridSpacing") private var _gridSpacing: Double = 16.0
    @AppStorage("Feather.allApps.useGlassEffects") private var _useGlassEffects: Bool = true
    @AppStorage("Feather.allApps.searchBarFloating") private var _searchBarFloating: Bool = false
    @AppStorage("Feather.allApps.showAppCount") private var _showAppCount: Bool = true
    @AppStorage("Feather.allApps.searchBarStyle") private var _searchBarStyle: Int = 0

    enum AllAppsRowStyle: String, CaseIterable, Identifiable {
        case minimal = "Minimal"
        case card = "Card"
        case flat = "Flat"
        var id: String { self.rawValue }
    }
    
    @State private var _searchText = ""
    @State private var _selectedRoute: SourceAppRoute?
    @FocusState private var _searchFieldFocused: Bool
    @State private var _isSearching = false

    @AppStorage("Feather.allApps.sortOption") private var _sortOption: AppSortOption = .name
    @AppStorage("Feather.allApps.sortAscending") private var _sortAscending: Bool = true

    enum AppSortOption: String, CaseIterable, Identifiable {
        case name = "Name"
        case date = "Date"
        case size = "Size"

        var id: String { self.rawValue }

        var icon: String {
            switch self {
            case .name: return "textformat"
            case .date: return "calendar"
            case .size: return "internaldrive"
            }
        }
    }
    
    var object: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    @State private var _sources: [ASRepository]?
    @State private var _isLoading = true
    @State private var _loadedSourcesCount = 0
    @State private var _currentFact = DidYouKnowFacts.random()
    
    // Optimized State for Large Datasets
    @State private var _allApps: [(source: ASRepository, app: ASRepository.App)] = []
    @State private var _filteredApps: [(source: ASRepository, app: ASRepository.App)] = []
    @State private var _filterTask: Task<Void, Never>?

    private var _totalAppCount: Int {
        _allApps.count
    }
    
    // MARK: Body
    var body: some View {
        Group {
            if isTab {
                mainContent
                    .searchable(text: $_searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search \(_totalAppCount) Apps")
            } else {
                mainContent
            }
        }
        .navigationBarHidden(!isTab)
        .onAppear {
            _loadAllSources()
        }
        .onChange(of: _searchText) { _ in
            _filterApps()
        }
        .onChange(of: object) { _ in
            _loadAllSources()
        }
        .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: _useGrid)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: _searchBarFloating)
    }

    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            if _isSearching {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text("Searching...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .systemGroupedBackground).opacity(0.8))
                .transition(.opacity)
                .zIndex(10)
            }

            if _isLoading {
                // Modern Loading Screen
                loadingScreen
            } else if let _sources, !_sources.isEmpty {
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        if !_searchBarFloating {
                            headerView
                            if !isTab {
                                searchBar
                            }
                        } else {
                            headerView
                        }

                        // Results count when searching
                        if !_searchText.isEmpty {
                            HStack {
                                Text("\(_filteredApps.count) Result\(_filteredApps.count == 1 ? "" : "s")")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        }

                        // Apps list
                        if _filteredApps.isEmpty && !_searchText.isEmpty {
                            emptySearchResultsView
                        } else {
                            appsListView
                        }

                        // Bottom padding
                        Color.clear.frame(height: _searchBarFloating ? 100 : 30)
                    }
                }

                if _searchBarFloating && !isTab {
                    searchBar
                        .padding(.bottom, 20)
                        .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                emptySourcesView
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 16) {
            if !isTab {
                Button {
                    HapticsManager.shared.softImpact()
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
            }

            if isTab {
                Text("Apps")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            } else if _showAppCount {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(_totalAppCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Apps Available")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("All Apps")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            Spacer()

            if _showSorting {
                Menu {
                    ForEach(AppSortOption.allCases) { option in
                        Button {
                            if _sortOption == option {
                                _sortAscending.toggle()
                            } else {
                                _sortOption = option
                                _sortAscending = true
                            }
                            _filterApps()
                        } label: {
                            HStack {
                                Label(option.rawValue, systemImage: option.icon)
                                if _sortOption == option {
                                    Image(systemName: _sortAscending ? "chevron.up" : "chevron.down")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentColor)
                        .padding(8)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)

            TextField("Search \(_totalAppCount) Apps", text: $_searchText)
                .font(.system(size: 16))
                .focused($_searchFieldFocused)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !_searchText.isEmpty {
                Button {
                    _searchText = ""
                    _filterApps()
                    HapticsManager.shared.softImpact()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.horizontal, _searchBarStyle == 2 ? 0 : 14)
        .padding(.vertical, _searchBarStyle == 1 ? 14 : 10)
        .background(
            Group {
                if _searchBarStyle == 2 {
                    Color.clear
                } else {
                    RoundedRectangle(cornerRadius: _searchBarStyle == 1 ? 20 : 14, style: .continuous)
                        .fill(_useGlassEffects ? AnyShapeStyle(.ultraThinMaterial) : AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground)))
                        .overlay(
                            RoundedRectangle(cornerRadius: _searchBarStyle == 1 ? 20 : 14, style: .continuous)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                }
            }
        )
        .overlay(alignment: .bottom) {
            if _searchBarStyle == 2 {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                    .offset(y: 8)
            }
        }
        .shadow(color: _searchBarFloating ? Color.black.opacity(0.1) : Color.clear, radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, _searchBarFloating ? 0 : 16)
    }

    private var appsListView: some View {
        Group {
            if _useGrid {
                let columns = Array(repeating: GridItem(.flexible(), spacing: _gridSpacing), count: _useGrid ? _gridColumns : 1)
                LazyVGrid(columns: columns, spacing: _gridSpacing) {
                    ForEach(Array(_filteredApps.enumerated()), id: \.element.app.currentUniqueId) { index, entry in
                        AllAppsRowView(
                            source: entry.source,
                            app: entry.app,
                            onTap: {
                                HapticsManager.shared.softImpact()
                                _selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
                            },
                            isLast: index == _filteredApps.count - 1
                        )
                    }
                }
                .padding(.horizontal, 20)
            } else {
                LazyVStack(spacing: _rowSpacing) {
                    ForEach(Array(_filteredApps.enumerated()), id: \.element.app.currentUniqueId) { index, entry in
                        AllAppsRowView(
                            source: entry.source,
                            app: entry.app,
                            onTap: {
                                HapticsManager.shared.softImpact()
                                _selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
                            },
                            isLast: index == _filteredApps.count - 1
                        )
                        .padding(.horizontal, _rowHorizontalPadding)
                    }
                }
            }
        }
    }

    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            VStack(spacing: 6) {
                Text("No Results Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Try a different search term.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var emptySourcesView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "tray")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            Text("No Sources")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            Text("Add sources to view all your apps here.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
	
	// MARK: - Loading Screen
	@ViewBuilder
	private var loadingScreen: some View {
		ZStack {
			LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
				.ignoresSafeArea()
			
			VStack(spacing: 30) {
				Spacer()
				
				// Animated loading circle
				ZStack {
					Circle()
						.stroke(Color.secondary.opacity(0.2), lineWidth: 8)
						.frame(width: 80, height: 80)

					Circle()
						.trim(from: 0, to: 0.7)
						.stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
						.frame(width: 80, height: 80)
						.rotationEffect(.degrees(-90))
						.rotationEffect(.degrees(_isLoading ? 360 : 0))
						.animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: _isLoading)
				}
				
				// Progress text
				VStack(spacing: 8) {
					Text("Loading Sources")
						.font(.system(size: 22, weight: .bold, design: .rounded))
						.foregroundStyle(.primary)

					Text("\(_loadedSourcesCount)/\(object.count) Sources are being loaded...")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.animation(.easeInOut(duration: 0.3), value: _loadedSourcesCount)
				}
				
				Spacer()

				// Did you know section
				VStack(spacing: 12) {
					HStack(spacing: 8) {
						Image(systemName: "lightbulb.fill")
							.font(.system(size: 18))
							.foregroundStyle(.yellow)
						Text("Did You Know?")
							.font(.headline)
							.fontWeight(.semibold)
							.foregroundStyle(.primary)
					}

					Text(_currentFact)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.center)
						.lineLimit(3)
						.padding(.horizontal, 40)
						.transition(AnyTransition.opacity.combined(with: .scale))
				}
				.padding(.bottom, 40)
			}
			.padding(30)
			.background(.ultraThinMaterial)
			.cornerRadius(20)
			.padding(20)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	private func _filterApps() {
		_filterTask?.cancel()

		let searchText = _searchText
		let allApps = _allApps
		let sortOption = _sortOption
		let sortAscending = _sortAscending
		let useSpringAnimations = _useSpringAnimations

		_filterTask = Task {
			// Debounce search typing
			if !searchText.isEmpty {
				try? await Task.sleep(nanoseconds: 300_000_000)
			}

			if Task.isCancelled { return }

            await MainActor.run {
                withAnimation {
                    _isSearching = true
                }
            }

			// Perform filtering and sorting in background
			let sortedApps = await Task.detached(priority: .userInitiated) {
				let apps: [(source: ASRepository, app: ASRepository.App)]

				if searchText.isEmpty {
					apps = allApps
				} else {
					let query = searchText.lowercased()
					apps = allApps.filter { entry in
						(entry.app.name?.lowercased().contains(query) ?? false) ||
						(entry.app.description?.lowercased().contains(query) ?? false) ||
						(entry.app.subtitle?.lowercased().contains(query) ?? false) ||
						(entry.app.localizedDescription?.lowercased().contains(query) ?? false)
					}
				}

				return apps.sorted { entry1, entry2 in
					let result: Bool
					switch sortOption {
					case .name:
						let name1 = entry1.app.name ?? ""
						let name2 = entry2.app.name ?? ""
						result = name1.localizedCaseInsensitiveCompare(name2) == .orderedAscending
					case .date:
						let date1 = entry1.app.currentDate?.date ?? .distantPast
						let date2 = entry2.app.currentDate?.date ?? .distantPast
						result = date1 < date2
					case .size:
						let size1 = entry1.app.size ?? 0
						let size2 = entry2.app.size ?? 0
						result = size1 < size2
					}
					return sortAscending ? result : !result
				}
			}.value

			if Task.isCancelled {
                await MainActor.run { _isSearching = false }
                return
            }

			await MainActor.run {
                if #available(iOS 17.0, *) {
                    withAnimation(.snappy) {
                        _filteredApps = sortedApps
                        _isSearching = false
                    }
                } else {
                    if useSpringAnimations {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            _filteredApps = sortedApps
                            _isSearching = false
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            _filteredApps = sortedApps
                            _isSearching = false
                        }
                    }
                }
			}
		}
	}


	// MARK: - Load All Sources
	private func _loadAllSources() {
		// If we don't have apps yet, show the loading screen
		if _allApps.isEmpty {
			_isLoading = true
			_loadedSourcesCount = 0
			_currentFact = DidYouKnowFacts.random()
		}
		
		Task {
			await updateSourcesInBackground()
			
			await MainActor.run {
				withAnimation(.easeInOut(duration: 0.3)) {
					_isLoading = false
				}
			}
		}
	}
	
	private func updateSourcesInBackground() async {
		// Ensure viewModel finishes loading if needed
		if !viewModel.isFinished {
			var timeoutCount = 0
			let maxTimeout = 150 // 15 seconds total
			while !viewModel.isFinished && timeoutCount < maxTimeout {
				try? await Task.sleep(nanoseconds: 100_000_000)
				timeoutCount += 1

				// Update progress based on viewModel progress
				await MainActor.run {
					_loadedSourcesCount = Int(Double(object.count) * viewModel.fetchProgress)
				}
			}
		}
		
		// Get final loaded sources from viewModel
		let finalSources = object.compactMap { viewModel.sources[$0] }
		
		// Flatten apps in background
		let flattenedApps = finalSources.flatMap { source in
			source.apps.map { (source: source, app: $0) }
		}

		await MainActor.run {
			_sources = finalSources
			_allApps = flattenedApps
			_filterApps()
			_loadedSourcesCount = object.count
		}
	}
	
	struct SourceAppRoute: Identifiable, Hashable {
		let source: ASRepository
		let app: ASRepository.App
		let id: String = UUID().uuidString
	}
}

// MARK: - All Apps Row View
struct AllAppsRowView: View {
	let source: ASRepository
	let app: ASRepository.App
	let onTap: () -> Void
	let isLast: Bool
	
	@AppStorage("Feather.allApps.showVersion") private var showVersion: Bool = true
	@AppStorage("Feather.allApps.showSize") private var showSize: Bool = true
	@AppStorage("Feather.allApps.showDeveloper") private var showDeveloper: Bool = true
	@AppStorage("Feather.allApps.showStatus") private var showStatus: Bool = true
	@AppStorage("Feather.allApps.showSourceIcon") private var showSourceIcon: Bool = true
	@AppStorage("Feather.allApps.iconSize") private var iconSize: Double = 54.0
	@AppStorage("Feather.allApps.iconCornerRadius") private var iconCornerRadius: Double = 12.0
	@AppStorage("Feather.allApps.iconPadding") private var iconPadding: Double = 0
	@AppStorage("Feather.allApps.iconShadowRadius") private var iconShadowRadius: Double = 0.0
    @AppStorage("Feather.allApps.iconBorderWidth") private var iconBorderWidth: Double = 0.0
    @AppStorage("Feather.allApps.iconBorderColor") private var iconBorderColor: String = "#0000001A"

	@AppStorage("Feather.allApps.rowStyle") private var rowStyle: AllAppsView.AllAppsRowStyle = .minimal
	@AppStorage("Feather.allApps.rowHorizontalPadding") private var rowHorizontalPadding: Double = 20.0
    @AppStorage("Feather.allApps.rowVerticalPadding") private var rowVerticalPadding: Double = 10.0
	@AppStorage("Feather.allApps.infoSpacing") private var infoSpacing: Double = 14.0
	@AppStorage("Feather.allApps.showDividers") private var showDividers: Bool = true
	@AppStorage("Feather.allApps.rowDividerOpacity") private var rowDividerOpacity: Double = 0.5
	@AppStorage("Feather.allApps.useSpringAnimations") private var useSpringAnimations: Bool = true

	@AppStorage("Feather.allApps.nameFontSize") private var nameFontSize: Double = 17.0
	@AppStorage("Feather.allApps.subtitleFontSize") private var subtitleFontSize: Double = 13.0
	@AppStorage("Feather.allApps.metadataFontSize") private var metadataFontSize: Double = 12.0
	@AppStorage("Feather.allApps.useBoldTitles") private var useBoldTitles: Bool = true

    // Advanced
    @AppStorage("Feather.allApps.useGrid") private var useGrid: Bool = false
    @AppStorage("Feather.allApps.titleFontSize") private var titleFontSize: Double = 17.0
    @AppStorage("Feather.allApps.boldTitles") private var boldTitles: Bool = true
    @AppStorage("Feather.allApps.useGlassEffects") private var useGlassEffects: Bool = true
    @AppStorage("Feather.allApps.showDescription") private var showDescription: Bool = false
    @AppStorage("Feather.allApps.descriptionLimit") private var descriptionLimit: Int = 2
    @AppStorage("Feather.allApps.cardBackgroundOpacity") private var cardBackgroundOpacity: Double = 1.0

	@ObservedObject private var downloadManager = DownloadManager.shared
	@State private var downloadProgress: Double = 0
	@State private var cancellable: AnyCancellable?
	
	private var currentDownload: Download? {
		downloadManager.getDownload(by: app.currentUniqueId)
	}
	
	private var isDownloading: Bool {
		currentDownload != nil
	}
	
	private var fileSize: String {
		if let size = app.size {
			return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
		}
		return ""
	}
	
	private var statusText: String {
		// Check if app is injected or modified based on version info or other metadata
		if app.beta ?? false {
			return "Beta"
		} else if let _ = app.developer {
			return "Official"
		}
		return ""
	}
	
	var body: some View {
		VStack(spacing: 0) {
            Button(action: onTap) {
                if useGrid {
                    gridView
                } else {
                    rowView
                }
            }
			.buttonStyle(AllAppsScaleButtonStyle())

			if !useGrid && showDividers && rowStyle == .minimal && !isLast {
				Divider()
					.padding(.leading, iconSize + iconPadding + infoSpacing + 4)
					.opacity(rowDividerOpacity)
			}
		}
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.description) { _ in
			setupObserver()
		}
		.animation(useSpringAnimations ? .spring(response: 0.4, dampingFraction: 0.8) : .easeInOut(duration: 0.25), value: isDownloading)
	}

    @ViewBuilder
    private var rowView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                // App Icon
                appIcon
                    .frame(width: iconSize, height: iconSize)
                    .overlay(alignment: .bottomLeading) {
                        if showSourceIcon, let iconURL = source.currentIconURL {
                            AsyncImage(url: iconURL) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: iconSize * 0.35, height: iconSize * 0.35)
                                        .clipShape(Circle())
                                        .background(Circle().fill(Color(uiColor: .secondarySystemBackground)))
                                        .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 1.5))
                                        .offset(x: iconSize * 0.75, y: iconSize * 0.05)
                                }
                            }
                        }
                    }
                    .padding(.leading, iconPadding)

                // Center column with app info
                VStack(alignment: .leading, spacing: 3) {
                    // App name
                    Text(app.currentName)
                        .font(.system(size: nameFontSize, weight: useBoldTitles ? .bold : .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    // Subtitle (status/developer)
                    if showStatus && !statusText.isEmpty {
                        Text(statusText)
                            .font(.system(size: subtitleFontSize, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .lineLimit(1)
                    } else if showDeveloper, let developer = app.developer {
                        Text(developer)
                            .font(.system(size: subtitleFontSize))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Version and file size
                    HStack(spacing: 6) {
                        if showVersion, let version = app.currentVersion {
                            Text("v\(version)")
                                .font(.system(size: metadataFontSize))
                                .foregroundStyle(.secondary)
                        }

                        if showSize, !fileSize.isEmpty {
                            if showVersion && app.currentVersion != nil {
                                Text("•")
                                    .font(.system(size: metadataFontSize))
                                    .foregroundStyle(.secondary)
                            }

                            Text(fileSize)
                                .font(.system(size: metadataFontSize))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if showDescription, let description = app.localizedDescription {
                        Text(description)
                            .font(.system(size: metadataFontSize))
                            .foregroundStyle(.secondary)
                            .lineLimit(descriptionLimit)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                // Action button
                actionButton
                    .frame(width: 34, height: 34)
            }

            // Progress bar when downloading
            if isDownloading {
                downloadProgressBar
            }
        }
        .padding(.vertical, rowStyle == .minimal ? rowVerticalPadding : rowVerticalPadding + 4)
        .padding(.horizontal, rowStyle == .minimal ? 4 : 14)
        .background(
            Group {
                if rowStyle != .minimal {
                    if useGlassEffects {
                        AnyShapeStyle(.ultraThinMaterial)
                    } else {
                        AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground))
                    }
                } else {
                    AnyShapeStyle(Color.clear)
                }
            }
            .opacity(cardBackgroundOpacity)
        )
        .cornerRadius(rowStyle == .card || rowStyle == .flat ? 16 : 0)
        .shadow(color: rowStyle == .card ? Color.black.opacity(0.02) : Color.clear, radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(rowStyle == .flat ? 0.1 : 0), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var gridView: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                appIcon
                    .frame(width: iconSize * 1.2, height: iconSize * 1.2)

                if showSourceIcon, let iconURL = source.currentIconURL {
                    AsyncImage(url: iconURL) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize * 0.4, height: iconSize * 0.4)
                                .clipShape(Circle())
                                .background(Circle().fill(Color(uiColor: .secondarySystemBackground)))
                                .overlay(Circle().stroke(Color(uiColor: .systemBackground), lineWidth: 1.5))
                                .offset(x: 4, y: 4)
                        }
                    }
                }

                actionButton
                    .frame(width: 28, height: 28)
                    .offset(x: 8, y: -8)
            }

            VStack(spacing: 2) {
                Text(app.currentName)
                    .font(.system(size: nameFontSize - 2, weight: useBoldTitles ? .bold : .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)

                if showVersion, let version = app.currentVersion {
                    Text("v\(version)")
                        .font(.system(size: subtitleFontSize - 2))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            if isDownloading {
                downloadProgressBar
            }
        }
        .padding(12)
        .background(
            Group {
                if useGlassEffects {
                    AnyShapeStyle(.ultraThinMaterial)
                } else {
                    AnyShapeStyle(Color(uiColor: .secondarySystemGroupedBackground))
                }
            }
            .opacity(cardBackgroundOpacity)
        )
        .cornerRadius(iconCornerRadius + 4)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var downloadProgressBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)

                    // Progress
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * downloadProgress, height: 4)
                }
            }
            .frame(height: 4)

            // Progress percentage
            HStack {
                Spacer()
                Text("\(Int(downloadProgress * 100))%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.9)))
    }
	
	@ViewBuilder
	private var appIcon: some View {
		if let iconURL = app.iconURL {
			AsyncImage(url: iconURL) { phase in
				switch phase {
				case .empty:
					iconPlaceholder
				case .success(let image):
					image
						.resizable()
						.aspectRatio(contentMode: .fill)
						.clipShape(RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                                .stroke(Color(hex: iconBorderColor), lineWidth: iconBorderWidth)
                        )
				case .failure:
					iconPlaceholder
				@unknown default:
					iconPlaceholder
				}
			}
		} else {
			iconPlaceholder
		}
	}
	
	private var iconPlaceholder: some View {
		RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
			.fill(Color.secondary.opacity(0.2))
			.overlay(
				Image(systemName: "app.fill")
					.font(.system(size: iconSize * 0.4))
					.foregroundStyle(.secondary)
			)
            .overlay(
                RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                    .stroke(Color(hex: iconBorderColor), lineWidth: iconBorderWidth)
            )
	}
	
	@ViewBuilder
	private var actionButton: some View {
		if isDownloading {
			// Download in progress - show progress circle with cancel
			Button {
				if let download = currentDownload {
					downloadManager.cancelDownload(download)
				}
			} label: {
				ZStack {
					// Background circle
					Circle()
						.stroke(Color.primary.opacity(0.15), lineWidth: 2.5)
					
					// Progress circle
					Circle()
						.trim(from: 0, to: downloadProgress)
						.stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
						.rotationEffect(.degrees(-90))
						.animation(.linear(duration: 0.2), value: downloadProgress)
					
					// Cancel icon
					Image(systemName: "xmark")
						.font(.system(size: 12, weight: .semibold))
						.foregroundStyle(Color.accentColor)
				}
			}
		} else {
			// Idle state - show download icon
			Button {
				if let url = app.currentDownloadUrl {
					_ = downloadManager.startDownload(from: url, id: app.currentUniqueId, fromSourcesView: true)
				}
			} label: {
				ZStack {
					Circle()
						.fill(Color.accentColor.opacity(0.15))
					
					Image(systemName: "arrow.down.circle.fill")
						.font(.system(size: 28))
						.foregroundStyle(Color.accentColor)
				}
			}
		}
	}
	
	private func setupObserver() {
		cancellable?.cancel()
		guard let download = currentDownload else {
			downloadProgress = 0
			return
		}
		downloadProgress = download.overallProgress
		
		let publisher = Publishers.CombineLatest(
			download.$progress,
			download.$unpackageProgress
		)
		
		cancellable = publisher.sink { _, _ in
			downloadProgress = download.overallProgress
		}
	}
}

// MARK: - Scale Button Style
struct AllAppsScaleButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.97 : 1.0)
			.animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
	}
}

// MARK: - AllAppsWrapperView
/// Wrapper view that switches between AllAppsView and SourceAppsView based on settings
struct AllAppsWrapperView: View {
	@AppStorage("Feather.allApps.useNewAllAppsView") private var useNewAllAppsView: Bool = true
	
	var object: [AltSource]
	@ObservedObject var viewModel: SourcesViewModel
	
	var body: some View {
		Group {
			if !useNewAllAppsView {
				SourceAppsView(object: object, viewModel: viewModel)
			} else {
				AllAppsView(object: object, viewModel: viewModel)
			}
		}
	}
}
