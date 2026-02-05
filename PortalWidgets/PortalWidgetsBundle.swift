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
        }
        
        if #available(iOS 16.1, *) {
            InstallationLiveActivityWidget()
        }

        if #unavailable(iOS 17.0) {
            QuickActionsWidgetLegacy()
            CertificateStatusWidgetLegacy()
            AllInOneWidgetLegacy()
        }
    }
}
