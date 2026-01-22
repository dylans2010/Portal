//  feather
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import SwiftUI
import NukeUI

@available(iOS 18, *)
struct ExtendedTabbarView: View {
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@AppStorage("Feather.tabCustomization") var customization = TabViewCustomization()
	@AppStorage("Feather.tabBar.dashboard") private var showDashboard = true
	@AppStorage("Feather.tabBar.sources") private var showSources = true
	@AppStorage("Feather.tabBar.library") private var showLibrary = true
	@AppStorage("Feather.tabBar.files") private var showFiles = true
	@AppStorage("Feather.tabBar.guides") private var showGuides = true
	@AppStorage("Feather.tabBar.order") private var tabOrder: String = "dashboard,sources,guides,library,files,settings"
	@AppStorage("Feather.tabBar.hideLabels") private var hideTabLabels = false
	@AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "dashboard"
	@AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
	@AppStorage("forceShowGuides") private var forceShowGuides = false
	@StateObject var viewModel = SourcesViewModel.shared
	
	@State private var selectedTab: TabEnum?
	@State private var _isAddingPresenting = false
	@State private var showInstallModifySheet = false
	@State private var appToInstall: (any AppInfoPresentable)?
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
		animation: .easeInOut(duration: 0.35)
	) private var _sources: FetchedResults<AltSource>
	
	private var orderedTabIds: [String] {
		tabOrder.split(separator: ",").map(String.init)
	}
	
	var visibleTabs: [TabEnum] {
		var enabledTabs: [TabEnum] = []
		if showDashboard { enabledTabs.append(.dashboard) }
		if showSources { enabledTabs.append(.sources) }
		if showLibrary { enabledTabs.append(.library) }
		if showFiles { enabledTabs.append(.files) }
		
		// Only show Guides if:
		// 1. forceShowGuides is enabled (set by Enterprise certificate)
		// 2. OR certificate experience is Enterprise
		if showGuides && (forceShowGuides || certificateExperience == "Enterprise") {
			enabledTabs.append(.guides)
		}
		
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
		TabView {
			ForEach(visibleTabs, id: \.hashValue) { tab in
				Tab(hideTabLabels ? "" : tab.title, systemImage: tab.icon) {
					TabEnum.view(for: tab)
				}
			}
			
			TabSection("Sources") {
				Tab(.localized("All Repositories"), systemImage: "globe.desk") {
					NavigationStack {
						SourceAppsView(object: Array(_sources), viewModel: viewModel)
					}
				}
				
				ForEach(_sources, id: \.identifier) { source in
					Tab {
						NavigationStack {
							SourceAppsView(object: [source], viewModel: viewModel)
						}
					} label: {
						_icon(source.name ?? .localized("Unknown"), iconUrl: source.iconURL)
					}
					.swipeActions {
						Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
							Storage.shared.deleteSource(for: source)
						}
					}
				}
			}
			.sectionActions {
				Button(.localized("Add Source"), systemImage: "plus") {
					_isAddingPresenting = true
				}
			}
			.defaultVisibility(.hidden, for: .tabBar)
			.hidden(horizontalSizeClass == .compact)
		}
		.tabViewStyle(.sidebarAdaptable)
		.tabViewCustomization($customization)
		.sheet(isPresented: $_isAddingPresenting) {
			SourcesAddView()
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
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
	
	@ViewBuilder
	private func _icon(_ title: String, iconUrl: URL?) -> some View {
		Label {
			Text(title)
		} icon: {
			if let iconURL = iconUrl {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image
					} else {
						standardIcon
					}
				}
				.processors([.resize(width: 14), .circle()])
			} else {
				standardIcon
			}
		}
	}

	
	var standardIcon: some View {
		Image(systemName: "app.dashed")
	}
}

