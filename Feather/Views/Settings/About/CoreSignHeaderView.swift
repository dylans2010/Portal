import SwiftUI

/// A SwiftUI header view for Portal with rotating subtitles
/// Changes subtitle when user switches tabs or when app returns to foreground
struct CoreSignHeaderView: View {
    // MARK: - State
    @State private var currentSubtitleIndex: Int = 0
    @State private var isAnimating = false
    @State private var showCredits = false
    var hideAboutButton: Bool = false

    // MARK: - Subtitle Definitions
    /// All available subtitle options as individual localized keys
    private let subtitles: [LocalizedStringKey] = [
        "subtitle.kravashit",
        "subtitle.wsf_top",
        "subtitle.just_when",
        "subtitle.no_competition",
        "subtitle.love_ragebaiting",
        "subtitle.drizzy_kendrick",
        "subtitle.crashouts",
        "subtitle.random_project",
        "subtitle.want_s",
        "subtitle.use_coresign",
        "subtitle.made_in",
        "subtitle.swiftui",
        "subtitle.kravasigner_who",
        "subtitle.most_modern_signer",
        "subtitle.greatest_signer",
        "subtitle.forgotten_signers",
        "subtitle.vibecoded"
    ]
    
    private var currentSubtitle: LocalizedStringKey {
        subtitles[currentSubtitleIndex]
    }

    // MARK: - Body
    var body: some View {
        mainContent
            .onAppear {
                setupLifecycleObservers()
                rotateSubtitle()
            }
            .sheet(isPresented: $showCredits) {
                CreditsView()
            }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerContent
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
        }
        .background(backgroundShape)
        .overlay(borderShape)
        .padding(.horizontal)
    }
    
    private var headerContent: some View {
        HStack(spacing: 12) {
            appIcon
            titleSection
            Spacer()
            actionButtons
        }
    }
    
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
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Portal")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.primary, .primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
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
    }
    
    private var actionButtons: some View {
        VStack(alignment: .trailing, spacing: 6) {
            versionBadge
            if !hideAboutButton {
                creditsButton
            }
        }
    }
    
    private var versionBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 8))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
            Text("1.3.0")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
            Text("Release")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.orange.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.accentColor.opacity(0.15),
                            Color.accentColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 0.5)
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
            .foregroundStyle(Color.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(uiColor: .secondarySystemGroupedBackground),
                        Color(uiColor: .secondarySystemGroupedBackground).opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private var borderShape: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.15),
                        Color(uiColor: .separator).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }

    // MARK: - Methods

    /// Sets up observers for app lifecycle and tab changes
    private func setupLifecycleObservers() {
        // Observe when app becomes active (foreground)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            rotateSubtitle()
        }

        // Observe when app will resign active (background)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Optional: Could pause animations here if needed
        }
    }

    /// Rotates to a new random subtitle with animation
    private func rotateSubtitle() {
        guard !subtitles.isEmpty else { return }

        // Get a random subtitle index different from current
        var newIndex = Int.random(in: 0..<subtitles.count)

        // Ensure it's different from current (if we have multiple options)
        if subtitles.count > 1 {
            var attempts = 0
            while newIndex == currentSubtitleIndex && attempts < 10 {
                newIndex = Int.random(in: 0..<subtitles.count)
                attempts += 1
            }
        }

        // Animate the change
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentSubtitleIndex = newIndex
        }
    }

    /// Public method to trigger subtitle rotation (call this when tab changes)
    func onTabChange() {
        rotateSubtitle()
    }
}

// MARK: - Preview
#Preview {
    CoreSignHeaderView()
        .padding()
}
