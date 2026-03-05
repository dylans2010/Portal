import SwiftUI

// MARK: - Navigate to Updates Environment Key
private struct NavigateToUpdatesKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var navigateToUpdates: Binding<Bool> {
        get { self[NavigateToUpdatesKey.self] }
        set { self[NavigateToUpdatesKey.self] = newValue }
    }
}
