import SwiftUI
import NimbleViews

// MARK: - View
struct CertificatesCellView: View {
	@State var data: Certificate?
	@ObservedObject var cert: CertificatePair
	
	// MARK: Body
	var body: some View {
		HStack(spacing: 14) {
			// Certificate Icon
			certificateIcon
			
			// Info
			VStack(alignment: .leading, spacing: 8) {
				// Title and subtitle
				VStack(alignment: .leading, spacing: 3) {
					HStack(spacing: 6) {
						Text(certificateTitle)
							.font(.system(size: 15, weight: .semibold))
							.foregroundStyle(.primary)
							.lineLimit(1)
						
						// Debug badge
						if let getTaskAllow = data?.Entitlements?["get-task-allow"]?.value as? Bool, getTaskAllow == true {
							Text("DEBUG")
								.font(.system(size: 9, weight: .bold))
								.foregroundStyle(.white)
								.padding(.horizontal, 5)
								.padding(.vertical, 2)
								.background(
									Capsule()
										.fill(Color.orange)
								)
						}
					}
					
					Text(data?.AppIDName ?? .localized("Unknown"))
						.font(.system(size: 12, weight: .medium))
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
				
				// Status pills
				statusPills
			}
			
			Spacer(minLength: 0)
		}
		.modifier(ContentTransitionOpacityModifier())
		.onAppear {
			withAnimation {
				data = Storage.shared.getProvisionFileDecoded(for: cert)
			}
		}
	}
	
	// MARK: - Certificate Title
	private var certificateTitle: String {
		cert.nickname ?? data?.Name ?? .localized("Unknown")
	}
	
	// MARK: - Certificate Icon
	private var certificateIcon: some View {
		ZStack {
			// Background gradient
			RoundedRectangle(cornerRadius: 14, style: .continuous)
				.fill(
					LinearGradient(
						colors: iconGradientColors,
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(width: 48, height: 48)
			
			// Icon
			Image(systemName: iconName)
				.font(.system(size: 20, weight: .semibold))
				.foregroundStyle(.white)
		}
		.shadow(color: iconGradientColors[0].opacity(0.3), radius: 6, x: 0, y: 3)
	}
	
	private var iconName: String {
		if cert.revoked == true {
			return "xmark.seal.fill"
		} else if cert.ppQCheck == true {
			return "exclamationmark.shield.fill"
		} else {
			return "checkmark.seal.fill"
		}
	}
	
	private var iconGradientColors: [Color] {
		if cert.revoked == true {
			return [.red, .red.opacity(0.7)]
		} else if cert.ppQCheck == true {
			return [.orange, .orange.opacity(0.7)]
		} else {
			return [.green, .green.opacity(0.7)]
		}
	}
	
	// MARK: - Status Pills
	private var statusPills: some View {
		HStack(spacing: 6) {
			// Revoked status
			if cert.revoked == true {
				modernPill(title: .localized("Revoked"), icon: "xmark.circle.fill", color: .red)
			}
			
			// PPQ Check
			if cert.ppQCheck == true {
				modernPill(title: "PPQ", icon: "exclamationmark.triangle.fill", color: .orange)
			}
			
			// Expiration
			if let info = cert.expiration?.expirationInfo() {
				modernPill(title: info.formatted, icon: info.icon, color: info.color)
			}
		}
	}
	
	private func modernPill(title: String, icon: String, color: Color) -> some View {
		HStack(spacing: 4) {
			Image(systemName: icon)
				.font(.system(size: 10, weight: .semibold))
			Text(title)
				.font(.system(size: 10, weight: .semibold))
		}
		.foregroundStyle(color)
		.padding(.horizontal, 8)
		.padding(.vertical, 4)
		.background(
			Capsule()
				.fill(color.opacity(0.12))
				.overlay(
					Capsule()
						.stroke(color.opacity(0.2), lineWidth: 0.5)
				)
		)
	}
}

// MARK: - Helper ViewModifier for iOS 16 compatibility
struct ContentTransitionOpacityModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.opacity)
        } else {
            content
                .animation(.easeInOut(duration: 0.2), value: UUID())
        }
    }
}
