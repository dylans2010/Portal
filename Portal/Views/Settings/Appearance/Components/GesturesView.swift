import SwiftUI
import NimbleViews

struct GesturesView: View {
    @StateObject private var gestureManager = GestureManager.shared

    // Tab visibility states (mirrored from TabBarCustomizationView)
    @AppStorage("Feather.tabBar.dashboard") private var showDashboard = true
    @AppStorage("Feather.tabBar.sources") private var showSources = true
    @AppStorage("Feather.tabBar.library") private var showLibrary = true
    @AppStorage("Feather.tabBar.files") private var showFiles = false
    @AppStorage("Feather.tabBar.guides") private var showGuides = true
    @AppStorage("Feather.tabBar.allApps") private var showAllApps = true

    private var visibleSections: [AppSection] {
        var sections: [AppSection] = []
        if showDashboard { sections.append(.dashboard) }
        if showSources { sections.append(.sources) }
        if showLibrary { sections.append(.library) }
        if showFiles { sections.append(.files) }
        if showGuides { sections.append(.guides) }
        if showAllApps { sections.append(.allApps) }
        sections.append(.settings)
        sections.append(.certificates)
        return sections
    }

    @State private var expandedSections: Set<AppSection> = []

    var body: some View {
        NBList(.localized("Gestures")) {
            ForEach(visibleSections) { section in
                Section {
                    if expandedSections.contains(section) {
                        ForEach(GestureType.allCases) { gesture in
                            gestureRow(for: gesture, in: section)
                        }
                    }
                } header: {
                    Button {
                        withAnimation {
                            if expandedSections.contains(section) {
                                expandedSections.remove(section)
                            } else {
                                expandedSections.insert(section)
                            }
                        }
                    } label: {
                        HStack {
                            Text(section.rawValue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .rotationEffect(.degrees(expandedSections.contains(section) ? 90 : 0))
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }

            Section {
                Button(role: .destructive) {
                    gestureManager.mappings = [:]
                    gestureManager.saveMappings()
                    gestureManager.loadMappings()
                    HapticsManager.shared.success()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Reset to Defaults")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func gestureRow(for gesture: GestureType, in section: AppSection) -> some View {
        let binding = Binding<GestureAction>(
            get: { gestureManager.getAction(for: gesture, in: section) },
            set: { gestureManager.setMapping(for: gesture, in: section, action: $0) }
        )

        Picker(selection: binding) {
            ForEach(filteredActions(for: section)) { action in
                Text(action.rawValue).tag(action)
            }
        } label: {
            HStack(spacing: 12) {
                gestureIcon(for: gesture)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24)

                Text(gesture.rawValue)
            }
        }
    }

    private func filteredActions(for section: AppSection) -> [GestureAction] {
        let commonActions: [GestureAction] = [.none]

        switch section {
        case .dashboard:
            return commonActions + [.rotateTip, .showHomeInfo, .toggleInversion, .openDetails]
        case .sources:
            return commonActions + [.openDetails, .deleteApp, .openRepository, .pin, .unlockSourceMaster, .copyURL, .refresh]
        case .library:
            return commonActions + [.openDetails, .signApp, .resignApp, .installApp, .deleteApp, .shareApp]
        case .allApps:
            return commonActions + [.openDetails, .signApp, .installApp, .shareApp]
        case .files:
            return commonActions + [.openDetails, .rename, .duplicate, .move, .deleteApp, .shareApp, .viewPermissions]
        case .guides:
            return commonActions + [.openDetails]
        case .certificates:
            return commonActions + [.openDetails, .select, .exportEntitlements, .deleteApp]
        case .settings:
            return commonActions + [.authenticateDeveloper]
        }
    }

    @ViewBuilder
    private func gestureIcon(for gesture: GestureType) -> some View {
        switch gesture {
        case .singleTap: Image(systemName: "hand.tap")
        case .doubleTap: Image(systemName: "hand.tap.fill")
        case .tripleTap: Image(systemName: "hand.tap.fill")
        case .longPress: Image(systemName: "hand.point.up.braille.fill")
        case .leftSwipe: Image(systemName: "arrow.left")
        case .rightSwipe: Image(systemName: "arrow.right")
        default: Image(systemName: "questionmark.circle")
        }
    }
}

#Preview {
    NavigationStack {
        GesturesView()
    }
}
