import SwiftUI
import AltSourceKit
import NukeUI
import NimbleViews

// MARK: - View
struct SourceNewsCardInfoView: View {
	var new: ASRepository.News
	
	// MARK: - Placeholder View
	private var placeholderView: some View {
		ZStack {
			LinearGradient(
				colors: [
					Color.accentColor.opacity(0.2),
					Color.accentColor.opacity(0.1),
					Color.accentColor.opacity(0.05)
				],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			
			Image(systemName: "newspaper.fill")
				.font(.system(size: 64, weight: .light))
				.foregroundStyle(Color.accentColor.opacity(0.3))
		}
	}
	
	// MARK: Body
	var body: some View {
		NavigationStack {
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					// Modern image header
					ZStack(alignment: .bottomLeading) {
						if let iconURL = new.imageURL {
							LazyImage(url: iconURL) { state in
								if let image = state.image {
									Color.clear.overlay(
										image
											.resizable()
											.aspectRatio(contentMode: .fill)
									)
								} else {
									placeholderView
								}
							}
						} else {
							placeholderView
						}
					}
					.frame(height: 280)
					.frame(maxWidth: .infinity)
					.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: 24, style: .continuous)
							.stroke(
								LinearGradient(
									colors: [Color.white.opacity(0.2), Color.clear],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 1
							)
					)
					.shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
					VStack(alignment: .leading, spacing: 16) {
						// Title
						Text(new.title)
							.font(.system(size: 28, weight: .bold))
							.foregroundStyle(.primary)
							.multilineTextAlignment(.leading)
						
						// Date
						if let date = new.date?.date {
							HStack(spacing: 6) {
								Image(systemName: "calendar")
									.font(.system(size: 11, weight: .semibold))
									.foregroundStyle(.white)
								Text(date.formatted(date: .abbreviated, time: .omitted))
									.font(.system(size: 12, weight: .semibold))
									.foregroundStyle(.white)
							}
							.padding(.vertical, 8)
							.padding(.horizontal, 14)
							.background(
								LinearGradient(
									colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
							.clipShape(Capsule())
							.shadow(color: Color.accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
						}
						
						// Caption
						if !new.caption.isEmpty {
							Text(new.caption)
								.font(.body)
								.foregroundStyle(.primary)
								.multilineTextAlignment(.leading)
								.lineSpacing(4)
						}
						
						// Open button
						if let url = new.url {
							Button {
								UIApplication.shared.open(url)
							} label: {
									HStack(spacing: 10) {
										Text(.localized("Read More"))
											.font(.system(size: 17, weight: .bold))
										Image(systemName: "arrow.up.right")
											.font(.system(size: 15, weight: .bold))
									}
									.foregroundStyle(.white)
									.frame(maxWidth: .infinity)
									.padding(.vertical, 16)
									.background(
										LinearGradient(
											colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
											startPoint: .leading,
											endPoint: .trailing
										)
									)
									.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
									.shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
							}
							.buttonStyle(.plain)
							.padding(.top, 8)
						}
					}
				}
				.frame(
					minWidth: 0,
					maxWidth: .infinity,
					minHeight: 0,
					maxHeight: .infinity,
					alignment: .topLeading
				)
				.padding()
			}
			.background(Color(uiColor: .systemBackground))
			.toolbar {
				NBToolbarButton(role: .close)
			}
		}
	}
}
