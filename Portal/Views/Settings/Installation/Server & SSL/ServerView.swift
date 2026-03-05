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
		case semiLocalBackground = 3
		
		var name: String {
			switch self {
			case .fullyLocal: return .localized("On Device")
			case .semiLocal: return .localized("Server")
			case .semiLocalBackground: return .localized("Server 2")
			}
		}
		
		var description: String {
			switch self {
			case .fullyLocal: return .localized("Sign and install on-device.")
			case .semiLocal: return .localized("Local signing, Wi-Fi install.")
			case .semiLocalBackground: return .localized("Background local signing.")
			}
		}
		
		var icon: String {
			switch self {
			case .fullyLocal: return "iphone"
			case .semiLocal: return "cloud"
			case .semiLocalBackground: return "externaldrive.badge.icloud"
			}
		}
		
		var color: Color {
			switch self {
			case .fullyLocal: return .blue
			case .semiLocal: return .green
			case .semiLocalBackground: return .teal
			}
		}
	}
}

// MARK: - View
struct ServerView: View {
    @Environment(\.dismiss) private var dismiss
	@AppStorage("Feather.ipFix") private var _ipFix: Bool = false
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	
	private let _dataService = NBFetchService()
	private let _serverPackUrl = "https://backloop.dev/pack.json"
	
	@State private var _showSuccessAnimation = false
	@State private var _isUpdatingSSL = false
	@State private var _sslUpdated = false

	private var selectedMethod: ServerMethod {
		ServerMethod(rawValue: _serverMethod) ?? .fullyLocal
	}
	
	// MARK: Body
	var body: some View {
        NavigationStack {
            Form {
                serverTypeSection

                sslCertificatesSection
            }
            .navigationTitle("Server Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
	}
	
	private var serverTypeSection: some View {
		Section {
            Menu {
                Picker("Server Type", selection: $_serverMethod) {
                    ForEach(ServerMethod.allCases, id: \.rawValue) { method in
                        Label(method.name, systemImage: method.icon)
                            .tag(method.rawValue)
                    }
                }
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedMethod.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            Text(selectedMethod.description)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedMethod.color.opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: selectedMethod.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(selectedMethod.color)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
			
			if _serverMethod == 1 || _serverMethod == 3 {
				Toggle(isOn: $_ipFix) {
					HStack(spacing: 12) {
						ZStack {
							RoundedRectangle(cornerRadius: 8, style: .continuous)
								.fill(Color.orange.opacity(0.15))
								.frame(width: 32, height: 32)
							
							Image(systemName: "extrernaldrive.fill.badge.checkmark")
								.font(.system(size: 14, weight: .semibold))
								.foregroundStyle(.orange)
						}
						
						VStack(alignment: .leading, spacing: 2) {
							Text(.localized("Localhost Only"))
								.font(.system(size: 14, weight: .medium))
							Text(.localized("Only Use Localhost Address"))
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
				Text(.localized("Server Type"))
					.font(.system(size: 12, weight: .semibold, design: .rounded))
					.foregroundStyle(.secondary)
			}
		}
	}
	
		private var sslCertificatesSection: some View {
		Section {
			Button {
				_isUpdatingSSL = true
				FR.downloadSSLCertificates(from: _serverPackUrl) { success in
					DispatchQueue.main.async {
						_isUpdatingSSL = false
						if success {
							withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
								_sslUpdated = true
							}

							HapticsManager.shared.success()

							DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
								withAnimation(.spring()) {
									_sslUpdated = false
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
			} label: {
				HStack {
					if _sslUpdated {
						Label(.localized("SSL Certificates Updated!"), systemImage: "checkmark.seal.fill")
							.foregroundStyle(.green)
							.font(.system(size: 16, weight: .bold))
					} else {
						Label {
							Text(_isUpdatingSSL ? .localized("Updating...") : .localized("Update SSL Certificates"))
						} icon: {
							if _isUpdatingSSL {
								ProgressView()
									.controlSize(.small)
									.padding(.trailing, 4)
							} else {
								Image(systemName: "arrow.down.doc")
							}
						}
					}

					Spacer()

					if _sslUpdated {
						Image(systemName: "sparkles")
							.foregroundStyle(.green)
							.pulseEffect()
					}
				}
				.padding(.vertical, 8)
				.padding(.horizontal, 12)
				.background {
					if _sslUpdated {
						ZStack {
							Color.green.opacity(0.15)
							Rectangle().fill(.ultraThinMaterial)
						}
						.cornerRadius(12)
						.overlay(
							RoundedRectangle(cornerRadius: 12)
								.stroke(Color.green.opacity(0.3), lineWidth: 1)
						)
					}
				}
			}
			.disabled(_isUpdatingSSL || _sslUpdated)
		} header: {
			Label(.localized("SSL Certificates"), systemImage: "lock.shield.fill")
		} footer: {
			Text(.localized("Download the latest SSL certificates for secure connections. Update them if you are having any signing errors."))
				.font(.caption)
		}
	}
	

	}
