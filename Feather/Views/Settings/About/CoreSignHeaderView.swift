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
        VStack(alignment: .leading, spacing: 16) {
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
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .offset(x: 2, y: 2)
                    .foregroundStyle(Color.black.opacity(0.2))
                    .blur(radius: 2)

                Text("Portal")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
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
                    .font(.system(size: 10, weight: .bold))
                    .kerning(1.0)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .foregroundStyle(Color.accentColor)
                    .overlay(
                        Capsule()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 0.5)
                    )
            }

            // Subtexts (Secondary Text)
            ModernShufflingText(text: currentSubtitle)
                .id(currentSubtitleIndex)
                .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                .padding(.top, 4)
            
            // Action Buttons
            if !hideAboutButton {
                creditsButton
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(white: 0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
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
        .shadow(color: Color.accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
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


struct ModernShufflingText: View {
    let text: String
    @State private var displayedText: String = ""
    @State private var isShuffling = false

    var body: some View {
        Text(displayedText)
            .font(.system(.subheadline, design: .monospaced))
            .fontWeight(.bold)
            .foregroundStyle(Color.accentColor.opacity(0.8))
            .onAppear {
                displayedText = text
            }
            .onChange(of: text) { newValue in
                withAnimation(.spring()) {
                    isShuffling = true
                }
                shuffleTo(newValue)
            }
            .scaleEffect(isShuffling ? 0.95 : 1.0)
            .opacity(isShuffling ? 0.7 : 1.0)
    }

    private func shuffleTo(_ targetText: String) {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+"
        var iteration = 0
        let maxIterations = 15

        Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            iteration += 1

            if iteration >= maxIterations {
                displayedText = targetText
                withAnimation(.spring()) {
                    isShuffling = false
                }
                timer.invalidate()
            } else {
                let shuffled = targetText.enumerated().map { index, char -> String in
                    if Double.random(in: 0...1) > Double(iteration) / Double(maxIterations) {
                        return String(characters.randomElement()!)
                    } else {
                        return String(char)
                    }
                }.joined()
                displayedText = shuffled
            }
        }
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
