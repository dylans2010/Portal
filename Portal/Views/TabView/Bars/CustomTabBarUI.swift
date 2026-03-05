import SwiftUI

// MARK: - Custom Tab Bar View (Liquid Glass Design)
struct CustomTabBarUI: View {
    @AppStorage("Feather.tabBar.dashboard") private var showDashboard = false
    @AppStorage("Feather.tabBar.sources") private var showSources = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = false
    @AppStorage("Feather.tabBar.guides") private var showGuides = false
    @AppStorage("Feather.tabBar.order") private var tabOrder: String = "sources,library,settings"
    @AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "sources"
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    
    @State private var selectedTab: TabEnum?
    @State private var showInstallModifySheet = false
    @State private var appToInstall: (any AppInfoPresentable)?
    @State private var hoverScale: CGFloat = 1.0
    @Namespace private var animation
    
    private var orderedTabIds: [String] {
        tabOrder.split(separator: ",").map(String.init)
    }
    
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
        
        if sortedTabs.count > maxVisibleTabs {
            var limitedTabs = Array(sortedTabs.prefix(maxVisibleTabs - 1))
            if !limitedTabs.contains(.settings) {
                limitedTabs.append(.settings)
            }
            return limitedTabs
        }
        
        return sortedTabs
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
            TabEnum.view(for: currentTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            liquidGlassTabBar
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if !AppStateManager.shared.hasSelectedInitialTab {
                selectedTab = getInitialTab()
                AppStateManager.shared.hasSelectedInitialTab = true
            }
        }
    }
    
    // MARK: - Liquid Glass Tab Bar
    private var liquidGlassTabBar: some View {
        HStack(spacing: 4) {
            ForEach(visibleTabs, id: \.self) { tab in
                liquidGlassTabButton(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Frosted glass effect with enhanced blur
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Enhanced inner glow
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Enhanced border with gradient
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.08),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 32)
        .padding(.bottom, 8)
    }
    
    // MARK: - Liquid Glass Tab Button
    @ViewBuilder
    private func liquidGlassTabButton(for tab: TabEnum) -> some View {
        let isSelected = currentTab == tab
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75, blendDuration: 0.3)) {
                selectedTab = tab
            }
            HapticsManager.shared.softImpact()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Enhanced selection indicator with multiple layers
                    if isSelected {
                        // Outer glow
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.3),
                                        Color.accentColor.opacity(0.15),
                                        Color.accentColor.opacity(0.05),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 24
                                )
                            )
                            .frame(width: 48, height: 48)
                            .matchedGeometryEffect(id: "tabGlow", in: animation)
                        
                        // Mid-layer blur effect
                        Circle()
                            .fill(Color.accentColor.opacity(0.12))
                            .blur(radius: 4)
                            .frame(width: 38, height: 38)
                        
                        // Inner background
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.2),
                                        Color.accentColor.opacity(0.15)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 36, height: 36)
                            .matchedGeometryEffect(id: "tabBackground", in: animation)
                    }
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 19, weight: isSelected ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(
                            isSelected ? 
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            ) : 
                            LinearGradient(
                                colors: [Color.secondary, Color.secondary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .modifier(TabBarBounceModifier(trigger: isSelected))
                }
                .frame(width: 36, height: 36)
                
                Text(tab.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium, design: .rounded))
                    .foregroundStyle(
                        isSelected ? 
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) : 
                        LinearGradient(
                            colors: [Color.secondary, Color.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(EnhancedLiquidGlassButtonStyle())
    }
}

// MARK: - Tab Bar Bounce Modifier
struct TabBarBounceModifier: ViewModifier {
    let trigger: Bool

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.bounce, value: trigger)
        } else {
            content
        }
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

// MARK: - Enhanced Liquid Glass Button Style
struct EnhancedLiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0.2), value: configuration.isPressed)
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
        case .allapps: return "square.stack.3d.up.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }
}
