import SwiftUI
import NimbleViews
import AltSourceKit

// MARK: - Widget Size
enum WidgetSize: String, CaseIterable, Codable, Identifiable {
    case compact = "compact"
    case normal = "normal"
    case large = "large"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .compact: return String.localized("Compact")
        case .normal: return String.localized("Normal")
        case .large: return String.localized("Large")
        }
    }
    
    var icon: String {
        switch self {
        case .compact: return "rectangle.compress.vertical"
        case .normal: return "rectangle"
        case .large: return "rectangle.expand.vertical"
        }
    }
}

// MARK: - Home Widget Type
enum HomeWidgetType: String, CaseIterable, Codable, Identifiable {
    case quickActions = "quickActions"
    case status = "status"
    case atAGlance = "atAGlance"
    case recentApps = "recentApps"
    case storageInfo = "storageInfo"
    case certificateStatus = "certificateStatus"
    case sourcesOverview = "sourcesOverview"
    case networkStatus = "networkStatus"
    case tips = "tips"
    case deviceInfo = "deviceInfo"
    case appStats = "appStats"
    case favoriteApps = "favoriteApps"
    case signingHistory = "signingHistory"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .quickActions: return String.localized("Quick Actions")
        case .status: return String.localized("Status")
        case .atAGlance: return String.localized("At A Glance")
        case .recentApps: return String.localized("Recent Apps")
        case .storageInfo: return String.localized("Storage Info")
        case .certificateStatus: return String.localized("Certificate Status")
        case .sourcesOverview: return String.localized("Sources Overview")
        case .networkStatus: return String.localized("Network Status")
        case .tips: return String.localized("Tips & Tricks")
        case .deviceInfo: return String.localized("Device Info")
        case .appStats: return String.localized("App Statistics")
        case .favoriteApps: return String.localized("Favorite Apps")
        case .signingHistory: return String.localized("Signing History")
        }
    }
    
    var icon: String {
        switch self {
        case .quickActions: return "bolt.fill"
        case .status: return "chart.bar.fill"
        case .atAGlance: return "eye.fill"
        case .recentApps: return "clock.fill"
        case .storageInfo: return "internaldrive.fill"
        case .certificateStatus: return "checkmark.seal.fill"
        case .sourcesOverview: return "globe.desk.fill"
        case .networkStatus: return "wifi"
        case .tips: return "lightbulb.fill"
        case .deviceInfo: return "iphone"
        case .appStats: return "chart.pie.fill"
        case .favoriteApps: return "star.fill"
        case .signingHistory: return "clock.arrow.circlepath"
        }
    }
    
    var color: Color {
        switch self {
        case .quickActions: return .orange
        case .status: return .blue
        case .atAGlance: return .purple
        case .recentApps: return .green
        case .storageInfo: return .gray
        case .certificateStatus: return .green
        case .sourcesOverview: return .cyan
        case .networkStatus: return .blue
        case .tips: return .yellow
        case .deviceInfo: return .indigo
        case .appStats: return .pink
        case .favoriteApps: return .yellow
        case .signingHistory: return .teal
        }
    }
    
    var description: String {
        switch self {
        case .quickActions: return String.localized("Quick access to common actions like adding certificates and sources")
        case .status: return String.localized("Overview of Portal version, sources, certificates, and signed apps")
        case .atAGlance: return String.localized("Detailed information about your current setup")
        case .recentApps: return String.localized("Recently signed and imported apps")
        case .storageInfo: return String.localized("Storage usage breakdown")
        case .certificateStatus: return String.localized("Active certificate details and expiration")
        case .sourcesOverview: return String.localized("Quick view of your app sources")
        case .networkStatus: return String.localized("Current network connection status")
        case .tips: return String.localized("Helpful tips and tricks for using Portal")
        case .deviceInfo: return String.localized("Information about your device")
        case .appStats: return String.localized("Statistics about your signed and imported apps")
        case .favoriteApps: return String.localized("Quick access to your favorite apps")
        case .signingHistory: return String.localized("Complete history of all signed apps with details")
        }
    }
    
    static var defaultOrder: [HomeWidgetType] {
        [.quickActions, .status, .signingHistory, .atAGlance, .recentApps, .storageInfo, .certificateStatus, .sourcesOverview, .networkStatus, .tips, .deviceInfo, .appStats, .favoriteApps]
    }
}

// MARK: - Home Widget Configuration
struct HomeWidgetConfig: Codable, Identifiable, Equatable {
    var id: String { type.rawValue }
    var type: HomeWidgetType
    var isEnabled: Bool
    var isPinned: Bool
    var order: Int
    var size: WidgetSize
    
    init(type: HomeWidgetType, isEnabled: Bool = true, isPinned: Bool = false, order: Int = 0, size: WidgetSize = .normal) {
        self.type = type
        self.isEnabled = isEnabled
        self.isPinned = isPinned
        self.order = order
        self.size = size
    }
}

// MARK: - Home Settings Manager
class HomeSettingsManager: ObservableObject {
    static let shared = HomeSettingsManager()
    
    @Published var widgets: [HomeWidgetConfig] = []
    
    private let widgetsKey = "Feather.homeWidgets"
    
    init() {
        loadWidgets()
    }
    
    func loadWidgets() {
        if let data = UserDefaults.standard.data(forKey: widgetsKey),
           let decoded = try? JSONDecoder().decode([HomeWidgetConfig].self, from: data) {
            var loadedWidgets = decoded
            let existingTypes = Set(loadedWidgets.map { $0.type })
            
            for (index, type) in HomeWidgetType.allCases.enumerated() {
                if !existingTypes.contains(type) {
                    loadedWidgets.append(HomeWidgetConfig(type: type, isEnabled: true, isPinned: false, order: loadedWidgets.count + index, size: .normal))
                }
            }
            
            widgets = loadedWidgets.sorted { $0.order < $1.order }
        } else {
            widgets = HomeWidgetType.defaultOrder.enumerated().map { index, type in
                HomeWidgetConfig(type: type, isEnabled: true, isPinned: false, order: index, size: .normal)
            }
        }
    }
    
    func saveWidgets() {
        if let encoded = try? JSONEncoder().encode(widgets) {
            UserDefaults.standard.set(encoded, forKey: widgetsKey)
        }
    }
    
    func toggleWidget(_ type: HomeWidgetType) {
        if let index = widgets.firstIndex(where: { $0.type == type }) {
            widgets[index].isEnabled.toggle()
            saveWidgets()
        }
    }
    
    func togglePin(_ type: HomeWidgetType) {
        if let index = widgets.firstIndex(where: { $0.type == type }) {
            widgets[index].isPinned.toggle()
            saveWidgets()
        }
    }
    
    func setWidgetSize(_ type: HomeWidgetType, size: WidgetSize) {
        if let index = widgets.firstIndex(where: { $0.type == type }) {
            widgets[index].size = size
            saveWidgets()
        }
    }
    
    func getWidgetSize(_ type: HomeWidgetType) -> WidgetSize {
        widgets.first(where: { $0.type == type })?.size ?? .normal
    }
    
    func moveWidget(from source: IndexSet, to destination: Int) {
        widgets.move(fromOffsets: source, toOffset: destination)
        updateOrder()
        saveWidgets()
    }
    
    func updateOrder() {
        for (index, _) in widgets.enumerated() {
            widgets[index].order = index
        }
    }
    
    func resetToDefaults() {
        widgets = HomeWidgetType.defaultOrder.enumerated().map { index, type in
            HomeWidgetConfig(type: type, isEnabled: true, isPinned: false, order: index, size: .normal)
        }
        saveWidgets()
    }
    
    var enabledWidgets: [HomeWidgetConfig] {
        widgets.filter { $0.isEnabled }.sorted { w1, w2 in
            if w1.isPinned && !w2.isPinned { return true }
            if !w1.isPinned && w2.isPinned { return false }
            return w1.order < w2.order
        }
    }
    
    func isEnabled(_ type: HomeWidgetType) -> Bool {
        widgets.first(where: { $0.type == type })?.isEnabled ?? true
    }
    
    func isPinned(_ type: HomeWidgetType) -> Bool {
        widgets.first(where: { $0.type == type })?.isPinned ?? false
    }
}

// MARK: - Profile Picture Manager
class ProfilePictureManager: ObservableObject {
    static let shared = ProfilePictureManager()
    
    @Published var profileImage: UIImage?
    
    private let profilePictureKey = "Feather.profilePicture"
    
    init() {
        loadProfilePicture()
    }
    
    func loadProfilePicture() {
        if let data = UserDefaults.standard.data(forKey: profilePictureKey),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }
    
    func saveProfilePicture(_ image: UIImage?) {
        if let image = image,
           let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: profilePictureKey)
            profileImage = image
        } else {
            UserDefaults.standard.removeObject(forKey: profilePictureKey)
            profileImage = nil
        }
    }
    
    func removeProfilePicture() {
        UserDefaults.standard.removeObject(forKey: profilePictureKey)
        profileImage = nil
    }
}

// MARK: - Home Settings View
struct HomeSettingsView: View {
    @StateObject private var settingsManager = HomeSettingsManager.shared
    @StateObject private var profileManager = ProfilePictureManager.shared
    @StateObject private var updateTrackingManager = AppUpdateTrackingManager.shared
    @State private var isReordering = false
    @State private var showResetConfirmation = false
    @State private var showImagePicker = false
    @State private var showRemoveProfileConfirmation = false
    @State private var showAppUpdateSettings = false
    @AppStorage("Feather.homeGreetingEnabled") private var greetingEnabled = true
    @AppStorage("Feather.homeAnimationsEnabled") private var animationsEnabled = true
    @AppStorage("Feather.homeCompactMode") private var compactMode = false
    @AppStorage("Feather.homeShowAppIcon") private var showAppIcon = true
    @AppStorage("Feather.useProfilePicture") private var useProfilePicture = false
    @AppStorage("Feather.showAppUpdateBanner") private var showAppUpdateBanner = true
    
    var body: some View {
        NBList(.localized("Home Settings")) {
            profilePictureSection
            appearanceSection
            appUpdateSection
            widgetOrderSection
            widgetsToggleSection
            resetSection
        }
        .alert(.localized("Reset Home Settings"), isPresented: $showResetConfirmation) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Reset"), role: .destructive) {
                resetAllSettings()
            }
        } message: {
            Text(.localized("This will reset all Home screen settings to their default values."))
        }
        .alert(.localized("Remove Profile Picture"), isPresented: $showRemoveProfileConfirmation) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Remove"), role: .destructive) {
                profileManager.removeProfilePicture()
                HapticsManager.shared.success()
            }
        } message: {
            Text(.localized("Are you sure you want to remove your profile picture?"))
        }
        .sheet(isPresented: $showImagePicker) {
            ProfileImagePicker { image in
                if let image = image {
                    profileManager.saveProfilePicture(image)
                    HapticsManager.shared.success()
                }
            }
        }
        .sheet(isPresented: $showAppUpdateSettings) {
            AppUpdateTrackingSettingsView()
        }
    }
    
    // MARK: - App Update Section
    private var appUpdateSection: some View {
        Section {
            Toggle(isOn: $showAppUpdateBanner) {
                SettingsRowView(icon: "arrow.down.app.fill", title: "Show Update Banner", color: .green)
            }
            
            NavigationLink {
                AppUpdateTrackingSettingsView()
            } label: {
                HStack {
                    SettingsRowView(icon: "app.badge.checkmark.fill", title: "Tracked Apps", color: .blue)
                    Spacer()
                    if !updateTrackingManager.trackedApps.isEmpty {
                        Text("\(updateTrackingManager.trackedApps.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text(.localized("App Update Notifications"))
        } footer: {
            Text(.localized("Track specific apps from sources and get notified when updates are available on the Home screen."))
        }
    }
    
    // MARK: - Sections
    private var profilePictureSection: some View {
        Section {
            Toggle(isOn: $useProfilePicture) {
                SettingsRowView(icon: "person.crop.circle.fill", title: "Use Profile Picture", color: .blue)
            }
            
            if useProfilePicture {
                profilePictureContent
            }
        } header: {
            Text(.localized("Profile Picture"))
        } footer: {
            Text(.localized("Set a profile picture to display on the top right of the Home tab."))
        }
    }
    
    private var profilePictureContent: some View {
        VStack(spacing: 16) {
            profileImageView
            profileActionButtons
        }
        .padding(.vertical, 8)
    }
    
    private var profileImageView: some View {
        ZStack {
            if let image = profileManager.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.accentColor.opacity(0.3), lineWidth: 2))
            } else {
                Circle()
                    .fill(Color(UIColor.tertiarySystemFill))
                    .frame(width: 88, height: 88)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                    )
            }
        }
    }
    
    private var profileActionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showImagePicker = true
            } label: {
                Label(profileManager.profileImage == nil ? "Choose" : "Change", systemImage: "photo")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            
            if profileManager.profileImage != nil {
                Button {
                    showRemoveProfileConfirmation = true
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var appearanceSection: some View {
        Section {
            Toggle(isOn: $greetingEnabled) {
                SettingsRowView(icon: "hand.wave.fill", title: "Show Greeting", color: .orange)
            }
            
            Toggle(isOn: $showAppIcon) {
                SettingsRowView(icon: "app.fill", title: "Show App Icon", color: .blue)
            }
            
            Toggle(isOn: $animationsEnabled) {
                SettingsRowView(icon: "sparkles", title: "Animations (Beta)", color: .purple)
            }
            
            Toggle(isOn: $compactMode) {
                SettingsRowView(icon: "rectangle.compress.vertical", title: "Compact Mode", color: .gray)
            }
        } header: {
            Text(.localized("Appearance"))
        } footer: {
            Text(.localized("Customize how the Home Screen looks."))
        }
    }
    
    private var widgetOrderSection: some View {
        Section {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isReordering.toggle()
                }
            } label: {
                HStack {
                    SettingsRowView(icon: "arrow.up.arrow.down", title: "Reorder Widgets", color: .orange)
                    Spacer()
                    Image(systemName: isReordering ? "checkmark.circle.fill" : "chevron.right")
                        .foregroundStyle(isReordering ? .green : .secondary)
                        .font(.system(size: 14))
                }
            }
            .foregroundStyle(.primary)
            
            if isReordering {
                ForEach(settingsManager.widgets) { widget in
                    ReorderableWidgetRow(widget: widget)
                }
                .onMove(perform: settingsManager.moveWidget)
            }
        } header: {
            Text(.localized("Widget Order"))
        } footer: {
            Text(.localized(isReordering ? "Drag to reorder widgets." : "Tap to customize widget order."))
        }
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
    }
    
    private var widgetsToggleSection: some View {
        Section {
            ForEach(HomeWidgetType.allCases) { widgetType in
                WidgetToggleRow(
                    widgetType: widgetType,
                    isEnabled: settingsManager.isEnabled(widgetType),
                    isPinned: settingsManager.isPinned(widgetType),
                    currentSize: settingsManager.getWidgetSize(widgetType),
                    onToggle: { settingsManager.toggleWidget(widgetType) },
                    onTogglePin: { settingsManager.togglePin(widgetType) },
                    onSizeChange: { size in settingsManager.setWidgetSize(widgetType, size: size) }
                )
            }
        } header: {
            Text(.localized("Widgets"))
        } footer: {
            Text(.localized("Enable or disable widgets. Long press to change size or pin."))
        }
    }
    
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                        .frame(width: 24)
                    Text(.localized("Reset To Defaults"))
                }
            }
        }
    }
    
    // MARK: - Actions
    private func resetAllSettings() {
        settingsManager.resetToDefaults()
        greetingEnabled = true
        animationsEnabled = true
        compactMode = false
        showAppIcon = true
        useProfilePicture = false
        profileManager.removeProfilePicture()
        HapticsManager.shared.success()
    }
}

// MARK: - Supporting Views
private struct SettingsRowView: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(.localized(title))
                .font(.body)
        }
    }
}

private struct ReorderableWidgetRow: View {
    let widget: HomeWidgetConfig
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: widget.type.icon)
                .font(.system(size: 14))
                .foregroundStyle(widget.type.color)
                .frame(width: 20)
            
            Text(widget.type.title)
                .font(.subheadline)
                .foregroundStyle(widget.isEnabled ? .primary : .secondary)
            
            if widget.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
            }
            
            Spacer()
            
            if !widget.isEnabled {
                Text(.localized("Off"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct WidgetToggleRow: View {
    let widgetType: HomeWidgetType
    let isEnabled: Bool
    let isPinned: Bool
    let currentSize: WidgetSize
    let onToggle: () -> Void
    let onTogglePin: () -> Void
    let onSizeChange: (WidgetSize) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(widgetType.color.opacity(0.12))
                    .frame(width: 32, height: 32)
                
                Image(systemName: widgetType.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(widgetType.color)
            }
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(widgetType.title)
                        .font(.subheadline.weight(.medium))
                    
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(.orange)
                    }
                    
                    Text(currentSize.title)
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(widgetType.color.opacity(0.7))
                        .cornerRadius(4)
                }
                
                Text(widgetType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in
                    onToggle()
                    HapticsManager.shared.softImpact()
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Menu {
                ForEach(WidgetSize.allCases) { size in
                    Button {
                        onSizeChange(size)
                        HapticsManager.shared.softImpact()
                    } label: {
                        Label(size.title, systemImage: currentSize == size ? "checkmark" : size.icon)
                    }
                }
            } label: {
                Label("Widget Size", systemImage: "rectangle.3.group")
            }
            
            Divider()
            
            Button {
                onTogglePin()
                HapticsManager.shared.softImpact()
            } label: {
                Label(
                    isPinned ? String.localized("Unpin") : String.localized("Pin to Top"),
                    systemImage: isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button {
                onToggle()
                HapticsManager.shared.softImpact()
            } label: {
                Label(
                    isEnabled ? String.localized("Disable") : String.localized("Enable"),
                    systemImage: isEnabled ? "eye.slash" : "eye"
                )
            }
        }
    }
}

// MARK: - Profile Image Picker
struct ProfileImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ProfileImagePicker
        
        init(_ parent: ProfileImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
            parent.onImagePicked(image)
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            parent.dismiss()
        }
    }
}

// MARK: - App Update Tracking Settings View
struct AppUpdateTrackingSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var updateManager = AppUpdateTrackingManager.shared
    @StateObject private var sourcesViewModel = SourcesViewModel.shared
    @State private var showAddAppSheet = false
    @State private var searchText = ""
    @State private var showRemoveConfirmation = false
    @State private var appToRemove: TrackedAppConfig?
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var sources: FetchedResults<AltSource>
    
    var body: some View {
        NavigationStack {
            List {
                // Fetch Sources Section
                fetchSourcesSection
                
                if updateManager.trackedApps.isEmpty {
                    emptyStateSection
                } else {
                    trackedAppsSection
                }
                
                addAppSection
                
                if !updateManager.availableUpdates.isEmpty {
                    availableUpdatesSection
                }
            }
            .navigationTitle("Tracked Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAppSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddAppSheet) {
                SelectAppToTrackView(sources: sourcesViewModel.sources)
            }
            .alert("Remove Tracked App", isPresented: $showRemoveConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Remove", role: .destructive) {
                    if let app = appToRemove {
                        updateManager.removeTrackedApp(bundleIdentifier: app.bundleIdentifier)
                    }
                }
            } message: {
                if let app = appToRemove {
                    Text("Are you sure you want to stop tracking \(app.appName)?")
                }
            }
            .task {
                await sourcesViewModel.fetchSources(sources)
            }
        }
    }
    
    // MARK: - Fetch Sources Section
    private var fetchSourcesSection: some View {
        Section {
            // Manual Fetch Button
            Button {
                Task {
                    await updateManager.manualFetchAllSources()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.system(size: 22))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fetch All Sources")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        if updateManager.isFetchingAllSources {
                            Text("Fetching... \(Int(updateManager.autoFetchProgress * 100))%")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        } else if let lastFetch = updateManager.lastAutoFetchDate {
                            Text("Last fetched: \(lastFetch, style: .relative) ago")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Never fetched")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if updateManager.isFetchingAllSources {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .disabled(updateManager.isFetchingAllSources)
            
            // Progress bar when fetching
            if updateManager.isFetchingAllSources {
                ProgressView(value: updateManager.autoFetchProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
            
            // Cache info
            if !updateManager.cachedApps.isEmpty {
                HStack {
                    Image(systemName: "archivebox.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(updateManager.cachedApps.count) apps cached")
                            .font(.caption)
                            .foregroundStyle(.primary)
                        
                        if let cacheDate = updateManager.lastCacheDate {
                            Text("Cache updated: \(cacheDate, style: .relative) ago")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
        } header: {
            Text("Source Data")
        } footer: {
            Text("Sources are automatically fetched every hour. Tap to manually refresh all sources and update the app cache.")
        }
    }
    
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(systemName: "app.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                Text("No Tracked Apps")
                    .font(.headline)
                
                Text("Add apps from your sources to track their updates and get notified on the Home screen.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    private var trackedAppsSection: some View {
        Section {
            ForEach(updateManager.trackedApps) { app in
                TrackedAppRow(app: app) {
                    updateManager.toggleTrackedApp(bundleIdentifier: app.bundleIdentifier)
                } onRemove: {
                    appToRemove = app
                    showRemoveConfirmation = true
                }
            }
        } header: {
            Text("Tracked Apps (\(updateManager.trackedApps.count))")
        } footer: {
            Text("Toggle apps to enable or disable update notifications. Swipe to remove.")
        }
    }
    
    private var addAppSection: some View {
        Section {
            Button {
                showAddAppSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.green)
                    Text("Add App to Track")
                }
            }
        }
    }
    
    private var availableUpdatesSection: some View {
        Section {
            ForEach(updateManager.availableUpdates) { update in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(update.appName)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(update.currentVersion) → \(update.newVersion)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    Text(update.sourceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Available Updates")
        }
    }
}

// MARK: - Tracked App Row
private struct TrackedAppRow: View {
    let app: TrackedAppConfig
    let onToggle: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            if let iconURLString = app.iconURL, let iconURL = URL(string: iconURLString) {
                AsyncImage(url: iconURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "app.fill")
                            .foregroundStyle(.blue)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.appName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(app.isEnabled ? .primary : .secondary)
                
                Text(app.sourceName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("v\(app.lastKnownVersion)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { app.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }
}

// MARK: - Select App To Track View
struct SelectAppToTrackView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var updateManager = AppUpdateTrackingManager.shared
    let sources: [AltSource: ASRepository]
    
    @State private var searchText = ""
    @State private var selectedSourceURL: String?
    @State private var isLoading = true
    
    // Use cached apps for fast loading
    private var filteredCachedApps: [CachedAppInfo] {
        var apps = updateManager.getCachedAppsFiltered(searchText: searchText, excludeTracked: true)
        
        // Filter by selected source
        if let sourceURL = selectedSourceURL {
            apps = apps.filter { $0.sourceURL == sourceURL }
        }
        
        return apps
    }
    
    // Get unique source names for filter chips
    private var availableSources: [(url: String, name: String)] {
        var seen = Set<String>()
        var result: [(url: String, name: String)] = []
        
        for app in updateManager.cachedApps {
            if !seen.contains(app.sourceURL) {
                seen.insert(app.sourceURL)
                result.append((url: app.sourceURL, name: app.sourceName))
            }
        }
        
        return result.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sourceFilterSection
                appListSection
            }
            .navigationTitle("Select App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .onAppear {
            loadAppsIfNeeded()
        }
    }
    
    private func loadAppsIfNeeded() {
        // If cache is valid, use it immediately
        if updateManager.isCacheValid() && !updateManager.cachedApps.isEmpty {
            isLoading = false
            return
        }
        
        // Otherwise, update cache from sources
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            updateManager.updateCache(from: sources)
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
    
    private var sourceFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChipButton(title: "All", isSelected: selectedSourceURL == nil) {
                    selectedSourceURL = nil
                }
                
                ForEach(availableSources, id: \.url) { source in
                    FilterChipButton(
                        title: source.name,
                        isSelected: selectedSourceURL == source.url
                    ) {
                        selectedSourceURL = source.url
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var appListSection: some View {
        List {
            if isLoading && updateManager.cachedApps.isEmpty {
                loadingSection
            } else if filteredCachedApps.isEmpty {
                emptyStateSection
            } else {
                availableAppsSection
            }
        }
        .searchable(text: $searchText, prompt: "Search apps")
    }
    
    private var loadingSection: some View {
        Section {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Loading apps...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                
                Text(searchText.isEmpty ? "No apps available" : "No apps found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
    }
    
    private var availableAppsSection: some View {
        Section {
            ForEach(filteredCachedApps) { app in
                CachedAppRow(app: app) {
                    addCachedAppToTracking(app)
                }
            }
        } header: {
            Text("Available Apps (\(filteredCachedApps.count))")
        }
    }
    
    private func addCachedAppToTracking(_ app: CachedAppInfo) {
        let config = TrackedAppConfig(
            bundleIdentifier: app.bundleIdentifier,
            appName: app.appName,
            sourceURL: app.sourceURL,
            sourceName: app.sourceName,
            lastKnownVersion: app.version ?? "1.0",
            iconURL: app.iconURL,
            isEnabled: true
        )
        
        updateManager.addTrackedApp(config)
        dismiss()
    }
}

// MARK: - Cached App Row (for fast loading)
private struct CachedAppRow: View {
    let app: CachedAppInfo
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                appIcon
                appInfo
                Spacer()
                chevron
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var appIcon: some View {
        if let iconURLString = app.iconURL, let iconURL = URL(string: iconURLString) {
            AsyncImage(url: iconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure(_):
                    placeholderIcon
                case .empty:
                    placeholderIcon
                        .overlay(ProgressView().scaleEffect(0.5))
                @unknown default:
                    placeholderIcon
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            placeholderIcon
        }
    }
    
    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.blue.opacity(0.2))
            .frame(width: 44, height: 44)
            .overlay(
                Image(systemName: "app.fill")
                    .foregroundStyle(.blue)
            )
    }
    
    private var appInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(app.appName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text(app.bundleIdentifier)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            
            HStack(spacing: 4) {
                if let version = app.version {
                    Text("v\(version)")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
                
                Text("•")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(app.sourceName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var chevron: some View {
        Image(systemName: "plus.circle.fill")
            .font(.system(size: 22))
            .foregroundStyle(.green)
    }
}

// MARK: - Filter Chip Button
private struct FilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeSettingsView()
    }
}
