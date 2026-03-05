import SwiftUI
import NimbleViews

// MARK: - TabBarCustomizationView
struct TabBarCustomizationView: View {
    @AppStorage("Feather.tabBar.dashboard") private var showDashboard = false
    @AppStorage("Feather.tabBar.sources") private var showSources = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = false
    @AppStorage("Feather.tabBar.guides") private var showGuides = false
    @AppStorage("Feather.tabBar.allApps") private var showAllApps = false
    @AppStorage("Feather.tabBar.order") private var tabOrder: String = "sources,library,settings"
    @AppStorage("Feather.tabBar.hideLabels") private var hideTabLabels = false
    @AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "sources"
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    // Settings cannot be disabled
    
    @State private var showMinimumWarning = false
    @State private var orderedTabs: [String] = []
    @State private var isReordering = false
    
    private var availableDefaultTabs: [String] {
        var tabs: [String] = []
        if showDashboard { tabs.append("dashboard") }
        if showSources { tabs.append("sources") }
        if showGuides { tabs.append("guides") }
        if showLibrary { tabs.append("library") }
        if showFiles { tabs.append("files") }
        if showAllApps { tabs.append("allapps") }
        tabs.append("settings")
        return tabs
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if showHeaderViews {
                    TabBarHeaderView()
                        .padding(.horizontal, 16)
                }

                // Tab Labels Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: .localized("Appearance").uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 16)

                    VStack(spacing: 0) {
                        Toggle(isOn: $hideTabLabels) {
                            HStack(spacing: 12) {
                                Image(systemName: "textformat")
                                    .foregroundStyle(.blue)
                                    .frame(width: 32, height: 32)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Circle())
                                Text(verbatim: .localized("Hide Tab Labels"))
                                    .font(.system(size: 16, weight: .medium))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)

                    Text(verbatim: .localized("Hide the labels under tab bar icons for a cleaner and nicer look."))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }

                // Reorder Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: .localized("Tab Order").uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 16)

                    VStack(spacing: 0) {
                        Button {
                            withAnimation(.spring()) {
                                isReordering.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.arrow.down")
                                    .foregroundStyle(.orange)
                                    .frame(width: 32, height: 32)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Circle())
                                Text(verbatim: .localized("Reorder Tabs"))
                                    .font(.system(size: 16, weight: .medium))
                                Spacer()
                                Image(systemName: isReordering ? "checkmark.circle.fill" : "chevron.right")
                                    .foregroundStyle(isReordering ? .green : .secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if isReordering {
                            Divider().padding(.leading, 60)

                            List {
                                ForEach(orderedTabs, id: \.self) { tabId in
                                    reorderableTabRow(for: tabId)
                                }
                                .onMove(perform: moveTab)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            }
            .scrollContentBackground(.hidden)
                            .listStyle(.plain)
                            .frame(height: CGFloat(orderedTabs.count * 44))
                            .environment(\.editMode, .constant(.active))

                            Divider().padding(.leading, 60)

                            Button {
                                resetTabOrder()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundStyle(.red)
                                        .frame(width: 32, height: 32)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(Circle())
                                Text(verbatim: .localized("Reset To Default Order"))
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                    }
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)

                    Text(verbatim: isReordering ? .localized("Drag tabs to reorder them. Settings will always appear last.") : .localized("Tap to customize the order of tabs in the Tab Bar."))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }
                
                // Visible Tabs Section
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: .localized("Visible Tabs").uppercased())
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 16)
                    
                    VStack(spacing: 0) {
                        ForEach(orderedTabs.indices, id: \.self) { index in
                            let tabId = orderedTabs[index]
                            tabRow(for: tabId)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)

                            if index < orderedTabs.count - 1 {
                                Divider().padding(.leading, 60)
                            }
                        }
                    }
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)

                    Text(verbatim: .localized("Choose which tabs appear in the bottom tab bar."))
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color.clear)
        .navigationTitle(.localized("Tab Bar"))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadTabOrder()
        }
        .alert(.localized("Minimum Tabs Required"), isPresented: $showMinimumWarning) {
            Button(.localized("OK")) {
                showMinimumWarning = false
            }
        } message: {
            Text(verbatim: .localized("At least 2 tabs must be visible (including Settings)."))
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
            case "dashboard":
                Image(systemName: "house.fill")
                    .foregroundStyle(.blue)
            case "sources":
                Image(systemName: "globe.desk.fill")
                    .foregroundStyle(.cyan)
            case "library":
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(.purple)
            case "files":
                Image(systemName: "folder.fill")
                    .foregroundStyle(.blue)
            case "guides":
                Image(systemName: "book.fill")
                    .foregroundStyle(.orange)
            case "allapps":
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(.pink)
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
        case "dashboard": return String.localized("Home")
        case "sources": return String.localized("Sources")
        case "library": return String.localized("Library")
        case "files": return String.localized("Files")
        case "guides": return String.localized("Guides")
        case "allapps": return String.localized("All Apps")
        case "settings": return String.localized("Settings")
        default: return tabId.capitalized
        }
    }
    
    @ViewBuilder
    private func tabRow(for tabId: String) -> some View {
        switch tabId {
        case "dashboard":
            Toggle(isOn: $showDashboard) {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 24)
                    Text(verbatim: .localized("Home"))
                }
            }
            .disabled(!canDisable(.dashboard))
            .onChange(of: showDashboard) { _ in validateMinimumTabs() }
            
        case "sources":
            Toggle(isOn: $showSources) {
                HStack {
                    Image(systemName: "globe.desk.fill")
                        .foregroundStyle(.cyan)
                        .frame(width: 24)
                    Text(verbatim: .localized("Sources"))
                }
            }
            .disabled(!canDisable(.sources))
            .onChange(of: showSources) { _ in validateMinimumTabs() }
            
        case "library":
            Toggle(isOn: $showLibrary) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(.purple)
                        .frame(width: 24)
                    Text(verbatim: .localized("Library"))
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
                    Text(verbatim: .localized("Files"))
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
                    Text(verbatim: .localized("Guides"))
                }
            }
            .disabled(!canDisable(.guides))
            .onChange(of: showGuides) { _ in validateMinimumTabs() }

        case "allapps":
            Toggle(isOn: $showAllApps) {
                HStack {
                    Image(systemName: "square.stack.3d.up.fill")
                        .foregroundStyle(.pink)
                        .frame(width: 24)
                    Text(verbatim: .localized("All Apps"))
                }
            }
            .disabled(!canDisable(.allapps))
            .onChange(of: showAllApps) { _ in validateMinimumTabs() }
            
        case "settings":
            HStack {
                Image(systemName: "gearshape.2")
                    .foregroundStyle(.gray)
                    .frame(width: 24)
                Text(verbatim: .localized("Settings"))
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
        var tabs = tabOrder.split(separator: ",").map(String.init)
        if tabs.isEmpty {
            tabs = ["sources", "library", "settings"]
        } else if !tabs.contains("allapps") {
            // Add allapps if missing, usually before settings
            if let settingsIndex = tabs.firstIndex(of: "settings") {
                tabs.insert("allapps", at: settingsIndex)
            } else {
                tabs.append("allapps")
            }
        }
        orderedTabs = tabs
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
        orderedTabs = ["sources", "library", "settings"]
        saveTabOrder()
    }
    
    private func validateMinimumTabs() {
        let visibleCount = [showDashboard, showSources, showLibrary, showFiles, showGuides, showAllApps].filter { $0 }.count + 1 // +1 for Settings
        if visibleCount < 2 {
            showMinimumWarning = true
            // Revert the last change
            if !showDashboard && !showSources && !showLibrary && !showFiles && !showGuides && !showAllApps {
                // Need at least one non-settings tab
                showDashboard = true
            }
        }
    }
    
    private func canDisable(_ tab: TabEnum) -> Bool {
        let visibleCount = [showDashboard, showSources, showLibrary, showFiles, showGuides, showAllApps].filter { $0 }.count + 1
        if visibleCount <= 2 {
            // Check if this specific tab is currently enabled
            switch tab {
            case .dashboard: return !showDashboard
            case .sources: return !showSources
            case .library: return !showLibrary
            case .files: return !showFiles
            case .guides: return !showGuides
            case .allapps: return !showAllApps
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
