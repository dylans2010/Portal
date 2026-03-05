import SwiftUI
import NimbleViews

// MARK: - View
struct SigningAlternativeIconView: View {
	@Environment(\.dismiss) var dismiss
	
	@State private var _alternateIcons: [(name: String, path: String)] = []
	
	var app: AppInfoPresentable
	@Binding var appIcon: UIImage?
	@Binding var isModifing: Bool
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("Alternative Icons"), displayMode: .inline) {
			List {
				if !_alternateIcons.isEmpty {
					ForEach(_alternateIcons, id: \.name) { icon in
						Button {
							appIcon = _iconUrl(icon.path)
							dismiss()
						} label: {
							_icon(icon)
						}
						.disabled(!isModifing)
					}
				} else {
					HStack {
						Spacer()
						VStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [
												Color.indigo.opacity(0.3),
												Color.purple.opacity(0.2),
												Color.indigo.opacity(0.1)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 60, height: 60)
									.shadow(color: Color.indigo.opacity(0.4), radius: 12, x: 0, y: 5)
								
								Image(systemName: "app.badge.questionmark")
									.font(.system(size: 28))
									.foregroundStyle(
										LinearGradient(
											colors: [Color.indigo, Color.purple, Color.indigo.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							Text(.localized("No Icons Found On App BUndle"))
								.font(.subheadline)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.secondary, Color.secondary.opacity(0.7)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
						}
						.padding(.vertical, 30)
						Spacer()
					}
				}
			}
            .scrollContentBackground(.hidden)
			.onAppear(perform: _loadAlternateIcons)
			.toolbar {
				if isModifing {
					NBToolbarButton(role: .close)
				}
			}
		}
	}
}

// MARK: - Extension: View
extension SigningAlternativeIconView {
	@ViewBuilder
	private func _icon(_ icon: (name: String, path: String)) -> some View {
		HStack(spacing: 12) {
			if let image = _iconUrl(icon.path) {
				Image(uiImage: image)
					.appIconStyle(size: 32)
					.shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
			}
			
			Text(icon.name)
				.font(.headline)
				.foregroundStyle(
					LinearGradient(
						colors: [Color.primary, Color.accentColor.opacity(0.6), Color.primary.opacity(0.8)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
		}
		.padding(.vertical, 4)
	}
	
	
	private func _iconUrl(_ path: String) -> UIImage? {
		guard let app = Storage.shared.getAppDirectory(for: app) else {
			return nil
		}
		return UIImage(contentsOfFile: app.appendingPathComponent(path).relativePath)?.resizeToSquare()
	}
	
	private func _loadAlternateIcons() {
		guard let appDirectory = Storage.shared.getAppDirectory(for: app) else { return }
		
		let infoPlistPath = appDirectory.appendingPathComponent("Info.plist")
		guard
			let infoPlist = NSDictionary(contentsOf: infoPlistPath),
			let iconDict = infoPlist["CFBundleIcons"] as? [String: Any],
			let alternateIconsDict = iconDict["CFBundleAlternateIcons"] as? [String: [String: Any]]
		else {
			return
		}
		
		_alternateIcons = alternateIconsDict.compactMap { (name, details) in
			if let files = details["CFBundleIconFiles"] as? [String], let path = files.first {
				return (name, path)
			}
			return nil
		}
	}
}
