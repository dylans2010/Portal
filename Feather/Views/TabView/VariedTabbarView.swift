import SwiftUI

struct VariedTabbarView: View {
    @AppStorage("feature_experimentalUI") var experimentalUI = false
    @AppStorage("Feather.enableCustomTabBar") var enableCustomTabBar = false
    
    var body: some View {
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
