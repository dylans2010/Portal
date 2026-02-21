import SwiftUI

struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitleIndex: Int = 0
    @State private var showCredits = false
    @State private var showSecretDimension = false
    @State private var badgeColor: Color = .orange
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
.applyGlobalTheme()
}
            .fullScreenCover(isPresented: $showSecretDimension) {
SecretDimensionView()
.applyGlobalTheme()
}
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        HStack(spacing: 12) {
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
            
            // Title & Subtitle
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Portal")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
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
                                    // 2-finger double tap is hard, so we just use double tap for random color
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

                    versionBadge
                        .onTapGesture {
                            withAnimation {
                                badgeColor = [Color.orange, Color.blue, Color.green, Color.purple, Color.red, Color.pink, Color.yellow].randomElement()!
                            }
                            HapticsManager.shared.softImpact()
                        }
                }
                
                Text(currentSubtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .transition(AnyTransition.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .id(currentSubtitleIndex)
            }
            
            Spacer()
            
            // Action Buttons
            if !hideAboutButton {
                creditsButton
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.clear)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.accentColor.opacity(0.1), lineWidth: 0.5)
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
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .accentColor.opacity(0.15), radius: 4, x: 0, y: 2)
        } else {
            Image(systemName: "questionmark.square.dashed")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Version Badge
    private var versionBadge: some View {
        HStack(spacing: 3) {
            Text("3.0")
                .font(.system(size: 9, weight: .bold, design: .rounded))
            Text("Release")
                .font(.system(size: 8, weight: .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(Capsule().fill(badgeColor))
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.accentColor.opacity(0.1)))
        .overlay(Capsule().strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 0.5))
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
        "what feature would you like to see here?",
        "listen to Junior H",
        "latinas on top",
        "OTRA RUPTURA MAS AL CORAZON",
        "Kravashit are a scam",
        "Just Works™",
        "Portal in full Spanish?? maybe...",
        "should i put my instagram here??",
        "Portal made by dylan lol",
        "5-7, 7-3, elite ball knowledge needed to understand",
        "why do I encounter stupid people ffs",
        "S on S tier, get it? probably not",
        "easter eggs hidden",
        "where tf is QuickSign at??",
        "Porque la vida es asi -Peso Pluma",
        "made with some crashouts",
        "When is DRUNK releasing omg",
        "girls want girls -drake",
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
