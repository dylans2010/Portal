//  feather
import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
	case dashboard
	case sources
	case library
	case settings
	case certificates
	case files
	case guides
	
	var title: String {
		switch self {
		case .dashboard:	return .localized("Home")
		case .sources:     	return .localized("Sources")
		case .library: 		return .localized("Library")
		case .settings: 	return .localized("Settings")
		case .certificates:	return .localized("Certificates")
		case .files:		return .localized("Files")
		case .guides:		return .localized("Guides")
		}
	}
	
	var icon: String {
		switch self {
		case .dashboard:	return "house.fill"
		case .sources: 		return "globe.desk.fill"
		case .library: 		return "square.grid.2x2"
		case .settings: 	return "gearshape.2"
		case .certificates: return "person.text.rectangle"
		case .files:		return "folder.fill"
		case .guides:		return "book.fill"
		}
	}
	
	@ViewBuilder
	static func view(for tab: TabEnum) -> some View {
		switch tab {
		case .dashboard: HomeView()
		case .sources: SourcesView()
		case .library: LibraryView()
		case .settings: SettingsView()
		case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
		case .files: FilesView()
		case .guides: GuidesView()
		}
	}
	
	static var defaultTabs: [TabEnum] {
		return [
			.dashboard,
			.sources,
			.guides,
			.library,
			.settings
		]
	}
	
	static var customizableTabs: [TabEnum] {
		// No customizable tabs anymore - all are default
		return []
	}
}
