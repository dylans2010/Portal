//  feather
import SwiftUI

struct TabbarView: View {
	@AppStorage("Feather.tabBar.dashboard") private var showDashboard = true
	@AppStorage("Feather.tabBar.sources") private var showSources = true
	@AppStorage("Feather.tabBar.library") private var showLibrary = true
	@AppStorage("Feather.tabBar.files") private var showFiles = false
	@AppStorage("Feather.tabBar.guides") private var showGuides = true
	@AppStorage("Feather.tabBar.order") private var tabOrder: String = "dashboard,sources,guides,library,files,settings"
	@AppStorage("Feather.tabBar.hideLabels") private var hideTabLabels = false
	@AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "dashboard"
	@AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
	@AppStorage("forceShowGuides") private var forceShowGuides = false
	
	@State private var selectedTab: TabEnum?
	@State private var showInstallModifySheet = false
	@State private var appToInstall: (any AppInfoPresentable)?
	
	private var orderedTabIds: [String] {
		tabOrder.split(separator: ",").map(String.init)
	}
	
	var visibleTabs: [TabEnum] {
		var enabledTabs: [TabEnum] = []
		if showDashboard { enabledTabs.append(.dashboard) }
		if showSources { enabledTabs.append(.sources) }
		if showGuides && (forceShowGuides || certificateExperience == "Enterprise") {
			enabledTabs.append(.guides)
		}
		if showLibrary { enabledTabs.append(.library) }
		if showFiles { enabledTabs.append(.files) }
		enabledTabs.append(.settings) // Always show settings
		
		// Sort tabs based on saved order
		var sortedTabs: [TabEnum] = []
		for tabId in orderedTabIds {
			if let tab = TabEnum(rawValue: tabId), enabledTabs.contains(tab) {
				sortedTabs.append(tab)
			}
		}
		
		// Add any enabled tabs that weren't in the order (fallback)
		for tab in enabledTabs {
			if !sortedTabs.contains(tab) {
				if tab == .settings {
					sortedTabs.append(tab) // Settings always last
				} else {
					sortedTabs.insert(tab, at: max(0, sortedTabs.count - 1))
				}
			}
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

	var body: some View {
		TabView(selection: Binding(
			get: { selectedTab ?? getInitialTab() },
			set: { selectedTab = $0 }
		)) {
			ForEach(visibleTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						if hideTabLabels {
							Image(systemName: tab.icon)
						} else {
							Label(tab.title, systemImage: tab.icon)
						}
					}
					.tag(tab)
			}
		}
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
			// Get the downloaded app from the Library
			if let url = notification.object as? URL {
				// Find the app in library by checking the file name
				let fileName = url.deletingPathExtension().lastPathComponent
				
				// Check both Signed and Imported apps
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
