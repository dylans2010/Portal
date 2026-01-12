import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@AppStorage("Feather.useTunnel") private var _useTunnel: Bool = false
	
	// Static constants for gradient colors
	private static let tunnelActiveGradient: [Color] = [
		Color.green, Color.mint, Color.green.opacity(0.8)
	]
	
	private static let tunnelInactiveGradient: [Color] = [
		Color.gray.opacity(0.3), Color.gray.opacity(0.2)
	]
	
	// MARK: Body
    var body: some View {
		NBList(.localized("Installation")) {
			ServerView()
			
			// Show Tunnel section for all methods
			// Tunnel Toggle Section
			NBSection(.localized("Connection Method")) {
					Toggle(isOn: $_useTunnel) {
						HStack(spacing: 10) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: _useTunnel ? Self.tunnelActiveGradient : Self.tunnelInactiveGradient,
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 32, height: 32)
									.shadow(color: _useTunnel ? Color.green.opacity(0.4) : Color.clear, radius: 6, x: 0, y: 2)
								
								Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
									.font(.system(size: 14))
									.foregroundStyle(_useTunnel ? .white : .secondary)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Tunnel"))
									.font(.body)
									.foregroundStyle(.primary)
								
								Text(.localized("Use iDevice and pairing file method"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
						}
						.padding(.vertical, 2)
					}
					.toggleStyle(SwitchToggleStyle(tint: .green))
				}
				
			// Only show TunnelView when Tunnel is enabled
			if _useTunnel {
				TunnelView()
			}
		}
    }
}
