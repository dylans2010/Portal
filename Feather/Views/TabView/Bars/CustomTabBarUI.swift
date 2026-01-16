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
    
    // MARK: - Modern Tab Bar (Compact)
    private var modernTabBar: some View {
        HStack(spacing: 0) {
            ForEach(visibleTabs, id: \.self) { tab in
                compactTabButton(for: tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
    }
    
    // MARK: - Compact Tab Button
    @ViewBuilder
    private func compactTabButton(for tab: TabEnum) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            HapticsManager.shared.softImpact()
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                            .matchedGeometryEffect(id: "tabBackground", in: animation)
                    }
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 17, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                }
                .frame(width: 36, height: 36)
                
                Text(tab.title)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
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
