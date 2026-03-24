import SwiftUI

extension Color {
    init(hex: String) {
        let cleaned = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6,
              let value = UInt64(cleaned, radix: 16) else {
            self = Color(.systemBackground)
            return
        }
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        let value = hexString
        return value.isEmpty ? nil : value
    }

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

    var adaptiveForeground: Color {
        brightness > 0.5 ? .black : .white
    }

    var hexString: String {
        guard let components = UIColor(self).cgColor.components,
              components.count >= 3 else {
            return "#000000"
        }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
