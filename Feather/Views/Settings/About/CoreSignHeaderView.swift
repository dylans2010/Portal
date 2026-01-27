import SwiftUI

/// A SwiftUI header view for Portal with rotating subtitles
/// Changes subtitle when user switches tabs or when app returns to foreground
///
/// ## Adding New Subtitles
/// Simply add a new entry to the `HeaderSubtitle.allSubtitles` array.
/// Each subtitle is a simple string that will be displayed below the app name.
///
/// Example:
/// ```swift
/// HeaderSubtitle.allSubtitles.append("Your new subtitle here")
/// ```
struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitleIndex: Int = 0
    @State private var showCredits = false
    var hideAboutButton: Bool = false

    // MARK: - Current Subtitle
    private var currentSubtitle: String {
        HeaderSubtitle.allSubtitles[safe: currentSubtitleIndex] ?? HeaderSubtitle.defaultSubtitle
    }

    // MARK: - Body
    var body: some View {
        headerCard
            .onAppear {
                setupLifecycleObservers()
                rotateSubtitle()
            }
            .sheet(isPresented: $showCredits) {
                CreditsView()
            }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        HStack(spacing: 12) {
            // App Icon
            appIcon
            
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text("Portal")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(currentSubtitle)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .id(currentSubtitleIndex)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(alignment: .trailing, spacing: 6) {
                versionBadge
                if !hideAboutButton {
                    creditsButton
                }
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    // MARK: - App Icon
    @ViewBuilder
    private var appIcon: some View {
        if let iconName = Bundle.main.iconFileName,
           let icon = UIImage(named: iconName) {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .accentColor.opacity(0.25), radius: 6, x: 0, y: 3)
        } else {
            Image(systemName: "questionmark.square.dashed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Version Badge
    private var versionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 8))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            Text("2.0")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text("Release")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.accentColor.opacity(0.12)))
        .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 0.5))
    }
    
    // MARK: - Credits Button
    private var creditsButton: some View {
        Button {
            showCredits = true
            HapticsManager.shared.softImpact()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 9))
                    .symbolRenderingMode(.hierarchical)
                Text(.localized("Credits"))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.accentColor))
            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Lifecycle Observers
    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            rotateSubtitle()
        }
    }

    // MARK: - Subtitle Rotation
    private func rotateSubtitle() {
        let subtitles = HeaderSubtitle.allSubtitles
        guard !subtitles.isEmpty else { return }

        var newIndex = Int.random(in: 0..<subtitles.count)
        
        if subtitles.count > 1 {
            var attempts = 0
            while newIndex == currentSubtitleIndex && attempts < 10 {
                newIndex = Int.random(in: 0..<subtitles.count)
                attempts += 1
            }
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentSubtitleIndex = newIndex
        }
    }

    /// Public method to trigger subtitle rotation (call this when tab changes)
    func onTabChange() {
        rotateSubtitle()
    }
}

// MARK: - easy to add header subtitles because i cbf to find the localizedstrings lmao
enum HeaderSubtitle {
    /// Default subtitle shown if array is empty
    static let defaultSubtitle = "the modern signer"

    static var allSubtitles: [String] = [
        "the modern signer",
        "no competition",
        "Are you using the latest Portal version?",
        "Built with Swift",
        "Kravashit are a scam",
        "Just Works™",
        "Portal in full Spanish?? maybe...",
        "should i put my instagram here??",
        "Portal made by dylan lol",
        "5-7, 7-3, elite ball knowledge needed to understand",
        "why do I encounter stupid people ffs",
        "easter eggs hidden",
        "Porque la vida es asi -Peso Pluma",
        "made with some crashouts",
        "this Portal is WAY better",
        "vibe coded project lol",
        "playing hard to get is NOT cool S...",
        "greatest signer",
        "Use Portal gng",
        "Random project",
        "if you want something custom here, ping dylan in the WSF server",
        "my grades are so fucked",
        "need me some Chrome Hearts",
        "coding ts on a mfucking chromebook",
        "WSF On Top",
        "feature rich signer",
        "Kravashit",
        "Just When You Thought",
        "love ragebaiting",
        "drizzy > kendrick",
        "love my future gf S ❤️",
        "Kravasigner Who?",
        "other forgotten signers",
    ]
    
    /// Add a new subtitle at runtime
    static func add(_ subtitle: String) {
        allSubtitles.append(subtitle)
    }
    
    /// Remove a subtitle at runtime
    static func remove(_ subtitle: String) {
        allSubtitles.removeAll { $0 == subtitle }
    }
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Preview
#Preview {
    CoreSignHeaderView()
        .padding()
}
