import SwiftUI

public final class ThemeManager: ObservableObject {
    public enum Theme {
        case light
        case dark
    }

    @Published public var currentTheme: Theme

    public init(currentTheme: Theme = .light) {
        self.currentTheme = currentTheme
    }
}
