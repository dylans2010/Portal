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
                    if _isSelectionMode {
                        SelectableAppCard(
                            app: app,
                            isSelected: app.uuid != nil && _selectedApps.contains(app.uuid!),
                            onToggleSelection: {
                                guard let uuid = app.uuid else { return }
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    if _selectedApps.contains(uuid) {
                                        _selectedApps.remove(uuid)
                                    } else {
                                        _selectedApps.insert(uuid)
                                    }
                                }
                                HapticsManager.shared.softImpact()
                            }
                        )
                        .id(app.uuid)
                    } else {
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

// MARK: - Selectable App Card
struct SelectableAppCard: View {
    let app: AppInfoPresentable
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    @State private var dominantColor: Color = .cyan
    
    var body: some View {
        Button(action: onToggleSelection) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                
                // App icon
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(dominantColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    FRAppIconView(app: app, size: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name ?? String.localized("Unknown"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    if let identifier = app.identifier {
                        Text(identifier)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 6) {
                        if let version = app.version {
                            Text("v\(version)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(dominantColor)
                        }
                        
                        if app.isSigned {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 9))
                                Text("Signed")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(.green)
                        } else {
                            HStack(spacing: 3) {
                                Image(systemName: "clock")
                                    .font(.system(size: 9))
                                Text("Unsigned")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(.orange)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 6 : 3, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
    
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
    ) private var certificates: FetchedResults<CertificatePair>
    
    @State private var selectedCertificateIndex = 0
    
    enum BatchSigningStatus: Equatable {
        case pending
        case signing
        case success
        case failed(String)
        
        static func == (lhs: BatchSigningStatus, rhs: BatchSigningStatus) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending), (.signing, .signing), (.success, .success):
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
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Certificate Selection
                if !isSigningInProgress && completedCount < apps.count {
                    certificateSelectionSection
                }
                
                // Apps List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(apps, id: \.uuid) { app in
                            BatchSigningAppRow(
                                app: app,
                                status: getStatusForApp(app)
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                
                // Action Button
                actionButtonSection
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
        }
        .onAppear {
            // Initialize all apps as pending
            for app in apps {
                if let uuid = app.uuid {
                    signingProgress[uuid] = .pending
                }
            }
        }
    }
    
    private func getStatusForApp(_ app: AppInfoPresentable) -> BatchSigningStatus {
        guard let uuid = app.uuid else { return .pending }
        return signingProgress[uuid] ?? .pending
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Button {
                    isCancelled = true
                    isSigningInProgress = false
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text("Batch Signing")
                    .font(.headline)
                
                Spacer()
                
                // Placeholder for symmetry
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.clear)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Progress indicator
            if isSigningInProgress {
                VStack(spacing: 8) {
                    ProgressView(value: overallProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    
                    Text("Signing \(min(completedCount + failedCount + 1, apps.count)) of \(apps.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
            }
            
            // Stats
            HStack(spacing: 24) {
                StatBadge(title: "Total", value: "\(apps.count)", color: .blue)
                StatBadge(title: "Completed", value: "\(completedCount)", color: .green)
                if failedCount > 0 {
                    StatBadge(title: "Failed", value: "\(failedCount)", color: .red)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var certificateSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            certificateSectionHeader
            certificateSectionContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var certificateSectionHeader: some View {
        Text("Certificate")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
    }
    
    @ViewBuilder
    private var certificateSectionContent: some View {
        if certificates.isEmpty {
            noCertificatesView
        } else {
            certificatePicker
        }
    }
    
    private var noCertificatesView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text("No certificates available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private var certificatePicker: some View {
        let certificateNames: [String] = certificates.enumerated().map { (index, cert) in
            cert.nickname ?? "Certificate \(index + 1)"
        }
        return Picker("Certificate", selection: $selectedCertificateIndex) {
            ForEach(certificateNames.indices, id: \.self) { idx in
                Text(certificateNames[idx]).tag(idx)
            }
        }
        .pickerStyle(.menu)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
    
    private var actionButtonSection: some View {
        VStack(spacing: 12) {
            actionButtonContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    @ViewBuilder
    private var actionButtonContent: some View {
        if isSigningInProgress {
            cancelButton
        } else if completedCount + failedCount == apps.count {
            doneButton
        } else {
            signAllButton
        }
    }
    
    private var cancelButton: some View {
        Button {
            isCancelled = true
            isSigningInProgress = false
        } label: {
            Text("Cancel")
                .font(.headline)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.red.opacity(0.1))
                )
        }
    }
    
    private var doneButton: some View {
        Button {
            onComplete()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Done")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.green)
            )
        }
    }
    
    private var signAllButton: some View {
        Button {
            startBatchSigning()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "signature")
                Text("Sign All Apps")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(certificates.isEmpty ? Color.gray : Color.accentColor)
            )
        }
        .disabled(certificates.isEmpty)
    }
    
    private func startBatchSigning() {
        guard !certificates.isEmpty, certificates.indices.contains(selectedCertificateIndex) else { return }
        
        isSigningInProgress = true
        isCancelled = false
        currentSigningIndex = 0
        completedCount = 0
        failedCount = 0
        overallProgress = 0
        
        // Reset all statuses to pending
        for app in apps {
            if let uuid = app.uuid {
                signingProgress[uuid] = .pending
            }
        }
        
        HapticsManager.shared.impact()
        signNextApp()
    }
    
    private func signNextApp() {
        guard currentSigningIndex < apps.count, isSigningInProgress, !isCancelled else {
            isSigningInProgress = false
            if completedCount > 0 {
                HapticsManager.shared.success()
            }
            return
        }
        
        let app = apps[currentSigningIndex]
        guard let uuid = app.uuid else {
            currentSigningIndex += 1
            signNextApp()
            return
        }
        
        // Update status to signing
        withAnimation {
            signingProgress[uuid] = .signing
        }
        
        // Get the selected certificate
        let certificate = certificates[selectedCertificateIndex]
        
        // Use default options for batch signing
        let options = OptionsManager.shared.options
        
        // Actually sign the app using FR.signPackageFile
        FR.signPackageFile(
            app,
            using: options,
            icon: nil,
            certificate: certificate
        ) { error in
            guard !isCancelled else { return }
            
            if let error = error {
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
                    signingProgress[uuid] = .success
                    completedCount += 1
                    overallProgress = Double(completedCount + failedCount) / Double(apps.count)
                }
                AppLogManager.shared.success("Batch signing succeeded for \(app.name ?? "Unknown")", category: "BatchSign")
            }
            
            currentSigningIndex += 1
            
            // Sign next app after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                signNextApp()
            }
        }
    }
}

// MARK: - Batch Signing App Row
private struct BatchSigningAppRow: View {
    let app: AppInfoPresentable
    let status: BatchSigningView.BatchSigningStatus
    
    var body: some View {
        HStack(spacing: 14) {
            // App Icon
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
            
            // Status indicator
            statusIndicator
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        switch status {
        case .pending:
            Image(systemName: "clock")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
        case .signing:
            ProgressView()
                .scaleEffect(0.8)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)
        case .failed(_):
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.red)
        }
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

