import SwiftUI

// MARK: - Custom Tab Bar View (Liquid Glass Design)
struct CustomTabBarUI: View {
    @AppStorage("Feather.tabBar.dashboard") private var showDashboard = true
    @AppStorage("Feather.tabBar.sources") private var showSources = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = false
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    @AppStorage("Feather.tabBar.order") private var tabOrder: String = "dashboard,sources,guides,library,files,settings"
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    
    @State private var selectedTab: TabEnum = .dashboard
    @State private var showInstallModifySheet = false
    @State private var appToInstall: (any AppInfoPresentable)?
    @State private var hoverScale: CGFloat = 1.0
    @Namespace private var animation
    
    private var orderedTabIds: [String] {
        tabOrder.split(separator: ",").map(String.init)
    }
    
    // Maximum tabs to show (5 to avoid iOS "More" section)
    private let maxVisibleTabs = 5
    
    var visibleTabs: [TabEnum] {
        var enabledTabs: [TabEnum] = []
        if showDashboard { enabledTabs.append(.dashboard) }
        if showSources { enabledTabs.append(.sources) }
        if showGuides && (forceShowGuides || certificateExperience == "Enterprise") {
            enabledTabs.append(.guides)
        }
        if showLibrary { enabledTabs.append(.library) }
        if showFiles { enabledTabs.append(.files) }
        enabledTabs.append(.settings)
        
        var sortedTabs: [TabEnum] = []
        for tabId in orderedTabIds {
            if let tab = TabEnum(rawValue: tabId), enabledTabs.contains(tab) {
                sortedTabs.append(tab)
            }
        }
        
        for tab in enabledTabs {
            if !sortedTabs.contains(tab) {
                if tab == .settings {
                    sortedTabs.append(tab)
                } else {
                    sortedTabs.insert(tab, at: max(0, sortedTabs.count - 1))
                }
            }
        }
        
        // Limit to maxVisibleTabs to avoid "More" section
        // Ensure settings is always included
        if sortedTabs.count > maxVisibleTabs {
            var limitedTabs = Array(sortedTabs.prefix(maxVisibleTabs - 1))
            if !limitedTabs.contains(.settings) {
                limitedTabs.append(.settings)
            }
            return limitedTabs
        }
        
        return sortedTabs
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabEnum.view(for: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            liquidGlassTabBar
        }
        .ignoresSafeArea(.keyboard)
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
    
    // MARK: - Liquid Glass Tab Bar
    private var liquidGlassTabBar: some View {
        HStack(spacing: 0) {
            ForEach(visibleTabs, id: \.self) { tab in
                liquidGlassTabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            ZStack {
                // Frosted glass effect
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle inner glow
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Border with gradient
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 40)
        .padding(.bottom, 6)
    }
    
    // MARK: - Liquid Glass Tab Button
    @ViewBuilder
    private func liquidGlassTabButton(for tab: TabEnum) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            HapticsManager.shared.softImpact()
        } label: {
            VStack(spacing: 3) {
                ZStack {
                    // Selection indicator with glow
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.25),
                                        Color.accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 40, height: 40)
                            .matchedGeometryEffect(id: "tabGlow", in: animation)
                        
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 32, height: 32)
                            .matchedGeometryEffect(id: "tabBackground", in: animation)
                    }
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }
                .frame(width: 32, height: 32)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }
}

// MARK: - Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Tab Button Style (Legacy)
struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Tab Enum Extension for Selected Icons
extension TabEnum {
    var selectedIcon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .sources: return "globe.desk.fill"
        case .library: return "square.stack.3d.up.fill"
        case .files: return "folder.fill"
        case .guides: return "book.fill"
        case .settings: return "gearshape.fill"
        case .certificates: return "person.text.rectangle.fill"
        }
    }
}
