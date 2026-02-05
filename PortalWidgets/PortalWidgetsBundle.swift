import WidgetKit
import SwiftUI

@main
struct PortalWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        if #available(iOS 17.0, *) {
            QuickActionsWidget()
            CertificateStatusWidget()
            AllInOneWidget()
            InstallationLiveActivityWidget()
        } else {
            QuickActionsWidgetLegacy()
            CertificateStatusWidgetLegacy()
            AllInOneWidgetLegacy()
        }
    }
}
