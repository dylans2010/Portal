import SwiftUI

extension Color {
	/// Initialize a Color from a hex string
	/// - Parameter hex: The hex string (e.g., "#FF0000" or "FF0000")
	init(hex: String) {
		let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hex).scanHexInt64(&int)
		let a, r, g, b: UInt64
		switch hex.count {
		case 3: // RGB (12-bit)
			(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
		case 6: // RGB (24-bit)
			(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
		case 8: // ARGB (32-bit)
			(a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
		default:
			(a, r, g, b) = (255, 0, 0, 0)
		}
		
		self.init(
			.sRGB,
			red: Double(r) / 255,
			green: Double(g) / 255,
			blue:  Double(b) / 255,
			opacity: Double(a) / 255
		)
	}
	
	/// Convert a Color to a hex string
	func toHex() -> String? {
		guard let components = UIColor(self).cgColor.components else { return nil }
		let r = Float(components[0])
		let g = Float(components[1])
		let b = Float(components[2])
		return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
	}

	/// Returns the perceived brightness of the color (0.0 to 1.0)
	var brightness: Double {
		var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
		if UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) {
			return Double((r * 299 + g * 587 + b * 114) / 1000)
		}

		var white: CGFloat = 0
		if UIColor(self).getWhite(&white, alpha: &a) {
			return Double(white)
		}

		return 0
	}

	/// Returns a high-contrast foreground color (black or white) based on the background brightness
	var adaptiveForeground: Color {
		brightness > 0.5 ? .black : .white
	}
}
