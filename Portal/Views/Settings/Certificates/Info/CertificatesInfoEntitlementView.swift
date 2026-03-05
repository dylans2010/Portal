import SwiftUI
import NimbleViews

// MARK: - View
struct CertificatesInfoEntitlementView: View {
	let entitlements: [String: AnyCodable]
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Entitlements")) {
			Section {
				ForEach(entitlements.keys.sorted(), id: \.self) { key in
					if let value = entitlements[key]?.value {
						CertificatesInfoEntitlementCellView(key: key, value: value)
							.padding(.vertical, 8)
					}
				}
			} header: {
				VStack(spacing: 16) {
					// Enhanced header with glass effect
					ZStack {
						// Glow effect
						Circle()
							.fill(
								RadialGradient(
									colors: [
										Color.accentColor.opacity(0.3),
										Color.accentColor.opacity(0.1),
										Color.clear
									],
									center: .center,
									startRadius: 20,
									endRadius: 50
								)
							)
							.frame(width: 70, height: 70)
						
						// Main circle with depth
						ZStack {
							Circle()
								.fill(Color.black.opacity(0.1))
								.frame(width: 46, height: 46)
								.blur(radius: 3)
								.offset(y: 2)
							
							Circle()
								.fill(
									LinearGradient(
										colors: [
											Color.accentColor.opacity(0.3),
											Color.accentColor.opacity(0.15)
										],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 46, height: 46)
							
							Circle()
								.stroke(
									LinearGradient(
										colors: [
											Color.accentColor.opacity(0.5),
											Color.accentColor.opacity(0.2)
										],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									),
									lineWidth: 2
								)
								.frame(width: 46, height: 46)
							
							Image(systemName: "key.fill")
								.font(.system(size: 18))
								.foregroundStyle(Color.accentColor)
								.shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
						}
						.shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
					}
					
					VStack(spacing: 4) {
						Text("\(entitlements.count) Entitlements")
							.font(.headline)
							.fontWeight(.bold)
							.foregroundStyle(.primary)
						
						Text("Security Capabilities")
							.font(.caption)
							.foregroundStyle(.secondary)
					}
				}
				.textCase(.none)
				.frame(maxWidth: .infinity)
				.padding(.vertical, 20)
			}
		}
		.listStyle(.insetGrouped)
	}
}
