import SwiftUI
import NimbleJSON
import NimbleViews

// MARK: - Extension: Model
extension ServerView {
	struct ServerPackModel: Decodable {
		var cert: String
		var ca: String
		var key: String
		var info: ServerPackInfo
		
		private enum CodingKeys: String, CodingKey {
			case cert, ca, key1, key2, info
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			cert = try container.decode(String.self, forKey: .cert)
			ca = try container.decode(String.self, forKey: .ca)
			let key1 = try container.decode(String.self, forKey: .key1)
			let key2 = try container.decode(String.self, forKey: .key2)
			key = key1 + key2
			info = try container.decode(ServerPackInfo.self, forKey: .info)
		}
		
		struct ServerPackInfo: Decodable {
			var issuer: Domains
			var domains: Domains
		}
		
		struct Domains: Decodable {
			var commonName: String
			
			private enum CodingKeys: String, CodingKey {
				case commonName = "commonName"
			}
		}
	}
	
	enum ServerMethod: Int, CaseIterable {
		case fullyLocal = 0
		case semiLocal = 1
		case custom = 2
		
		var name: String {
			switch self {
			case .fullyLocal: return .localized("Fully Local")
			case .semiLocal: return .localized("Semi Local")
			case .custom: return .localized("Custom")
			}
		}
		
		var description: String {
			switch self {
			case .fullyLocal: return .localized("Signs and installs apps entirely on your device without external servers")
			case .semiLocal: return .localized("Signs locally but uses a local server for installation via Wi-Fi. This method is more reliable.")
			case .custom: return .localized("Use your own custom API endpoint for remote signing and installation")
			}
		}
		
		var icon: String {
			switch self {
			case .fullyLocal: return "iphone"
			case .semiLocal: return "wifi"
			case .custom: return "link"
			}
		}
		
		var color: Color {
			switch self {
			case .fullyLocal: return .blue
			case .semiLocal: return .green
			case .custom: return .purple
			}
		}
	}
}

// MARK: - Server Method Card View
private struct ServerMethodCard: View {
	let method: ServerView.ServerMethod
	let isSelected: Bool
	let action: () -> Void
	
	var body: some View {
		Button(action: action) {
			HStack(spacing: 14) {
				ZStack {
					RoundedRectangle(cornerRadius: 10, style: .continuous)
						.fill(
							LinearGradient(
								colors: isSelected ? [method.color, method.color.opacity(0.8)] : [Color(.tertiarySystemFill), Color(.tertiarySystemFill)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 40, height: 40)
						.shadow(color: isSelected ? method.color.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
					
					Image(systemName: method.icon)
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(isSelected ? .white : .secondary)
				}
				
				VStack(alignment: .leading, spacing: 3) {
					Text(method.name)
						.font(.system(size: 15, weight: .semibold))
						.foregroundStyle(isSelected ? .primary : .secondary)
					
					Text(method.description)
						.font(.system(size: 12))
						.foregroundStyle(.secondary)
						.lineLimit(2)
						.fixedSize(horizontal: false, vertical: true)
				}
				
				Spacer()
				
				ZStack {
					Circle()
						.strokeBorder(isSelected ? method.color : Color(.tertiarySystemFill), lineWidth: 2)
						.frame(width: 22, height: 22)
					
					if isSelected {
						Circle()
							.fill(method.color)
							.frame(width: 14, height: 14)
					}
				}
			}
			.padding(14)
			.background(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.fill(isSelected ? method.color.opacity(0.08) : Color(.secondarySystemGroupedBackground))
			)
			.overlay(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.strokeBorder(isSelected ? method.color.opacity(0.3) : Color.clear, lineWidth: 1.5)
			)
		}
		.buttonStyle(.plain)
		.animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
	}
}

// MARK: - View
struct ServerView: View {
	@AppStorage("Feather.ipFix") private var _ipFix: Bool = false
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@AppStorage("Feather.customSigningAPI") private var _customSigningAPI: String = ""
	
	private let _dataService = NBFetchService()
	private let _serverPackUrl = "https://backloop.dev/pack.json"
	
	@State private var _showSuccessAnimation = false
	
	private var selectedMethod: ServerMethod {
		ServerMethod(rawValue: _serverMethod) ?? .fullyLocal
	}
	
	// MARK: Body
	var body: some View {
		Group {
			serverTypeSection
			
			// Show custom API input when Custom method is selected
			if _serverMethod == 2 {
				customAPISection
			}
			
			sslCertificatesSection
			
			successAnimationSection
		}
	}
	
	private var serverTypeSection: some View {
		Section {
			VStack(spacing: 10) {
				ForEach(ServerMethod.allCases, id: \.rawValue) { method in
					ServerMethodCard(
						method: method,
						isSelected: _serverMethod == method.rawValue
					) {
						withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
							_serverMethod = method.rawValue
						}
						HapticsManager.shared.softImpact()
					}
				}
			}
			.padding(.vertical, 4)
			
			if _serverMethod == 1 {
				Toggle(isOn: $_ipFix) {
					HStack(spacing: 12) {
						ZStack {
							RoundedRectangle(cornerRadius: 8, style: .continuous)
								.fill(Color.orange.opacity(0.15))
								.frame(width: 32, height: 32)
							
							Image(systemName: "lifepreserver")
								.font(.system(size: 14, weight: .semibold))
								.foregroundStyle(.orange)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Localhost Only"))
								.font(.system(size: 14, weight: .medium))
							Text(.localized("Only use localhost address"))
								.font(.system(size: 11))
								.foregroundStyle(.secondary)
						}
					}
				}
				.tint(.orange)
				.padding(.top, 4)
			}
		} header: {
			HStack(spacing: 6) {
				Image(systemName: "server.rack")
					.font(.system(size: 11, weight: .semibold))
					.foregroundStyle(.secondary)
				Text(.localized("SERVER TYPE"))
					.font(.system(size: 12, weight: .semibold, design: .rounded))
					.foregroundStyle(.secondary)
			}
		}
	}
	
	private var customAPISection: some View {
		Section {
			VStack(alignment: .leading, spacing: 12) {
				HStack(spacing: 8) {
					Image(systemName: "link.circle.fill")
						.font(.system(size: 14))
						.foregroundStyle(Color.accentColor)
					Text("API Endpoint URL")
						.font(.subheadline.weight(.semibold))
				}
				
				TextField("https://your-api.example.com/sign", text: $_customSigningAPI)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
					.keyboardType(.URL)
					.font(.system(size: 14, design: .monospaced))
					.padding(10)
					.background(
						RoundedRectangle(cornerRadius: 8, style: .continuous)
							.fill(Color(UIColor.tertiarySystemBackground))
					)
					.overlay(
						RoundedRectangle(cornerRadius: 8, style: .continuous)
							.strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
					)
			}
			.padding(.vertical, 4)
		} header: {
			Label("Custom API Configuration", systemImage: "gearshape.2.fill")
		} footer: {
			VStack(alignment: .leading, spacing: 8) {
				Text("Enter your custom signing API endpoint URL. The API should accept IPA, P12, and provisioning profile files and return an itms:// installation link.")
					.font(.caption)
				
				if !_customSigningAPI.isEmpty {
					HStack(spacing: 4) {
						Image(systemName: _customSigningAPI.hasPrefix("https://") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
							.font(.caption2)
							.foregroundStyle(_customSigningAPI.hasPrefix("https://") ? .green : .orange)
						Text(_customSigningAPI.hasPrefix("https://") ? "HTTPS endpoint configured" : "Warning: Using HTTP may be insecure")
							.font(.caption2)
							.foregroundStyle(_customSigningAPI.hasPrefix("https://") ? .green : .orange)
					}
				}
			}
		}
	}
	
	private var sslCertificatesSection: some View {
		Section {
			Button(.localized("Update SSL Certificates"), systemImage: "arrow.down.doc") {
				FR.downloadSSLCertificates(from: _serverPackUrl) { success in
					DispatchQueue.main.async {
						if success {
							withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
								_showSuccessAnimation = true
							}
							DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
								withAnimation(.easeOut(duration: 0.3)) {
									_showSuccessAnimation = false
								}
							}
						} else {
							UIAlertController.showAlertWithOk(
								title: .localized("SSL Certificates"),
								message: .localized("Failed to download, check your internet connection and try again.")
							)
						}
					}
				}
			}
		} header: {
			Label(.localized("SSL Certificates"), systemImage: "lock.shield.fill")
		} footer: {
			Text(.localized("Download the latest SSL certificates for secure connections"))
				.font(.caption)
		}
	}
	
	@ViewBuilder
	private var successAnimationSection: some View {
		if _showSuccessAnimation {
			Section {
				HStack {
					Spacer()
					VStack(spacing: 12) {
						ZStack {
							Circle()
								.fill(Color.green.opacity(0.15))
								.frame(width: 80, height: 80)
							
							Image(systemName: "checkmark.circle.fill")
								.font(.system(size: 50))
								.foregroundStyle(.green)
						}
						.scaleEffect(_showSuccessAnimation ? 1.0 : 0.5)
						.opacity(_showSuccessAnimation ? 1.0 : 0.0)
						.animation(.spring(response: 0.6, dampingFraction: 0.7), value: _showSuccessAnimation)
						
						Text(.localized("SSL Certificates Updated Successfully!"))
							.font(.headline)
							.foregroundStyle(.green)
							.opacity(_showSuccessAnimation ? 1.0 : 0.0)
							.animation(.easeIn(duration: 0.3).delay(0.2), value: _showSuccessAnimation)
					}
					.padding(.vertical, 20)
					Spacer()
				}
			}
		}
	}
}
