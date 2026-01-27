import SwiftUI
import AltSourceKit
import NimbleViews

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

// MARK: - All Apps View (iOS 26 Style with Bottom Search)
struct AllAppsView: View {
    @AppStorage("Feather.useGradients") private var _useGradients: Bool = true
    
    @State private var _searchText = ""
    @State private var _selectedRoute: SourceAppRoute?
    @FocusState private var _searchFieldFocused: Bool
    
    var object: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    @State private var _sources: [ASRepository]?
    @State private var _isLoading = true
    @State private var _loadedSourcesCount = 0
    @State private var _currentFact = DidYouKnowFacts.random()
    
    // Computed property for all apps with their sources
    private var _allAppsWithSource: [(source: ASRepository, app: ASRepository.App)] {
        guard let sources = _sources else { return [] }
        return sources.flatMap { source in
            source.apps.map { (source: source, app: $0) }
        }
    }
    
    // Filtered apps based on search
    private var _filteredApps: [(source: ASRepository, app: ASRepository.App)] {
        if _searchText.isEmpty {
            return _allAppsWithSource
        }
        
        return _allAppsWithSource.filter { entry in
            (entry.app.name?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
            (entry.app.description?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
            (entry.app.subtitle?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
            (entry.app.localizedDescription?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var _totalAppCount: Int {
        _allAppsWithSource.count
    }
    
    // MARK: Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if _isLoading {
                    // Modern Loading Screen
                    loadingScreen
                } else if let _sources, !_sources.isEmpty {
                    // Main content
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Header with app count
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(_totalAppCount)")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text("Apps Available")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                            
                            // Results count when searching
                            if !_searchText.isEmpty {
                                HStack {
                                    Text("\(_filteredApps.count) result\(_filteredApps.count == 1 ? "" : "s")")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                            }
                            
                            // Apps list
                            if _filteredApps.isEmpty && !_searchText.isEmpty {
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
                                        Text("No Results")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(.primary)
                                        Text("Try a different search term")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 80)
                            } else {
                                ForEach(Array(_filteredApps.enumerated()), id: \.element.app.currentUniqueId) { index, entry in
                                    AllAppsRowView(
                                        source: entry.source,
                                        app: entry.app,
                                        onTap: {
                                            _selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
                                        }
                                    )
                                    
                                    if index < _filteredApps.count - 1 {
                                        Divider()
                                            .padding(.leading, 76)
                                    }
                                }
                            }
                            
                            // Bottom padding for search bar
                            Color.clear.frame(height: 100)
                        }
                    }
                } else {
                    // Empty state
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
                        Text("Add sources to discover apps")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                }
                
                // iOS 26 Style Bottom Search Bar
                if !_isLoading {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .frame(height: 1)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                TextField("Search \(_totalAppCount) Apps", text: $_searchText)
                                    .font(.system(size: 16))
                                    .focused($_searchFieldFocused)
                                
                                if !_searchText.isEmpty {
                                    Button {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            _searchText = ""
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            
                            if _searchFieldFocused {
                                Button("Cancel") {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        _searchText = ""
                                        _searchFieldFocused = false
                                    }
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Color.accentColor)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 8)
                        .background(.ultraThinMaterial)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: _searchFieldFocused)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            _loadAllSources()
        }
        .onChange(of: object) { _ in
            _loadAllSources()
        }
        .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
	
	// MARK: - Loading Screen
	@ViewBuilder
	private var loadingScreen: some View {
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
					.font(.title2)
					.fontWeight(.bold)
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
					.transition(.opacity.combined(with: .scale))
			}
			.padding(.bottom, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	// MARK: - Load All Sources
	private func _loadAllSources() {
		_isLoading = true
		_loadedSourcesCount = 0
		_currentFact = DidYouKnowFacts.random()
		
		Task {
			_ = object.count
			
			// Load all sources one by one with progress updates
			for (index, _) in object.enumerated() {
				// Update progress
				await MainActor.run {
					_loadedSourcesCount = index + 1
				}
				
				// Small delay for smooth animation
				try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
			}
			
			// Ensure viewModel finishes loading if needed
			if !viewModel.isFinished {
				// Wait for viewModel to finish with timeout
				var timeoutCount = 0
				let maxTimeout = 100 // 10 seconds total (100 * 0.1s)
				while !viewModel.isFinished && timeoutCount < maxTimeout {
					try? await Task.sleep(nanoseconds: 100_000_000)
					timeoutCount += 1
				}
			}
			
			// Get final loaded sources from viewModel
			let finalSources = object.compactMap { viewModel.sources[$0] }
			
			await MainActor.run {
				_sources = finalSources
			}
			
			// Add a small delay before hiding loading screen for better UX
			try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
			
			await MainActor.run {
				withAnimation(.easeInOut(duration: 0.3)) {
					_isLoading = false
				}
			}
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
		Button(action: onTap) {
			VStack(spacing: 8) {
				HStack(spacing: 12) {
					// App Icon
					appIcon
						.frame(width: 50, height: 50)
					
					// Center column with app info
					VStack(alignment: .leading, spacing: 4) {
						// App name
						Text(app.currentName)
							.font(.system(size: 16, weight: .semibold))
							.foregroundStyle(.primary)
							.lineLimit(1)
						
						// Subtitle (status)
						if !statusText.isEmpty {
							Text(statusText)
								.font(.system(size: 13))
								.foregroundStyle(.secondary)
								.lineLimit(1)
						}
						
						// Version and file size
						HStack(spacing: 6) {
							if let version = app.currentVersion {
								Text("v\(version)")
									.font(.system(size: 12))
									.foregroundStyle(.secondary)
							}
							
							if !fileSize.isEmpty {
								Text("•")
									.font(.system(size: 12))
									.foregroundStyle(.secondary)
								
								Text(fileSize)
									.font(.system(size: 12))
									.foregroundStyle(.secondary)
							}
						}
					}
					
					Spacer()
					
					// Action button
					actionButton
						.frame(width: 40, height: 40)
				}
				
				// Progress bar when downloading
				if isDownloading {
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
					.transition(.opacity.combined(with: .scale(scale: 0.9)))
				}
			}
			.padding(.vertical, 8)
		}
		.buttonStyle(.plain)
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.description) { _ in
			setupObserver()
		}
		.animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDownloading)
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
						.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
		RoundedRectangle(cornerRadius: 12, style: .continuous)
			.fill(Color.secondary.opacity(0.2))
			.overlay(
				Image(systemName: "app.fill")
					.font(.system(size: 22))
					.foregroundStyle(.secondary)
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

// MARK: - Search Sheet View
struct SearchSheetView: View {
	@Binding var searchText: String
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationView {
			VStack(spacing: 16) {
				// Search bar
				HStack(spacing: 12) {
					Image(systemName: "magnifyingglass")
						.foregroundStyle(.secondary)
						.font(.system(size: 16))
					
					TextField("Search Apps", text: $searchText)
						.foregroundStyle(.primary)
						.autocorrectionDisabled()
						.textInputAutocapitalization(.never)
					
					if !searchText.isEmpty {
						Button {
							searchText = ""
						} label: {
							Image(systemName: "xmark.circle.fill")
								.foregroundStyle(.secondary)
						}
					}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.background(
					Capsule()
						.fill(Color.secondary.opacity(0.15))
				)
				.padding(.horizontal, 20)
				.padding(.top, 10)
				
				Spacer()
			}
			.navigationTitle("Search")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") {
						dismiss()
					}
				}
			}
		}
	}
}

// MARK: - Import Combine for Publishers
import Combine

// MARK: - AllAppsWrapperView
/// Wrapper view that switches between AllAppsView and SourceAppsView based on settings and app count
struct AllAppsWrapperView: View {
	@AppStorage("Feather.useNewAllAppsView") private var useNewAllAppsView: Bool = true
	
	var object: [AltSource]
	@ObservedObject var viewModel: SourcesViewModel
	
	@State private var totalAppCount: Int = 0
	@State private var shouldUseFallback: Bool = false
	@State private var hasShownToast: Bool = false
	
	var body: some View {
		Group {
			if shouldUseFallback || !useNewAllAppsView || totalAppCount > 250 {
				SourceAppsView(object: object, viewModel: viewModel)
			} else {
				AllAppsView(object: object, viewModel: viewModel)
					.onAppear {
						calculateTotalApps()
						// Monitor if AllAppsView fails to load properly
						checkViewLoadingHealth()
					}
			}
		}
		.onAppear {
			calculateTotalApps()
			// Automatically switch to old view if more than 250 apps
			if totalAppCount > 250 && !hasShownToast {
				shouldUseFallback = true
			}
		}
	}
	
	private func calculateTotalApps() {
		totalAppCount = object.reduce(0) { count, source in
			count + (viewModel.sources[source]?.apps.count ?? 0)
		}
	}
	
	private func checkViewLoadingHealth() {
		// Set a timeout to detect if the view is stuck loading
		Task {
			try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
			
			await MainActor.run {
				// If still loading after 30 seconds, switch to fallback
				if !viewModel.isFinished && !shouldUseFallback {
					shouldUseFallback = true
					showFallbackToast()
				}
			}
		}
	}
	
	private func showFallbackToast() {
		guard !hasShownToast else { return }
		hasShownToast = true
		
		UIAlertController.showAlertWithOk(
			title: .localized("Loading Issue"),
			message: .localized("New Apps view couldn't load, using old view as fallback")
		)
	}
}
