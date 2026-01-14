import SwiftUI
import NimbleViews

// MARK: - TabBarCustomizationView
struct TabBarCustomizationView: View {
    @AppStorage("Feather.tabBar.home") private var showHome = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = false
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    @AppStorage("Feather.tabBar.order") private var tabOrder: String = "home,guides,library,files,settings"
    @AppStorage("Feather.tabBar.hideLabels") private var hideTabLabels = false
    @AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "home"
    // Settings cannot be disabled
    
    @State private var showMinimumWarning = false
    @State private var orderedTabs: [String] = []
    @State private var isReordering = false
    
    private var availableDefaultTabs: [String] {
        var tabs: [String] = []
        if showHome { tabs.append("home") }
        if showGuides { tabs.append("guides") }
        if showLibrary { tabs.append("library") }
        if showFiles { tabs.append("files") }
        tabs.append("settings")
        return tabs
    }
    
    var body: some View {
        NBList(.localized("Tab Bar")) {
            // Default Tab Section
            Section {
                Picker(selection: $defaultTab) {
                    ForEach(availableDefaultTabs, id: \.self) { tabId in
                        HStack {
                            tabIcon(for: tabId)
                            Text(tabName(for: tabId))
                        }
                        .tag(tabId)
                    }
                } label: {
                    HStack {
                        Image(systemName: "house.circle.fill")
                            .foregroundStyle(.green)
                            .frame(width: 24)
                        Text(.localized("Default Tab"))
                    }
                }
            } header: {
                Text(.localized("Launch"))
            } footer: {
                Text(.localized("Choose which tab opens by default when you launch the app (Beta)."))
            }
            .onChange(of: showHome) { _ in validateDefaultTab() }
            .onChange(of: showLibrary) { _ in validateDefaultTab() }
            .onChange(of: showFiles) { _ in validateDefaultTab() }
            .onChange(of: showGuides) { _ in validateDefaultTab() }
            
            // Tab Labels Section
            Section {
                Toggle(isOn: $hideTabLabels) {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundStyle(.blue)
                            .frame(width: 24)
                        Text(.localized("Hide Tab Labels"))
                    }
                }
            } header: {
                Text(.localized("Appearance"))
            } footer: {
                Text(.localized("Hide the labels under tab bar icons for a cleaner look."))
            }
            
            // Reorder Section
            Section {
                Button {
                    isReordering.toggle()
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundStyle(.orange)
                            .frame(width: 24)
                        Text(.localized("Reorder Tabs"))
                        Spacer()
                        Image(systemName: isReordering ? "checkmark.circle.fill" : "chevron.right")
                            .foregroundStyle(isReordering ? .green : .secondary)
                            .font(.system(size: 14))
                    }
                }
                .foregroundStyle(.primary)
                
                if isReordering {
                    ForEach(orderedTabs, id: \.self) { tabId in
                        reorderableTabRow(for: tabId)
                    }
                    .onMove(perform: moveTab)
                    
                    Button {
                        resetTabOrder()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundStyle(.red)
                                .frame(width: 24)
                            Text(.localized("Reset To Default Order"))
                        }
                    }
                    .foregroundStyle(.red)
                }
            } header: {
                Text(.localized("Tab Order"))
            } footer: {
                if isReordering {
                    Text(.localized("Drag tabs to reorder them. Settings will always appear last."))
                } else {
                    Text(.localized("Tap to customize the order of tabs in the tab bar."))
                }
            }
            .environment(\.editMode, .constant(isReordering ? .active : .inactive))
            
            // Visible Tabs Section
            Section {
                ForEach(orderedTabs, id: \.self) { tabId in
                    tabRow(for: tabId)
                }
            } header: {
                Text(.localized("Visible Tabs"))
            } footer: {
                Text(.localized("Choose which tabs appear in the bottom tab bar. Settings cannot be hidden."))
            }
        }
        .onAppear {
            loadTabOrder()
        }
        .alert(.localized("Minimum Tabs Required"), isPresented: $showMinimumWarning) {
            Button(.localized("OK")) {
                showMinimumWarning = false
            }
        } message: {
            Text(.localized("At least 2 tabs must be visible (including Settings)."))
        }
    }
    
    @ViewBuilder
    private func reorderableTabRow(for tabId: String) -> some View {
        HStack {
            tabIcon(for: tabId)
            Text(tabName(for: tabId))
            Spacer()
            if tabId == "settings" {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func tabIcon(for tabId: String) -> some View {
        Group {
            switch tabId {
            case "home":
                Image(systemName: "house.fill")
                    .foregroundStyle(.blue)
            case "library":
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.purple)
            case "files":
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
            case "guides":
                Image(systemName: "book.fill")
                    .foregroundStyle(.orange)
            case "settings":
                Image(systemName: "gearshape.2")
                    .foregroundStyle(.gray)
            default:
                Image(systemName: "questionmark")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 24)
    }
    
    private func tabName(for tabId: String) -> String {
        switch tabId {
        case "home": return String.localized("Home")
        case "library": return String.localized("Library")
        case "files": return String.localized("Files")
        case "guides": return String.localized("Guides")
        case "settings": return String.localized("Settings")
        default: return tabId.capitalized
        }
    }
    
    @ViewBuilder
    private func tabRow(for tabId: String) -> some View {
        switch tabId {
        case "home":
            Toggle(isOn: $showHome) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text(.localized("Home"))
                }
            }
            .disabled(!canDisable(.home))
            .onChange(of: showHome) { _ in validateMinimumTabs() }
            
        case "library":
            Toggle(isOn: $showLibrary) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(.purple)
                        .frame(width: 24)
                    Text(.localized("Library"))
                }
            }
            .disabled(!canDisable(.library))
            .onChange(of: showLibrary) { _ in validateMinimumTabs() }
            
        case "files":
            Toggle(isOn: $showFiles) {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text(.localized("Files"))
                }
            }
            .disabled(!canDisable(.files))
            .onChange(of: showFiles) { _ in validateMinimumTabs() }
            
        case "guides":
            Toggle(isOn: $showGuides) {
                HStack {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.orange)
                        .frame(width: 24)
                    Text(.localized("Guides"))
                }
            }
            .disabled(!canDisable(.guides))
            .onChange(of: showGuides) { _ in validateMinimumTabs() }
            
        case "settings":
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundStyle(.gray)
                    .frame(width: 24)
                Text(.localized("Settings"))
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            
        default:
            EmptyView()
        }
    }
    
    private func loadTabOrder() {
        let tabs = tabOrder.split(separator: ",").map(String.init)
        orderedTabs = tabs.isEmpty ? ["home", "guides", "library", "files", "settings"] : tabs
    }
    
    private func moveTab(from source: IndexSet, to destination: Int) {
        // Don't allow moving settings from last position
        guard let sourceIndex = source.first else { return }
        let movingTab = orderedTabs[sourceIndex]
        
        // Settings must stay at the end
        if movingTab == "settings" { return }
        
        // Don't allow moving past settings
        let settingsIndex = orderedTabs.firstIndex(of: "settings") ?? orderedTabs.count - 1
        let adjustedDestination = min(destination, settingsIndex)
        
        orderedTabs.move(fromOffsets: source, toOffset: adjustedDestination)
        
        // Ensure settings is always last
        if let settingsIdx = orderedTabs.firstIndex(of: "settings"), settingsIdx != orderedTabs.count - 1 {
            orderedTabs.remove(at: settingsIdx)
            orderedTabs.append("settings")
        }
        
        saveTabOrder()
    }
    
    private func saveTabOrder() {
        tabOrder = orderedTabs.joined(separator: ",")
    }
    
    private func resetTabOrder() {
        orderedTabs = ["home", "guides", "library", "files", "settings"]
        saveTabOrder()
    }
    
    private func validateMinimumTabs() {
        let visibleCount = [showHome, showLibrary, showFiles, showGuides].filter { $0 }.count + 1 // +1 for Settings
        if visibleCount < 2 {
            showMinimumWarning = true
            // Revert the last change
            if !showHome && !showLibrary && !showFiles && !showGuides {
                // Need at least one non-settings tab
                showHome = true
            }
        }
    }
    
    private func canDisable(_ tab: TabEnum) -> Bool {
        let visibleCount = [showHome, showLibrary, showFiles, showGuides].filter { $0 }.count + 1
        if visibleCount <= 2 {
            // Check if this specific tab is currently enabled
            switch tab {
            case .home: return !showHome
            case .library: return !showLibrary
            case .files: return !showFiles
            case .guides: return !showGuides
            default: return false
            }
        }
        return true
    }
    
    private func validateDefaultTab() {
        // If the current default tab is no longer available, reset to first available
        if !availableDefaultTabs.contains(defaultTab) {
            defaultTab = availableDefaultTabs.first ?? "settings"
        }
    }
}
