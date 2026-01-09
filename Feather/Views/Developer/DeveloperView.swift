// Created by dylan on 12/30/25
// Adding auth next (todo)

import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications

// MARK: - Developer View
struct DeveloperView: View {
    @AppStorage("debugModeEnabled") private var debugModeEnabled = false
    @AppStorage("showLayoutBoundaries") private var showLayoutBoundaries = false
    @AppStorage("slowAnimations") private var slowAnimations = false
    @State private var showResetConfirmation = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NBNavigationView("Developer") {
            List {
                Section(header: Text("Diagnostics")) {
                    NavigationLink(destination: AppLogsView()) {
                        Label("App Logs", systemImage: "terminal")
                    }
                    NavigationLink(destination: NetworkInspectorView()) {
                        Label("Network Inspector", systemImage: "network")
                    }
                    NavigationLink(destination: PerformanceMonitorView()) {
                        Label("Performance Monitor", systemImage: "speedometer")
                    }
                    Toggle("Debug Mode", isOn: $debugModeEnabled)
                        .onChange(of: debugModeEnabled) { newValue in
                            // Enable verbose logging
                        }
                    Toggle("Verbose Logging", isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "verboseLogging") },
                        set: { UserDefaults.standard.set($0, forKey: "verboseLogging") }
                    ))
                }
                
                Section(header: Text("Analysis")) {
                    NavigationLink(destination: IPAInspectorView()) {
                        Label("IPA Inspector", systemImage: "doc.zipper")
                    }
                    NavigationLink(destination: IPAIntegrityCheckerView()) {
                        Label("Integrity Checker", systemImage: "checkmark.shield")
                    }
                    NavigationLink(destination: FileSystemBrowserView()) {
                        Label("File System", systemImage: "folder")
                    }
                }
                
                Section(header: Text("Data")) {
                    NavigationLink(destination: SourceDataView()) {
                        Label("Source Data", systemImage: "server.rack")
                    }
                    NavigationLink(destination: AppStateView()) {
                        Label("App State & Storage", systemImage: "memorychip")
                    }
                    NavigationLink(destination: UserDefaultsEditorView()) {
                        Label("UserDefaults Editor", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(destination: CoreDataInspectorView()) {
                        Label("CoreData Inspector", systemImage: "cylinder.split.1x2")
                    }
                }
                
                Section(header: Text("UI Debugging")) {
                    Toggle("Show Layout Boundaries", isOn: $showLayoutBoundaries)
                        .onChange(of: showLayoutBoundaries) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "_UIConstraintBasedLayoutPlayground")
                        }
                    
                    Toggle("Slow Animations", isOn: $slowAnimations)
                        .onChange(of: slowAnimations) { newValue in
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                windowScene.windows.first?.layer.speed = newValue ? 0.1 : 1.0
                            }
                        }
                }
                
                Section {
                    NavigationLink(destination: FeatureFlagsView()) {
                        Label("Feature Flags", systemImage: "flag")
                    }
                    
                    Toggle(isOn: Binding(
                        get: { UserDefaults.standard.bool(forKey: "forceShowGuides") },
                        set: { UserDefaults.standard.set($0, forKey: "forceShowGuides") }
                    )) {
                        Label("Force Show Guides", systemImage: "book.circle")
                    }
                    
                    Button {
                        // Reset onboarding flag to show it again
                        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                        HapticsManager.shared.success()
                        
                        // Log the action
                        AppLogManager.shared.info("Onboarding reset - user will see onboarding again on next launch", category: "Developer")
                        
                        // Show confirmation alert
                        UIAlertController.showAlertWithOk(
                            title: "Onboarding Reset",
                            message: "The onboarding screen will be shown when you restart the app."
                        )
                    } label: {
                        Label("Replay Onboarding", systemImage: "arrow.counterclockwise.circle")
                    }
                } header: {
                    Text("Experiments")
                }
                
                Section(header: Text("Notifications")) {
                    NavigationLink(destination: TestNotificationsView()) {
                        Label("Test Notifications", systemImage: "bell.badge")
                    }
                }
                
                Section(header: Text("Danger Zone")) {
                    Button(role: .destructive) {
                        resetAppState()
                    } label: {
                        Label("Reset App State", systemImage: "trash")
                    }
                    
                    Button(role: .destructive) {
                        resetSettings()
                    } label: {
                        Label("Reset Settings", systemImage: "gear.badge.xmark")
                    }
                    
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset All Data", systemImage: "exclamationmark.triangle.fill")
                    }
                }
                
                Section {
                    Button("Lock Developer Mode") {
                        UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
                    }
                    .foregroundStyle(.red)
                }
            }
        }
        .alert("Reset All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will delete all sources, apps, settings, and certificates. This action cannot be undone.")
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                // Hide developer mode when app goes to background or becomes inactive
                UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
            }
        }
    }
    
    private func resetAppState() {
        // Implementation to clear cache, etc.
    }
    
    private func resetSettings() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }
    
    private func resetAllData() {
        resetAppState()
        resetSettings()
        // Add more reset logic here (e.g. delete CoreData store)
    }
}

// MARK: - Subviews

struct NetworkInspectorView: View {
    var body: some View {
        List {
            Text("No active requests")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Network Inspector")
    }
}

struct FileSystemBrowserView: View {
    var body: some View {
        List {
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                Text(documentsPath.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Documents")
            Text("Library")
            Text("tmp")
        }
        .navigationTitle("File System")
    }
}

struct UserDefaultsEditorView: View {
    var body: some View {
        List {
            ForEach(Array(UserDefaults.standard.dictionaryRepresentation().keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption.monospaced())
                    Spacer()
                    Text("\(String(describing: UserDefaults.standard.object(forKey: key) ?? "nil"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .navigationTitle("UserDefaults")
    }
}

struct AppLogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogEntry.LogLevel?
    @State private var selectedCategory: String?
    @State private var showFilters = false
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var autoScroll = true
    
    var filteredLogs: [LogEntry] {
        logManager.filteredLogs(searchText: searchText, level: selectedLevel, category: selectedCategory)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search Logs", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // All logs
                        FilterPill(
                            title: "All",
                            isSelected: selectedLevel == nil,
                            count: logManager.logs.count
                        ) {
                            selectedLevel = nil
                        }
                        
                        // Level filters
                        ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                            let count = logManager.logs.filter { $0.level == level }.count
                            if count > 0 {
                                FilterPill(
                                    title: level.rawValue,
                                    icon: level.icon,
                                    isSelected: selectedLevel == level,
                                    count: count
                                ) {
                                    selectedLevel = selectedLevel == level ? nil : level
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding()
            
            Divider()
            
            // Logs List
            if filteredLogs.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text(logManager.logs.isEmpty ? "No Logs Yet" : "No Matching Logs")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    if !logManager.logs.isEmpty {
                        Text("Try adjusting your search or filters")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(filteredLogs) { log in
                                LogEntryRow(entry: log)
                                    .id(log.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: filteredLogs.count) { _ in
                        if autoScroll, let lastLog = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("App Logs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Auto-scroll toggle
                Button(action: { autoScroll.toggle() }) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                }
                
                // Clear logs
                Button(role: .destructive, action: {
                    logManager.clearLogs()
                }) {
                    Image(systemName: "trash")
                }
                
                // Share menu
                Menu {
                    Button(action: shareAsText) {
                        Label("Share as Text", systemImage: "doc.text")
                    }
                    
                    Button(action: shareAsJSON) {
                        Label("Share as JSON", systemImage: "doc.badge.gearshape")
                    }
                    
                    Button(action: copyToClipboard) {
                        Label("Copy to Clipboard", systemImage: "doc.on.clipboard")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [shareText])
        }
        .onAppear {
            // Add initial log
            if logManager.logs.isEmpty {
                logManager.info("App Logs view initialized", category: "Developer")
            }
        }
    }
    
    private func shareAsText() {
        shareText = logManager.exportLogs()
        showShareSheet = true
    }
    
    private func shareAsJSON() {
        if let jsonData = logManager.exportLogsAsJSON(),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            shareText = jsonString
            showShareSheet = true
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = logManager.exportLogs()
        logManager.success("Logs copied to clipboard", category: "Developer")
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Text(icon)
                }
                Text(title)
                    .font(.caption.bold())
                Text("(\(count))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Log Entry Row
struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                // Level indicator
                Text(entry.level.icon)
                    .font(.system(size: 12))
                
                VStack(alignment: .leading, spacing: 2) {
                    // Main message
                    HStack {
                        Text(entry.formattedTimestamp)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                        
                        Text("[\(entry.category)]")
                            .font(.caption2.bold())
                            .foregroundStyle(.blue)
                        
                        Spacer()
                    }
                    
                    Text(entry.message)
                        .font(.caption.monospaced())
                        .foregroundStyle(levelColor(entry.level))
                    
                    // Expanded details
                    if isExpanded {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 4) {
                            DetailRow(label: "Level", value: entry.level.rawValue)
                            DetailRow(label: "Category", value: entry.category)
                            DetailRow(label: "File", value: entry.file)
                            DetailRow(label: "Function", value: entry.function)
                            DetailRow(label: "Line", value: "\(entry.line)")
                        }
                        .font(.caption2.monospaced())
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(levelBackgroundColor(entry.level))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(levelBorderColor(entry.level), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
    }
    
    private func levelColor(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
    
    private func levelBackgroundColor(_ level: LogEntry.LogLevel) -> Color {
        levelColor(level).opacity(0.05)
    }
    
    private func levelBorderColor(_ level: LogEntry.LogLevel) -> Color {
        levelColor(level).opacity(0.2)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Activity View Controller
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct IPAInspectorView: View {
    @State private var isImporting = false
    @State private var selectedFile: URL?
    @State private var ipaInfo: IPAInfo?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var showFileBrowser = false
    
    struct IPAInfo {
        let fileName: String
        let fileSize: String
        let infoPlist: [String: Any]?
        let bundleID: String?
        let version: String?
        let buildNumber: String?
        let displayName: String?
        let minIOSVersion: String?
        let dylibs: [String]
        let frameworks: [String]
        let plugins: [String]
        let entitlements: [String: Any]?
        let provisioning: ProvisioningInfo?
        let fileStructure: [String]
        let appIconData: Data?
        let limitations: [String]
    }
    
    struct ProvisioningInfo {
        let teamName: String?
        let teamID: String?
        let expirationDate: Date?
        let appIDName: String?
        let provisionedDevices: [String]?
        let entitlements: [String: Any]?
    }
    
    var body: some View {
        List {
            // Import Section
            Section(header: Text("Import")) {
                Button(action: { isImporting = true }) {
                    HStack {
                        Image(systemName: "doc.zipper")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Select IPA File")
                                .font(.headline)
                            if let file = selectedFile {
                                Text(file.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("No File Selected")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        if isAnalyzing {
                            ProgressView()
                        }
                    }
                }
            }
            
            // Error Section
            if let error = errorMessage {
                Section(header: Text("Error")) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Basic Info Section
            if let info = ipaInfo {
                // App Icon Section (if available)
                if let iconData = info.appIconData, let iconImage = UIImage(data: iconData) {
                    Section {
                        HStack {
                            Spacer()
                            Image(uiImage: iconImage)
                                .resizable()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(radius: 4)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                
                Section(header: Text("Basic Information")) {
                    DeveloperInfoRow(label: "File Name", value: info.fileName)
                    DeveloperInfoRow(label: "File Size", value: info.fileSize)
                    if let bundleID = info.bundleID {
                        DeveloperInfoRow(label: "Bundle ID", value: bundleID)
                    }
                    if let displayName = info.displayName {
                        DeveloperInfoRow(label: "App Name", value: displayName)
                    }
                    if let version = info.version {
                        DeveloperInfoRow(label: "Version", value: version)
                    }
                    if let buildNumber = info.buildNumber {
                        DeveloperInfoRow(label: "Build Number", value: buildNumber)
                    }
                    if let minVersion = info.minIOSVersion {
                        DeveloperInfoRow(label: "Min iOS", value: minVersion)
                    }
                }
                
                // Provisioning Profile Section
                if let provisioning = info.provisioning {
                    Section(header: Text("Provisioning Profile")) {
                        if let teamName = provisioning.teamName {
                            DeveloperInfoRow(label: "Team Name", value: teamName)
                        }
                        if let teamID = provisioning.teamID {
                            DeveloperInfoRow(label: "Team ID", value: teamID)
                        }
                        if let appIDName = provisioning.appIDName {
                            DeveloperInfoRow(label: "App ID Name", value: appIDName)
                        }
                        if let expirationDate = provisioning.expirationDate {
                            DeveloperInfoRow(
                                label: "Expires",
                                value: {
                                    let formatter = DateFormatter()
                                    formatter.dateStyle = .medium
                                    formatter.timeStyle = .short
                                    return formatter.string(from: expirationDate)
                                }()
                            )
                        }
                        if let devices = provisioning.provisionedDevices {
                            NavigationLink(destination: ListDetailView(items: devices, title: "Provisioned Devices")) {
                                HStack {
                                    Image(systemName: "iphone")
                                        .foregroundStyle(.blue)
                                    Text("\(devices.count) devices")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
                
                // Info.plist Section
                if let plist = info.infoPlist, !plist.isEmpty {
                    Section(header: Text("Info.plist")) {
                        NavigationLink(destination: PlistViewer(dictionary: plist, title: "Info.plist")) {
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(.blue)
                                Text("\(plist.count) entries")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                // Dynamic Libraries Section
                if !info.dylibs.isEmpty {
                    Section(header: Text("Dynamic Libraries (\(info.dylibs.count))"), footer: Text("Detected .dylib files that may be injected into the app.")) {
                        ForEach(info.dylibs.prefix(10), id: \.self) { dylib in
                            HStack {
                                Image(systemName: "cube.box")
                                    .foregroundStyle(.purple)
                                    .font(.caption)
                                Text(dylib)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.dylibs.count > 10 {
                            NavigationLink(destination: ListDetailView(items: info.dylibs, title: "All Dynamic Libraries")) {
                                Text("View All \(info.dylibs.count) Libraries")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                // Frameworks Section
                if !info.frameworks.isEmpty {
                    Section(header: Text("Frameworks (\(info.frameworks.count))")) {
                        ForEach(info.frameworks.prefix(10), id: \.self) { framework in
                            HStack {
                                Image(systemName: "shippingbox")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(framework)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.frameworks.count > 10 {
                            NavigationLink(destination: ListDetailView(items: info.frameworks, title: "All Frameworks")) {
                                Text("View All \(info.frameworks.count) Frameworks")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                // Plugins Section
                if !info.plugins.isEmpty {
                    Section(header: Text("Plugins/Extensions (\(info.plugins.count))")) {
                        ForEach(info.plugins, id: \.self) { plugin in
                            HStack {
                                Image(systemName: "puzzlepiece.extension")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(plugin)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                
                // Entitlements Section
                if let entitlements = info.entitlements, !entitlements.isEmpty {
                    Section(header: Text("Entitlements (From Provisioning Profile)"), footer: Text("Entitlements declared in the embedded provisioning profile.")) {
                        NavigationLink(destination: PlistViewer(dictionary: entitlements, title: "Entitlements")) {
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .foregroundStyle(.green)
                                Text("\(entitlements.count) entitlements")
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                
                // File Structure Section
                if !info.fileStructure.isEmpty {
                    Section(header: Text("File Structure (\(info.fileStructure.count) files)")) {
                        ForEach(info.fileStructure.prefix(15), id: \.self) { file in
                            HStack {
                                Image(systemName: fileIcon(for: file))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(file)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                            }
                        }
                        if info.fileStructure.count > 15 {
                            NavigationLink(destination: ListDetailView(items: info.fileStructure, title: "All Files")) {
                                Text("View all \(info.fileStructure.count) files")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
                
                // Limitations Section
                Section(header: Text("Limitations"), footer: Text("Some advanced analysis features require macOS command-line tools or specialized security frameworks not available in the iOS sandbox.")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.orange)
                            Text("iOS On-Device Limitations")
                                .font(.subheadline.bold())
                        }
                        
                        ForEach(info.limitations, id: \.self) { limitation in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(limitation)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("IPA Inspector")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isImporting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    selectedFile = url
                    analyzeIPA(url: url)
                }
            )
            .ignoresSafeArea()
        }
    }
    
    private func analyzeIPA(url: URL) {
        isAnalyzing = true
        errorMessage = nil
        ipaInfo = nil
        
        AppLogManager.shared.info("Analyzing IPA: \(url.lastPathComponent)", category: "IPA Inspector")
        
        Task {
            do {
                let info = try await extractIPAInfo(from: url)
                await MainActor.run {
                    ipaInfo = info
                    isAnalyzing = false
                    AppLogManager.shared.success("Successfully analyzed IPA: \(url.lastPathComponent)", category: "IPA Inspector")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    AppLogManager.shared.error("Failed to analyze IPA: \(error.localizedDescription)", category: "IPA Inspector")
                }
            }
        }
    }
    
    private func extractIPAInfo(from url: URL) async throws -> IPAInfo {
        let fileManager = FileManager.default
        
        // Start accessing security-scoped resource FIRST
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "IPAInspector", code: -3, userInfo: [NSLocalizedDescriptionKey: "Cannot access file. Permission denied."])
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attributes[.size] as? UInt64 ?? 0), countStyle: .file)
        
        // Create temp directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Extract IPA using ZIPFoundation
        do {
            try fileManager.unzipItem(at: url, to: tempDir)
        } catch {
            throw NSError(domain: "IPAInspector", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to extract IPA: \(error.localizedDescription)"])
        }
        
        // Find .app bundle in Payload directory
        let payloadDir = tempDir.appendingPathComponent("Payload")
        guard let appBundle = try fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) else {
            throw NSError(domain: "IPAInspector", code: -1, userInfo: [NSLocalizedDescriptionKey: "No .app bundle found in IPA"])
        }
        
        // Parse Info.plist
        let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
        var infoPlist: [String: Any]?
        var bundleID: String?
        var version: String?
        var buildNumber: String?
        var displayName: String?
        var minIOSVersion: String?
        
        if let plistData = try? Data(contentsOf: infoPlistURL),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
            infoPlist = plist
            bundleID = plist["CFBundleIdentifier"] as? String
            version = plist["CFBundleShortVersionString"] as? String
            buildNumber = plist["CFBundleVersion"] as? String
            displayName = plist["CFBundleDisplayName"] as? String ?? plist["CFBundleName"] as? String
            minIOSVersion = plist["MinimumOSVersion"] as? String
        }
        
        // Find dynamic libraries (.dylib files in main bundle)
        var dylibs: [String] = []
        if let dylibFiles = try? fileManager.contentsOfDirectory(at: appBundle, includingPropertiesForKeys: nil) {
            dylibs = dylibFiles.filter { $0.pathExtension == "dylib" }.map { $0.lastPathComponent }
        }
        
        // Find frameworks
        var frameworks: [String] = []
        let frameworksDir = appBundle.appendingPathComponent("Frameworks")
        if fileManager.fileExists(atPath: frameworksDir.path) {
            if let frameworkFiles = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                frameworks = frameworkFiles.filter { $0.pathExtension == "framework" }.map { $0.lastPathComponent }
            }
        }
        
        // Find plugins/extensions
        var plugins: [String] = []
        let pluginsDir = appBundle.appendingPathComponent("PlugIns")
        if fileManager.fileExists(atPath: pluginsDir.path) {
            if let pluginFiles = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
                plugins = pluginFiles.map { $0.lastPathComponent }
            }
        }
        
        // Extract provisioning profile information
        var provisioningInfo: ProvisioningInfo? = nil
        let provisioningURL = appBundle.appendingPathComponent("embedded.mobileprovision")
        if fileManager.fileExists(atPath: provisioningURL.path) {
            provisioningInfo = parseProvisioningProfile(at: provisioningURL)
        }
        
        // Try to extract app icon
        var appIconData: Data? = nil
        if let iconFiles = infoPlist?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = iconFiles["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFileNames = primaryIcon["CFBundleIconFiles"] as? [String] {
            // Try to find the largest icon
            for iconName in iconFileNames.reversed() {
                let iconURL = appBundle.appendingPathComponent("\(iconName).png")
                if fileManager.fileExists(atPath: iconURL.path),
                   let data = try? Data(contentsOf: iconURL) {
                    appIconData = data
                    break
                }
                // Also try with @2x and @3x
                let icon2xURL = appBundle.appendingPathComponent("\(iconName)@2x.png")
                if fileManager.fileExists(atPath: icon2xURL.path),
                   let data = try? Data(contentsOf: icon2xURL) {
                    appIconData = data
                    break
                }
            }
        }
        
        // Get file structure
        var fileStructure: [String] = []
        if let enumerator = fileManager.enumerator(at: appBundle, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let fileURL as URL in enumerator {
                if let isRegularFile = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile, isRegularFile {
                    let relativePath = fileURL.path.replacingOccurrences(of: appBundle.path + "/", with: "")
                    fileStructure.append(relativePath)
                }
            }
        }
        
        // Define limitations for iOS on-device inspection
        // macOS Only Tools (will try to add 3rd party soon)
        let limitations = [
            "Code signature validation: Not available on iOS (requires macOS security tools)",
            "Full entitlements extraction: Limited (only from provisioning profile)",
            "Binary analysis: Not available (requires specialized tools)",
            "Deep framework inspection: Limited (file listing only)"
        ]
        
        return IPAInfo(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            infoPlist: infoPlist,
            bundleID: bundleID,
            version: version,
            buildNumber: buildNumber,
            displayName: displayName,
            minIOSVersion: minIOSVersion,
            dylibs: dylibs,
            frameworks: frameworks,
            plugins: plugins,
            entitlements: provisioningInfo?.entitlements,
            provisioning: provisioningInfo,
            fileStructure: fileStructure.sorted(),
            appIconData: appIconData,
            limitations: limitations
        )
    }
    
    private func parseProvisioningProfile(at url: URL) -> ProvisioningInfo? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        // Provisioning profiles contain XML plist data between <plist> tags
        // Extract the plist portion
        guard let dataString = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Find plist content
        guard let plistStart = dataString.range(of: "<?xml"),
              let plistEnd = dataString.range(of: "</plist>") else {
            return nil
        }
        
        let plistString = String(dataString[plistStart.lowerBound...plistEnd.upperBound])
        guard let plistData = plistString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] else {
            return nil
        }
        
        let teamName = plist["TeamName"] as? String
        let teamID = (plist["TeamIdentifier"] as? [String])?.first
        let expirationDate = plist["ExpirationDate"] as? Date
        let appIDName = plist["AppIDName"] as? String
        let provisionedDevices = plist["ProvisionedDevices"] as? [String]
        let entitlements = plist["Entitlements"] as? [String: Any]
        
        return ProvisioningInfo(
            teamName: teamName,
            teamID: teamID,
            expirationDate: expirationDate,
            appIDName: appIDName,
            provisionedDevices: provisionedDevices,
            entitlements: entitlements
        )
    }
    
    private func fileIcon(for filename: String) -> String {
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "plist": return "doc.text"
        case "png", "jpg", "jpeg": return "photo"
        case "dylib": return "cube.box"
        case "framework": return "shippingbox"
        case "nib", "storyboard", "xib": return "square.grid.3x3"
        case "strings": return "text.quote"
        case "html", "css", "js": return "globe"
        case "json", "xml": return "doc.badge.gearshape"
        default: return "doc"
        }
    }
}

// MARK: - Supporting Views

struct DeveloperInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ListDetailView: View {
    let items: [String]
    let title: String
    @State private var searchText = ""
    
    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredItems, id: \.self) { item in
                Text(item)
                    .font(.caption.monospaced())
            }
        }
        .searchable(text: $searchText, prompt: "Search...")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PlistViewer: View {
    let dictionary: [String: Any]
    let title: String
    @State private var searchText = ""
    
    var filteredKeys: [String] {
        let keys = dictionary.keys.sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            ForEach(filteredKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 4) {
                    Text(key)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(String(describing: dictionary[key] ?? ""))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
        }
        .searchable(text: $searchText, prompt: "Search Keys...")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IPAIntegrityCheckerView: View {
    var body: some View {
        Text("Integrity Checker Placeholder")
            .navigationTitle("Integrity Checker")
    }
}

struct SourceDataView: View {
    var body: some View {
        List {
            ForEach(Storage.shared.getSources(), id: \.self) { source in
                NavigationLink(destination: JSONViewer(json: source.description)) {
                    Text(source.name ?? "Unknown")
                }
            }
        }
        .navigationTitle("Source Data")
    }
}

struct JSONViewer: View {
    let json: String
    var body: some View {
        ScrollView {
            Text(json)
                .font(.caption.monospaced())
                .padding()
        }
        .navigationTitle("JSON")
    }
}

struct AppStateView: View {
    var body: some View {
        List {
            Section(header: Text("Storage")) {
                Text("Documents: \(getDocumentsSize())")
                Text("Cache: \(getCacheSize())")
            }
        }
        .navigationTitle("App State")
    }
    
    func getDocumentsSize() -> String {
        // Calculate size
        return "12.5 MB"
    }
    
    func getCacheSize() -> String {
        return "4.2 MB"
    }
}

struct FeatureFlagsView: View {
    @AppStorage("feature_enhancedAnimations") var enhancedAnimations = false
    @AppStorage("feature_advancedSigning") var advancedSigning = false
    
    var body: some View {
        List {
            Section {
                Toggle("Enhanced Animations", isOn: $enhancedAnimations)
            } header: {
                Text("Performance")
            }
            
            Section {
                Toggle("Advanced Signing Options", isOn: $advancedSigning)
            } header: {
                Text("Signing")
            }
        }
        .navigationTitle("Feature Flags")
    }
}

struct PerformanceMonitorView: View {
    @State private var cpuUsage: Double = 0.0
    @State private var memoryUsage: String = "0 MB"
    @State private var diskSpace: String = "0 GB"
    @State private var timer: Timer?
    
    var body: some View {
        List {
            Section(header: Text("System Resources")) {
                HStack {
                    Label("CPU Usage", systemImage: "cpu")
                    Spacer()
                    Text("\(Int(cpuUsage))%")
                        .foregroundStyle(cpuUsage > 80 ? .red : cpuUsage > 50 ? .orange : .green)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Memory", systemImage: "memorychip")
                    Spacer()
                    Text(memoryUsage)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Label("Disk Space", systemImage: "internaldrive")
                    Spacer()
                    Text(diskSpace)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("App Performance")) {
                HStack {
                    Label("Frame Rate", systemImage: "waveform.path.ecg")
                    Spacer()
                    Text("60 FPS")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Label("Launch Time", systemImage: "timer")
                    Spacer()
                    Text("0.8s")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Performance Monitor")
        .onAppear {
            updateMetrics()
            timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                updateMetrics()
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func updateMetrics() {
        // Get CPU usage - using host_processor_info
        var numCPUs: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var usage: Double = 0.0
        
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCpuInfo)
        
        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            let cpuLoadInfo = cpuInfo.withMemoryRebound(to: processor_cpu_load_info_t.self, capacity: Int(numCPUs)) { $0 }
            
            var totalUser: UInt32 = 0
            var totalSystem: UInt32 = 0
            var totalIdle: UInt32 = 0
            var totalNice: UInt32 = 0
            
            for i in 0..<Int(numCPUs) {
                let cpuLoad = cpuLoadInfo[i]
                // CPU dev data (not for regular user)
                // CPU_STATE_USER = 0, CPU_STATE_SYSTEM = 1, CPU_STATE_IDLE = 2, CPU_STATE_NICE = 3
                totalUser += cpuLoad.pointee.cpu_ticks.0    // CPU_STATE_USER
                totalSystem += cpuLoad.pointee.cpu_ticks.1  // CPU_STATE_SYSTEM
                totalIdle += cpuLoad.pointee.cpu_ticks.2    // CPU_STATE_IDLE
                totalNice += cpuLoad.pointee.cpu_ticks.3    // CPU_STATE_NICE
            }
            
            let totalTicks = totalUser + totalSystem + totalIdle + totalNice
            if totalTicks > 0 {
                let usedTicks = totalUser + totalSystem + totalNice
                usage = Double(usedTicks) / Double(totalTicks) * 100.0
            }
            
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(Int(numCpuInfo) * MemoryLayout<integer_t>.stride))
        }
        
        cpuUsage = min(usage, 100.0)
        
        // Get memory info
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            memoryUsage = String(format: "%.1f MB", usedMB)
        }
        
        // Get disk space
        if let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
            let freeGB = Double(truncating: freeSpace) / 1024.0 / 1024.0 / 1024.0
            diskSpace = String(format: "%.1f GB Free", freeGB)
        }
    }
}

struct CoreDataInspectorView: View {
    var body: some View {
        List {
            Section(header: Text("Entities")) {
                NavigationLink("Certificates") {
                    EntityDetailView(entityName: "Certificate")
                }
                NavigationLink("Sources") {
                    EntityDetailView(entityName: "AltSource")
                }
                NavigationLink("Signed Apps") {
                    EntityDetailView(entityName: "Signed")
                }
                NavigationLink("Imported Apps") {
                    EntityDetailView(entityName: "Imported")
                }
            }
            
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Certificates")
                    Spacer()
                    Text("\(Storage.shared.getCertificates().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Sources")
                    Spacer()
                    Text("\(Storage.shared.getSources().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Signed Apps")
                    Spacer()
                    Text("\(Storage.shared.getSignedApps().count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("CoreData Inspector")
    }
}

struct EntityDetailView: View {
    let entityName: String
    
    var body: some View {
        List {
            Text("Entity: \(entityName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            // Add more detailed entity inspection here
        }
        .navigationTitle(entityName)
    }
}

// MARK: - Test Notifications View
struct TestNotificationsView: View {
    @State private var isTestingNotification = false
    @State private var countdown: Int = 3
    @State private var showResultDialog = false
    @State private var notificationSent = false
    @State private var debugInfo: [String] = []
    @State private var timer: Timer?
    
    var body: some View {
        List {
            Section(header: Text("Test Notifications"), footer: Text("This will send a test notification after a 3-second countdown. Make sure notifications are enabled for Feather in Settings.")) {
                Button {
                    startNotificationTest()
                } label: {
                    HStack {
                        Spacer()
                        if isTestingNotification {
                            VStack(spacing: 8) {
                                ProgressView()
                                Text("Sending in \(countdown)...")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Label("Send Test Notification", systemImage: "bell.badge")
                                .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .disabled(isTestingNotification)
            }
            
            if !debugInfo.isEmpty {
                Section(header: Text("Debug Information")) {
                    ForEach(debugInfo, id: \.self) { info in
                        Text(info)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Test Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Did you receive the notification?", isPresented: $showResultDialog) {
            Button("Yes") {
                handleYesResponse()
            }
            Button("No") {
                handleNoResponse()
            }
        } message: {
            Text("Please confirm if you received the test notification.")
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startNotificationTest() {
        isTestingNotification = true
        countdown = 3
        debugInfo.removeAll()
        notificationSent = false
        
        // Log notification permission status
        checkNotificationPermissions()
        
        // Start countdown
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            countdown -= 1
            
            if countdown == 0 {
                timer?.invalidate()
                sendTestNotification()
            }
        }
    }
    
    private func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                debugInfo.append("Notification Authorization: \(settings.authorizationStatus.debugDescription)")
                debugInfo.append("Alert Setting: \(settings.alertSetting.debugDescription)")
                debugInfo.append("Sound Setting: \(settings.soundSetting.debugDescription)")
                debugInfo.append("Badge Setting: \(settings.badgeSetting.debugDescription)")
                debugInfo.append("Notification Center Setting: \(settings.notificationCenterSetting.debugDescription)")
                debugInfo.append("Lock Screen Setting: \(settings.lockScreenSetting.debugDescription)")
                
                if settings.authorizationStatus != .authorized {
                    debugInfo.append("⚠️ WARNING: Notifications not authorized!")
                }
            }
        }
    }
    
    private func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from Feather Developer Tools."
        content.sound = .default
        content.badge = 1
        
        // Create a trigger for immediate delivery
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "feather.test.notification.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    debugInfo.append("❌ ERROR: Failed to schedule notification")
                    debugInfo.append("Error: \(error.localizedDescription)")
                    AppLogManager.shared.error("Failed to send test notification: \(error.localizedDescription)", category: "Test Notifications")
                } else {
                    debugInfo.append("✅ Notification scheduled successfully")
                    AppLogManager.shared.success("Test notification scheduled", category: "Test Notifications")
                }
                
                notificationSent = true
                isTestingNotification = false
                
                // Show result dialog after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showResultDialog = true
                }
            }
        }
    }
    
    private func handleYesResponse() {
        debugInfo.append("✅ User confirmed notification received")
        AppLogManager.shared.success("Test notification received successfully", category: "Test Notifications")
        
        UIAlertController.showAlertWithOk(
            title: "Success",
            message: "Notifications are working correctly!"
        )
    }
    
    private func handleNoResponse() {
        debugInfo.append("❌ User did not receive notification")
        AppLogManager.shared.warning("Test notification not received", category: "Test Notifications")
        
        // Collect comprehensive debugging information
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                var troubleshooting: [String] = []
                
                // Check authorization
                if settings.authorizationStatus == .notDetermined {
                    troubleshooting.append("• Notification permission not requested yet")
                } else if settings.authorizationStatus == .denied {
                    troubleshooting.append("• Notification permission denied by user")
                    troubleshooting.append("• Go to Settings > Portal > Notifications to enable")
                }
                
                // Check settings
                if settings.alertSetting == .disabled {
                    troubleshooting.append("• Alert style is disabled")
                }
                if settings.soundSetting == .disabled {
                    troubleshooting.append("• Sound is disabled")
                }
                if settings.notificationCenterSetting == .disabled {
                    troubleshooting.append("• Notification Center is disabled")
                }
                if settings.lockScreenSetting == .disabled {
                    troubleshooting.append("• Lock Screen Notifications Are Disabled")
                }
                
                // Check Do Not Disturb / Focus mode
                troubleshooting.append("• Check if Do Not Disturb or Focus mode is active")
                
                // Check app state
                let appState = UIApplication.shared.applicationState
                troubleshooting.append("• App State: \(appState == .active ? "Active (notifications may not show)" : appState == .background ? "Background" : "Inactive")")
                
                // Add pending notifications count
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    DispatchQueue.main.async {
                        troubleshooting.append("• Pending Notifications: \(requests.count)")
                        
                        UNUserNotificationCenter.current().getDeliveredNotifications { delivered in
                            DispatchQueue.main.async {
                                troubleshooting.append("• Delivered Notifications: \(delivered.count)")
                                
                                debugInfo.append(contentsOf: troubleshooting)
                                
                                // Show comprehensive alert
                                let message = troubleshooting.joined(separator: "\n")
                                UIAlertController.showAlertWithOk(
                                    title: "Notification Not Received",
                                    message: "Troubleshooting Info:\n\n\(message)\n\nCheck the Debug Information section for more details."
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UNAuthorizationStatus Extension
extension UNAuthorizationStatus {
    var debugDescription: String {
        switch self {
        case .notDetermined: return "Not Determined"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - UNNotificationSetting Extension
extension UNNotificationSetting {
    var debugDescription: String {
        switch self {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled"
        case .enabled: return "Enabled"
        @unknown default: return "Unknown"
        }
    }
}
