import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
    var body: some View {
        NBList(.localized("Installation")) {
            ServerView()
        }
    }
}
