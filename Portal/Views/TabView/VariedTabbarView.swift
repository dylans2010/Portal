import SwiftUI

struct VariedTabbarView: View {
    @AppStorage("feature_experimentalUI") var experimentalUI = false
    @AppStorage("Feather.enableCustomTabBar") var enableCustomTabBar = false
    
    @State private var cornerSequence: [Int] = []

    var body: some View {
        _mainTabContent
    }

    @ViewBuilder
    private var _mainTabContent: some View {
        _tabGroup
            .simultaneousGesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        let horizontal = value.translation.width
                        let vertical = value.translation.height

                        if abs(horizontal) > abs(vertical) {
                            if horizontal > 0 {
                                EasterEggManager.shared.handleKonamiKey(.right)
                            } else {
                                EasterEggManager.shared.handleKonamiKey(.left)
                            }
                        } else {
                            if vertical > 0 {
                                EasterEggManager.shared.handleKonamiKey(.down)
                            } else {
                                EasterEggManager.shared.handleKonamiKey(.up)
                            }
                        }
                    }
            )
            .withEasterEggs()
    }

    @ViewBuilder
    private var _tabGroup: some View {
        if enableCustomTabBar {
            // Custom modern tab bar (Developer option)
            CustomTabBarUI()
        } else if experimentalUI {
            // Experimental UI
            ExperimentalTabbarView()
        } else {
            // Original UI
            if #available(iOS 18, *) {
                ExtendedTabbarView()
            } else {
                TabbarView()
            }
        }
    }
}
