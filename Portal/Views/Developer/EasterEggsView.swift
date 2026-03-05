import SwiftUI
import NimbleViews

struct EasterEggInfo: Identifiable {
    let id = UUID()
    let name: String
    let hint: String
    let difficulty: Difficulty

    enum Difficulty: String, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        case impossible = "Impossible"

        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .blue
            case .hard: return .orange
            case .impossible: return .red
            }
        }
    }
}

struct EasterEggsView: View {
    let eggs: [EasterEggInfo] = [
        // Easy
        EasterEggInfo(name: "Matrix Rain", hint: "Shake your device on the Home screen.", difficulty: .easy),
        EasterEggInfo(name: "Color Splash", hint: "2-finger double tap on the 'Portal' title in Settings.", difficulty: .easy),
        EasterEggInfo(name: "Badge Fun", hint: "Tap the version badge in Settings.", difficulty: .easy),
        EasterEggInfo(name: "Dedicated Developer", hint: "Tap the app icon in About 7 times.", difficulty: .easy),
        EasterEggInfo(name: "Best Signer", hint: "Long press the app icon in Settings.", difficulty: .easy),
        EasterEggInfo(name: "App Count", hint: "Long press the 'Library' title.", difficulty: .easy),
        EasterEggInfo(name: "Home Message", hint: "Tap 'Portal Information' on Home 5 times.", difficulty: .easy),

        // Medium
        EasterEggInfo(name: "Source Master", hint: "Rapidly tap the 'Sources' title 7 times.", difficulty: .medium),
        EasterEggInfo(name: "Emoji Rain", hint: "Type 'RAIN' in any search bar.", difficulty: .medium),
        EasterEggInfo(name: "Snowy Day", hint: "Type 'SNOW' in any search bar.", difficulty: .medium),
        EasterEggInfo(name: "Bouncing Ball", hint: "Type 'BALL' in any search bar.", difficulty: .medium),
        EasterEggInfo(name: "Spinny Icon", hint: "Triple tap the app icon in Settings.", difficulty: .medium),
        EasterEggInfo(name: "Bundle Explorer", hint: "Triple tap any app row in Library.", difficulty: .medium),
        EasterEggInfo(name: "Purple Glow", hint: "Type 'FEATHER' in any search bar.", difficulty: .medium),

        // Hard
        EasterEggInfo(name: "Konami Code", hint: "U, U, D, D, L, R, L, R, B, A on the main screen.", difficulty: .hard),
        EasterEggInfo(name: "Hidden Credits", hint: "Long press the 'Settings' title.", difficulty: .hard),
        EasterEggInfo(name: "Theme Cycle", hint: "Long press the 'Theme' icon in Appearance.", difficulty: .hard),
        EasterEggInfo(name: "Secret Dimension", hint: "Type 'SECRET' in the Developer Token field.", difficulty: .hard),
        EasterEggInfo(name: "Glitch Mode", hint: "Type 'GLITCH' in the Developer Token field.", difficulty: .hard),
        EasterEggInfo(name: "Turbo Updates", hint: "Long press the 'Check For Updates' button.", difficulty: .hard),
        EasterEggInfo(name: "Color Invert", hint: "Long press on the Home screen for 3 seconds.", difficulty: .hard),

        // Impossible
        EasterEggInfo(name: "Invisible Button", hint: "Find the hidden button at the bottom of the About screen.", difficulty: .impossible),
        EasterEggInfo(name: "No Skip", hint: "Tap the Portal logo in Onboarding 5 times.", difficulty: .impossible),
        EasterEggInfo(name: "Dylan Finder", hint: "Tap the dylans2010 card in Credits 10 times.", difficulty: .impossible),
        EasterEggInfo(name: "Meaning of Life", hint: "Enter '42' in the greetings name field.", difficulty: .impossible),
        EasterEggInfo(name: "Earthquake", hint: "Shake your device for 5 seconds straight.", difficulty: .impossible),
        EasterEggInfo(name: "Sneaky Dev", hint: "Triple tap the 'Developer Mode' title while locked.", difficulty: .impossible)
    ]

    var body: some View {
        NBList("Easter Eggs") {
            Section {
                Text("Try to find all 25+ Easter eggs hidden throughout the app!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ForEach(EasterEggInfo.Difficulty.allCases, id: \.self) { difficulty in
                section(for: difficulty)
            }
        }
    }

    @ViewBuilder
    private func section(for difficulty: EasterEggInfo.Difficulty) -> some View {
        Section(header: Text(difficulty.rawValue).foregroundStyle(difficulty.color)) {
            ForEach(eggs.filter { $0.difficulty == difficulty }) { egg in
                VStack(alignment: .leading, spacing: 4) {
                    Text(egg.name)
                        .font(.headline)
                    Text(egg.hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
    }
}
