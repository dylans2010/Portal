import SwiftUI
import NimbleViews

struct AppHideElementsView: View {
    @StateObject private var sourcesManager = SourcesHideManager.shared
    @StateObject private var libraryManager = LibraryHideManager.shared
    @StateObject private var filesManager = FilesHideManager.shared
    @StateObject private var guidesManager = GuidesHideManager.shared
    @StateObject private var settingsManager = SettingsHideManager.shared

    @State private var searchText = ""

    var body: some View {
        NBNavigationView(.localized("Hide UI Elements")) {
            List {
.scrollContentBackground(.hidden)
                Section {
                    Button(role: .destructive) {
                        sourcesManager.resetToDefaults()
                        libraryManager.resetToDefaults()
                        filesManager.resetToDefaults()
                        guidesManager.resetToDefaults()
                        settingsManager.resetToDefaults()
                    } label: {
                        Label("Reset All To Defaults", systemImage: "arrow.counterclockwise")
                    }
                }

                managerSection(title: "Sources", manager: sourcesManager)
                managerSection(title: "Library", manager: libraryManager)
                managerSection(title: "Files", manager: filesManager)
                managerSection(title: "Guides", manager: guidesManager)
                managerSection(title: "Settings", manager: settingsManager)
            }
            .scrollContentBackground(.hidden)

            .searchable(text: $searchText, prompt: "Search Items")
        }
    }

    @ViewBuilder
    private func managerSection<M: AppHideManaging>(title: String, manager: M) -> some View {
        let filteredItems = manager.hideableItems.filter {
            searchText.isEmpty ||
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }

        if !filteredItems.isEmpty {
            Section {
                ForEach(filteredItems) { item in
                    Toggle(isOn: Binding(
                        get: { manager.isHidden(item.id) },
                        set: { manager.setHidden(item.id, value: $0) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.body)
                            Text(item.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                HStack {
                    Text(title)
                    Spacer()
                    Button("Reset") {
                        manager.resetToDefaults()
                    }
                    .font(.caption)
                    .textCase(.none)
                }
            }
        }
    }
}
