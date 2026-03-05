import UIKit

extension UIUserInterfaceStyle: @retroactive CaseIterable {
	public static var allCases: [UIUserInterfaceStyle] {
		[.unspecified, .dark, .light]
	}
	
	var label: String {
		switch self {
		case .unspecified: .localized("Default")
		case .dark: .localized("Dark")
		case .light: .localized("Light")
		@unknown default: .localized("Unknown")
		}
	}
	
	var iconName: String {
		switch self {
		case .unspecified: "circle.lefthalf.filled"
		case .dark: "moon.fill"
		case .light: "sun.max.fill"
		@unknown default: "questionmark.circle"
		}
	}
}
