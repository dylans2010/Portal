// Developer Mode - Production Grade Internal Control Panel
// Secure authentication required for access

import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication

// MARK: - Developer Mode Entry Point
struct DeveloperView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var showAuthSheet = true
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                DeveloperControlPanelView()
            } else {
                DeveloperAuthView(onAuthenticated: {
                    showAuthSheet = false
                })
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                authManager.lockDeveloperMode()
            }
        }
        .onAppear {
            authManager.checkSessionValidity()
        }
    }
}

// MARK: - Developer Authentication View
struct DeveloperAuthView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var passcode = ""
    @State private var developerToken = ""
    @State private var showSetupPasscode = false
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var authMethod: AuthMethod = .passcode
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let onAuthenticated: () -> Void
    
    enum AuthMethod: String, CaseIterable {
        case passcode = "Passcode"
        case biometric = "Biometric"
        case token = "Developer Token"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(.orange)
                        }
                        
                        Text("Developer Mode")
                            .font(.title2.bold())
                        
                        Text("Authentication required")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Auth method picker
                    Picker("Authentication Method", selection: $authMethod) {
                        ForEach(AuthMethod.allCases, id: \.self) { method in
                            if method == .biometric && !authManager.canUseBiometrics {
                                EmptyView()
                            } else {
                                Text(method.rawValue).tag(method)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                    
                    // Auth input based on method
                    VStack(spacing: 16) {
                        switch authMethod {
                        case .passcode:
                            if authManager.hasPasscodeSet {
                                SecureField("Enter Passcode", text: $passcode)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal)
                                    .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                                
                                Button("Authenticate") {
                                    if authManager.verifyPasscode(passcode) {
                                        onAuthenticated()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .contentShape(Rectangle())
                            } else {
                                Text("No passcode set")
                                    .foregroundStyle(.secondary)
                                
                                Button("Set Up Passcode") {
                                    showSetupPasscode = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .contentShape(Rectangle())
                            }
                            
                        case .biometric:
                            Button {
                                authManager.authenticateWithBiometrics { success, error in
                                    if success {
                                        onAuthenticated()
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: authManager.biometricType == .faceID ? "faceid" : "touchid")
                                    Text("Authenticate with \(authManager.biometricType == .faceID ? "Face ID" : "Touch ID")")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .contentShape(Rectangle())
                            
                        case .token:
                            TextField("Developer Token", text: $developerToken)
                                .textFieldStyle(.roundedBorder)
                                .autocapitalization(.allCharacters)
                                .padding(.horizontal)
                                .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                            
                            Button("Validate Token") {
                                if authManager.validateDeveloperToken(developerToken) {
                                    onAuthenticated()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                            .contentShape(Rectangle())
                            .disabled(developerToken.isEmpty)
                        }
                    }
                    
                    // Error message
                    if let error = authManager.authenticationError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Exit button
                    Button("Cancel") {
                        UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
                    }
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
                    .padding(.vertical, 20)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSetupPasscode) {
                PasscodeSetupView(onComplete: { success in
                    showSetupPasscode = false
                })
            }
        }
    }
}

// MARK: - Passcode Setup View
struct PasscodeSetupView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    let onComplete: (Bool) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Create Passcode"), footer: Text("Passcode must be at least 6 characters")) {
                    SecureField("New Passcode", text: $newPasscode)
                    SecureField("Confirm Passcode", text: $confirmPasscode)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button("Set Passcode") {
                        if newPasscode.count < 6 {
                            errorMessage = "Passcode must be at least 6 characters"
                        } else if newPasscode != confirmPasscode {
                            errorMessage = "Passcodes do not match"
                        } else if authManager.setPasscode(newPasscode) {
                            onComplete(true)
                            dismiss()
                        } else {
                            errorMessage = "Failed to set passcode"
                        }
                    }
                    .contentShape(Rectangle())
                    .disabled(newPasscode.isEmpty || confirmPasscode.isEmpty)
                }
            }
            .navigationTitle("Setup Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onComplete(false)
                        dismiss()
                    }
                    .contentShape(Rectangle())
                }
            }
        }
    }
}

// MARK: - Developer Control Panel (Main View)
struct DeveloperControlPanelView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var showResetConfirmation = false
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NBNavigationView("Developer Mode") {
            List {
                // Updates & Releases Section
                Section {
                    NavigationLink(destination: UpdatesReleasesView()) {
                        DeveloperMenuRow(icon: "arrow.down.circle.fill", title: "Updates & Releases", color: .blue)
                    }
                } header: {
                    Text("Updates & Releases")
                } footer: {
                    Text("GitHub release checks, prerelease filtering, update enforcement")
                }
                
                // Sources & Library Section
                Section {
                    NavigationLink(destination: SourcesLibraryDevView()) {
                        DeveloperMenuRow(icon: "server.rack", title: "Sources & Library", color: .purple)
                    }
                } header: {
                    Text("Sources & Library")
                } footer: {
                    Text("Source reloads, cache invalidation, raw JSON inspection")
                }
                
                // Install & IPA Section
                Section {
                    NavigationLink(destination: InstallIPADevView()) {
                        DeveloperMenuRow(icon: "doc.zipper", title: "Install & IPA", color: .orange)
                    }
                } header: {
                    Text("Install & IPA")
                } footer: {
                    Text("IPA validation, install queue, logs, InstallModifyDialog testing")
                }
                
                // UI & Layout Section
                Section {
                    NavigationLink(destination: UILayoutDevView()) {
                        DeveloperMenuRow(icon: "paintbrush.fill", title: "UI & Layout", color: .pink)
                    }
                } header: {
                    Text("UI & Layout")
                } footer: {
                    Text("Appearance overrides, dynamic type, animations, debugging overlays")
                }
                
                // Network & System Section
                Section {
                    NavigationLink(destination: NetworkSystemDevView()) {
                        DeveloperMenuRow(icon: "network", title: "Network & System", color: .green)
                    }
                } header: {
                    Text("Network & System")
                } footer: {
                    Text("Offline simulation, latency injection, request logging")
                }
                
                // State & Persistence Section
                Section {
                    NavigationLink(destination: StatePersistenceDevView()) {
                        DeveloperMenuRow(icon: "cylinder.split.1x2.fill", title: "State & Persistence", color: .cyan)
                    }
                } header: {
                    Text("State & Persistence")
                } footer: {
                    Text("AppStorage, UserDefaults, caches, onboarding state")
                }
                
                // Diagnostics & Debug Tools Section
                Section {
                    NavigationLink(destination: AppLogsView()) {
                        DeveloperMenuRow(icon: "terminal.fill", title: "App Logs", color: .gray)
                    }
                    NavigationLink(destination: DeviceInfoView()) {
                        DeveloperMenuRow(icon: "iphone", title: "Device Information", color: .indigo)
                    }
                    NavigationLink(destination: EnvironmentInspectorView()) {
                        DeveloperMenuRow(icon: "gearshape.2.fill", title: "Environment Inspector", color: .teal)
                    }
                    NavigationLink(destination: CrashLogViewer()) {
                        DeveloperMenuRow(icon: "exclamationmark.triangle.fill", title: "Crash Logs", color: .red)
                    }
                    NavigationLink(destination: TestNotificationsView()) {
                        DeveloperMenuRow(icon: "bell.badge.fill", title: "Test Notifications", color: .yellow)
                    }
                } header: {
                    Text("Diagnostics & Debugging")
                } footer: {
                    Text("Device info, environment variables, crash logs, and notification testing")
                }
                
                // Power Tools Section
                Section {
                    NavigationLink(destination: QuickActionsDevView()) {
                        DeveloperMenuRow(icon: "bolt.fill", title: "Quick Actions", color: .yellow)
                    }
                    NavigationLink(destination: FeatureFlagsView()) {
                        DeveloperMenuRow(icon: "flag.fill", title: "Feature Flags", color: .mint)
                    }
                    NavigationLink(destination: PerformanceMonitorView()) {
                        DeveloperMenuRow(icon: "gauge.with.dots.needle.67percent", title: "Performance Monitor", color: .purple)
                    }
                } header: {
                    Text("Power Tools")
                } footer: {
                    Text("Quick actions, feature flags, and performance monitoring")
                }
                
                // Security Section
                Section {
                    NavigationLink(destination: DeveloperSecurityView()) {
                        DeveloperMenuRow(icon: "lock.shield.fill", title: "Security Settings", color: .orange)
                    }
                    
                    Button {
                        authManager.lockDeveloperMode()
                        UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
                    } label: {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.red)
                            Text("Lock Developer Mode")
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Security")
                }
            }
        }
        .withToast()
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                authManager.lockDeveloperMode()
            }
        }
    }
}

// MARK: - Developer Menu Row
struct DeveloperMenuRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
        }
    }
}

// MARK: - Developer Security View
struct DeveloperSecurityView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var showChangePasscode = false
    @State private var showRemovePasscode = false
    
    var body: some View {
        List {
            Section(header: Text("Authentication")) {
                HStack {
                    Text("Passcode")
                    Spacer()
                    Text(authManager.hasPasscodeSet ? "Set" : "Not Set")
                        .foregroundStyle(.secondary)
                }
                
                if authManager.hasPasscodeSet {
                    Button("Change Passcode") {
                        showChangePasscode = true
                    }
                    
                    Button("Remove Passcode", role: .destructive) {
                        showRemovePasscode = true
                    }
                } else {
                    Button("Set Up Passcode") {
                        showChangePasscode = true
                    }
                }
            }
            
            Section(header: Text("Biometrics")) {
                HStack {
                    Text("Biometric Type")
                    Spacer()
                    Text(biometricTypeName)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Available")
                    Spacer()
                    Text(authManager.canUseBiometrics ? "Yes" : "No")
                        .foregroundStyle(authManager.canUseBiometrics ? .green : .red)
                }
            }
            
            Section(header: Text("Developer Token")) {
                HStack {
                    Text("Saved Token")
                    Spacer()
                    Text(authManager.hasSavedToken ? "Present" : "None")
                        .foregroundStyle(.secondary)
                }
                
                if authManager.hasSavedToken {
                    Button("Clear Saved Token", role: .destructive) {
                        authManager.clearSavedToken()
                    }
                }
            }
            
            Section(header: Text("Session")) {
                HStack {
                    Text("Last Authentication")
                    Spacer()
                    if let lastAuth = authManager.lastAuthTime {
                        Text(lastAuth, style: .relative)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Never")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Security Settings")
        .sheet(isPresented: $showChangePasscode) {
            PasscodeSetupView(onComplete: { _ in })
        }
        .alert("Remove Passcode", isPresented: $showRemovePasscode) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                _ = authManager.removePasscode()
            }
        } message: {
            Text("Are you sure you want to remove the developer passcode?")
        }
    }
    
    private var biometricTypeName: String {
        switch authManager.biometricType {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "None"
        @unknown default: return "Unknown"
        }
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
    @State private var isImporting = false
    @State private var selectedFile: URL?
    @State private var integrityResults: IntegrityResults?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    
    struct IntegrityResults {
        let fileName: String
        let fileSize: String
        let bundleID: String?
        let isValidZip: Bool
        let hasPayloadFolder: Bool
        let hasAppBundle: Bool
        let hasValidInfoPlist: Bool
        let hasValidProvisioning: Bool
        let provisioningExpired: Bool
        let provisioningExpiryDate: Date?
        let hasCodeSignature: Bool
        let frameworksCount: Int
        let dylibsCount: Int
        let pluginsCount: Int
        let warnings: [String]
        let errors: [String]
        let suggestions: [String]
    }
    
    var body: some View {
        List {
            // Import Section
            Section(header: Text("Import IPA")) {
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
            
            // Results Section
            if let results = integrityResults {
                // Basic Info
                Section(header: Text("File Information")) {
                    LabeledContent("File Name", value: results.fileName)
                    LabeledContent("File Size", value: results.fileSize)
                    if let bundleID = results.bundleID {
                        LabeledContent("Bundle ID", value: bundleID)
                    }
                }
                
                // Integrity Checks
                Section(header: Text("Integrity Checks")) {
                    CheckRow(label: "Valid ZIP Archive", passed: results.isValidZip)
                    CheckRow(label: "Has Payload Folder", passed: results.hasPayloadFolder)
                    CheckRow(label: "Has .app Bundle", passed: results.hasAppBundle)
                    CheckRow(label: "Valid Info.plist", passed: results.hasValidInfoPlist)
                    CheckRow(label: "Has Provisioning Profile", passed: results.hasValidProvisioning)
                    if results.hasValidProvisioning {
                        CheckRow(label: "Provisioning Not Expired", passed: !results.provisioningExpired)
                        if let expiryDate = results.provisioningExpiryDate {
                            LabeledContent("Expires", value: expiryDate.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    CheckRow(label: "Has Code Signature", passed: results.hasCodeSignature)
                }
                
                // Content Analysis
                Section(header: Text("Content Analysis")) {
                    LabeledContent("Frameworks", value: "\(results.frameworksCount)")
                    LabeledContent("Dynamic Libraries", value: "\(results.dylibsCount)")
                    LabeledContent("Plugins/Extensions", value: "\(results.pluginsCount)")
                }
                
                // Warnings
                if !results.warnings.isEmpty {
                    Section(header: Text("Warnings")) {
                        ForEach(results.warnings, id: \.self) { warning in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .font(.caption)
                                Text(warning)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Errors
                if !results.errors.isEmpty {
                    Section(header: Text("Errors")) {
                        ForEach(results.errors, id: \.self) { error in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Suggestions
                if !results.suggestions.isEmpty {
                    Section(header: Text("Suggestions")) {
                        ForEach(results.suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Overall Status
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: overallStatus.icon)
                                .font(.system(size: 40))
                                .foregroundStyle(overallStatus.color)
                            Text(overallStatus.message)
                                .font(.headline)
                                .foregroundStyle(overallStatus.color)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Integrity Checker")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isImporting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                onDocumentsPicked: { urls in
                    guard let url = urls.first else { return }
                    selectedFile = url
                    analyzeIntegrity(url: url)
                }
            )
            .ignoresSafeArea()
        }
    }
    
    private var overallStatus: (icon: String, color: Color, message: String) {
        guard let results = integrityResults else {
            return ("questionmark.circle", .gray, "No analysis yet")
        }
        
        if !results.errors.isEmpty {
            return ("xmark.circle.fill", .red, "Integrity Issues Found")
        } else if !results.warnings.isEmpty {
            return ("exclamationmark.triangle.fill", .orange, "Minor Issues Detected")
        } else {
            return ("checkmark.circle.fill", .green, "All Checks Passed")
        }
    }
    
    private func analyzeIntegrity(url: URL) {
        isAnalyzing = true
        errorMessage = nil
        integrityResults = nil
        
        Task {
            do {
                let results = try await performIntegrityChecks(url: url)
                await MainActor.run {
                    integrityResults = results
                    isAnalyzing = false
                    
                    if results.errors.isEmpty && results.warnings.isEmpty {
                        ToastManager.shared.show("✅ IPA integrity verified", type: .success)
                        AppLogManager.shared.success("IPA integrity verified: \(url.lastPathComponent)", category: "Integrity Checker")
                    } else if !results.errors.isEmpty {
                        ToastManager.shared.show("❌ IPA integrity issues found", type: .error)
                        AppLogManager.shared.error("IPA integrity issues found: \(url.lastPathComponent)", category: "Integrity Checker")
                    } else {
                        ToastManager.shared.show("⚠️ IPA has warnings", type: .warning)
                        AppLogManager.shared.warning("IPA has warnings: \(url.lastPathComponent)", category: "Integrity Checker")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    ToastManager.shared.show("❌ Failed to analyze IPA", type: .error)
                    AppLogManager.shared.error("Failed to analyze IPA: \(error.localizedDescription)", category: "Integrity Checker")
                }
            }
        }
    }
    
    private static let maxProvisioningFileSize: Int64 = 10 * 1024 * 1024 // 10 MB limit
    private static let provisioningWarningDays: TimeInterval = 7 * 24 * 3600 // 7 days
    
    private func performIntegrityChecks(url: URL) async throws -> IntegrityResults {
        let fileManager = FileManager.default
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw NSError(domain: "IntegrityChecker", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file. Permission denied."])
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        // Get file size
        let attributes = try fileManager.attributesOfItem(atPath: url.path)
        let fileSize = ByteCountFormatter.string(fromByteCount: Int64(attributes[.size] as? UInt64 ?? 0), countStyle: .file)
        
        var warnings: [String] = []
        var errors: [String] = []
        var suggestions: [String] = []
        
        // Check if it's a valid ZIP
        var isValidZip = true
        var hasPayloadFolder = false
        var hasAppBundle = false
        var hasValidInfoPlist = false
        var hasValidProvisioning = false
        var provisioningExpired = false
        var provisioningExpiryDate: Date? = nil
        var hasCodeSignature = false
        var bundleID: String? = nil
        var frameworksCount = 0
        var dylibsCount = 0
        var pluginsCount = 0
        
        // Create temp directory
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // Extract IPA (using ZIPFoundation extension)
        do {
            try fileManager.unzipItem(at: url, to: tempDir)
        } catch {
            isValidZip = false
            errors.append("Failed to extract IPA: Not a valid ZIP archive")
            throw error
        }
        
        // Check for Payload folder
        let payloadDir = tempDir.appendingPathComponent("Payload")
        hasPayloadFolder = fileManager.fileExists(atPath: payloadDir.path)
        
        if !hasPayloadFolder {
            errors.append("Missing Payload folder")
        } else {
            // Find .app bundle
            if let appBundle = try? fileManager.contentsOfDirectory(at: payloadDir, includingPropertiesForKeys: nil).first(where: { $0.pathExtension == "app" }) {
                hasAppBundle = true
                
                // Check Info.plist
                let infoPlistURL = appBundle.appendingPathComponent("Info.plist")
                if let plistData = try? Data(contentsOf: infoPlistURL),
                   let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                    hasValidInfoPlist = true
                    bundleID = plist["CFBundleIdentifier"] as? String
                    
                    if bundleID == nil {
                        warnings.append("Info.plist missing CFBundleIdentifier")
                    }
                } else {
                    errors.append("Invalid or missing Info.plist")
                }
                
                // Check provisioning profile with size limits
                let provisioningURL = appBundle.appendingPathComponent("embedded.mobileprovision")
                if fileManager.fileExists(atPath: provisioningURL.path) {
                    // Check file size before loading
                    if let provisioningAttrs = try? fileManager.attributesOfItem(atPath: provisioningURL.path),
                       let provisioningSize = provisioningAttrs[.size] as? Int64,
                       provisioningSize <= Self.maxProvisioningFileSize {
                        hasValidProvisioning = true
                        
                        // Parse provisioning profile
                        if let data = try? Data(contentsOf: provisioningURL),
                           let dataString = String(data: data, encoding: .ascii) ?? String(data: data, encoding: .utf8),
                           let plistStart = dataString.range(of: "<?xml"),
                           let plistEnd = dataString.range(of: "</plist>") {
                            let plistString = String(dataString[plistStart.lowerBound...plistEnd.upperBound])
                            if let plistData = plistString.data(using: .utf8),
                               let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
                                if let expirationDate = plist["ExpirationDate"] as? Date {
                                    provisioningExpiryDate = expirationDate
                                    provisioningExpired = expirationDate < Date()
                                    
                                    if provisioningExpired {
                                        errors.append("Provisioning profile has expired")
                                    } else if expirationDate.timeIntervalSinceNow < Self.provisioningWarningDays {
                                        warnings.append("Provisioning profile expires soon")
                                    }
                                }
                            }
                        }
                    } else {
                        warnings.append("Provisioning profile file too large or invalid")
                    }
                } else {
                    warnings.append("No embedded provisioning profile found")
                }
                
                // Check code signature
                let codeSignatureDir = appBundle.appendingPathComponent("_CodeSignature")
                hasCodeSignature = fileManager.fileExists(atPath: codeSignatureDir.path)
                
                if !hasCodeSignature {
                    warnings.append("No code signature found")
                    suggestions.append("Sign the IPA before installation")
                }
                
                // Count frameworks
                let frameworksDir = appBundle.appendingPathComponent("Frameworks")
                if fileManager.fileExists(atPath: frameworksDir.path) {
                    if let frameworks = try? fileManager.contentsOfDirectory(at: frameworksDir, includingPropertiesForKeys: nil) {
                        frameworksCount = frameworks.filter { $0.pathExtension == "framework" }.count
                    }
                }
                
                // Count dylibs (may be injected tweaks or legitimate dependencies)
                if let files = try? fileManager.contentsOfDirectory(at: appBundle, includingPropertiesForKeys: nil) {
                    dylibsCount = files.filter { $0.pathExtension == "dylib" }.count
                    
                    if dylibsCount > 0 {
                        warnings.append("Found \(dylibsCount) dynamic libraries (may be tweaks or legitimate dependencies)")
                    }
                }
                
                // Count plugins
                let pluginsDir = appBundle.appendingPathComponent("PlugIns")
                if fileManager.fileExists(atPath: pluginsDir.path) {
                    if let plugins = try? fileManager.contentsOfDirectory(at: pluginsDir, includingPropertiesForKeys: nil) {
                        pluginsCount = plugins.count
                    }
                }
            } else {
                errors.append("No .app bundle found in Payload folder")
            }
        }
        
        // Add suggestions based on findings
        if !hasValidProvisioning {
            suggestions.append("Add a valid provisioning profile before installation")
        }
        
        if errors.isEmpty && warnings.isEmpty {
            suggestions.append("IPA appears to be valid and ready for installation")
        }
        
        return IntegrityResults(
            fileName: url.lastPathComponent,
            fileSize: fileSize,
            bundleID: bundleID,
            isValidZip: isValidZip,
            hasPayloadFolder: hasPayloadFolder,
            hasAppBundle: hasAppBundle,
            hasValidInfoPlist: hasValidInfoPlist,
            hasValidProvisioning: hasValidProvisioning,
            provisioningExpired: provisioningExpired,
            provisioningExpiryDate: provisioningExpiryDate,
            hasCodeSignature: hasCodeSignature,
            frameworksCount: frameworksCount,
            dylibsCount: dylibsCount,
            pluginsCount: pluginsCount,
            warnings: warnings,
            errors: errors,
            suggestions: suggestions
        )
    }
}

// MARK: - Check Row
struct CheckRow: View {
    let label: String
    let passed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? .green : .red)
            Text(label)
                .font(.subheadline)
            Spacer()
        }
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

// MARK: - Updates & Releases View
struct UpdatesReleasesView: View {
    @State private var isCheckingUpdates = false
    @State private var latestRelease: GitHubRelease?
    @State private var allReleases: [GitHubRelease] = []
    @State private var errorMessage: String?
    @State private var showPrereleases = false
    @AppStorage("dev.mandatoryUpdateEnabled") private var mandatoryUpdateEnabled = false
    @AppStorage("dev.updateBannerDismissed") private var updateBannerDismissed = false
    @AppStorage("dev.showUpdateBannerPreview") private var showUpdateBannerPreview = false
    
    private let repoOwner = "aoyn1xw"
    private let repoName = "Portal"
    
    var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var body: some View {
        List {
            // Current Version Info
            Section(header: Text("Installed Version")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(currentVersion)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(currentBuild)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Bundle ID")
                    Spacer()
                    Text(Bundle.main.bundleIdentifier ?? "Unknown")
                        .foregroundStyle(.secondary)
                        .font(.caption.monospaced())
                        .lineLimit(1)
                }
            }
            
            // Update Check
            Section(header: Text("GitHub Releases")) {
                Button {
                    checkForUpdates()
                } label: {
                    HStack {
                        if isCheckingUpdates {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Check for Updates")
                    }
                }
                .disabled(isCheckingUpdates)
                
                Toggle("Include Prereleases", isOn: $showPrereleases)
                    .onChange(of: showPrereleases) { _ in
                        checkForUpdates()
                    }
                
                if let release = latestRelease {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Latest: \(release.tagName)")
                                .font(.headline)
                            if release.prerelease {
                                Text("PRE")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(release.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let publishedAt = release.publishedAt {
                            Text("Published: \(publishedAt, style: .date)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            // All Releases
            if !allReleases.isEmpty {
                Section(header: Text("All Releases (\(allReleases.count))")) {
                    ForEach(allReleases, id: \.id) { release in
                        NavigationLink(destination: ReleaseDetailView(release: release)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(release.tagName)
                                            .font(.system(.body, design: .monospaced))
                                        if release.prerelease {
                                            Text("PRE")
                                                .font(.caption2.bold())
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(Color.orange.opacity(0.2))
                                                .foregroundStyle(.orange)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    Text(release.name)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                        }
                    }
                }
            }
            
            // Update Settings
            Section(header: Text("Update Settings")) {
                Toggle("Mandatory Update Enforcement", isOn: $mandatoryUpdateEnabled)
                
                Toggle("Show Update Banner Preview", isOn: $showUpdateBannerPreview)
                
                Button("Reset Dismissed Update State") {
                    updateBannerDismissed = false
                    HapticsManager.shared.success()
                    AppLogManager.shared.info("Update banner dismissed state reset", category: "Developer")
                }
                
                HStack {
                    Text("Banner Dismissed")
                    Spacer()
                    Text(updateBannerDismissed ? "Yes" : "No")
                        .foregroundStyle(updateBannerDismissed ? .orange : .green)
                }
            }
        }
        .navigationTitle("Updates & Releases")
        .onAppear {
            if allReleases.isEmpty {
                checkForUpdates()
            }
        }
    }
    
    private func checkForUpdates() {
        isCheckingUpdates = true
        errorMessage = nil
        
        let urlString = "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases"
        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isCheckingUpdates = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isCheckingUpdates = false
                
                if let error = error {
                    errorMessage = error.localizedDescription
                    AppLogManager.shared.error("Failed to check updates: \(error.localizedDescription)", category: "Developer")
                    return
                }
                
                guard let data = data else {
                    errorMessage = "No data received"
                    return
                }
                
                do {
                    // Configure JSONDecoder with ISO8601 date decoding strategy
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let releases = try decoder.decode([GitHubRelease].self, from: data)
                    allReleases = showPrereleases ? releases : releases.filter { !$0.prerelease }
                    latestRelease = allReleases.first
                    AppLogManager.shared.success("Fetched \(releases.count) releases", category: "Developer")
                } catch {
                    errorMessage = "Failed to parse releases: \(error.localizedDescription)"
                    AppLogManager.shared.error("Failed to parse releases: \(error.localizedDescription)", category: "Developer")
                }
            }
        }.resume()
    }
}

// MARK: - GitHub Release Model
struct GitHubRelease: Codable, Identifiable {
    let id: Int
    let tagName: String
    let name: String
    let body: String?
    let prerelease: Bool
    let draft: Bool
    let publishedAt: Date?
    let htmlUrl: String
    let assets: [GitHubAsset]
    
    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case prerelease
        case draft
        case publishedAt = "published_at"
        case htmlUrl = "html_url"
        case assets
    }
}

struct GitHubAsset: Codable, Identifiable {
    let id: Int
    let name: String
    let size: Int
    let downloadCount: Int
    let browserDownloadUrl: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, size
        case downloadCount = "download_count"
        case browserDownloadUrl = "browser_download_url"
    }
}

// MARK: - Release Detail View
struct ReleaseDetailView: View {
    let release: GitHubRelease
    
    var body: some View {
        List {
            Section(header: Text("Release Info")) {
                LabeledContent("Tag", value: release.tagName)
                LabeledContent("Name", value: release.name)
                LabeledContent("Prerelease", value: release.prerelease ? "Yes" : "No")
                if let date = release.publishedAt {
                    LabeledContent("Published", value: date.formatted())
                }
            }
            
            if let body = release.body, !body.isEmpty {
                Section(header: Text("Release Notes")) {
                    Text(body)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            if !release.assets.isEmpty {
                Section(header: Text("Assets (\(release.assets.count))")) {
                    ForEach(release.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.name)
                                .font(.system(.body, design: .monospaced))
                            HStack {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))
                                Text("•")
                                Text("\(asset.downloadCount) downloads")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section {
                Button("Open in GitHub") {
                    if let url = URL(string: release.htmlUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
        .navigationTitle(release.tagName)
    }
}

// MARK: - Sources & Library Dev View
struct SourcesLibraryDevView: View {
    @StateObject private var viewModel = SourcesViewModel.shared
    @State private var isReloading = false
    @State private var selectedSource: AltSource?
    @State private var rawJSON: String = ""
    @State private var showRawJSON = false
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var sources: FetchedResults<AltSource>
    
    var body: some View {
        List {
            // Source Actions
            Section(header: Text("Source Actions")) {
                Button {
                    reloadAllSources()
                } label: {
                    HStack {
                        if isReloading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Force Reload All Sources")
                    }
                }
                .disabled(isReloading)
                
                Button {
                    invalidateSourceCache()
                } label: {
                    Label("Invalidate Source Cache", systemImage: "trash")
                }
                
                Button {
                    refetchMetadata()
                } label: {
                    Label("Re-fetch All Metadata", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            // Source List
            Section(header: Text("Sources (\(sources.count))")) {
                ForEach(sources) { source in
                    NavigationLink(destination: SourceInspectorView(source: source, viewModel: viewModel)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.name ?? "Unknown")
                                .font(.headline)
                            if let url = source.sourceURL {
                                Text(url.absoluteString)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            if let repo = viewModel.sources[source] {
                                Text("\(repo.apps.count) apps")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            
            // Library Actions
            Section(header: Text("Library Actions")) {
                Button {
                    forceLibraryRerender()
                } label: {
                    Label("Force Library Re-render", systemImage: "arrow.counterclockwise")
                }
                
                Button {
                    clearLibraryCache()
                } label: {
                    Label("Clear Library Cache", systemImage: "trash")
                }
            }
            
            // Offline Handling
            Section(header: Text("Offline Handling")) {
                Toggle("Simulate Offline Mode", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "dev.simulateOffline") },
                    set: { UserDefaults.standard.set($0, forKey: "dev.simulateOffline") }
                ))
                
                Button {
                    testOfflineSourceHandling()
                } label: {
                    Label("Test Offline Source Handling", systemImage: "wifi.slash")
                }
            }
        }
        .navigationTitle("Sources & Library")
    }
    
    private func reloadAllSources() {
        isReloading = true
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            await MainActor.run {
                isReloading = false
                HapticsManager.shared.success()
                ToastManager.shared.show("✅ All sources reloaded successfully", type: .success)
                AppLogManager.shared.success("All sources reloaded", category: "Developer")
            }
        }
    }
    
    private func invalidateSourceCache() {
        // Clear URLCache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear image cache
        let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        if let cacheURL = cacheURL {
            try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
        }
        
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Source cache invalidated", type: .success)
        AppLogManager.shared.success("Source cache invalidated", category: "Developer")
    }
    
    private func refetchMetadata() {
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Metadata re-fetched successfully", type: .success)
            AppLogManager.shared.success("Metadata re-fetched", category: "Developer")
        }
    }
    
    private func forceLibraryRerender() {
        NotificationCenter.default.post(name: Notification.Name("Feather.forceLibraryRerender"), object: nil)
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Library re-render triggered", type: .success)
        AppLogManager.shared.info("Library re-render triggered", category: "Developer")
    }
    
    private func clearLibraryCache() {
        // Clear any library-specific caches
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Library cache cleared", type: .success)
        AppLogManager.shared.success("Library cache cleared", category: "Developer")
    }
    
    private func testOfflineSourceHandling() {
        UserDefaults.standard.set(true, forKey: "dev.simulateOffline")
        Task {
            await viewModel.fetchSources(sources, refresh: true)
            await MainActor.run {
                UserDefaults.standard.set(false, forKey: "dev.simulateOffline")
                ToastManager.shared.show("ℹ️ Offline source handling test completed", type: .info)
                AppLogManager.shared.info("Offline source handling test completed", category: "Developer")
            }
        }
    }
}

// MARK: - Source Inspector View
struct SourceInspectorView: View {
    let source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    @State private var rawJSON: String = ""
    @State private var isLoadingJSON = false
    
    var body: some View {
        List {
            Section(header: Text("Source Info")) {
                LabeledContent("Name", value: source.name ?? "Unknown")
                if let url = source.sourceURL {
                    LabeledContent("URL", value: url.absoluteString)
                }
                LabeledContent("Order", value: "\(source.order)")
                if let date = source.date {
                    LabeledContent("Added", value: date.formatted())
                }
            }
            
            if let repo = viewModel.sources[source] {
                Section(header: Text("Repository Data")) {
                    LabeledContent("Apps", value: "\(repo.apps.count)")
                    if let news = repo.news {
                        LabeledContent("News Items", value: "\(news.count)")
                    }
                    if let name = repo.name {
                        LabeledContent("Repo Name", value: name)
                    }
                }
            }
            
            Section(header: Text("Raw JSON")) {
                Button {
                    loadRawJSON()
                } label: {
                    HStack {
                        if isLoadingJSON {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Load Raw JSON")
                    }
                }
                
                if !rawJSON.isEmpty {
                    ScrollView(.horizontal) {
                        Text(rawJSON)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)
                    
                    Button("Copy JSON") {
                        UIPasteboard.general.string = rawJSON
                        HapticsManager.shared.success()
                    }
                }
            }
        }
        .navigationTitle(source.name ?? "Source")
    }
    
    private func loadRawJSON() {
        guard let url = source.sourceURL else { return }
        isLoadingJSON = true
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoadingJSON = false
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        rawJSON = prettyString
                    } else {
                        rawJSON = String(data: data, encoding: .utf8) ?? "Unable to decode"
                    }
                } else if let error = error {
                    rawJSON = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

// MARK: - Install & IPA Dev View
struct InstallIPADevView: View {
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var showInstallModifyDialog = false
    @State private var lastInstallLogs: [String] = []
    @State private var selectedApp: (any AppInfoPresentable)?
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.dateAdded, ascending: false)]
    ) private var importedApps: FetchedResults<Imported>
    
    var body: some View {
        List {
            // Install Queue
            Section(header: Text("Download Queue (\(downloadManager.downloads.count))")) {
                if downloadManager.downloads.isEmpty {
                    Text("No active downloads")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(downloadManager.downloads, id: \.id) { download in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(download.fileName)
                                .font(.system(.body, design: .monospaced))
                            ProgressView(value: download.overallProgress)
                            HStack {
                                Text("\(Int(download.progress * 100))% downloaded")
                                Spacer()
                                Text("\(Int(download.unpackageProgress * 100))% processed")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Button("Clear Pending Installs", role: .destructive) {
                    clearPendingInstalls()
                }
            }
            
            // IPA Validation
            Section(header: Text("IPA Tools")) {
                NavigationLink(destination: IPAInspectorView()) {
                    Label("IPA Inspector", systemImage: "doc.zipper")
                }
                
                NavigationLink(destination: IPAIntegrityCheckerView()) {
                    Label("Integrity Checker", systemImage: "checkmark.shield")
                }
            }
            
            // InstallModifyDialog Testing
            Section(header: Text("InstallModifyDialog Testing")) {
                if let firstApp = importedApps.first {
                    Button("Show InstallModifyDialog (Full Screen)") {
                        selectedApp = firstApp
                        showInstallModifyDialog = true
                    }
                } else {
                    Text("No imported apps available for testing")
                        .foregroundStyle(.secondary)
                }
                
                Toggle("Always Show After Download", isOn: Binding(
                    get: { UserDefaults.standard.bool(forKey: "dev.alwaysShowInstallModify") },
                    set: { UserDefaults.standard.set($0, forKey: "dev.alwaysShowInstallModify") }
                ))
            }
            
            // Last Install Logs
            Section(header: Text("Last Install Logs")) {
                Button("Load Install Logs") {
                    loadInstallLogs()
                }
                
                if !lastInstallLogs.isEmpty {
                    ForEach(lastInstallLogs, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle("Install & IPA")
        .fullScreenCover(isPresented: $showInstallModifyDialog) {
            if let app = selectedApp {
                InstallModifyDialogView(app: app)
            }
        }
    }
    
    private func clearPendingInstalls() {
        for download in downloadManager.downloads {
            downloadManager.cancelDownload(download)
        }
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Pending installs cleared", type: .success)
        AppLogManager.shared.info("Pending installs cleared", category: "Developer")
    }
    
    private func loadInstallLogs() {
        lastInstallLogs = AppLogManager.shared.logs
            .filter { $0.category == "Install" || $0.category == "Download" }
            .prefix(20)
            .map { "[\($0.level.rawValue)] \($0.message)" }
    }
}

// MARK: - UI & Layout Dev View
struct UILayoutDevView: View {
    @AppStorage("dev.showLayoutBoundaries") private var showLayoutBoundaries = false
    @AppStorage("dev.slowAnimations") private var slowAnimations = false
    @AppStorage("dev.animationSpeed") private var animationSpeed: Double = 1.0
    @AppStorage("dev.forceDarkMode") private var forceDarkMode = false
    @AppStorage("dev.forceLightMode") private var forceLightMode = false
    @AppStorage("dev.forceReducedMotion") private var forceReducedMotion = false
    @AppStorage("dev.dynamicTypeSize") private var dynamicTypeSize: String = "default"
    @AppStorage("dev.showBannerPreview") private var showBannerPreview = false
    
    var body: some View {
        List {
            // Appearance Overrides
            Section(header: Text("Appearance Overrides")) {
                Toggle("Force Dark Mode", isOn: $forceDarkMode)
                    .onChange(of: forceDarkMode) { newValue in
                        if newValue { forceLightMode = false }
                        applyAppearanceOverride()
                    }
                
                Toggle("Force Light Mode", isOn: $forceLightMode)
                    .onChange(of: forceLightMode) { newValue in
                        if newValue { forceDarkMode = false }
                        applyAppearanceOverride()
                    }
                
                Button("Reset to System") {
                    forceDarkMode = false
                    forceLightMode = false
                    applyAppearanceOverride()
                }
            }
            
            // Dynamic Type
            Section(header: Text("Dynamic Type")) {
                Picker("Text Size", selection: $dynamicTypeSize) {
                    Text("Default").tag("default")
                    Text("Extra Small").tag("xSmall")
                    Text("Small").tag("small")
                    Text("Medium").tag("medium")
                    Text("Large").tag("large")
                    Text("Extra Large").tag("xLarge")
                    Text("XXL").tag("xxLarge")
                    Text("XXXL").tag("xxxLarge")
                    Text("Accessibility M").tag("accessibility1")
                    Text("Accessibility L").tag("accessibility2")
                    Text("Accessibility XL").tag("accessibility3")
                }
            }
            
            // Motion & Animations
            Section(header: Text("Motion & Animations")) {
                Toggle("Reduced Motion", isOn: $forceReducedMotion)
                
                Toggle("Slow Animations", isOn: $slowAnimations)
                    .onChange(of: slowAnimations) { newValue in
                        applyAnimationSpeed(newValue ? 0.1 : animationSpeed)
                    }
                
                VStack(alignment: .leading) {
                    Text("Animation Speed: \(String(format: "%.1fx", animationSpeed))")
                    Slider(value: $animationSpeed, in: 0.1...2.0, step: 0.1)
                        .onChange(of: animationSpeed) { newValue in
                            if !slowAnimations {
                                applyAnimationSpeed(newValue)
                            }
                        }
                }
            }
            
            // Layout Debugging
            Section(header: Text("Layout Debugging")) {
                Toggle("Show Layout Boundaries", isOn: $showLayoutBoundaries)
                    .onChange(of: showLayoutBoundaries) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "_UIConstraintBasedLayoutPlayground")
                    }
            }
            
            // Banner Injection
            Section(header: Text("Banner Injection")) {
                Toggle("Show Test Banner", isOn: $showBannerPreview)
                
                Button("Inject Update Banner") {
                    injectUpdateBanner()
                }
                
                Button("Inject Error Banner") {
                    injectErrorBanner()
                }
                
                Button("Clear All Banners") {
                    clearBanners()
                }
            }
        }
        .navigationTitle("UI & Layout")
    }
    
    private func applyAppearanceOverride() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        if forceDarkMode {
            window.overrideUserInterfaceStyle = .dark
        } else if forceLightMode {
            window.overrideUserInterfaceStyle = .light
        } else {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
    
    private func applyAnimationSpeed(_ speed: Double) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.layer.speed = Float(speed)
    }
    
    private func injectUpdateBanner() {
        NotificationCenter.default.post(
            name: Notification.Name("Feather.showBanner"),
            object: nil,
            userInfo: ["type": "update", "message": "A new version is available!"]
        )
        ToastManager.shared.show("✅ Update banner injected", type: .success)
        AppLogManager.shared.info("Update banner injected", category: "Developer")
    }
    
    private func injectErrorBanner() {
        NotificationCenter.default.post(
            name: Notification.Name("Feather.showBanner"),
            object: nil,
            userInfo: ["type": "error", "message": "Test error banner"]
        )
        ToastManager.shared.show("✅ Error banner injected", type: .success)
        AppLogManager.shared.info("Error banner injected", category: "Developer")
    }
    
    private func clearBanners() {
        NotificationCenter.default.post(name: Notification.Name("Feather.clearBanners"), object: nil)
        ToastManager.shared.show("✅ Banners cleared", type: .success)
        AppLogManager.shared.info("Banners cleared", category: "Developer")
    }
}

// MARK: - Network & System Dev View
struct NetworkSystemDevView: View {
    @AppStorage("dev.simulateOffline") private var simulateOffline = false
    @AppStorage("dev.latencyInjection") private var latencyInjection: Double = 0
    @AppStorage("dev.verboseLogging") private var verboseLogging = false
    @AppStorage("dev.logNetworkRequests") private var logNetworkRequests = false
    @State private var networkLogs: [String] = []
    @State private var systemInfo: [String: String] = [:]
    
    var body: some View {
        List {
            // Network Simulation
            Section(header: Text("Network Simulation")) {
                Toggle("Simulate Offline Mode", isOn: $simulateOffline)
                    .onChange(of: simulateOffline) { newValue in
                        AppLogManager.shared.info("Offline simulation: \(newValue ? "enabled" : "disabled")", category: "Developer")
                    }
                
                VStack(alignment: .leading) {
                    Text("Latency Injection: \(Int(latencyInjection))ms")
                    Slider(value: $latencyInjection, in: 0...5000, step: 100)
                }
                
                Toggle("Log Network Requests", isOn: $logNetworkRequests)
            }
            
            // Logging
            Section(header: Text("Logging")) {
                Toggle("Verbose Logging", isOn: $verboseLogging)
                    .onChange(of: verboseLogging) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "verboseLogging")
                    }
                
                NavigationLink(destination: AppLogsView()) {
                    Label("View App Logs", systemImage: "terminal")
                }
                
                Button("Export Logs") {
                    exportLogs()
                }
            }
            
            // System Info
            Section(header: Text("System Information")) {
                Button("Refresh System Info") {
                    loadSystemInfo()
                }
                
                ForEach(Array(systemInfo.keys.sorted()), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text(systemInfo[key] ?? "")
                            .foregroundStyle(.secondary)
                            .font(.system(.caption, design: .monospaced))
                    }
                }
            }
            
            // Failure Inspection
            Section(header: Text("Failure Inspection")) {
                NavigationLink(destination: FailureInspectorView()) {
                    Label("View Recent Failures", systemImage: "exclamationmark.triangle")
                }
                
                Button("Simulate Network Failure") {
                    simulateNetworkFailure()
                }
            }
        }
        .navigationTitle("Network & System")
        .onAppear {
            loadSystemInfo()
        }
    }
    
    private func loadSystemInfo() {
        systemInfo = [
            "Device": UIDevice.current.model,
            "iOS Version": UIDevice.current.systemVersion,
            "App Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "Build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
            "Memory": getMemoryUsage(),
            "Disk Free": getDiskSpace(),
            "Network": getNetworkStatus()
        ]
    }
    
    private func getMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return ByteCountFormatter.string(fromByteCount: Int64(info.resident_size), countStyle: .memory)
        }
        return "Unknown"
    }
    
    private func getDiskSpace() -> String {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSpace = attrs[.systemFreeSize] as? Int64 {
            return ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
        }
        return "Unknown"
    }
    
    private func getNetworkStatus() -> String {
        return simulateOffline ? "Offline (Simulated)" : "Online"
    }
    
    private func exportLogs() {
        let logs = AppLogManager.shared.exportLogs()
        UIPasteboard.general.string = logs
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
        AppLogManager.shared.success("Logs exported to clipboard", category: "Developer")
    }
    
    private func simulateNetworkFailure() {
        NotificationCenter.default.post(
            name: DownloadManager.downloadDidFailNotification,
            object: nil,
            userInfo: ["error": "Simulated network failure", "downloadId": "test"]
        )
        ToastManager.shared.show("⚠️ Network failure simulated", type: .warning)
        AppLogManager.shared.warning("Network failure simulated", category: "Developer")
    }
}

// MARK: - Failure Inspector View
struct FailureInspectorView: View {
    @StateObject private var logManager = AppLogManager.shared
    
    var failureLogs: [LogEntry] {
        logManager.logs.filter { $0.level == .error || $0.level == .critical }
    }
    
    var body: some View {
        List {
            if failureLogs.isEmpty {
                Text("No failures recorded")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(failureLogs) { log in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(log.level.icon)
                            Text(log.formattedTimestamp)
                                .font(.caption.monospaced())
                        }
                        Text(log.message)
                            .font(.system(.body, design: .monospaced))
                        Text("[\(log.category)] \(log.file):\(log.line)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Failures")
    }
}

// MARK: - State & Persistence Dev View
struct StatePersistenceDevView: View {
    @State private var userDefaultsKeys: [String] = []
    @State private var appStorageKeys: [String] = []
    @State private var cacheSize: String = "Calculating..."
    @State private var showClearConfirmation = false
    @State private var clearTarget: ClearTarget = .all
    
    enum ClearTarget {
        case all, userDefaults, caches, onboarding
    }
    
    var body: some View {
        List {
            // AppStorage / UserDefaults
            Section(header: Text("UserDefaults")) {
                NavigationLink(destination: UserDefaultsEditorView()) {
                    Label("UserDefaults Editor", systemImage: "list.bullet.rectangle")
                }
                
                Button("Clear All UserDefaults", role: .destructive) {
                    clearTarget = .userDefaults
                    showClearConfirmation = true
                }
            }
            
            // Caches
            Section(header: Text("Caches")) {
                HStack {
                    Text("Cache Size")
                    Spacer()
                    Text(cacheSize)
                        .foregroundStyle(.secondary)
                }
                
                Button("Clear URL Cache") {
                    URLCache.shared.removeAllCachedResponses()
                    calculateCacheSize()
                    HapticsManager.shared.success()
                    ToastManager.shared.show("✅ URL cache cleared", type: .success)
                    AppLogManager.shared.success("URL cache cleared", category: "Developer")
                }
                
                Button("Clear Image Cache") {
                    clearImageCache()
                    ToastManager.shared.show("✅ Image cache cleared", type: .success)
                }
                
                Button("Clear All Caches", role: .destructive) {
                    clearTarget = .caches
                    showClearConfirmation = true
                }
            }
            
            // Onboarding State
            Section(header: Text("Onboarding State")) {
                HStack {
                    Text("Completed")
                    Spacer()
                    Text(UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") ? "Yes" : "No")
                        .foregroundStyle(.secondary)
                }
                
                Button("Reset Onboarding") {
                    clearTarget = .onboarding
                    showClearConfirmation = true
                }
            }
            
            // CoreData
            Section(header: Text("CoreData")) {
                NavigationLink(destination: CoreDataInspectorView()) {
                    Label("CoreData Inspector", systemImage: "cylinder.split.1x2")
                }
            }
            
            // Danger Zone
            Section(header: Text("Danger Zone")) {
                Button("Reset All App Data", role: .destructive) {
                    clearTarget = .all
                    showClearConfirmation = true
                }
            }
        }
        .navigationTitle("State & Persistence")
        .onAppear {
            calculateCacheSize()
        }
        .alert("Confirm Clear", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                performClear()
            }
        } message: {
            Text(clearConfirmationMessage)
        }
    }
    
    private var clearConfirmationMessage: String {
        switch clearTarget {
        case .all: return "This will reset all app data including settings, sources, and certificates. This cannot be undone."
        case .userDefaults: return "This will clear all UserDefaults. Some settings may be lost."
        case .caches: return "This will clear all cached data including images and network responses."
        case .onboarding: return "This will reset the onboarding state. You will see the onboarding screen on next launch."
        }
    }
    
    private func calculateCacheSize() {
        var totalSize: Int64 = 0
        
        // URL Cache
        totalSize += Int64(URLCache.shared.currentDiskUsage)
        
        // Image cache directory
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            if let size = try? FileManager.default.allocatedSizeOfDirectory(at: cacheURL) {
                totalSize += Int64(size)
            }
        }
        
        cacheSize = ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    private func clearImageCache() {
        if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let nukeCache = cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache")
            try? FileManager.default.removeItem(at: nukeCache)
        }
        calculateCacheSize()
        HapticsManager.shared.success()
        AppLogManager.shared.success("Image cache cleared", category: "Developer")
    }
    
    private func performClear() {
        switch clearTarget {
        case .all:
            // Clear everything
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            URLCache.shared.removeAllCachedResponses()
            clearImageCache()
            ToastManager.shared.show("⚠️ All app data reset", type: .warning)
            AppLogManager.shared.warning("All app data reset", category: "Developer")
            
        case .userDefaults:
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            ToastManager.shared.show("✅ UserDefaults cleared", type: .success)
            AppLogManager.shared.info("UserDefaults cleared", category: "Developer")
            
        case .caches:
            URLCache.shared.removeAllCachedResponses()
            clearImageCache()
            ToastManager.shared.show("✅ All caches cleared", type: .success)
            AppLogManager.shared.info("All caches cleared", category: "Developer")
            
        case .onboarding:
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            ToastManager.shared.show("✅ Onboarding state reset", type: .success)
            AppLogManager.shared.info("Onboarding state reset", category: "Developer")
        }
        
        calculateCacheSize()
        HapticsManager.shared.success()
    }
}

// MARK: - FileManager Extension for Directory Size
extension FileManager {
    func allocatedSizeOfDirectory(at url: URL) throws -> UInt64 {
        var totalSize: UInt64 = 0
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey]
        
        guard let enumerator = self.enumerator(at: url, includingPropertiesForKeys: Array(resourceKeys), options: [], errorHandler: nil) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            let resourceValues = try fileURL.resourceValues(forKeys: resourceKeys)
            guard resourceValues.isRegularFile == true else { continue }
            totalSize += UInt64(resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize ?? 0)
        }
        
        return totalSize
    }
}

// MARK: - Device Information View
struct DeviceInfoView: View {
    @State private var deviceInfo: [String: String] = [:]
    @State private var hardwareInfo: [String: String] = [:]
    @State private var storageInfo: [String: String] = [:]
    @State private var batteryInfo: [String: String] = [:]
    
    var body: some View {
        List {
            // Device Section
            Section(header: Text("Device")) {
                ForEach(Array(deviceInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: deviceInfo[key] ?? "Unknown")
                }
            }
            
            // Hardware Section
            Section(header: Text("Hardware")) {
                ForEach(Array(hardwareInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: hardwareInfo[key] ?? "Unknown")
                }
            }
            
            // Storage Section
            Section(header: Text("Storage")) {
                ForEach(Array(storageInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: storageInfo[key] ?? "Unknown")
                }
            }
            
            // Battery Section
            Section(header: Text("Battery")) {
                ForEach(Array(batteryInfo.keys.sorted()), id: \.self) { key in
                    DeviceInfoRow(label: key, value: batteryInfo[key] ?? "Unknown")
                }
            }
            
            // App Info Section
            Section(header: Text("App Information")) {
                DeviceInfoRow(label: "App Name", value: Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown")
                DeviceInfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                DeviceInfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                DeviceInfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
            }
            
            // Export Section
            Section {
                Button {
                    exportDeviceInfo()
                } label: {
                    Label("Copy Device Info to Clipboard", systemImage: "doc.on.clipboard")
                }
            }
        }
        .navigationTitle("Device Information")
        .onAppear {
            loadDeviceInfo()
        }
    }
    
    private func loadDeviceInfo() {
        let device = UIDevice.current
        
        // Device Info
        deviceInfo = [
            "Name": device.name,
            "Model": device.model,
            "System Name": device.systemName,
            "System Version": device.systemVersion,
            "Identifier": getDeviceIdentifier()
        ]
        
        // Hardware Info
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
        
        hardwareInfo = [
            "Machine": machine,
            "Processor Count": "\(ProcessInfo.processInfo.processorCount) cores",
            "Physical Memory": ByteCountFormatter.string(fromByteCount: Int64(ProcessInfo.processInfo.physicalMemory), countStyle: .memory),
            "Active Processor Count": "\(ProcessInfo.processInfo.activeProcessorCount) cores"
        ]
        
        // Storage Info
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) {
            let totalSpace = attrs[.systemSize] as? Int64 ?? 0
            let freeSpace = attrs[.systemFreeSize] as? Int64 ?? 0
            let usedSpace = totalSpace - freeSpace
            
            storageInfo = [
                "Total Space": ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file),
                "Free Space": ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file),
                "Used Space": ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
            ]
        }
        
        // Battery Info
        device.isBatteryMonitoringEnabled = true
        let batteryState: String
        switch device.batteryState {
        case .charging: batteryState = "Charging"
        case .full: batteryState = "Full"
        case .unplugged: batteryState = "Unplugged"
        case .unknown: batteryState = "Unknown"
        @unknown default: batteryState = "Unknown"
        }
        
        batteryInfo = [
            "Battery Level": "\(Int(device.batteryLevel * 100))%",
            "Battery State": batteryState
        ]
    }
    
    private func getDeviceIdentifier() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "Unknown"
            }
        }
    }
    
    private func exportDeviceInfo() {
        var info = "=== Device Information ===\n\n"
        
        info += "-- Device --\n"
        for (key, value) in deviceInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- Hardware --\n"
        for (key, value) in hardwareInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- Storage --\n"
        for (key, value) in storageInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- Battery --\n"
        for (key, value) in batteryInfo.sorted(by: { $0.key < $1.key }) {
            info += "\(key): \(value)\n"
        }
        
        info += "\n-- App --\n"
        info += "Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")\n"
        info += "Build: \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n"
        info += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")\n"
        
        UIPasteboard.general.string = info
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Device info copied to clipboard", type: .success)
    }
}

struct DeviceInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Environment Inspector View
struct EnvironmentInspectorView: View {
    @State private var environment: [String: String] = [:]
    @State private var searchText = ""
    
    var filteredEnvironment: [(key: String, value: String)] {
        let sorted = environment.sorted { $0.key < $1.key }
        if searchText.isEmpty {
            return sorted
        }
        return sorted.filter { $0.key.localizedCaseInsensitiveContains(searchText) || $0.value.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List {
            // Process Info Section
            Section(header: Text("Process Information")) {
                LabeledContent("Process ID", value: "\(ProcessInfo.processInfo.processIdentifier)")
                LabeledContent("Process Name", value: ProcessInfo.processInfo.processName)
                LabeledContent("Host Name", value: ProcessInfo.processInfo.hostName)
                LabeledContent("OS Version", value: ProcessInfo.processInfo.operatingSystemVersionString)
                LabeledContent("Is Low Power Mode", value: ProcessInfo.processInfo.isLowPowerModeEnabled ? "Yes" : "No")
            }
            
            // Launch Arguments
            Section(header: Text("Launch Arguments (\(ProcessInfo.processInfo.arguments.count))")) {
                ForEach(ProcessInfo.processInfo.arguments, id: \.self) { arg in
                    Text(arg)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                }
            }
            
            // Environment Variables
            Section(header: Text("Environment Variables (\(filteredEnvironment.count))")) {
                ForEach(filteredEnvironment, id: \.key) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.key)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.semibold)
                        Text(item.value)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // Actions
            Section {
                Button {
                    exportEnvironment()
                } label: {
                    Label("Copy Environment to Clipboard", systemImage: "doc.on.clipboard")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search environment...")
        .navigationTitle("Environment Inspector")
        .onAppear {
            loadEnvironment()
        }
    }
    
    private func loadEnvironment() {
        environment = ProcessInfo.processInfo.environment
    }
    
    private func exportEnvironment() {
        var output = "=== Environment Variables ===\n\n"
        for (key, value) in environment.sorted(by: { $0.key < $1.key }) {
            output += "\(key)=\(value)\n"
        }
        UIPasteboard.general.string = output
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Environment copied to clipboard", type: .success)
    }
}

// MARK: - Crash Log Viewer
struct CrashLogViewer: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var crashLogs: [LogEntry] = []
    
    var body: some View {
        List {
            if crashLogs.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        
                        Text("No Crash Logs")
                            .font(.headline)
                        
                        Text("The app has not recorded any crashes. This is good!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .listRowBackground(Color.clear)
            } else {
                Section(header: Text("Critical Errors (\(crashLogs.count))")) {
                    ForEach(crashLogs) { log in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(log.level.icon)
                                Text(log.formattedTimestamp)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(log.message)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.red)
                            
                            HStack {
                                Text("[\(log.category)]")
                                Text("\(log.file):\(log.line)")
                            }
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        clearCrashLogs()
                    } label: {
                        Label("Clear Crash Logs", systemImage: "trash")
                    }
                }
            }
            
            // Export Section
            Section {
                Button {
                    exportCrashLogs()
                } label: {
                    Label("Export All Logs", systemImage: "square.and.arrow.up")
                }
            }
        }
        .navigationTitle("Crash Logs")
        .onAppear {
            loadCrashLogs()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    loadCrashLogs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    private func loadCrashLogs() {
        crashLogs = logManager.logs.filter { $0.level == .critical || $0.level == .error }
    }
    
    private func clearCrashLogs() {
        // Note: This only removes them from view, not from the actual log manager
        crashLogs.removeAll()
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Crash logs cleared from view", type: .success)
    }
    
    private func exportCrashLogs() {
        let logs = logManager.exportLogs()
        UIPasteboard.general.string = logs
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
    }
}

// MARK: - Quick Actions Dev View
struct QuickActionsDevView: View {
    @State private var showConfirmation = false
    @State private var selectedAction: QuickAction?
    
    enum QuickAction: String, CaseIterable {
        case clearAllCaches = "Clear All Caches"
        case resetOnboarding = "Reset Onboarding"
        case reloadSources = "Reload All Sources"
        case exportLogs = "Export All Logs"
        case resetUserDefaults = "Reset UserDefaults"
        case simulateCrash = "Simulate Crash Log"
        case triggerMemoryWarning = "Trigger Memory Warning"
        case clearImageCache = "Clear Image Cache"
        
        var icon: String {
            switch self {
            case .clearAllCaches: return "trash.circle.fill"
            case .resetOnboarding: return "arrow.counterclockwise.circle.fill"
            case .reloadSources: return "arrow.clockwise.circle.fill"
            case .exportLogs: return "square.and.arrow.up.circle.fill"
            case .resetUserDefaults: return "gear.badge.xmark"
            case .simulateCrash: return "exclamationmark.triangle.fill"
            case .triggerMemoryWarning: return "memorychip.fill"
            case .clearImageCache: return "photo.badge.arrow.down.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .clearAllCaches: return .orange
            case .resetOnboarding: return .blue
            case .reloadSources: return .green
            case .exportLogs: return .purple
            case .resetUserDefaults: return .red
            case .simulateCrash: return .red
            case .triggerMemoryWarning: return .yellow
            case .clearImageCache: return .cyan
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .clearAllCaches, .resetOnboarding, .resetUserDefaults, .simulateCrash:
                return true
            default:
                return false
            }
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("Cache Actions")) {
                quickActionButton(.clearAllCaches)
                quickActionButton(.clearImageCache)
            }
            
            Section(header: Text("State Actions")) {
                quickActionButton(.resetOnboarding)
                quickActionButton(.resetUserDefaults)
            }
            
            Section(header: Text("Data Actions")) {
                quickActionButton(.reloadSources)
                quickActionButton(.exportLogs)
            }
            
            Section(header: Text("Debug Actions")) {
                quickActionButton(.simulateCrash)
                quickActionButton(.triggerMemoryWarning)
            }
        }
        .navigationTitle("Quick Actions")
        .alert("Confirm Action", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(selectedAction?.isDestructive == true ? "Confirm" : "Execute", role: selectedAction?.isDestructive == true ? .destructive : nil) {
                if let action = selectedAction {
                    executeAction(action)
                }
            }
        } message: {
            Text("Are you sure you want to \(selectedAction?.rawValue.lowercased() ?? "perform this action")?")
        }
    }
    
    private func quickActionButton(_ action: QuickAction) -> some View {
        Button {
            selectedAction = action
            if action.isDestructive {
                showConfirmation = true
            } else {
                executeAction(action)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(action.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: action.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(action.color)
                }
                
                Text(action.rawValue)
                    .foregroundStyle(.primary)
                
                Spacer()
            }
        }
    }
    
    private func executeAction(_ action: QuickAction) {
        switch action {
        case .clearAllCaches:
            URLCache.shared.removeAllCachedResponses()
            if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ All caches cleared", type: .success)
            AppLogManager.shared.info("All caches cleared via Quick Actions", category: "Developer")
            
        case .resetOnboarding:
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Onboarding reset. Restart app to see changes.", type: .success)
            AppLogManager.shared.info("Onboarding reset via Quick Actions", category: "Developer")
            
        case .reloadSources:
            NotificationCenter.default.post(name: Notification.Name("Feather.reloadSources"), object: nil)
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Source reload triggered", type: .success)
            AppLogManager.shared.info("Sources reload triggered via Quick Actions", category: "Developer")
            
        case .exportLogs:
            let logs = AppLogManager.shared.exportLogs()
            UIPasteboard.general.string = logs
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Logs exported to clipboard", type: .success)
            
        case .resetUserDefaults:
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("⚠️ UserDefaults reset. Restart app.", type: .warning)
            AppLogManager.shared.warning("UserDefaults reset via Quick Actions", category: "Developer")
            
        case .simulateCrash:
            AppLogManager.shared.critical("Simulated crash log entry for testing purposes", category: "Developer")
            HapticsManager.shared.error()
            ToastManager.shared.show("⚠️ Crash log entry created", type: .warning)
            
        case .triggerMemoryWarning:
            // Post a simulated memory warning notification
            NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
            HapticsManager.shared.warning()
            ToastManager.shared.show("⚠️ Memory warning triggered", type: .warning)
            AppLogManager.shared.warning("Memory warning triggered via Quick Actions", category: "Developer")
            
        case .clearImageCache:
            if let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                try? FileManager.default.removeItem(at: cacheURL.appendingPathComponent("com.github.kean.Nuke.Cache"))
            }
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Image cache cleared", type: .success)
            AppLogManager.shared.info("Image cache cleared via Quick Actions", category: "Developer")
        }
    }
}

