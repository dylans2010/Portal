import SwiftUI
import NimbleViews

// MARK: - Developer Mode Entry Point
struct DeveloperView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                DeveloperControlPanelView()
            } else {
                DeveloperAuthView(onAuthenticated: {
                    // Auth state is handled by authManager
                })
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                authManager.lockDeveloperMode()
            }
        }
        .onAppear {
            authManager.checkSessionValidity()
        }
    }
}
