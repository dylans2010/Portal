//  feather
import SwiftUI

struct TabbarView: View {
	@State private var selectedTab: TabEnum = .home
	@AppStorage("Feather.tabBar.home") private var showHome = true
	@AppStorage("Feather.tabBar.library") private var showLibrary = true
	@AppStorage("Feather.tabBar.files") private var showFiles = false
	@AppStorage("Feather.tabBar.guides") private var showGuides = true
	@AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "home"
	@AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
	@AppStorage("forceShowGuides") private var forceShowGuides = false
	
	@State private var showInstallModifySheet = false
	@State private var appToInstall: (any AppInfoPresentable)?
	@State private var hasSetInitialTab = false
	
	var visibleTabs: [TabEnum] {
		var tabs: [TabEnum] = []
		if showHome { tabs.append(.home) }
		if showGuides && (forceShowGuides || certificateExperience == "Enterprise") {
			tabs.append(.guides)
		}
		if showLibrary { tabs.append(.library) }
		if showFiles { tabs.append(.files) }
		
		tabs.append(.settings) // Always show settings
		return tabs
	}
	
	private var initialTab: TabEnum {
		switch defaultTab {
		case "home": return visibleTabs.contains(.home) ? .home : visibleTabs.first ?? .settings
		case "library": return visibleTabs.contains(.library) ? .library : visibleTabs.first ?? .settings
		case "files": return visibleTabs.contains(.files) ? .files : visibleTabs.first ?? .settings
		case "guides": return visibleTabs.contains(.guides) ? .guides : visibleTabs.first ?? .settings
		case "settings": return .settings
		default: return visibleTabs.first ?? .settings
		}
	}

	var body: some View {
		TabView(selection: $selectedTab) {
			ForEach(visibleTabs, id: \.hashValue) { tab in
				TabEnum.view(for: tab)
					.tabItem {
						ConditionalLabel(title: LocalizedStringKey(tab.title), systemImage: tab.icon)
					}
					.tag(tab)
			}
		}
		.onAppear {
			if !hasSetInitialTab {
				selectedTab = initialTab
				hasSetInitialTab = true
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
