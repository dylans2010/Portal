//  feather
//  Copyright (c) 2024 Samara M (khcrysalis)
//

import SwiftUI
import NukeUI

@available(iOS 18, *)
struct ExtendedTabbarView: View {
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@AppStorage("Feather.tabCustomization") var customization = TabViewCustomization()
	@AppStorage("Feather.tabBar.dashboard") private var showDashboard = false
	@AppStorage("Feather.tabBar.sources") private var showSources = true
	@AppStorage("Feather.tabBar.library") private var showLibrary = true
	@AppStorage("Feather.tabBar.files") private var showFiles = false
	@AppStorage("Feather.tabBar.guides") private var showGuides = false
	@AppStorage("Feather.tabBar.allApps") private var showAllApps = false
	@AppStorage("Feather.tabBar.order") private var tabOrder: String = "sources,library,settings"
	@AppStorage("Feather.tabBar.hideLabels") private var hideTabLabels = false
	@AppStorage("Feather.tabBar.defaultTab") private var defaultTab: String = "sources"
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
	
	// Maximum tabs to show (5 to avoid iOS "More" section)
	private let maxVisibleTabs = 5
	
	var visibleTabs: [TabEnum] {
		var enabledTabs: [TabEnum] = []
		if showDashboard { enabledTabs.append(.dashboard) }
		if showSources { enabledTabs.append(.sources) }
		if showLibrary { enabledTabs.append(.library) }
		if showFiles { enabledTabs.append(.files) }
		if showAllApps { enabledTabs.append(.allapps) }

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
				if tab == .sources && horizontalSizeClass != .compact {
					Tab(hideTabLabels ? "" : tab.title, systemImage: "list.bullet.rectangle", value: tab) {
						customiPadSourcesView
					}
				} else {
					Tab(hideTabLabels ? "" : tab.title, systemImage: tab.icon, value: tab) {
						TabEnum.view(for: tab)
					}
				}
			}
		}
		.tabViewStyle(.sidebarAdaptable)
		.tabViewCustomization($customization)
		.onAppear {
			if !AppStateManager.shared.hasSelectedInitialTab {
				selectedTab = getInitialTab()
				AppStateManager.shared.hasSelectedInitialTab = true
			}
		}
		.sheet(isPresented: $_isAddingPresenting) {
			SourcesAddView()
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
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

	@ViewBuilder
	private var customiPadSourcesView: some View {
		NavigationStack {
			List {
				NavigationLink {
					SourceAppsView(object: Array(_sources), viewModel: viewModel)
				} label: {
					Label(.localized("All Repositories"), systemImage: "globe.desk")
				}

				ForEach(_sources, id: \.identifier) { source in
					NavigationLink {
						SourceAppsView(object: [source], viewModel: viewModel)
					} label: {
						_icon(source.name ?? .localized("Unknown"), iconUrl: source.iconURL)
					}
				}
			}
            .scrollContentBackground(.hidden)
			.navigationTitle(.localized("Sources"))
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						_isAddingPresenting = true
					} label: {
						Label(.localized("Add Source"), systemImage: "plus")
					}
				}
			}
		}
	}
}

