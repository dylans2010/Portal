import SwiftUI
import CoreData
import NimbleViews
import Combine
import IDeviceSwift

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
    
    // Batch selection states
    @State private var _isSelectionMode = false
    @State private var _selectedApps: Set<String> = []
    @State private var _showBatchSigningSheet = false
    @State private var _showBatchDeleteConfirmation = false
    
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
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .unsigned: return "doc.badge.clock"
            case .signed: return "checkmark.seal"
            }
        }
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
            .fullScreenCover(isPresented: $_showBatchSigningSheet) {
                BatchSigningView(
                    apps: getSelectedUnsignedApps(),
                    onComplete: {
                        _showBatchSigningSheet = false
                        _selectedApps.removeAll()
                        _isSelectionMode = false
                    }
                )
            }
            .alert("Delete Selected Apps", isPresented: $_showBatchDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedApps()
                }
            } message: {
                Text("Are you sure you want to delete \(_selectedApps.count) selected app(s)? This action cannot be undone.")
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
    
    // MARK: - Filter Chips (Modern Compact Design)
    private var filterChips: some View {
        HStack(spacing: 8) {
            // Modern segmented filter
            HStack(spacing: 2) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    CompactFilterChip(
                        title: mode.rawValue,
                        icon: mode.icon,
                        isSelected: _filterMode == mode,
                        namespace: _namespace
                    ) {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            _filterMode = mode
                        }
                        HapticsManager.shared.softImpact()
                    }
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(UIColor.tertiarySystemBackground))
            )
            
            Spacer()
            
            // Selection mode toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    _isSelectionMode.toggle()
                    if !_isSelectionMode {
                        _selectedApps.removeAll()
                    }
                }
                HapticsManager.shared.softImpact()
            } label: {
                Image(systemName: _isSelectionMode ? "checkmark.circle.fill" : "checklist")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(_isSelectionMode ? .white : .primary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(_isSelectionMode ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                    )
            }
        }
    }
    
    // MARK: - Selection Action Bar
    @ViewBuilder
    private var selectionActionBar: some View {
        if _isSelectionMode && !_selectedApps.isEmpty {
            HStack(spacing: 12) {
                // Selected count
                Text("\(_selectedApps.count) selected")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Sign All button (only for unsigned apps)
                let unsignedSelectedApps = getSelectedUnsignedApps()
                if !unsignedSelectedApps.isEmpty {
                    Button {
                        _showBatchSigningSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "signature")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Sign (\(unsignedSelectedApps.count))")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.accentColor, in: Capsule())
                    }
                }
                
                // Delete button
                Button {
                    _showBatchDeleteConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Delete")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.red, in: Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func getSelectedUnsignedApps() -> [AppInfoPresentable] {
        displayedApps.filter { app in
            guard let uuid = app.uuid else { return false }
            return _selectedApps.contains(uuid) && !app.isSigned
        }
    }
    
    private func getSelectedApps() -> [AppInfoPresentable] {
        displayedApps.filter { app in
            guard let uuid = app.uuid else { return false }
            return _selectedApps.contains(uuid)
        }
    }
    
    private func deleteSelectedApps() {
        let appsToDelete = getSelectedApps()
        for app in appsToDelete {
            Storage.shared.deleteApp(for: app)
        }
        _selectedApps.removeAll()
        _isSelectionMode = false
        HapticsManager.shared.success()
    }
    
    // MARK: - Apps Content
    @ViewBuilder
    private var appsContent: some View {
        if displayedApps.isEmpty {
            emptyStateView
        } else {
            LazyVStack(spacing: 14) {
                ForEach(displayedApps, id: \.uuid) { app in
                    HStack(spacing: 12) {
                        // Selection checkmark - always visible when in selection mode
                        if _isSelectionMode {
                            Button {
                                guard let uuid = app.uuid else { return }
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if _selectedApps.contains(uuid) {
                                        _selectedApps.remove(uuid)
                                    } else {
                                        _selectedApps.insert(uuid)
                                    }
                                }
                                HapticsManager.shared.softImpact()
                            } label: {
                                Image(systemName: app.uuid != nil && _selectedApps.contains(app.uuid!) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24))
                                    .foregroundStyle(app.uuid != nil && _selectedApps.contains(app.uuid!) ? Color.accentColor : Color.secondary.opacity(0.5))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // App card
                        PremiumAppCard(
                            app: app,
                            selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                            selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                            selectedInstallAppPresenting: $_selectedInstallAppPresenting
                        )
                        .allowsHitTesting(!_isSelectionMode)
                    }
                    .id(app.uuid)
                }
            }
            
            // Selection action bar at the bottom
            selectionActionBar
                .padding(.top, 16)
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

// MARK: - Compact Filter Chip (New Modern Design)
struct CompactFilterChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor)
                        .matchedGeometryEffect(id: "compactFilterBackground", in: namespace)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(FilterChipButtonStyle())
    }
}



// MARK: - Batch Signing View
struct BatchSigningView: View {
    @Environment(\.dismiss) private var dismiss
    let apps: [AppInfoPresentable]
    let onComplete: () -> Void
    
    @State private var signingProgress: [String: BatchSigningStatus] = [:]
    @State private var currentSigningIndex = 0
    @State private var isSigningInProgress = false
    @State private var overallProgress: Double = 0
    @State private var completedCount = 0
    @State private var failedCount = 0
    @State private var isCancelled = false
    @State private var autoInstall = true
    @State private var signedAppsForInstall: [AppInfoPresentable] = []
    @State private var currentPhase: BatchPhase = .signing
    @State private var installationIndex = 0
    @State private var appearAnimation = false
    
    @AppStorage("Feather.installationMethod") private var installationMethod: Int = 0
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var certificates: FetchedResults<CertificatePair>
    
    @State private var selectedCertificateIndex = 0
    
    enum BatchPhase {
        case signing
        case installing
        case completed
    }
    
    enum BatchSigningStatus: Equatable {
        case pending
        case signing
        case signed
        case installing
        case success
        case failed(String)
        
        static func == (lhs: BatchSigningStatus, rhs: BatchSigningStatus) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending), (.signing, .signing), (.signed, .signed), 
                 (.installing, .installing), (.success, .success):
                return true
            case (.failed(let a), .failed(let b)):
                return a == b
            default:
                return false
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color(.systemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Header
                    modernHeaderSection
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            // Certificate Selection and Options
                            if !isSigningInProgress && completedCount < apps.count && currentPhase == .signing {
                                modernCertificateSection
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                            }
                            
                            // Apps List
                            VStack(spacing: 10) {
                                ForEach(Array(apps.enumerated()), id: \.element.uuid) { index, app in
                                    ModernBatchSigningAppRow(
                                        app: app,
                                        status: getStatusForApp(app),
                                        index: index + 1
                                    )
                                    .opacity(appearAnimation ? 1 : 0)
                                    .offset(y: appearAnimation ? 0 : 20)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15 + Double(index) * 0.03), value: appearAnimation)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 16)
                    }
                    
                    // Action Button
                    modernActionButtonSection
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Initialize all apps as pending
            for app in apps {
                if let uuid = app.uuid {
                    signingProgress[uuid] = .pending
                }
            }
            withAnimation {
                appearAnimation = true
            }
        }
    }
    
    private func getStatusForApp(_ app: AppInfoPresentable) -> BatchSigningStatus {
        guard let uuid = app.uuid else { return .pending }
        return signingProgress[uuid] ?? .pending
    }
    
    // MARK: - Modern Header Section
    private var modernHeaderSection: some View {
        VStack(spacing: 20) {
            // Top bar
            HStack {
                Button {
                    isCancelled = true
                    isSigningInProgress = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color(.tertiarySystemGroupedBackground))
                        )
                }
                
                Spacer()
                
                // Phase indicator
                if currentPhase != .signing || isSigningInProgress {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(currentPhase == .installing ? Color.green : (currentPhase == .completed ? Color.green : Color.accentColor))
                            .frame(width: 8, height: 8)
                        Text(currentPhase == .installing ? "Installing" : (currentPhase == .completed ? "Completed" : "Signing"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(currentPhase == .installing ? .green : (currentPhase == .completed ? .green : .accentColor))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((currentPhase == .installing || currentPhase == .completed ? Color.green : Color.accentColor).opacity(0.12))
                    )
                }
                
                Spacer()
                
                // Placeholder for symmetry
                Color.clear
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Title and icon
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "signature")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                
                Text("Batch Signing")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("\(apps.count) app\(apps.count == 1 ? "" : "s") selected")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            // Progress and Stats
            if isSigningInProgress || completedCount > 0 || failedCount > 0 {
                VStack(spacing: 12) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        colors: currentPhase == .installing ? [.green, .green.opacity(0.8)] : [.accentColor, .accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * overallProgress, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: overallProgress)
                        }
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 20)
                    
                    // Stats row
                    HStack(spacing: 20) {
                        ModernStatPill(icon: "square.stack.fill", value: "\(apps.count)", label: "Total", color: .blue)
                        ModernStatPill(icon: "checkmark.seal.fill", value: "\(completedCount)", label: "Signed", color: .green)
                        if autoInstall && installationIndex > 0 {
                            ModernStatPill(icon: "arrow.down.app.fill", value: "\(installationIndex)", label: "Installed", color: .cyan)
                        }
                        if failedCount > 0 {
                            ModernStatPill(icon: "xmark.circle.fill", value: "\(failedCount)", label: "Failed", color: .red)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 16)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Modern Certificate Section
    private var modernCertificateSection: some View {
        VStack(spacing: 12) {
            // Certificate picker
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.orange)
                    Text("Certificate")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                
                if certificates.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("No Certificates Available")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange.opacity(0.1))
                    )
                } else {
                    let certificateNames: [String] = certificates.enumerated().map { (index, cert) in
                        cert.nickname ?? "Certificate \(index + 1)"
                    }
                    Menu {
                        ForEach(certificateNames.indices, id: \.self) { idx in
                            Button {
                                selectedCertificateIndex = idx
                            } label: {
                                HStack {
                                    Text(certificateNames[idx])
                                    if idx == selectedCertificateIndex {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.orange)
                            Text(certificateNames.indices.contains(selectedCertificateIndex) ? certificateNames[selectedCertificateIndex] : "Select Certificate")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
            
            // Auto install toggle
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Auto Install")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Install apps automatically after signing.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $autoInstall)
                    .labelsHidden()
                    .tint(.green)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Modern Action Button Section
    private var modernActionButtonSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            Group {
                if isSigningInProgress {
                    Button {
                        isCancelled = true
                        isSigningInProgress = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Cancel")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.red.opacity(0.12))
                        )
                    }
                } else if completedCount + failedCount == apps.count {
                    Button {
                        onComplete()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Done")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                } else {
                    Button {
                        startBatchSigning()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "signature")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Sign All Apps")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: certificates.isEmpty ? [.gray, .gray.opacity(0.85)] : [.accentColor, .accentColor.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: certificates.isEmpty ? .clear : .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .disabled(certificates.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }
    
    private func startBatchSigning() {
        guard !certificates.isEmpty, certificates.indices.contains(selectedCertificateIndex) else { 
            AppLogManager.shared.error("No certificates available for batch signing", category: "BatchSign")
            return 
        }
        
        AppLogManager.shared.info("Starting batch signing for \(apps.count) apps", category: "BatchSign")
        
        isSigningInProgress = true
        isCancelled = false
        currentSigningIndex = 0
        completedCount = 0
        failedCount = 0
        overallProgress = 0
        currentPhase = .signing
        signedAppsForInstall = []
        installationIndex = 0
        
        // Reset all statuses to pending
        for app in apps {
            if let uuid = app.uuid {
                signingProgress[uuid] = .pending
            }
        }
        
        HapticsManager.shared.impact()
        
        // Start signing in background
        Task {
            await signAppsSequentially()
        }
    }
    
    private func signAppsSequentially() async {
        for (index, app) in apps.enumerated() {
            guard !isCancelled else {
                await MainActor.run {
                    isSigningInProgress = false
                    currentPhase = .completed
                }
                return
            }
            
            guard let uuid = app.uuid else { continue }
            
            await MainActor.run {
                currentSigningIndex = index
                withAnimation {
                    signingProgress[uuid] = .signing
                }
            }
            
            // Get the selected certificate
            let certificate = certificates[selectedCertificateIndex]
            let options = OptionsManager.shared.options
            
            AppLogManager.shared.info("Signing app \(index + 1)/\(apps.count): \(app.name ?? "Unknown")", category: "BatchSign")
            
            // Sign the app and wait for completion
            let signResult = await withCheckedContinuation { continuation in
                FR.signPackageFile(
                    app,
                    using: options,
                    icon: nil,
                    certificate: certificate
                ) { error in
                    continuation.resume(returning: error)
                }
            }
            
            await MainActor.run {
                if let error = signResult {
                    // Signing failed
                    withAnimation {
                        signingProgress[uuid] = .failed(error.localizedDescription)
                        failedCount += 1
                        overallProgress = Double(completedCount + failedCount) / Double(apps.count)
                    }
                    AppLogManager.shared.error("Batch signing failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
                } else {
                    // Signing succeeded
                    withAnimation {
                        signingProgress[uuid] = autoInstall ? .signed : .success
                        completedCount += 1
                        overallProgress = Double(completedCount + failedCount) / Double(apps.count)
                    }
                    AppLogManager.shared.success("Batch signing succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
                    
                    // Get the newly signed app from storage and add to install queue
                    if autoInstall {
                        if let signedApp = Storage.shared.getLatestSignedApp() {
                            signedAppsForInstall.append(signedApp)
                        }
                    }
                }
            }
            
            // Small delay between apps
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        
        // All apps signed, check if we need to install
        await MainActor.run {
            if autoInstall && !signedAppsForInstall.isEmpty && !isCancelled {
                currentPhase = .installing
                overallProgress = 0
                installAppsSequentially()
            } else {
                currentPhase = .completed
                isSigningInProgress = false
                if completedCount > 0 {
                    HapticsManager.shared.success()
                }
            }
        }
    }
    
    private func installAppsSequentially() {
        Task {
            await installAppsSequentiallyAsync()
        }
    }
    
    private func installAppsSequentiallyAsync() async {
        // Start background audio to keep app alive during installation
        await MainActor.run {
            BackgroundAudioManager.shared.start()
        }
        
        for (index, app) in signedAppsForInstall.enumerated() {
            guard !isCancelled else {
                await MainActor.run {
                    isSigningInProgress = false
                    currentPhase = .completed
                    BackgroundAudioManager.shared.stop()
                }
                return
            }
            
            guard let uuid = app.uuid else { continue }
            
            await MainActor.run {
                installationIndex = index
                withAnimation {
                    signingProgress[uuid] = .installing
                    overallProgress = Double(index) / Double(signedAppsForInstall.count)
                }
            }
            
            AppLogManager.shared.info("Installing App \(index + 1)/\(signedAppsForInstall.count): \(app.name ?? "Unknown")", category: "BatchSign")
            
            // Create a view model for installation tracking
            let viewModel = InstallerStatusViewModel(isIdevice: installationMethod == 1)
            
            do {
                // Create archive handler to package the app
                let archiveHandler = ArchiveHandler(app: app, viewModel: viewModel)
                try await archiveHandler.move()
                let packageUrl = try await archiveHandler.archive()
                
                if installationMethod == 0 {
                    // Server-based installation using ServerInstaller
                    let installer = try ServerInstaller(app: app, viewModel: viewModel)
                    installer.packageUrl = packageUrl
                    
                    // Get server method preference
                    let serverMethod = UserDefaults.standard.integer(forKey: "Feather.serverMethod")
                    
                    await MainActor.run {
                        viewModel.status = .ready
                        
                        if serverMethod == 0 {
                            // Direct iTunes link
                            UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                        } else {
                            // Web page method
                            UIApplication.shared.open(installer.pageEndpoint)
                        }
                    }
                    
                    // Wait for installation to complete
                    var waitCount = 0
                    let maxWait = 60 // 30 seconds max wait
                    while waitCount < maxWait {
                        try await Task.sleep(nanoseconds: 500_000_000)
                        waitCount += 1
                        
                        if case .completed = viewModel.status {
                            break
                        }
                        if case .broken = viewModel.status {
                            throw NSError(domain: "BatchInstall", code: -1, userInfo: [NSLocalizedDescriptionKey: "Installation failed"])
                        }
                    }
                    
                } else if installationMethod == 1 {
                    // Direct installation via InstallationProxy (requires pairing)
                    let installProxy = InstallationProxy(viewModel: viewModel)
                    try await installProxy.install(at: packageUrl, suspend: false)
                }
                
                await MainActor.run {
                    withAnimation {
                        signingProgress[uuid] = .success
                    }
                    AppLogManager.shared.success("Batch installation succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        signingProgress[uuid] = .failed("Install failed: \(error.localizedDescription)")
                    }
                    AppLogManager.shared.error("Batch installation failed for \(app.name ?? "Unknown"): \(error.localizedDescription)", category: "BatchSign")
                }
            }
            
            // Delay between installations
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        // All done
        await MainActor.run {
            installationIndex = signedAppsForInstall.count
            currentPhase = .completed
            isSigningInProgress = false
            BackgroundAudioManager.shared.stop()
            HapticsManager.shared.success()
            AppLogManager.shared.success("Batch installation completed: \(signedAppsForInstall.count) apps processed", category: "BatchSign")
        }
    }
    
}

// MARK: - Batch Signing App Row
// MARK: - Modern Batch Signing App Row
private struct ModernBatchSigningAppRow: View {
    let app: AppInfoPresentable
    let status: BatchSigningView.BatchSigningStatus
    let index: Int
    
    private var statusColor: Color {
        switch status {
        case .pending: return .secondary
        case .signing: return .accentColor
        case .signed: return .orange
        case .installing: return .green
        case .success: return .green
        case .failed: return .red
        }
    }
    
    private var statusIcon: String {
        switch status {
        case .pending: return "circle"
        case .signing: return "arrow.triangle.2.circlepath"
        case .signed: return "checkmark.seal.fill"
        case .installing: return "arrow.down.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private var statusText: String {
        switch status {
        case .pending: return "Waiting"
        case .signing: return "Signing..."
        case .signed: return "Signed"
        case .installing: return "Installing..."
        case .success: return "Completed"
        case .failed(let error): return error
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Index badge
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                if status == .signing || status == .installing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(statusColor)
                } else {
                    Text("\(index)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                }
            }
            
            // App Icon
            FRAppIconView(app: app, size: 48)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .stroke(statusColor.opacity(status == .success ? 0.5 : 0), lineWidth: 2)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 10, weight: .semibold))
                    Text(statusText)
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(statusColor)
                .lineLimit(1)
            }
            
            Spacer()
            
            // Status indicator
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(statusColor.opacity(status == .signing || status == .installing ? 0.3 : 0), lineWidth: 2)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: status)
    }
}

// MARK: - Modern Stat Pill
private struct ModernStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Legacy Batch Signing App Row (kept for compatibility)
private struct BatchSigningAppRow: View {
    let app: AppInfoPresentable
    let status: BatchSigningView.BatchSigningStatus
    
    var body: some View {
        HStack(spacing: 14) {
            FRAppIconView(app: app, size: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                
                if let identifier = app.identifier {
                    Text(identifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Stat Badge
private struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 60)
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

