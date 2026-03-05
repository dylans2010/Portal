import Foundation

class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    @Published var hasSelectedInitialTab = false
    @Published var isSigning = false

    private init() {}
}
