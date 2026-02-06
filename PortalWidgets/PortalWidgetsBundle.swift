import WidgetKit
import SwiftUI

@main
struct PortalWidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        // iOS 17+ widgets
        if #available(iOS 17.0, *) {
            QuickActionsWidget()
        }
        if #available(iOS 17.0, *) {
            CertificateStatusWidget()
        }
        if #available(iOS 17.0, *) {
            AllInOneWidget()
        }
        
        // Legacy widgets for iOS 16 (when iOS 17+ is not available)
        if #unavailable(iOS 17.0) {
            QuickActionsWidgetLegacy()
        }
        if #unavailable(iOS 17.0) {
            CertificateStatusWidgetLegacy()
        }
        if #unavailable(iOS 17.0) {
            AllInOneWidgetLegacy()
        }
        
        // Live Activity widget available on iOS 16.1+
        if #available(iOS 16.1, *) {
            InstallationLiveActivityWidget()
        }
    }
}
