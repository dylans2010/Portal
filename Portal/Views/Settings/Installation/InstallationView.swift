import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @State private var _showServerSheet = false

    var body: some View {
        NBList(.localized("Installation")) {
            if showHeaderViews {
                Section {
                    InstallationHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Button {
                    _showServerSheet = true
                    HapticsManager.shared.softImpact()
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Server & SSL"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.primary)
                            Text(.localized("Configure signing server and SSL certificates"))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "server.rack")
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .sheet(isPresented: $_showServerSheet) {
            ServerView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}
