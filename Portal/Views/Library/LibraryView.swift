import SwiftUI
import CoreData
import NimbleViews
import Combine
import IDeviceSwift
import Zip

// MARK: - Modern Library View with Blue Gradient Background
struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("Feather.useGradients") private var _useGradients: Bool = true
    
    @StateObject var downloadManager = DownloadManager.shared
    @StateObject private var hideManager = LibraryHideManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _selectedInstallModifyAppPresenting: AnyApp?
    @State private var _showImportSelection = false
    @State private var _importStatus: ImportStatus = .loading
    @State private var _importedAppName: String = ""
    @State private var _importErrorMessage: String = ""
    @State private var _currentDownloadId: String = ""
    @State private var _downloadProgress: Double = 0.0
    @State private var _shouldAutoSignNext = false
    
    // Batch selection states
    @State private var _editMode: EditMode = .inactive
    @State private var _selectedApps: Set<String?> = []
    @State private var _showBatchSigningSheet = false
    @State private var _showBatchDeleteConfirmation = false
    @State private var _showGestureDeleteConfirmation = false
    @State private var _appToDelete: AppInfoPresentable?
    
    enum ImportStatus {
        case loading
        case downloading
        case processing
        case success
        case failed
    }
    
    @State private var _searchText = ""
    @State private var _searchGlow = false
    @State private var _filterMode: FilterMode = .all
    
    enum FilterMode: String, CaseIterable {
        case all = "All"
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
            VStack(spacing: 0) {
                if !downloadManager.manualDownloads.isEmpty {
                    LibraryDownloadHeaderView(downloadManager: downloadManager)
                        .padding(.top, 10)
                }
                
                if !hideManager.isHidden("library.filterChips") {
                    filterChips
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .shadow(color: _searchGlow ? .purple : .clear, radius: 15)
                        .shadow(color: _searchGlow ? .cyan : .clear, radius: 10)
                        .scaleEffect(_searchGlow ? 1.05 : 1.0)
                        .animation(.spring(), value: _searchGlow)
                }

                ScrollView {
                    LazyVStack(spacing: 24) {
                        if displayedApps.isEmpty {
                            emptyStateView
                                .padding(.top, 40)
                        } else {
                            if _filterMode == .all || _filterMode == .signed {
                                let apps = _filterMode == .all ? filteredSignedApps : displayedApps.compactMap { $0 as? Signed }
                                if !apps.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Signed")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Color.secondary.opacity(0.1))
                                            .clipShape(Capsule())
                                            .padding(.horizontal, 24)

                                        ForEach(apps, id: \.uuid) { app in
                                            libraryAppRow(for: app)
                                        }
                                    }
                                }
                            }

                            if _filterMode == .all && !filteredSignedApps.isEmpty && !filteredImportedApps.isEmpty {
                                Divider()
                                    .padding(.horizontal, 24)
                            }

                            if _filterMode == .all || _filterMode == .unsigned {
                                let apps = _filterMode == .all ? filteredImportedApps : displayedApps.compactMap { $0 as? Imported }
                                if !apps.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Imported")
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Color.secondary.opacity(0.1))
                                            .clipShape(Capsule())
                                            .padding(.horizontal, 24)

                                        ForEach(apps, id: \.uuid) { app in
                                            libraryAppRow(for: app)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .environment(\.editMode, $_editMode)

                if _editMode == .active && !_selectedApps.isEmpty {
                    selectionActionBar
                        .padding(.horizontal, 20)
                        .background(Color.clear)
                }
            }
            .searchable(text: $_searchText)
            .onChange(of: _searchText) { newValue in
                if newValue.uppercased() == "FEATHER" {
                    _searchGlow = true
                    HapticsManager.shared.success()
                } else {
                    _searchGlow = false
                }

                if newValue.uppercased() == "RAIN" {
                    EasterEggManager.shared.activeEffect = .rain
                    _searchText = ""
                } else if newValue.uppercased() == "SNOW" {
                    EasterEggManager.shared.activeEffect = .snow
                    _searchText = ""
                } else if newValue.uppercased() == "BALL" {
                    EasterEggManager.shared.activeEffect = .ball
                    _searchText = ""
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !hideManager.isHidden("library.importButton") {
                        Button {
                            _showImportSelection = true
                            HapticsManager.shared.softImpact()
                        } label: {
                            Image(systemName: "document.badge.plus.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.accentColor)
                                .symbolRenderingMode(.hierarchical)
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
                        .sheet(isPresented: $_showImportSelection) {
                            AppAddView()
                                .presentationDetents([.height(260)])
                                .presentationDragIndicator(.visible)
                                .compatPresentationRadius(24)
                        }
                        .overlay {
                            Group {
                                if let installApp = _selectedInstallAppPresenting {
                                    InstallPreviewView(
                                        app: installApp.base,
                                        isSharing: installApp.archive,
                                        onDismiss: {
                                            withAnimation(.easeInOut(duration: 0.25)) {
                                                _selectedInstallAppPresenting = nil
                                            }
                                        }
                                    )
                                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                                }
                            }
                            .animation(.easeInOut(duration: 0.25), value: _selectedInstallAppPresenting?.id)
                        }
            .fullScreenCover(isPresented: $_showBatchSigningSheet) {
                BatchSigningView(
                    apps: getSelectedUnsignedApps(),
                    onComplete: {
                        _showBatchSigningSheet = false
                        _selectedApps.removeAll()
                        _editMode = .inactive
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
            .alert("Delete App", isPresented: $_showGestureDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let app = _appToDelete {
                        Storage.shared.deleteApp(for: app)
                        HapticsManager.shared.success()
                    }
                }
            } message: {
                if let app = _appToDelete {
                    Text("Are you sure you want to delete \(app.name ?? "this app")?")
                }
            }
                        // Listen for import success notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidSucceedNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId else { return }
                                
                                // Check for large app support (3GB+)
                                if let latestApp = Storage.shared.getLatestImportedApp(),
                                   latestApp.size > 3 * 1024 * 1024 * 1024 {
                                    AppLogManager.shared.info("Large app detected (>3GB): \(latestApp.name ?? "Unknown"), enabling supportBigApps.", category: "Library")
                                    OptionsManager.shared.options.supportBigApps = true
                                    OptionsManager.shared.saveOptions()
                                }

                                // Auto-sign logic
                                if _shouldAutoSignNext {
                                    _shouldAutoSignNext = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        if let latestApp = Storage.shared.getLatestImportedApp() {
                                            _selectedSigningAppPresenting = AnyApp(base: latestApp)
                                        }
                                    }
                                }

                                _currentDownloadId = ""
                        }
                        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.TriggerImport"))) { notification in
                            if let userInfo = notification.userInfo, let autoSign = userInfo["autoSign"] as? Bool {
                                _shouldAutoSignNext = autoSign
                            }
                            _showImportSelection = true
                        }
                        // Listen for import failure notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.importDidFailNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId else { return }
                                
                                _importErrorMessage = userInfo["error"] as? String ?? "Unknown Error"
                                _currentDownloadId = ""
                        }
                        // Listen for download failure notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidFailNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId else { return }
                                
                                _importErrorMessage = userInfo["error"] as? String ?? "Download Failed"
                                _currentDownloadId = ""
                        }
                        // Listen for download progress notifications
                        .onReceive(NotificationCenter.default.publisher(for: DownloadManager.downloadDidProgressNotification)) { notification in
                                guard let userInfo = notification.userInfo,
                                          let downloadId = userInfo["downloadId"] as? String,
                                          downloadId == _currentDownloadId,
                                          let progress = userInfo["progress"] as? Double else { return }
                                
                                // Check for large download (3GB+)
                                if let totalBytes = userInfo["totalBytes"] as? Int64,
                                   totalBytes > 3 * 1024 * 1024 * 1024 {
                                    if !OptionsManager.shared.options.supportBigApps {
                                        AppLogManager.shared.info("Large download detected (>3GB), enabling supportBigApps.", category: "Library")
                                        OptionsManager.shared.options.supportBigApps = true
                                        OptionsManager.shared.saveOptions()
                                    }
                                }

                                _downloadProgress = progress
                                
                                // Switch to processing status when download is complete (progress >= 0.99)
                                if progress >= 0.99 && _importStatus == .downloading {
                                        _importStatus = .processing
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
                        .onReceive(NotificationCenter.default.publisher(for: .gestureOpenDetails)) { notification in
                            if let app = notification.object as? AppInfoPresentable {
                                _selectedInfoAppPresenting = AnyApp(base: app)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .gestureSignApp)) { notification in
                            if let app = notification.object as? AppInfoPresentable {
                                _selectedSigningAppPresenting = AnyApp(base: app)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .gestureInstallApp)) { notification in
                            if let app = notification.object as? AppInfoPresentable {
                                _selectedInstallAppPresenting = AnyApp(base: app)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .gestureShareApp)) { notification in
                            if let app = notification.object as? AppInfoPresentable {
                                exportApp(app)
                            }
                        }
                        .onReceive(NotificationCenter.default.publisher(for: .gestureRequireConfirmation)) { notification in
                            guard let userInfo = notification.userInfo,
                                  let action = userInfo["action"] as? GestureAction,
                                  action == .deleteApp,
                                  let app = userInfo["context"] as? AppInfoPresentable else { return }

                            _appToDelete = app
                            _showGestureDeleteConfirmation = true
                        }
                }
        }
}

// MARK: - Extension: View Components
extension LibraryView {
    // MARK: - Modern Filter Chips
    private var filterChips: some View {
        HStack(spacing: 12) {
            HStack(spacing: 0) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    let isSelected = _filterMode == mode

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            _filterMode = mode
                        }
                        HapticsManager.shared.softImpact()
                    } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                            .foregroundStyle(isSelected ? .primary : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if isSelected {
                                    Capsule()
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        .matchedGeometryEffect(id: "activeFilter", in: _namespace)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(UIColor.secondarySystemFill).opacity(0.5))
            .clipShape(Capsule())
            
            Spacer()
            
            if totalAppCount >= 1 && !hideManager.isHidden("library.selectionButton") {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        _editMode = _editMode == .active ? .inactive : .active
                        if _editMode == .inactive {
                            _selectedApps.removeAll()
                        }
                    }
                    HapticsManager.shared.softImpact()
                } label: {
                    Image(systemName: _editMode == .active ? "checkmark.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
    
    // MARK: - Selection Action Bar
    @ViewBuilder
    private var selectionActionBar: some View {
        if _editMode == .active && !_selectedApps.isEmpty {
            HStack(spacing: 16) {
                Text("\(_selectedApps.count) Selected")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                let unsignedSelectedApps = getSelectedUnsignedApps()
                if !unsignedSelectedApps.isEmpty {
                    Button {
                        _showBatchSigningSheet = true
                    } label: {
                        Text("Sign \(unsignedSelectedApps.count)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .contentShape(Rectangle())
                    }

                }
                
                Button {
                    _showBatchDeleteConfirmation = true
                } label: {
                    Text("Delete")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.red)
                        .contentShape(Rectangle())
                }

            }
            .padding(.vertical, 12)
            .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func getSelectedUnsignedApps() -> [AppInfoPresentable] {
        displayedApps.filter { app in
            _selectedApps.contains(app.uuid) && !app.isSigned
        }
    }
    
    private func getSelectedApps() -> [AppInfoPresentable] {
        displayedApps.filter { app in
            _selectedApps.contains(app.uuid)
        }
    }
    
    private func deleteSelectedApps() {
        let appsToDelete = getSelectedApps()
        for app in appsToDelete {
            Storage.shared.deleteApp(for: app)
        }
        _selectedApps.removeAll()
        _editMode = .inactive
        HapticsManager.shared.success()
    }
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        if #available(iOS 17, *) {
            ContentUnavailableView {
                Label {
                    Text("No Apps")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                } icon: {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: 50, weight: .thin))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
            } description: {
                Text("Import an IPA file to get started")
                    .font(.system(size: 15))
            } actions: {
                Menu {
                    _importActions()
                } label: {
                    Text("Import")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
            .padding(.top, 60)
        } else {
            VStack(spacing: 20) {
                Spacer(minLength: 80)

                Image(systemName: "square.stack.3d.up.slash")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(.secondary.opacity(0.6))

                VStack(spacing: 8) {
                    Text("No Apps")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("There is no apps here. Import an IPA file to get started!")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                Menu {
                    _importActions()
                } label: {
                    Text("Import")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.top, 8)

                Spacer(minLength: 80)
            }
        }
    }
    
    @ViewBuilder
    private func _importActions() -> some View {
        Button(String.localized("Import From Files"), systemImage: "folder.fill") {
            _showImportSelection = true
        }
        Button(String.localized("Import From URL"), systemImage: "globe.americas.fill") {
            _showImportSelection = true
        }
    }
    
    private func exportApp(_ app: AppInfoPresentable) {
        guard app.isSigned, let archiveURL = app.archiveURL else { return }
        UIActivityViewController.show(activityItems: [archiveURL])
        HapticsManager.shared.success()
    }

    private func downloadIPA(for app: AppInfoPresentable) {
        _selectedInstallAppPresenting = AnyApp(base: app, archive: true)
        HapticsManager.shared.softImpact()
    }

    @ViewBuilder
    private func libraryAppRow(for app: AppInfoPresentable) -> some View {
        LibraryAppRow(
            app: app,
            selectedInfoAppPresenting: $_selectedInfoAppPresenting,
            selectedSigningAppPresenting: $_selectedSigningAppPresenting,
            selectedInstallAppPresenting: $_selectedInstallAppPresenting,
            selectedApps: $_selectedApps,
            editMode: $_editMode
        )
        .padding(.horizontal, 16)
        .onTapGesture(count: 2) {
            Task {
                await GestureManager.shared.performAction(for: .doubleTap, in: .library, context: app)
            }
        }
        .onLongPressGesture {
            Task {
                await GestureManager.shared.performAction(for: .longPress, in: .library, context: app)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                Task {
                    await GestureManager.shared.performAction(for: .leftSwipe, in: .library, context: app)
                }
            } label: {
                Label("Action", systemImage: "hand.tap")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                Task {
                    await GestureManager.shared.performAction(for: .rightSwipe, in: .library, context: app)
                }
            } label: {
                Label("Action", systemImage: "hand.tap")
            }
            .tint(.accentColor)
        }
        .contextMenu {
            Button {
                _selectedInfoAppPresenting = AnyApp(base: app)
            } label: {
                Label(String.localized("Details"), systemImage: "info.circle")
            }

            if app.isSigned {
                Button {
                    _selectedInstallAppPresenting = AnyApp(base: app)
                } label: {
                    Label(String.localized("Install"), systemImage: "arrow.down.circle")
                }
                Button {
                    _selectedSigningAppPresenting = AnyApp(base: app)
                } label: {
                    Label(String.localized("Sign Again"), systemImage: "signature")
                }
            } else {
                Button {
                    _selectedSigningAppPresenting = AnyApp(base: app)
                } label: {
                    Label(String.localized("Sign"), systemImage: "signature")
                }
            }

            Button {
                downloadIPA(for: app)
            } label: {
                Label(String.localized("Download IPA"), systemImage: "square.and.arrow.down")
            }

            Divider()

            Button(role: .destructive) {
                Storage.shared.deleteApp(for: app)
            } label: {
                Label(String.localized("Delete"), systemImage: "trash")
            }
        }
    }
}

// MARK: - Simplified Library App Row
struct LibraryAppRow: View {
    let app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    @Binding var selectedApps: Set<String?>
    @Binding var editMode: EditMode
    
    var body: some View {
        let isEditing = editMode == .active

        HStack(spacing: 12) {
            // Main row button
            Button {
                if isEditing {
                    if selectedApps.contains(app.uuid) {
                        selectedApps.remove(app.uuid)
                    } else {
                        selectedApps.insert(app.uuid)
                    }
                } else {
                    selectedInfoAppPresenting = AnyApp(base: app)
                }
                HapticsManager.shared.softImpact()
            } label: {
                HStack(spacing: 12) {
                    if isEditing {
                        Image(systemName: selectedApps.contains(app.uuid) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundStyle(selectedApps.contains(app.uuid) ? Color.accentColor : .secondary.opacity(0.4))
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    FRAppIconView(app: app, size: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.name ?? String.localized("Unknown"))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            if let version = app.version {
                                Text(version)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }

                            Text("•")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)

                            Text(app.isSigned ? String.localized("Signed") : String.localized("Unsigned"))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(app.isSigned ? .green : .orange)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }

            
            if !isEditing {
                Button {
                    if app.isSigned {
                        selectedInstallAppPresenting = AnyApp(base: app)
                    } else {
                        selectedSigningAppPresenting = AnyApp(base: app)
                    }
                    HapticsManager.shared.softImpact()
                } label: {
                    Image(systemName: app.isSigned ? "arrow.down.circle.fill" : "signature")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(app.isSigned ? Color.green : Color.accentColor)
                        .contentShape(Rectangle())
                }

            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
    }
}

// MARK: - Library Download Header View
struct LibraryDownloadHeaderView: View {
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        if !downloadManager.manualDownloads.isEmpty {
            VStack(spacing: 12) {
                if let firstDownload = downloadManager.manualDownloads.first {
                    LibraryDownloadItemView(download: firstDownload)

                    if downloadManager.manualDownloads.count > 1 {
                        HStack {
                            Spacer()
                            Text(verbatim: "+\(downloadManager.manualDownloads.count - 1) more")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.accentColor.opacity(0.1)))
                        }
                    }
                }
            }
            .padding(14)
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

struct LibraryDownloadItemView: View {
    let download: Download
    @State private var progress: Double = 0
    @State private var bytesDownloaded: Int64 = 0
    @State private var totalBytes: Int64 = 0
    @State private var unpackageProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: overallProgress >= 1.0 ? "checkmark.circle.fill" : "arrow.down.circle.fill")
                    .font(.title3)
                    .foregroundStyle(overallProgress >= 1.0 ? .green : .accentColor)

                Text(download.fileName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Spacer()

                Text("\(Int(overallProgress * 100))%")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: overallProgress)
                .tint(.accentColor)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
        }
        .onReceive(download.$progress) { self.progress = $0 }
        .onReceive(download.$bytesDownloaded) { self.bytesDownloaded = $0 }
        .onReceive(download.$totalBytes) { self.totalBytes = $0 }
        .onReceive(download.$unpackageProgress) { self.unpackageProgress = $0 }
    }

    private var overallProgress: Double {
        download.onlyArchiving ? unpackageProgress : (0.3 * unpackageProgress) + (0.7 * progress)
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

    }
}
