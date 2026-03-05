import SwiftUI
import AltSourceKit
import NukeUI
import NimbleViews

// MARK: - View
struct SourceNewsCardView: View {
	var new: ASRepository.News
	
	// MARK: Body
	var body: some View {
		ZStack(alignment: .bottomLeading) {
			let placeholderView = {
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.3),
						Color.accentColor.opacity(0.1)
					],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
			}()
			
			if let iconURL = new.imageURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 280, height: 180)
							.clipped()
					} else {
						placeholderView
					}
				}
			} else {
				placeholderView
			}
			
			// Modern gradient overlay
			LinearGradient(
				gradient: Gradient(colors: [
					.black.opacity(0.8),
					.black.opacity(0.5),
					.clear
				]),
				startPoint: .bottom,
				endPoint: .top
			)
			.frame(height: 100)
			.frame(maxWidth: .infinity, alignment: .bottom)
			
			VStack(alignment: .leading, spacing: 6) {
				Text(new.title)
					.font(.system(size: 17, weight: .semibold))
					.foregroundColor(.white)
					.lineLimit(2)
					.multilineTextAlignment(.leading)
				
				if let date = new.date?.date {
					Text(date.formatted(date: .abbreviated, time: .omitted))
						.font(.caption)
						.foregroundStyle(.white.opacity(0.8))
				}
			}
			.padding(16)
		}
		.frame(width: 280, height: 180)
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
		.shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
	}
}

