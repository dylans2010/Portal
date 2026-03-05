import SwiftUI
import NimbleViews

// MARK: - Credits Item Model
struct CreditItem: Identifiable {
	var id: String { githubUsername }
	let username: String
	let githubUsername: String // Username to fetch from GitHub API
	let role: String
	let githubUrl: String
	let gradientColors: [Color]
	let icon: String
}

// MARK: - WSF Link Model
struct WSFLink: Identifiable {
	let id = UUID()
	let title: String
	let url: String
	let icon: String
	let color: Color
}

// MARK: - View
struct CreditsView: View {
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
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Credits")) {
			// Header Section
			if showHeaderViews {
				Section {
					CreditsHeaderView()
						.listRowInsets(EdgeInsets())
						.listRowBackground(Color.clear)
				}
				.listRowBackground(Color.clear)
				.listRowSeparator(.hidden)
			}

			// Developers Section
			Section {
				VStack(spacing: 12) {
					ForEach(credits) { credit in
						GitHubCreditCard(credit: credit)
					}
				}
			} header: {
				Text(.localized("Development"))
					.font(.footnote.bold())
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
			}
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)

			// WSF Team Links Section
			Section {
				VStack(spacing: 12) {
					ForEach(wsfLinks) { link in
						WSFLinkButton(link: link)
					}
				}
			} header: {
				Text(.localized("Join WSF"))
					.font(.footnote.bold())
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
			}
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)

			// Portal Source Code Section
			Section {
				WSFLinkButton(link: WSFLink(
					title: .localized("Check out Portal's code"),
					url: "https://github.com/dylans2010/Portal",
					icon: "code.bracket",
					color: .blue
				))
			} header: {
				Text(.localized("Portal Source"))
					.font(.footnote.bold())
					.foregroundStyle(.secondary)
					.textCase(.uppercase)
			}
			.listRowBackground(Color.clear)
			.listRowSeparator(.hidden)
		}
	}
}

// MARK: - WSF Link Button
struct WSFLinkButton: View {
	let link: WSFLink

	var body: some View {
		Button {
			guard let url = URL(string: link.url) else { return }
			UIApplication.open(url)
		} label: {
			HStack(spacing: 12) {
				// Icon with background
				Image(systemName: link.icon)
					.font(.system(size: 18, weight: .semibold))
					.foregroundStyle(.white)
					.frame(width: 36, height: 36)
					.background(
						RoundedRectangle(cornerRadius: 10, style: .continuous)
							.fill(link.color.gradient)
					)

				Text(link.title)
					.font(.body.weight(.medium))
					.foregroundStyle(.primary)

				Spacer()

				// Chevron
				Image(systemName: "chevron.right")
					.font(.system(size: 14, weight: .bold))
					.foregroundStyle(.secondary.opacity(0.5))
			}
			.padding(12)
			.background(Color.clear)
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			.shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
		}
		.buttonStyle(CreditsScaleButtonStyle())
	}
}

// MARK: - GitHub Credit Card View
struct GitHubCreditCard: View {
	let credit: CreditItem
	@State private var _tapCount = 0
	
	@StateObject private var viewModel = GitHubUserViewModel()
	
	var body: some View {
		Button {
			guard let url = URL(string: credit.githubUrl) else { return }
			UIApplication.open(url)
		} label: {
			HStack(spacing: 12) {
				// Profile picture or icon with gradient
				ZStack {
					if let avatarImage = viewModel.avatarImage {
						Image(uiImage: avatarImage)
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 48, height: 48)
							.clipShape(Circle())
							.overlay(
								Circle()
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
						// Fallback to icon while loading or on error
						Circle()
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

				// Text content
				VStack(alignment: .leading, spacing: 2) {
					Text(viewModel.user?.name ?? credit.username)
						.font(.body.weight(.bold))
						.foregroundStyle(.primary)
					
					Text(credit.role)
						.font(.subheadline)
						.foregroundStyle(.secondary)
					
					if let bio = viewModel.user?.bio, !bio.isEmpty {
						Text(bio)
							.font(.caption)
							.foregroundStyle(.secondary.opacity(0.8))
							.lineLimit(1)
					}
				}

				Spacer()

				// Arrow
				Image(systemName: "arrow.up.right")
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(.secondary.opacity(0.5))
			}
			.padding(12)
			.background(Color.clear)
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.stroke(
						LinearGradient(
							colors: credit.gradientColors.map { $0.opacity(0.2) },
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 1
					)
			)
			.shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
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
			// Fetch GitHub user data using the explicit GitHub username
			viewModel.fetchUser(username: credit.githubUsername)
		}
	}
}

// MARK: - Scale Button Style
struct CreditsScaleButtonStyle: ButtonStyle {
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? 0.95 : 1.0)
			.animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
	}
}
