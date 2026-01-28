import SwiftUI
import NimbleViews
import UIKit

// MARK: - App Icon Model
enum AppIconOption: String, CaseIterable, Identifiable {
	case defaultIcon = "AppIcon"
	case tinted = "AppIcon-Tinted"
	case clear = "AppIcon-Clear"
	case clearDark = "AppIcon-ClearDark"
	case clearLight = "AppIcon-ClearLight"
	case tintedDark = "AppIcon-TintedDark"
	case tintedLight = "AppIcon-TintedLight"
	case macOS = "AppIcon-macOS"
	case macOSDark = "AppIcon-macOS-Dark"
	case macOSTinted = "AppIcon-macOS-Tinted"
	
	var id: String { rawValue }
	
	var displayName: String {
		switch self {
		case .defaultIcon:
			return .localized("Default")
		case .tinted:
			return .localized("Tinted")
		case .clear:
			return .localized("Clear")
		case .clearDark:
			return .localized("Clear Dark")
		case .clearLight:
			return .localized("Clear Light")
		case .tintedDark:
			return .localized("Tinted Dark")
		case .tintedLight:
			return .localized("Tinted Light")
		case .macOS:
			return .localized("macOS Style")
		case .macOSDark:
			return .localized("macOS Dark")
		case .macOSTinted:
			return .localized("macOS Tinted")
		}
	}
	
	var description: String {
		switch self {
		case .defaultIcon:
			return .localized("Automatically switches between light and dark")
		case .tinted:
			return .localized("Tinted icon style")
		case .clear:
			return .localized("Clear icon style")
		case .clearDark:
			return .localized("Clear icon with dark appearance")
		case .clearLight:
			return .localized("Clear icon with light appearance")
		case .tintedDark:
			return .localized("Tinted icon with dark appearance")
		case .tintedLight:
			return .localized("Tinted icon with light appearance")
		case .macOS:
			return .localized("Classic macOS style icon")
		case .macOSDark:
			return .localized("macOS style icon with dark appearance")
		case .macOSTinted:
			return .localized("macOS style icon with tinted appearance")
		}
	}
	
	var iconName: String? {
		switch self {
		case .defaultIcon:
			return nil // nil means primary app icon
		case .tinted:
			return "AppIcon-Tinted"
		case .clear:
			return "AppIcon-Clear"
		case .clearDark:
			return "AppIcon-ClearDark"
		case .clearLight:
			return "AppIcon-ClearLight"
		case .tintedDark:
			return "AppIcon-TintedDark"
		case .tintedLight:
			return "AppIcon-TintedLight"
		case .macOS:
			return "AppIcon-macOS"
		case .macOSDark:
			return "AppIcon-macOS-Dark"
		case .macOSTinted:
			return "AppIcon-macOS-Tinted"
		}
	}
	
	var previewImageName: String {
		switch self {
		case .defaultIcon:
			return "AppIconPreview-Default"
		case .tinted:
			return "AppIconPreview-Tinted"
		case .clear:
			return "AppIconPreview-Clear"
		case .clearDark:
			return "AppIconPreview-ClearDark"
		case .clearLight:
			return "AppIconPreview-ClearLight"
		case .tintedDark:
			return "AppIconPreview-TintedDark"
		case .tintedLight:
			return "AppIconPreview-TintedLight"
		case .macOS:
			return "AppIconPreview-macOS"
		case .macOSDark:
			return "AppIconPreview-macOS-Dark"
		case .macOSTinted:
			return "AppIconPreview-macOS-Tinted"
		}
	}
}

// MARK: - View
struct AppIconView: View {
	@State private var currentIcon: String? = UIApplication.shared.alternateIconName
	@State private var showingError = false
	@State private var errorMessage = ""
	
	private var selectedOption: AppIconOption {
		if let iconName = currentIcon {
			return AppIconOption(rawValue: iconName) ?? .defaultIcon
		}
		return .defaultIcon
	}
	
	/// Returns a UIImage for the app icon preview based on the icon name
	/// - Parameter iconName: The name of the alternate icon, or nil for the default icon
	/// - Returns: A UIImage representing the app icon preview. Returns a system app icon image if the preview image cannot be loaded from assets.
	static func altImage(_ iconName: String?) -> UIImage {
		let imageName: String
		if let iconName = iconName, let option = AppIconOption(rawValue: iconName) {
			imageName = option.previewImageName
		} else {
			imageName = AppIconOption.defaultIcon.previewImageName
		}
		
		// Return the preview image from assets, or fallback to a system placeholder
		if let image = UIImage(named: imageName) {
			return image
		}
		
		// Fallback to a system app icon as a visible placeholder
		return UIImage(systemName: "app.fill") ?? UIImage()
	}
	
	// MARK: Body
	var body: some View {
		NBList(.localized("App Icons")) {
			Section {
				ForEach(AppIconOption.allCases) { option in
					Button {
						setAppIcon(option)
					} label: {
						HStack(spacing: 16) {
							// Icon preview
							Image(option.previewImageName)
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 60, height: 60)
								.clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
								.overlay(
									RoundedRectangle(cornerRadius: 13, style: .continuous)
										.stroke(Color.secondary.opacity(0.3), lineWidth: 1)
								)
							
							// Text content
							VStack(alignment: .leading, spacing: 4) {
								Text(option.displayName)
									.font(.headline)
									.foregroundColor(.primary)
								Text(option.description)
									.font(.caption)
									.foregroundColor(.secondary)
							}
							
							Spacer()
							
							// Selection indicator
							if selectedOption == option {
								Image(systemName: "checkmark.circle.fill")
									.foregroundColor(.accentColor)
									.font(.title2)
							}
						}
						.padding(.vertical, 8)
					}
					.buttonStyle(.plain)
				}
			} footer: {
				Text(.localized("The default icon automatically adapts to light and dark mode. Choose from various tinted and clear icon styles with different appearances. Keep in mind this is still WIP and will be fully done later."))
			}
		}
		.alert(.localized("Error"), isPresented: $showingError) {
			Button(.localized("OK"), role: .cancel) { }
		} message: {
			Text(errorMessage)
		}
	}
	
	private func setAppIcon(_ option: AppIconOption) {
		guard UIApplication.shared.supportsAlternateIcons else {
			errorMessage = .localized("Rare alert but this device doesn't support alternate icons")
			showingError = true
			return
		}
		
		UIApplication.shared.setAlternateIconName(option.iconName) { error in
			if let error = error {
				errorMessage = error.localizedDescription
				showingError = true
			} else {
				currentIcon = option.iconName
				HapticsManager.shared.success()
			}
		}
	}
}
