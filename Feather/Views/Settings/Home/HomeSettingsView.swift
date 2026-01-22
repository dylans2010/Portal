import SwiftUI
import NimbleViews

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
        }
    }
    
    static var defaultOrder: [HomeWidgetType] {
        [.quickActions, .status, .atAGlance, .recentApps, .storageInfo, .certificateStatus, .sourcesOverview, .networkStatus, .tips]
    }
}

// MARK: - Home Widget Configuration
struct HomeWidgetConfig: Codable, Identifiable, Equatable {
    var id: String { type.rawValue }
    var type: HomeWidgetType
    var isEnabled: Bool
    var isPinned: Bool
    var order: Int
    
    init(type: HomeWidgetType, isEnabled: Bool = true, isPinned: Bool = false, order: Int = 0) {
        self.type = type
        self.isEnabled = isEnabled
        self.isPinned = isPinned
        self.order = order
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
            // Merge with any new widget types that might have been added
            var loadedWidgets = decoded
            let existingTypes = Set(loadedWidgets.map { $0.type })
            
            for (index, type) in HomeWidgetType.allCases.enumerated() {
                if !existingTypes.contains(type) {
                    loadedWidgets.append(HomeWidgetConfig(type: type, isEnabled: true, isPinned: false, order: loadedWidgets.count + index))
                }
            }
            
            widgets = loadedWidgets.sorted { $0.order < $1.order }
        } else {
            // Default configuration
            widgets = HomeWidgetType.defaultOrder.enumerated().map { index, type in
                HomeWidgetConfig(type: type, isEnabled: true, isPinned: false, order: index)
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
            HomeWidgetConfig(type: type, isEnabled: true, isPinned: false, order: index)
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

// MARK: - Home Settings View
struct HomeSettingsView: View {
    @StateObject private var settingsManager = HomeSettingsManager.shared
    @State private var isReordering = false
    @State private var showResetConfirmation = false
    @AppStorage("Feather.homeGreetingEnabled") private var greetingEnabled = true
    @AppStorage("Feather.homeAnimationsEnabled") private var animationsEnabled = true
    @AppStorage("Feather.homeCompactMode") private var compactMode = false
    @AppStorage("Feather.homeShowAppIcon") private var showAppIcon = true
    
    var body: some View {
        NBList(.localized("Home Settings")) {
            // Appearance Section
            Section {
                Toggle(isOn: $greetingEnabled) {
                    settingsRow(icon: "hand.wave.fill", title: "Show Greeting", color: .orange)
                }
                
                Toggle(isOn: $showAppIcon) {
                    settingsRow(icon: "app.fill", title: "Show App Icon", color: .blue)
                }
                
                Toggle(isOn: $animationsEnabled) {
                    settingsRow(icon: "sparkles", title: "Enable Animations", color: .purple)
                }
                
                Toggle(isOn: $compactMode) {
                    settingsRow(icon: "rectangle.compress.vertical", title: "Compact Mode", color: .gray)
                }
            } header: {
                sectionHeader("Appearance", icon: "paintbrush.fill")
            } footer: {
                Text(.localized("Customize how the Home screen looks and feels."))
            }
            
            // Widget Management Section
            Section {
                Button {
                    withAnimation {
                        isReordering.toggle()
                    }
                } label: {
                    HStack {
                        settingsRow(icon: "arrow.up.arrow.down", title: "Reorder Widgets", color: .orange)
                        Spacer()
                        Image(systemName: isReordering ? "checkmark.circle.fill" : "chevron.right")
                            .foregroundStyle(isReordering ? .green : .secondary)
                            .font(.system(size: 14))
                    }
                }
                .foregroundStyle(.primary)
                
                if isReordering {
                    ForEach(settingsManager.widgets) { widget in
                        reorderableWidgetRow(widget)
                    }
                    .onMove(perform: settingsManager.moveWidget)
                }
            } header: {
                sectionHeader("Widget Order", icon: "square.stack.3d.up.fill")
            } footer: {
                if isReordering {
                    Text(.localized("Drag widgets to reorder them on the Home screen."))
                } else {
                    Text(.localized("Tap to customize the order of widgets."))
                }
            }
            .environment(\.editMode, .constant(isReordering ? .active : .inactive))
            
            // Widgets Toggle Section
            Section {
                ForEach(HomeWidgetType.allCases) { widgetType in
                    widgetToggleRow(widgetType)
                }
            } header: {
                sectionHeader("Widgets", icon: "square.grid.2x2.fill")
            } footer: {
                Text(.localized("Enable or disable widgets on the Home screen. Long press a widget to pin it to the top."))
            }
            
            // Reset Section
            Section {
                Button {
                    showResetConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(.red)
                            .frame(width: 24)
                        Text(.localized("Reset to Defaults"))
                            .foregroundStyle(.red)
                    }
                }
            } footer: {
                Text(.localized("Reset all Home settings to their default values."))
            }
        }
        .alert(.localized("Reset Home Settings"), isPresented: $showResetConfirmation) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Reset"), role: .destructive) {
                settingsManager.resetToDefaults()
                greetingEnabled = true
                animationsEnabled = true
                compactMode = false
                showAppIcon = true
                HapticsManager.shared.success()
            }
        } message: {
            Text(.localized("This will reset all Home screen settings to their default values."))
        }
    }
    
    // MARK: - Helper Views
    @ViewBuilder
    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 26)
            
            Text(.localized(title))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.primary)
        }
    }
    
    @ViewBuilder
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func reorderableWidgetRow(_ widget: HomeWidgetConfig) -> some View {
        HStack(spacing: 12) {
            Image(systemName: widget.type.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(widget.type.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(widget.type.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(widget.isEnabled ? .primary : .secondary)
                
                if widget.isPinned {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                        Text(.localized("Pinned"))
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.orange)
                }
            }
            
            Spacer()
            
            if !widget.isEnabled {
                Text(.localized("Disabled"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private func widgetToggleRow(_ widgetType: HomeWidgetType) -> some View {
        let isEnabled = settingsManager.isEnabled(widgetType)
        let isPinned = settingsManager.isPinned(widgetType)
        
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(widgetType.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: widgetType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(widgetType.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(widgetType.title)
                        .font(.system(size: 15, weight: .medium))
                    
                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                }
                
                Text(widgetType.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { _ in
                    settingsManager.toggleWidget(widgetType)
                    HapticsManager.shared.softImpact()
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                settingsManager.togglePin(widgetType)
                HapticsManager.shared.softImpact()
            } label: {
                Label(
                    isPinned ? String.localized("Unpin") : String.localized("Pin to Top"),
                    systemImage: isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button {
                settingsManager.toggleWidget(widgetType)
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

#Preview {
    NavigationStack {
        HomeSettingsView()
    }
}
