
import SwiftUI
import Combine
import AltSourceKit
import NimbleViews

struct DownloadButtonView: View {
	let app: ASRepository.App
	@ObservedObject private var downloadManager = DownloadManager.shared

	@State private var downloadProgress: Double = 0
	@State private var cancellable: AnyCancellable?

	var body: some View {
		ZStack {
			if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
				ZStack {
					// Outer glow
					Circle()
						.fill(Color.accentColor.opacity(0.1))
						.frame(width: 40, height: 40)
						.blur(radius: 4)
					
					// Background circle with depth
					Circle()
						.stroke(Color.accentColor.opacity(0.15), lineWidth: 3)
						.frame(width: 34, height: 34)
						.shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
					
					// Progress circle with enhanced gradient
					Circle()
						.trim(from: 0, to: downloadProgress)
						.stroke(
							LinearGradient(
								colors: [
									Color.accentColor.opacity(0.9),
									Color.accentColor,
									Color.accentColor.opacity(0.7)
								],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							),
							style: StrokeStyle(lineWidth: 3, lineCap: .round)
						)
						.rotationEffect(.degrees(-90))
						.frame(width: 34, height: 34)
						.shadow(color: Color.accentColor.opacity(0.4), radius: 3, x: 0, y: 2)
						.animation(animationForPlatform(), value: downloadProgress)

					if downloadProgress >= 0.75 {
						ZStack {
							Circle()
								.fill(Color.accentColor.opacity(0.2))
								.frame(width: 24, height: 24)
								.blur(radius: 2)
							
							Image(systemName: "checkmark")
								.foregroundStyle(Color.accentColor)
								.font(.system(size: 13, weight: .bold))
								.scaleEffect(1.2)
								.shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
						}
						.animation(.spring(response: 0.3, dampingFraction: 0.6), value: downloadProgress >= 0.75)
					} else {
						VStack(spacing: 2) {
							Text("\(Int(downloadProgress * 100))%")
								.font(.system(size: 9, weight: .bold))
								.foregroundStyle(.tint)
								.minimumScaleFactor(0.5)
								.shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
							
							Image(systemName: "stop.fill")
								.foregroundStyle(.tint)
								.font(.system(size: 8, weight: .bold))
								.shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
						}
						.scaleEffect(0.9)
					}
				}
				.contentShape(Circle())
				.onTapGesture {
					if downloadProgress <= 0.75 {
						downloadManager.cancelDownload(currentDownload)
					}
				}
				.compatTransition()
			} else {
				Button {
					if let url = app.currentDownloadUrl {
						_ = downloadManager.startDownload(from: url, id: app.currentUniqueId, fromSourcesView: true)
					}
				} label: {
					ZStack {
						// Shadow layer for depth
						Text(.localized("Get"))
							.lineLimit(0)
							.font(.headline.bold())
							.foregroundStyle(Color.black.opacity(0.3))
							.padding(.horizontal, 28)
							.padding(.vertical, 8)
							.background(Color.accentColor.opacity(0.2))
							.clipShape(Capsule())
							.blur(radius: 3)
							.offset(y: 3)
						
						// Main button with enhanced gradient
						Text(.localized("Get"))
							.lineLimit(0)
							.font(.headline.bold())
							.foregroundStyle(.white)
							.padding(.horizontal, 28)
							.padding(.vertical, 8)
							.background(
								ZStack {
									// Inner shadow effect
									Capsule()
										.fill(
											LinearGradient(
												colors: [
													Color.accentColor.opacity(0.7),
													Color.accentColor,
													Color.accentColor.opacity(0.9)
												],
												startPoint: .top,
												endPoint: .bottom
											)
										)
									
									// Glossy highlight
									Capsule()
										.fill(
											LinearGradient(
												colors: [
													Color.white.opacity(0.3),
													Color.clear
												],
												startPoint: .top,
												endPoint: .center
											)
										)
								}
							)
							.clipShape(Capsule())
							.overlay(
								Capsule()
									.stroke(
										LinearGradient(
											colors: [
												Color.white.opacity(0.4),
												Color.clear
											],
											startPoint: .top,
											endPoint: .bottom
										),
										lineWidth: 1
									)
							)
							.shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
							.shadow(color: Color.accentColor.opacity(0.2), radius: 3, x: 0, y: 2)
					}
				}
				.buttonStyle(.borderless)
				.compatTransition()
			}
		}
		.onAppear(perform: setupObserver)
		.onDisappear { cancellable?.cancel() }
		.onChange(of: downloadManager.downloads.description) { _ in
			setupObserver()
		}
		.animation(.spring(response: 0.4, dampingFraction: 0.8), value: downloadManager.getDownload(by: app.currentUniqueId) != nil)
	}

	private func setupObserver() {
		cancellable?.cancel()
		guard let download = downloadManager.getDownload(by: app.currentUniqueId) else {
			downloadProgress = 0
			return
		}
		downloadProgress = download.overallProgress

		let publisher = Publishers.CombineLatest(
			download.$progress,
			download.$unpackageProgress
		)

		cancellable = publisher.sink { _, _ in
			downloadProgress = download.overallProgress
		}
	}
    
    private func animationForPlatform() -> Animation {
        if #available(iOS 17.0, *) {
            return .smooth
        } else {
            return .easeInOut(duration: 0.35)
        }
    }
}
