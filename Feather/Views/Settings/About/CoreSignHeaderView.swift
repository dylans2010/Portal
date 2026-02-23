import SwiftUI

struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitleIndex: Int = 0
    @State private var showCredits = false
    @State private var showSecretDimension = false
    @State private var iconRotationAngle: Double = 0
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
            .fullScreenCover(isPresented: $showSecretDimension) {
                SecretDimensionView()
            }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // App Icon
            appIcon
                .rotationEffect(.degrees(iconRotationAngle))
                .onTapGesture(count: 3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                        iconRotationAngle += 360
                    }
                    HapticsManager.shared.success()
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 2.0)
                        .onEnded { _ in
                            ToastManager.shared.show("🤫 Portal is the best, don't tell anyone!", type: .info)
                            HapticsManager.shared.success()
                        }
                )
            
            // App Name
            ZStack(alignment: .leading) {
                Text("Portal")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .offset(x: 2, y: 2)
                    .foregroundStyle(Color.accentColor.opacity(0.15))
                    .blur(radius: 1)

                Text("Portal")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.accentColor, .accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
                .simultaneousGesture(
                    TapGesture(count: 3)
                        .onEnded {
                            showSecretDimension = true
                            HapticsManager.shared.success()
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink, .cyan, .mint]
                            if let randomColor = colors.randomElement() {
                                UIApplication.shared.connectedScenes
                                    .compactMap { $0 as? UIWindowScene }
                                    .flatMap { $0.windows }
                                    .forEach { $0.tintColor = UIColor(randomColor) }
                                ToastManager.shared.show("🎨 Color Splash!", type: .info)
                                HapticsManager.shared.success()
                            }
                        }
                )

            HStack(spacing: 8) {
                // Version Row
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.05))
                .clipShape(Capsule())

                // Release Label (Modern capsule badge)
                Text("RELEASE")
                    .font(.system(size: 10, weight: .black))
                    .kerning(1.2)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.accentColor.opacity(0.1))
                    )
                    .clipShape(Capsule())
                    .foregroundStyle(Color.accentColor)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.accentColor.opacity(0.5), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }

            // Subtexts (Secondary Text)
            ModernShufflingText(text: currentSubtitle)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.5)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .id(currentSubtitleIndex)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.accentColor.opacity(0.05))
                .cornerRadius(8)
                .padding(.top, 4)
            
            // Action Buttons
            if !hideAboutButton {
                creditsButton
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(white: 0.12))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear, .white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - App Icon
    @ViewBuilder
    private var appIcon: some View {
        ZStack {
            Color.accentColor.opacity(0.15)

            if let iconName = Bundle.main.iconFileName,
               let icon = UIImage(named: iconName) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(Color.accentColor)
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.accentColor.opacity(0.2), radius: 12, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.3), .clear, .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
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
    static let defaultSubtitle = "the modern signer ✦"

    static var allSubtitles: [String] = [
        "the modern signer ✦",
        "no competition ⚡️",
        "Are you using the latest Portal version?",
        "Built with Swift 🐦",
        "vibe coded project 🌊",
        "latinas on top 💅",
        "Just Works™ ✅",
        "Portal made by dylan lol",
        "5-7, 7-3, elite ball knowledge needed",
        "easter eggs hidden 🥚",
        "where tf is QuickSign at??",
        "made with some crashouts 💀",
        "When is DRUNK releasing omg",
        "this Portal is WAY better 💎",
        "greatest signer of all time 🐐",
        "Use Portal gng 🚀",
        "WSF On Top 🔝",
        "feature rich signer ✨",
        "Kravasigner Who? 🤔",
        "stay ahead of the game 🎮",
        "unmatched performance 🔋",
        "crafted with care ❤️",
        "your apps, your way 🛠️",
        "pure innovation 🌌",
        "redefining excellence 🏆",
        "signed, sealed, delivered 📦",
        "no limits, just portal 🚪",
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
