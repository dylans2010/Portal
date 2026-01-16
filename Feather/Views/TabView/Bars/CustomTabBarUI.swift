import SwiftUI

// MARK: - Custom Tab Bar View
struct CustomTabBarUI: View {
    @AppStorage("Feather.tabBar.home") private var showHome = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = false
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    @AppStorage("Feather.tabBar.order") private var tabOrder: String = "home,guides,library,files,settings"
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    
    @State private var selectedTab: TabEnum = .home
    @State private var showInstallModifySheet = false
    @State private var appToInstall: (any AppInfoPresentable)?
    @State private var tabBarScale: CGFloat = 1.0
    @Namespace private var animation
    
    private var orderedTabIds: [String] {
        tabOrder.split(separator: ",").map(String.init)
    }
    
    var visibleTabs: [TabEnum] {
        var enabledTabs: [TabEnum] = []
        if showHome { enabledTabs.append(.home) }
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
        
        return sortedTabs
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabEnum.view(for: selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            modernTabBar
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
    
    // MARK: - Modern Tab Bar
    private var modernTabBar: some View {
        HStack(spacing: 4) {
            ForEach(visibleTabs, id: \.self) { tab in
                modernTabButton(for: tab)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Glassmorphism base
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Subtle gradient overlay
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Border with gradient
                RoundedRectangle(cornerRadius: 28, style: .continuous)
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
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.12), radius: 25, x: 0, y: -8)
        .shadow(color: Color.accentColor.opacity(0.08), radius: 20, x: 0, y: -5)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
        .scaleEffect(tabBarScale)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                tabBarScale = 1.0
            }
        }
    }
    
    // MARK: - Modern Tab Button
    @ViewBuilder
    private func modernTabButton(for tab: TabEnum) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            HapticsManager.shared.softImpact()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Selected background with glow
                    if isSelected {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.3),
                                        Color.accentColor.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 25
                                )
                            )
                            .frame(width: 50, height: 50)
                            .blur(radius: 5)
                        
                        // Background pill
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.2),
                                        Color.accentColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 36)
                            .overlay(
                                Capsule()
                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                            )
                            .matchedGeometryEffect(id: "tabBackground", in: animation)
                    }
                    
                    // Icon with animation
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: isSelected ? 20 : 18, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(
                            isSelected 
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(Color.secondary)
                        )
                        .scaleEffect(isSelected ? 1.0 : 0.9)
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(height: 36)
                
                // Label
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .opacity(isSelected ? 1.0 : 0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabButtonStyle())
    }
}

// MARK: - Tab Button Style
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
        case .home: return "house.fill"
        case .library: return "square.stack.3d.up.fill"
        case .files: return "folder.fill"
        case .guides: return "book.fill"
        case .settings: return "gearshape.fill"
        case .certificates: return "person.text.rectangle.fill"
        }
    }
}
