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
        } else if #available(iOS 16.1, *) {
            QuickActionsWidgetLegacy()
            CertificateStatusWidgetLegacy()
            AllInOneWidgetLegacy()
            InstallationLiveActivityWidget()
        } else {
            QuickActionsWidgetLegacy()
            CertificateStatusWidgetLegacy()
            AllInOneWidgetLegacy()
        }
    }
}
