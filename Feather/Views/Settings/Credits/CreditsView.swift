import SwiftUI
import NimbleViews

struct CreditItem: Identifiable {
        var id: String { githubUsername }
        let username: String
        let githubUsername: String
        let role: String
        let githubUrl: String
        let gradientColors: [Color]
        let icon: String
}

struct WSFLink: Identifiable {
        let id = UUID()
        let title: String
        let url: String
        let icon: String
        let color: Color
}

struct CreditsView: View {
        @EnvironmentObject var themeManager: ThemeManager
        @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
        private let credits: [CreditItem] = [
                CreditItem(
                        username: "dylans2010",
                        githubUsername: "dylans2010",
                        role: .localized("Developer"),
                        githubUrl: "https://github.com/dylans2010",
                        gradientColors: [SwiftUI.Color(hex: "#ff7a83"), SwiftUI.Color(hex: "#FF2D55")],
                        icon: "paintbrush.fill"
                ),
                CreditItem(
                        username: "Feather",
                        githubUsername: "khcrysalis",
                        role: .localized("Original Developer"),
                        githubUrl: "https://github.com/khcrysalis/Feather",
                        gradientColors: [SwiftUI.Color(hex: "#4CD964"), SwiftUI.Color(hex: "#4860e8")],
                        icon: "star.fill"
                )
        ]

        private let wsfLinks: [WSFLink] = [
                WSFLink(
                        title: .localized("WSF Website"),
                        url: "https://wsfteam.xyz",
                        icon: "globe",
                        color: .blue
                ),
                WSFLink(
                        title: .localized("Join Our Discord"),
                        url: "https://wsfteam.xyz/discord",
                        icon: "bubble.left.and.bubble.right.fill",
                        color: Color(hex: "#5865F2")
                ),
                WSFLink(
                        title: .localized("Follow Us On X"),
                        url: "https://x.com/wsf_team",
                        icon: "xmark",
                        color: .primary
                ),
                WSFLink(
                        title: .localized("Star Our GitHub Repo"),
                        url: "https://github.com/WSF-Team/WSF",
                        icon: "star.fill",
                        color: .orange
                )
        ]

        var body: some View {
                ScrollView {
                        VStack(spacing: 28) {
                                if showHeaderViews {
                                        CreditsHeaderView()
                                }

                                VStack(alignment: .leading, spacing: 12) {
                                        Text(.localized("Development"))
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .themedText(.header)
                                                .textCase(.uppercase)
                                                .padding(.leading, 4)

                                        VStack(spacing: 0) {
                                                ForEach(Array(credits.enumerated()), id: \.element.id) { index, credit in
                                                        GitHubCreditCard(credit: credit)

                                                        if index < credits.count - 1 {
                                                                Divider()
                                                                        .padding(.leading, 76)
                                                                        .opacity(0.4)
                                                        }
                                                }
                                        }
                                        .themedCard()
                                }

                                VStack(alignment: .leading, spacing: 12) {
                                        Text(.localized("Join WSF"))
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .themedText(.header)
                                                .textCase(.uppercase)
                                                .padding(.leading, 4)

                                        VStack(spacing: 0) {
                                                ForEach(Array(wsfLinks.enumerated()), id: \.element.id) { index, link in
                                                        WSFLinkButton(link: link)

                                                        if index < wsfLinks.count - 1 {
                                                                Divider()
                                                                        .padding(.leading, 60)
                                                                        .opacity(0.4)
                                                        }
                                                }
                                        }
                                        .themedCard()
                                }

                                VStack(alignment: .leading, spacing: 12) {
                                        Text(.localized("Portal Source"))
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .themedText(.header)
                                                .textCase(.uppercase)
                                                .padding(.leading, 4)

                                        WSFLinkButton(link: WSFLink(
                                                title: .localized("Check out Portal's code"),
                                                url: "https://github.com/dylans2010/Portal",
                                                icon: "chevron.left.forwardslash.chevron.right",
                                                color: .blue
                                        ))
                                        .themedCard()
                                }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                }
                .globalTheme()
                .navigationTitle(.localized("Credits"))
                .navigationBarTitleDisplayMode(.inline)
        }
}

struct WSFLinkButton: View {
        @EnvironmentObject var themeManager: ThemeManager
        let link: WSFLink

        var body: some View {
                Button {
                        guard let url = URL(string: link.url) else { return }
                        UIApplication.open(url)
                } label: {
                        HStack(spacing: 14) {
                                ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(link.color.opacity(0.12))
                                                .frame(width: 36, height: 36)

                                        Image(systemName: link.icon)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(link.color)
                                }

                                Text(link.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .themedText(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                .buttonStyle(CreditsScaleButtonStyle())
        }
}

struct GitHubCreditCard: View {
        @EnvironmentObject var themeManager: ThemeManager
        let credit: CreditItem
        @State private var _tapCount = 0

        @StateObject private var viewModel = GitHubUserViewModel()

        var body: some View {
                Button {
                        guard let url = URL(string: credit.githubUrl) else { return }
                        UIApplication.open(url)
                } label: {
                        HStack(spacing: 14) {
                                ZStack {
                                        if let avatarImage = viewModel.avatarImage {
                                                Image(uiImage: avatarImage)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 48, height: 48)
                                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                                        .overlay(
                                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                                        .stroke(
                                                                                LinearGradient(
                                                                                        colors: credit.gradientColors,
                                                                                        startPoint: .topLeading,
                                                                                        endPoint: .bottomTrailing
                                                                                ),
                                                                                lineWidth: 1.5
                                                                        )
                                                        )
                                        } else {
                                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                        .fill(
                                                                LinearGradient(
                                                                        colors: credit.gradientColors,
                                                                        startPoint: .topLeading,
                                                                        endPoint: .bottomTrailing
                                                                )
                                                        )
                                                        .frame(width: 48, height: 48)

                                                if viewModel.isLoading {
                                                        ProgressView()
                                                                .tint(.white)
                                                } else {
                                                        Image(systemName: credit.icon)
                                                                .font(.system(size: 20, weight: .semibold))
                                                                .foregroundStyle(.white)
                                                }
                                        }
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                        Text(viewModel.user?.name ?? credit.username)
                                                .font(.system(size: 16, weight: .bold))
                                                .themedText(.primary)

                                        Text(credit.role)
                                                .font(.system(size: 13, weight: .medium))
                                                .themedText(.secondary)

                                        if let bio = viewModel.user?.bio, !bio.isEmpty {
                                                Text(bio)
                                                        .font(.system(size: 12))
                                                        .themedText(.secondary)
                                                        .opacity(0.8)
                                                        .lineLimit(1)
                                        }
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                .buttonStyle(CreditsScaleButtonStyle())
                .simultaneousGesture(
                        TapGesture()
                                .onEnded {
                                        if credit.username == "dylans2010" {
                                                _tapCount += 1
                                                if _tapCount == 10 {
                                                        ToastManager.shared.show("🐐 You found dylan! The goat of signers!", type: .success)
                                                        HapticsManager.shared.success()
                                                        _tapCount = 0
                                                }
                                        }
                                }
                )
                .onAppear {
                        viewModel.fetchUser(username: credit.githubUsername)
                }
        }
}

struct CreditsScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
                configuration.label
                        .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
        }
}
