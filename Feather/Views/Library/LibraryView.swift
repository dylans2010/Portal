import SwiftUI
import CoreData
import NimbleViews
import Combine

// MARK: - Modern Library View with Blue Gradient Background
struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("Feather.useGradients") private var _useGradients: Bool = true
    
    @StateObject var downloadManager = DownloadManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _selectedInstallModifyAppPresenting: AnyApp?
    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false
    @State private var _showImportAnimation = false
    @State private var _importStatus: ImportStatus = .loading
    @State private var _importedAppName: String = ""
    @State private var _importErrorMessage: String = ""
    @State private var _currentDownloadId: String = ""
    @State private var _downloadProgress: Double = 0.0
    
    enum ImportStatus {
        case loading
        case downloading
        case processing
        case success
        case failed
    }
    
    @State private var _searchText = ""
    @State private var _filterMode: FilterMode = .all
    
    enum FilterMode: String, CaseIterable {
        case all = "All"
        case unsigned = "Unsigned"
        case signed = "Signed"
    }
    
    @Namespace private var _namespace
    
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .default
    ) private var _signedApps: FetchedResults<Signed>
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
        animation: .default
    ) private var _importedApps: FetchedResults<Imported>
    
    private var filteredSignedApps: [Signed] {
        _signedApps.filter { app in
            _searchText.isEmpty || (app.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var filteredImportedApps: [Imported] {
        _importedApps.filter { app in
            _searchText.isEmpty || (app.name?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var displayedApps: [AppInfoPresentable] {
        switch _filterMode {
        case .all:
            return Array(filteredSignedApps) + Array(filteredImportedApps)
        case .unsigned:
            return Array(filteredImportedApps)
        case .signed:
            return Array(filteredSignedApps)
        }
    }
    
    private var totalAppCount: Int {
        _signedApps.count + _importedApps.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Simple background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Custom navigation area
                        customNavigationBar
                        
                        VStack(spacing: 20) {
                            // Filter chips
                            filterChips
                            
                            // Apps content
                            appsContent
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
					.presentationDetents([.height(200)])
					.presentationDragIndicator(.visible)
					.compatPresentationRadius(21)
			}
			.fullScreenCover(item: $_selectedSigningAppPresenting) { app in
				ModernSigningView(app: app.base)
			}
			.sheet(item: $_selectedInstallModifyAppPresenting) { app in
				InstallModifyDialogView(app: app.base)
					.presentationDetents([.medium, .large])
					.presentationDragIndicator(.visible)
			}
			.sheet(isPresented: $_isImportingPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.ipa, .tipa],
					allowsMultipleSelection: true,
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						for url in urls {
							let id = "FeatherManualDownload_\(UUID().uuidString)"
							let dl = downloadManager.startArchive(from: url, id: id)
							
							// Show loading animation
							_importedAppName = url.deletingPathExtension().lastPathComponent
							_currentDownloadId = id
							_importStatus = .processing
							_importErrorMessage = ""
							withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
								_showImportAnimation = true
							}
							
							// Start the import - completion will be handled via notifications
							do {
								try downloadManager.handlePachageFile(url: url, dl: dl)
							} catch {
								// This catch is for synchronous errors only (rare)
								_importErrorMessage = error.localizedDescription
								withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
									_importStatus = .failed
								}
								DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
									withAnimation(.easeOut(duration: 0.3)) {
										_showImportAnimation = false
									}
								}
							}
						}
					}
				)
				.ignoresSafeArea()
			}
			.sheet(isPresented: $_isDownloadingPresenting) {
				ModernImportURLView { url in
					// Start URL download with proper tracking
					let downloadId = "FeatherManualDownload_\(UUID().uuidString)"
					_currentDownloadId = downloadId
					_importedAppName = url.deletingPathExtension().lastPathComponent
					_downloadProgress = 0.0
					_importStatus = .downloading
					_importErrorMessage = ""
					
					withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
						_showImportAnimation = true
					}
					
					// Start the download - progress and completion handled via notifications
					_ = downloadManager.startDownload(from: url, id: downloadId)
				}
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
			}
			// Listen for import success notifications
			.onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidSucceedNotification)) { notification in
				guard let userInfo = notification.userInfo,
					  let downloadId = userInfo["downloadId"] as? String,
					  downloadId == _currentDownloadId else { return }
				
				withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
					_importStatus = .success
				}
				
				// Auto-dismiss after showing success
				DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
					withAnimation(.easeOut(duration: 0.3)) {
						_showImportAnimation = false
						_currentDownloadId = ""
					}
				}
			}
			// Listen for import failure notifications
			.onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidFailNotification)) { notification in
				guard let userInfo = notification.userInfo,
					  let downloadId = userInfo["downloadId"] as? String,
					  downloadId == _currentDownloadId else { return }
				
				_importErrorMessage = userInfo["error"] as? String ?? "Unknown error"
				withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
					_importStatus = .failed
				}
				
				// Auto-dismiss after showing error
				DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
					withAnimation(.easeOut(duration: 0.3)) {
						_showImportAnimation = false
						_currentDownloadId = ""
					}
				}
			}
			// Listen for download failure notifications
			.onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidFailNotification)) { notification in
				guard let userInfo = notification.userInfo,
					  let downloadId = userInfo["downloadId"] as? String,
					  downloadId == _currentDownloadId else { return }
				
				_importErrorMessage = userInfo["error"] as? String ?? "Download failed"
				withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
					_importStatus = .failed
				}
				
				// Auto-dismiss after showing error
				DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
					withAnimation(.easeOut(duration: 0.3)) {
						_showImportAnimation = false
						_currentDownloadId = ""
					}
				}
			}
			// Listen for download progress notifications
			.onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidProgressNotification)) { notification in
				guard let userInfo = notification.userInfo,
					  let downloadId = userInfo["downloadId"] as? String,
					  downloadId == _currentDownloadId,
					  let progress = userInfo["progress"] as? Double else { return }
				
				_downloadProgress = progress
				
				// Switch to processing status when download is complete (progress >= 0.99)
				if progress >= 0.99 && _importStatus == .downloading {
					withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
						_importStatus = .processing
					}
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
				if let latest = _signedApps.first {
					_selectedInstallAppPresenting = AnyApp(base: latest)
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.openSigningView"))) { notification in
				if let app = notification.object as? AppInfoPresentable {
					_selectedSigningAppPresenting = AnyApp(base: app)
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.showInstallModifyPopup"))) { notification in
				// When app is downloaded from Sources view, show Install/Modify dialog
				if let _ = notification.object as? URL {
					// Get the latest imported app (just downloaded)
					if let latestApp = Storage.shared.getLatestImportedApp() {
						_selectedInstallModifyAppPresenting = AnyApp(base: latestApp)
					}
				}
			}
			.overlay {
				if _showImportAnimation {
					ZStack {
						Color.black.opacity(0.5)
							.ignoresSafeArea()
							.transition(.opacity)
						
						VStack(spacing: 20) {
							ZStack {
								// Background circle with status color
								Circle()
									.fill(
										_importStatus == .success 
											? Color.green
											: _importStatus == .failed
											? Color.red
											: Color.blue
									)
									.frame(width: 100, height: 100)
									.scaleEffect(_showImportAnimation ? 1.0 : 0.5)
									.animation(.spring(response: 0.6, dampingFraction: 0.6), value: _showImportAnimation)
								
								// Progress ring for downloading state
								if _importStatus == .downloading {
									Circle()
										.stroke(Color.white.opacity(0.3), lineWidth: 6)
										.frame(width: 90, height: 90)
									
									Circle()
										.trim(from: 0, to: _downloadProgress)
										.stroke(Color.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
										.frame(width: 90, height: 90)
										.rotationEffect(.degrees(-90))
										.animation(.easeInOut(duration: 0.2), value: _downloadProgress)
								}
								
								Group {
									switch _importStatus {
									case .loading, .processing:
										ProgressView()
											.progressViewStyle(CircularProgressViewStyle(tint: .white))
											.scaleEffect(1.5)
									case .downloading:
										VStack(spacing: 2) {
											Image(systemName: "arrow.down")
												.font(.system(size: 28, weight: .bold))
												.foregroundStyle(.white)
											Text("\(Int(_downloadProgress * 100))%")
												.font(.system(size: 14, weight: .bold))
												.foregroundStyle(.white)
										}
									case .success:
										Image(systemName: "checkmark")
											.font(.system(size: 50, weight: .bold))
											.foregroundStyle(.white)
									case .failed:
										Image(systemName: "xmark")
											.font(.system(size: 50, weight: .bold))
											.foregroundStyle(.white)
									}
								}
								.scaleEffect(_showImportAnimation && (_importStatus == .success || _importStatus == .failed) ? 1.0 : (_importStatus == .downloading ? 1.0 : 0.8))
								.animation(.spring(response: 0.6, dampingFraction: 0.6).delay((_importStatus == .success || _importStatus == .failed) ? 0.1 : 0), value: _importStatus)
							}
							
							VStack(spacing: 8) {
								Text(_statusTitle)
									.font(.title2)
									.fontWeight(.bold)
									.foregroundStyle(.white)
								
								Text(_importedAppName)
									.font(.subheadline)
									.foregroundStyle(.white.opacity(0.8))
									.lineLimit(2)
									.multilineTextAlignment(.center)
									.padding(.horizontal, 40)
								
								// Show error message if failed
								if _importStatus == .failed && !_importErrorMessage.isEmpty {
									Text(_importErrorMessage)
										.font(.caption)
										.foregroundStyle(.white.opacity(0.6))
										.lineLimit(3)
										.multilineTextAlignment(.center)
										.padding(.horizontal, 20)
										.padding(.top, 4)
								}
							}
							.opacity(_showImportAnimation ? 1.0 : 0.0)
							.offset(y: _showImportAnimation ? 0 : 20)
							.animation(.easeOut(duration: 0.4).delay(0.2), value: _showImportAnimation)
						}
						.padding(40)
						.background(
							RoundedRectangle(cornerRadius: 30, style: .continuous)
								.fill(Color(uiColor: .systemBackground))
								.shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
						)
						.scaleEffect(_showImportAnimation ? 1.0 : 0.8)
						.animation(.spring(response: 0.6, dampingFraction: 0.7), value: _showImportAnimation)
					}
				}
			}
		}
	}
	
	private var _statusTitle: String {
		switch _importStatus {
		case .loading:
			return String.localized("Loading")
		case .downloading:
			return String.localized("Downloading")
		case .processing:
			return String.localized("Processing")
		case .success:
			return String.localized("Import Successful!")
		case .failed:
			return String.localized("Import Failed")
		}
	}
}

// MARK: - Extension: View Components
extension LibraryView {
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack(spacing: 16) {
            Spacer()
            
            Text("Library")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Menu {
                _importActions()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.green)
                }
            }
            .padding(.trailing, 20)
        }
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Filter Chips (Modern Glass Design)
    private var filterChips: some View {
        HStack(spacing: 6) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                ModernFilterChip(
                    title: mode.rawValue,
                    isSelected: _filterMode == mode,
                    namespace: _namespace
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        _filterMode = mode
                    }
                    HapticsManager.shared.softImpact()
                }
            }
            
            Spacer()
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Apps Content
    @ViewBuilder
    private var appsContent: some View {
        if displayedApps.isEmpty {
            emptyStateView
        } else {
            LazyVStack(spacing: 14) {
                ForEach(displayedApps, id: \.uuid) { app in
                    PremiumAppCard(
                        app: app,
                        selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                        selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                        selectedInstallAppPresenting: $_selectedInstallAppPresenting
                    )
                    .id(app.uuid)
                }
            }
        }
    }
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "questionmark.app.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(Color.accentColor)
            }
            
            VStack(spacing: 12) {
                Text("No Apps")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Get started by importing and installing your first IPA file.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Menu {
                _importActions()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Import")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(Color.accentColor)
                )
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            
            Spacer(minLength: 60)
        }
    }
    
    @ViewBuilder
    private func _importActions() -> some View {
        Button(String.localized("Import From Files"), systemImage: "folder") {
            _isImportingPresenting = true
        }
        Button(String.localized("Import From URL"), systemImage: "globe") {
            _isDownloadingPresenting = true
        }
    }
    
    private func exportApp(_ app: AppInfoPresentable) {
        guard app.isSigned, let archiveURL = app.archiveURL else { return }
        UIActivityViewController.show(activityItems: [archiveURL])
        HapticsManager.shared.success()
    }
}

// MARK: - Premium App Card (Glassy Dark Gradient)
struct PremiumAppCard: View {
    let app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    
    @State private var dominantColor: Color = .cyan
    
    var body: some View {
        HStack(spacing: 16) {
            // Elevated app icon container
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(dominantColor.opacity(0.12))
                    .frame(width: 60, height: 60)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                FRAppIconView(app: app, size: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(app.name ?? String.localized("Unknown"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let identifier = app.identifier {
                    Text(identifier)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    if let version = app.version {
                        Text("v\(version)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(dominantColor)
                    }
                    
                    if app.isSigned {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                            Text("Signed")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            // Action button
            Button {
                if app.isSigned {
                    selectedInstallAppPresenting = AnyApp(base: app)
                } else {
                    selectedSigningAppPresenting = AnyApp(base: app)
                }
            } label: {
                Text(app.isSigned ? "Install" : "Sign")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(app.isSigned ? Color.green : Color.accentColor)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            selectedInfoAppPresenting = AnyApp(base: app)
        }
        .contextMenu {
            Button {
                selectedInfoAppPresenting = AnyApp(base: app)
            } label: {
                Label(String.localized("Details"), systemImage: "info.circle.fill")
            }
            
            if app.isSigned {
                Button {
                    selectedInstallAppPresenting = AnyApp(base: app)
                } label: {
                    Label(String.localized("Install"), systemImage: "arrow.down.circle.fill")
                }
                Button {
                    selectedSigningAppPresenting = AnyApp(base: app)
                } label: {
                    Label(String.localized("ReSign"), systemImage: "signature")
                }
            } else {
                Button {
                    selectedSigningAppPresenting = AnyApp(base: app)
                } label: {
                    Label(String.localized("Sign"), systemImage: "signature")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                Storage.shared.deleteApp(for: app)
            } label: {
                Label(String.localized("Delete"), systemImage: "trash.fill")
            }
        }
    }
}

// MARK: - Legacy Support Structures (kept for compatibility)
struct LibraryAppRow: View {
    let app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    
    var body: some View {
        PremiumAppCard(
            app: app,
            selectedInfoAppPresenting: $selectedInfoAppPresenting,
            selectedSigningAppPresenting: $selectedSigningAppPresenting,
            selectedInstallAppPresenting: $selectedInstallAppPresenting
        )
    }
}

// MARK: - Modern Filter Chip
struct ModernFilterChip: View {
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .primary.opacity(0.7))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
                            .matchedGeometryEffect(id: "filterBackground", in: namespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(FilterChipButtonStyle())
    }
}

// MARK: - Filter Chip Button Style
struct FilterChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

