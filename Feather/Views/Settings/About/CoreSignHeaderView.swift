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
        "subtitle.ae_lovers",
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
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
        }
        .background(backgroundShape)
        .overlay(borderShape)
        .padding(.horizontal)
    }
    
    private var headerContent: some View {
        HStack(spacing: 10) {
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
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(color: .accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
        } else {
            placeholderIcon
        }
    }
    
    private var placeholderIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
            
            Image(systemName: "app.badge")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
        }
        .shadow(color: .accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Portal")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text(currentSubtitle)
                .font(.caption2)
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
        HStack(spacing: 3) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 7))
                .foregroundStyle(Color.accentColor)
            Text("1.0")
                .font(.system(size: 9))
                .fontWeight(.semibold)
            Text("Beta")
                .font(.system(size: 8))
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 1.5)
                .background(
                    Capsule()
                        .fill(Color.orange)
                )
        }
        .foregroundStyle(.primary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.accentColor.opacity(0.12))
        )
    }
    
    private var creditsButton: some View {
        Button {
            showCredits = true
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 8))
                Text(.localized("Credits"))
                    .font(.system(size: 10))
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.accentColor)
            )
            .shadow(color: .accentColor.opacity(0.25), radius: 3, x: 0, y: 1.5)
        }
    }
    
    private var backgroundShape: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(uiColor: .secondarySystemGroupedBackground))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
    
    private var borderShape: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color(uiColor: .separator).opacity(0.3), lineWidth: 0.5)
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
