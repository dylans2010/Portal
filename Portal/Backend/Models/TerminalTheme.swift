import SwiftUI

enum TerminalTheme: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case modern = "Modern"
    case matrix = "Matrix"
    case hacker = "Hacker"
    case retro = "Retro"
    case ubuntu = "Ubuntu"
    case dracula = "Dracula"
    case solarizedDark = "Solarized Dark"
    case solarizedLight = "Solarized Light"
    case midnight = "Midnight"
    case cyberPunch = "Cyber Punch"

    var id: String { self.rawValue }

    var backgroundColor: Color {
        switch self {
        case .classic: return .black
        case .modern: return Color(UIColor.systemBackground)
        case .matrix: return .black
        case .hacker: return Color(hex: "#1c1c1c")
        case .retro: return Color(hex: "#2b1b17")
        case .ubuntu: return Color(hex: "#300a24")
        case .dracula: return Color(hex: "#282a36")
        case .solarizedDark: return Color(hex: "#002b36")
        case .solarizedLight: return Color(hex: "#fdf6e3")
        case .midnight: return Color(hex: "#000022")
        case .cyberPunch: return Color(hex: "#2d002d")
        }
    }

    var textColor: Color {
        switch self {
        case .classic: return .green
        case .modern: return .primary
        case .matrix: return Color(hex: "#00FF41")
        case .hacker: return .cyan
        case .retro: return .orange
        case .ubuntu: return .white
        case .dracula: return Color(hex: "#f8f8f2")
        case .solarizedDark: return Color(hex: "#839496")
        case .solarizedLight: return Color(hex: "#657b83")
        case .midnight: return .cyan
        case .cyberPunch: return .yellow
        }
    }

    var promptColor: Color {
        switch self {
        case .classic: return .green
        case .modern: return .accentColor
        case .matrix: return Color(hex: "#00FF41")
        case .hacker: return .green
        case .retro: return .yellow
        case .ubuntu: return Color(hex: "#8ae234")
        case .dracula: return Color(hex: "#bd93f9")
        case .solarizedDark: return Color(hex: "#b58900")
        case .solarizedLight: return Color(hex: "#b58900")
        case .midnight: return .white
        case .cyberPunch: return Color(hex: "#ff00ff")
        }
    }

    var secondaryTextColor: Color {
        switch self {
        case .modern: return .secondary
        case .solarizedLight: return textColor.opacity(0.7)
        default: return textColor.opacity(0.6)
        }
    }
}
