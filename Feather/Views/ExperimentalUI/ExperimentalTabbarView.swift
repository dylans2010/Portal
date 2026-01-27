//
//  ExperimentalTabbarView.swift
//  Feather
//
//  Experimental UI redesigned tabbar
//

import SwiftUI

struct ExperimentalTabbarView: View {
    @State private var selectedTab: TabEnum?
    @AppStorage("Feather.tabBar.dashboard") private var showDashboard = true
    @AppStorage("Feather.tabBar.sources") private var showSources = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = true
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    @AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "dashboard"
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @Namespace private var animation
    
    @State private var showInstallModifySheet = false
    @State private var appToInstall: (any AppInfoPresentable)?
    
    var visibleTabs: [TabEnum] {
        var tabs: [TabEnum] = []
        if showDashboard { tabs.append(.dashboard) }
        if showSources { tabs.append(.sources) }
        if showLibrary { tabs.append(.library) }
        if showFiles { tabs.append(.files) }
        
        if showGuides && (forceShowGuides || certificateExperience == "Enterprise") {
            tabs.append(.guides)
        }
        
        tabs.append(.settings)
        return tabs
    }
    
    private func getInitialTab() -> TabEnum {
        switch defaultTab {
        case "dashboard": return visibleTabs.contains(.dashboard) ? .dashboard : visibleTabs.first ?? .settings
        case "sources": return visibleTabs.contains(.sources) ? .sources : visibleTabs.first ?? .settings
        case "library": return visibleTabs.contains(.library) ? .library : visibleTabs.first ?? .settings
        case "files": return visibleTabs.contains(.files) ? .files : visibleTabs.first ?? .settings
        case "guides": return visibleTabs.contains(.guides) ? .guides : visibleTabs.first ?? .settings
        case "settings": return .settings
        default: return visibleTabs.first ?? .settings
        }
    }
    
    private var currentTab: TabEnum {
        selectedTab ?? getInitialTab()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: Binding(
                get: { currentTab },
                set: { selectedTab = $0 }
            )) {
                ForEach(visibleTabs, id: \.hashValue) { tab in
                    ExperimentalTabContent(for: tab)
                        .tag(tab)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            ExperimentalCustomTabBar(
                selectedTab: Binding(
                    get: { currentTab },
                    set: { selectedTab = $0 }
                ),
                tabs: visibleTabs,
                namespace: animation
            )
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            .padding(.bottom, ExperimentalUITheme.Spacing.sm)
        }
        .experimentalGradientBackground()
        .onAppear {
            if selectedTab == nil {
                selectedTab = getInitialTab()
            }
        }
        .sheet(isPresented: $showInstallModifySheet) {
            if let app = appToInstall {
                InstallModifyDialogView(app: app)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("Feather.showInstallModifyPopup"))) { notification in
            if let url = notification.object as? URL {
                let fileName = url.deletingPathExtension().lastPathComponent
                let signedRequest = Signed.fetchRequest()
                let importedRequest = Imported.fetchRequest()
                
                if let signed = try? Storage.shared.context.fetch(signedRequest).first(where: { 
                    $0.name?.contains(fileName) == true || $0.identifier?.contains(fileName) == true
                }) {
                    appToInstall = signed
                    showInstallModifySheet = true
                } else if let imported = try? Storage.shared.context.fetch(importedRequest).first(where: { 
                    $0.name?.contains(fileName) == true || $0.identifier?.contains(fileName) == true
                }) {
                    appToInstall = imported
                    showInstallModifySheet = true
                }
            }
        }
    }
}

// MARK: - Experimental Tab Content
struct ExperimentalTabContent: View {
    let tab: TabEnum
    
    init(for tab: TabEnum) {
        self.tab = tab
    }
    
    var body: some View {
        Group {
            switch tab {
            case .dashboard:
                HomeView()
            case .sources:
                ExperimentalSourcesView()
            case .library:
                ExperimentalLibraryView()
            case .settings:
                ExperimentalSettingsView()
            case .files:
                ExperimentalFilesView()
            case .guides:
                ExperimentalGuidesView()
            default:
                Text("Coming Soon")
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct ExperimentalCustomTabBar: View {
    @Binding var selectedTab: TabEnum
    let tabs: [TabEnum]
    let namespace: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.hashValue) { tab in
                ExperimentalTabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    namespace: namespace
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                        HapticsManager.shared.softImpact()
                    }
                }
            }
        }
        .padding(.horizontal, ExperimentalUITheme.Spacing.sm)
        .padding(.vertical, ExperimentalUITheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.xl)
                .fill(.ultraThinMaterial)
                .shadow(
                    color: ExperimentalUITheme.Shadow.lg.color,
                    radius: ExperimentalUITheme.Shadow.lg.radius,
                    x: ExperimentalUITheme.Shadow.lg.x,
                    y: ExperimentalUITheme.Shadow.lg.y
                )
        )
    }
}

// MARK: - Tab Bar Item
struct ExperimentalTabBarItem: View {
    let tab: TabEnum
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                            .fill(ExperimentalUITheme.Gradients.primary)
                            .matchedGeometryEffect(id: "selectedTab", in: namespace)
                            .frame(width: 50, height: 50)
                    }
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : ExperimentalUITheme.Colors.textSecondary)
                        .frame(width: 50, height: 50)
                }
                
                if isSelected {
                    Text(tab.title)
                        .font(ExperimentalUITheme.Typography.caption)
                        .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                        .fontWeight(.semibold)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
