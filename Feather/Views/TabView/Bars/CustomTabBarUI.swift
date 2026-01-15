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
            customTabBar
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
    
    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(visibleTabs, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Tab Button
    @ViewBuilder
    private func tabButton(for tab: TabEnum) -> some View {
        let isSelected = selectedTab == tab
        
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
            HapticsManager.shared.softImpact()
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.accentColor.opacity(0.15))
                            .frame(width: 48, height: 32)
                            .matchedGeometryEffect(id: "tabBackground", in: animation)
                    }
                    
                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 32)
                
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        }
    }
}
