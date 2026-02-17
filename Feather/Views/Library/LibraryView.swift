import SwiftUI
import CoreData
import NimbleViews
import Combine
import IDeviceSwift

// MARK: - Modern Library View
struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("Feather.useGradients") private var _useGradients: Bool = true
    
    @StateObject var downloadManager = DownloadManager.shared
    @StateObject private var hideManager = LibraryHideManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppOverlay: AnyApp?
    @State private var _selectedInstallModifyAppPresenting: AnyApp?
    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false
    @State private var _showImportAnimation = false
    @State private var _importStatus: ImportStatus = .loading
    @State private var _importedAppName: String = ""
    @State private var _importErrorMessage: String = ""
    @State private var _currentDownloadId: String = ""
    @State private var _downloadProgress: Double = 0.0
    @State private var _shouldAutoSignNext = false
    
    // Batch selection states
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
        case all = "All Apps"
        case unsigned = "Imported"
        case signed = "Signed"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .unsigned: return "doc.badge.clock"
            case .signed: return "checkmark.seal"
            }
        }
    }
    
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
        let apps: [AppInfoPresentable]
        switch _filterMode {
        case .all:
            apps = Array(filteredSignedApps) + Array(filteredImportedApps)
        case .unsigned:
            apps = Array(filteredImportedApps)
        case .signed:
            apps = Array(filteredSignedApps)
        }
        return apps.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }
    }
    
    private var totalAppCount: Int {
        _signedApps.count + _importedApps.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List(displayedApps, id: \.uuid, selection: $_selectedApps) { app in
                    appRow(for: app)
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    HapticsManager.shared.softImpact()
                }
                .overlay {
                    if displayedApps.isEmpty {
                        emptyStateView
                    }
                }
                .searchable(text: $_searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Apps")
                .safeAreaInset(edge: .bottom) {
                    if !_selectedApps.isEmpty {
                        batchActionBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // Import overlay
                if _showImportAnimation {
                    importToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, _selectedApps.isEmpty ? 20 : 100)
                }

                // Install preview overlay
                if let app = _selectedInstallAppOverlay {
                    InstallPreviewView(app: app.base, isSharing: app.archive, onDismiss: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            _selectedInstallAppOverlay = nil
                        }
                    })
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(101)
                    .ignoresSafeArea()
                }
            }
            .navigationTitle("Library")
            .toolbarTitleMenu {
                filterMenu
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !hideManager.isHidden("library.importButton") {
                        importMenu
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !_selectedApps.isEmpty {
                        Button("Clear") {
                            _selectedApps.removeAll()
                        }
                    }
                }
            }
            .sheet(item: $_selectedInfoAppPresenting) { app in
                LibraryInfoView(app: app.base)
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
                    allowedContentTypes: [.ipa, .tipa],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        handleImport(urls: urls)
                    }
                )
                .ignoresSafeArea()
            }
            .sheet(isPresented: $_isDownloadingPresenting) {
                ModernImportURLView { url in
                    handleDownload(url: url)
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
                    }
                )
            }
            .alert("Delete Selected Apps", isPresented: $_showBatchDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedApps()
                }
            } message: {
                Text("Are you sure you want to delete \(_selectedApps.count) selected app(s)?")
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidSucceedNotification)) { notification in
                handleImportSuccess(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.TriggerImport"))) { notification in
                if let userInfo = notification.userInfo, let autoSign = userInfo["autoSign"] as? Bool {
                    _shouldAutoSignNext = autoSign
                }
                _isImportingPresenting = true
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidFailNotification)) { notification in
                handleImportFailure(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidFailNotification)) { notification in
                handleDownloadFailure(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidProgressNotification)) { notification in
                handleDownloadProgress(notification: notification)
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.installApp"))) { _ in
                if let latest = _signedApps.first {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        _selectedInstallAppOverlay = AnyApp(base: latest)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.openSigningView"))) { notification in
                if let app = notification.object as? AppInfoPresentable {
                    _selectedSigningAppPresenting = AnyApp(base: app)
                }
            }
        }
    }
}

// MARK: - Subviews & Actions
extension LibraryView {

    @ViewBuilder
    private func appRow(for app: AppInfoPresentable) -> some View {
        LibraryCellView(
            app: app,
            selectedInfoAppPresenting: $_selectedInfoAppPresenting,
            selectedSigningAppPresenting: $_selectedSigningAppPresenting,
            selectedInstallAppPresenting: $_selectedInstallAppOverlay
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.visible)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Storage.shared.deleteApp(for: app)
                HapticsManager.shared.success()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                if app.isSigned {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        _selectedInstallAppOverlay = AnyApp(base: app)
                    }
                } else {
                    _selectedSigningAppPresenting = AnyApp(base: app)
                }
            } label: {
                Label(app.isSigned ? "Install" : "Sign", systemImage: app.isSigned ? "arrow.down" : "signature")
            }
            .tint(app.isSigned ? .green : .accentColor)
        }
        .contextMenu {
            Button {
                _selectedInfoAppPresenting = AnyApp(base: app)
            } label: {
                Label("Details", systemImage: "info.circle")
            }

            Divider()

            if app.isSigned {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        _selectedInstallAppOverlay = AnyApp(base: app)
                    }
                } label: {
                    Label("Install", systemImage: "arrow.down.circle")
                }
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        _selectedInstallAppOverlay = AnyApp(base: app, archive: true)
                    }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                Button {
                    _selectedSigningAppPresenting = AnyApp(base: app)
                } label: {
                    Label("Sign Again", systemImage: "signature")
                }
            } else {
                Button {
                    _selectedSigningAppPresenting = AnyApp(base: app)
                } label: {
                    Label("Sign", systemImage: "signature")
                }
            }

            Divider()

            Button(role: .destructive) {
                Storage.shared.deleteApp(for: app)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var filterMenu: some View {
        ForEach(FilterMode.allCases, id: \.self) { mode in
            Button {
                withAnimation { _filterMode = mode }
            } label: {
                Label(mode.rawValue, systemImage: mode.icon)
            }
        }
    }

    private var importMenu: some View {
        Menu {
            Button {
                _isImportingPresenting = true
            } label: {
                Label("Import From Files", systemImage: "folder")
            }

            Button {
                _isDownloadingPresenting = true
            } label: {
                Label("Import From URL", systemImage: "globe")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: 18))
        }
    }

    private var batchActionBar: some View {
        HStack(spacing: 20) {
            let unsignedSelected = getSelectedUnsignedApps()

            if !unsignedSelected.isEmpty {
                Button {
                    _showBatchSigningSheet = true
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "signature")
                        Text("Sign (\(unsignedSelected.count))")
                            .font(.caption2)
                    }
                }
            }
            
            Spacer()
            
            Text("\(_selectedApps.count) Selected")
                .font(.system(size: 15, weight: .bold))

            Spacer()

            Button(role: .destructive) {
                _showBatchDeleteConfirmation = true
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("Delete")
                        .font(.caption2)
                }
                .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.bottom, 10)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    private var importToast: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                statusIcon
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(_statusTitle)
                    .font(.system(size: 14, weight: .bold))
                
                Text(_importedAppName)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if _importStatus == .downloading || _importStatus == .processing || _importStatus == .loading {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    private var _statusTitle: String {
        switch _importStatus {
        case .loading: return "Loading"
        case .downloading: return "Downloading (\(Int(_downloadProgress * 100))%)"
        case .processing: return "Processing"
        case .success: return "Import Successful!"
        case .failed: return "Import Failed"
        }
    }
    
    private var statusColor: Color {
        switch _importStatus {
        case .success: return .green
        case .failed: return .red
        default: return .accentColor
        }
    }
    
    private var statusIcon: some View {
        switch _importStatus {
        case .success: return Image(systemName: "checkmark")
        case .failed: return Image(systemName: "xmark")
        case .downloading: return Image(systemName: "arrow.down")
        default: return Image(systemName: "hourglass")
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label {
                    Text(_searchText.isEmpty ? "No Apps" : "No Results")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                } icon: {
                    Image(systemName: _searchText.isEmpty ? "square.stack.3d.up.slash" : "magnifyingglass")
                        .font(.system(size: 50, weight: .thin))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            } description: {
                Text(_searchText.isEmpty ? "Import an IPA file to get started" : "No apps found matching \"\(_searchText)\"")
                    .font(.system(size: 15))
            } actions: {
                if _searchText.isEmpty {
                    importMenu
                        .buttonStyle(.borderedProminent)
                        .clipShape(Capsule())
                } else {
                    Button("Clear Search") {
                        _searchText = ""
                    }
                    .buttonStyle(.bordered)
                    .clipShape(Capsule())
                }
            }
        } else {
            VStack(spacing: 20) {
                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(.secondary.opacity(0.6))

                VStack(spacing: 8) {
                    Text("No Apps")
                        .font(.system(size: 22, weight: .semibold))
                    Text("Import an IPA file to get started!")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Logic
extension LibraryView {
    private func handleImport(urls: [URL]) {
        guard !urls.isEmpty else { return }

        for url in urls {
            let id = "FeatherManualDownload_\(UUID().uuidString)"
            let dl = downloadManager.startArchive(from: url, id: id)
            
            _importedAppName = url.deletingPathExtension().lastPathComponent
            _currentDownloadId = id
            _importStatus = .processing
            _importErrorMessage = ""
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                _showImportAnimation = true
            }
            
            do {
                try downloadManager.handlePachageFile(url: url, dl: dl)
            } catch {
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
    
    private func handleDownload(url: URL) {
        let downloadId = "FeatherManualDownload_\(UUID().uuidString)"
        _currentDownloadId = downloadId
        _importedAppName = url.deletingPathExtension().lastPathComponent
        _downloadProgress = 0.0
        _importStatus = .downloading
        _importErrorMessage = ""

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            _showImportAnimation = true
        }

        _ = downloadManager.startDownload(from: url, id: downloadId)
    }
    
    private func handleImportSuccess(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let downloadId = userInfo["downloadId"] as? String,
              downloadId == _currentDownloadId else { return }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            _importStatus = .success
        }

        if _shouldAutoSignNext {
            _shouldAutoSignNext = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let latestApp = Storage.shared.getLatestImportedApp() {
                    _selectedSigningAppPresenting = AnyApp(base: latestApp)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                _showImportAnimation = false
                _currentDownloadId = ""
            }
        }
    }
    
    private func handleImportFailure(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let downloadId = userInfo["downloadId"] as? String,
              downloadId == _currentDownloadId else { return }

        _importErrorMessage = userInfo["error"] as? String ?? "Unknown Error"
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            _importStatus = .failed
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                _showImportAnimation = false
                _currentDownloadId = ""
            }
        }
    }

    private func handleDownloadFailure(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let downloadId = userInfo["downloadId"] as? String,
              downloadId == _currentDownloadId else { return }

        _importErrorMessage = userInfo["error"] as? String ?? "Download Failed"
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            _importStatus = .failed
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                _showImportAnimation = false
                _currentDownloadId = ""
            }
        }
    }

    private func handleDownloadProgress(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let downloadId = userInfo["downloadId"] as? String,
              downloadId == _currentDownloadId,
              let progress = userInfo["progress"] as? Double else { return }

        _downloadProgress = progress

        if progress >= 0.99 && _importStatus == .downloading {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                _importStatus = .processing
            }
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
        HapticsManager.shared.success()
    }
}
