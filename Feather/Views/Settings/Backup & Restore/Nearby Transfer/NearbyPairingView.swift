import SwiftUI

// MARK: - Nearby Pairing View
/// Replaced by the new unified Pairing flow (PairingView + PairingService).
/// This wrapper preserves the existing NavigationLink entry-point from
/// TransferSetupView while delegating all logic to the new Pairing screen.
struct NearbyPairingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    var body: some View {
        PairingView(isEmbedded: true)
    }
}
