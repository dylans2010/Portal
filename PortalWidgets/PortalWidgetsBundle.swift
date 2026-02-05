import WidgetKit
import SwiftUI

@main
struct PortalWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PortalWidget()
        if #available(iOS 16.1, *) {
            InstallationLiveActivityWidget()
        }
    }
}
