import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitleIndex: Int = 0
    @State private var recentSubtitleIndices: [Int] = []
    @State private var showCredits = false
    @State private var showSecretDimension = false
    @State private var iconRotationAngle: Double = 0
    @State private var iconBackgroundColor: Color = Color.accentColor.opacity(0.15)
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
                loadIconBackgroundColor()
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
            Text(.localized("Portal"))
                .font(.title2).bold()
                .foregroundStyle(Color.accentColor)
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

                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 10))
                    Text(.localized("Release"))
                        .font(.system(size: 10, weight: .bold))
                        .kerning(1.0)
                }
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

            Text("\(UIDevice.current.humanReadableModelName) • \(UIDevice.current.systemVersion) • \(Bundle.main.bundleIdentifier ?? "com.feather.portal")")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.accentColor.opacity(0.5))

            Text(currentSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor.opacity(0.7))
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .id(currentSubtitleIndex)
                .padding(.top, 4)
            
            if !hideAboutButton {
                creditsButton
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
    
    @ViewBuilder
    private var appIcon: some View {
        ZStack {
            iconBackgroundColor
                .overlay(
                    iconBackgroundColor
                        .blur(radius: 8)
                        .opacity(0.6)
                )

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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: iconBackgroundColor.opacity(0.5), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }
    
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

    private func setupLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            rotateSubtitle()
        }
    }

    private func rotateSubtitle() {
        let maxRecentSubtitles = 3
        let subtitles = HeaderSubtitle.allSubtitles
        guard !subtitles.isEmpty else { return }

        var newIndex = Int.random(in: 0..<subtitles.count)

        if subtitles.count > 1 {
            var attempts = 0
            // Avoid the last `maxRecentSubtitles` shown indices to prevent repeats
            while recentSubtitleIndices.contains(newIndex) && attempts < 20 {
                newIndex = Int.random(in: 0..<subtitles.count)
                attempts += 1
            }
        }

        // Update recent history (keep last maxRecentSubtitles)
        recentSubtitleIndices.append(newIndex)
        if recentSubtitleIndices.count > maxRecentSubtitles {
            recentSubtitleIndices.removeFirst()
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            currentSubtitleIndex = newIndex
        }
    }

    private func loadIconBackgroundColor() {
        let rgbMaxValue: CGFloat = 255
        guard let iconName = Bundle.main.iconFileName,
              let icon = UIImage(named: iconName),
              let ciImage = CIImage(image: icon) else { return }
        // CIVector uses x/y for origin and z/w for width/height of the rectangle
        let extent = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y,
                              z: ciImage.extent.size.width, w: ciImage.extent.size.height)
        guard let filter = CIFilter(name: "CIAreaAverage",
                                    parameters: [kCIInputImageKey: ciImage,
                                                 kCIInputExtentKey: extent]),
              let output = filter.outputImage else { return }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(output, toBitmap: &bitmap, rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8, colorSpace: nil)
        let color = Color(UIColor(red: CGFloat(bitmap[0]) / rgbMaxValue,
                                  green: CGFloat(bitmap[1]) / rgbMaxValue,
                                  blue: CGFloat(bitmap[2]) / rgbMaxValue,
                                  alpha: 0.25))
        DispatchQueue.main.async { iconBackgroundColor = color }
    }

    func onTabChange() {
        rotateSubtitle()
    }
}

// MARK: - easy to add header subtitles because i cbf to find the localizedstrings lmao
enum HeaderSubtitle {
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
    
    static func add(_ subtitle: String) {
        allSubtitles.append(subtitle)
    }

    static func remove(_ subtitle: String) {
        allSubtitles.removeAll { $0 == subtitle }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    CoreSignHeaderView()
        .padding()
}
