import SwiftUI
import NimbleViews
import NukeUI

// MARK: - View
struct SourcesCellView: View {
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var dominantColor: Color = .accentColor
	
	var source: AltSource
	
	private var iconView: some View {
		Group {
			if let iconURL = source.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 40, height: 40)
							.clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
							.shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
							.onAppear {
								if let uiImage = state.imageContainer?.image {
									extractDominantColor(from: uiImage)
								}
							}
					} else {
						placeholderIcon
					}
				}
			} else {
				placeholderIcon
			}
		}
	}
	
	private var placeholderIcon: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 9, style: .continuous)
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
				.frame(width: 40, height: 40)
			
			Image(systemName: "globe")
				.font(.system(size: 20))
				.foregroundStyle(Color.accentColor)
		}
		.shadow(color: Color.accentColor.opacity(0.15), radius: 2, x: 0, y: 1)
	}
	
	private func extractDominantColor(from image: UIImage) {
		guard let inputImage = CIImage(image: image) else { return }
		let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
		
		guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return }
		guard let outputImage = filter.outputImage else { return }
		
		var bitmap = [UInt8](repeating: 0, count: 4)
		let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
		context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
		
		dominantColor = Color(red: Double(bitmap[0]) / 255, green: Double(bitmap[1]) / 255, blue: Double(bitmap[2]) / 255)
	}
	
	// MARK: Body
	var body: some View {
		let isPinned = viewModel.isPinned(source)
		
		HStack(spacing: 12) {
			// Icon - slightly larger and more prominent
			iconView
			
			// Title with app count
			VStack(alignment: .leading, spacing: 3) {
				Text(source.name ?? .localized("Unknown"))
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				if let appCount = viewModel.sources[source]?.apps.count, appCount > 0 {
					HStack(spacing: 4) {
						Image(systemName: "app.fill")
							.font(.system(size: 8))
						Text("\(appCount) \(appCount == 1 ? "app" : "apps")")
							.font(.system(size: 10, weight: .medium))
					}
					.foregroundStyle(.secondary)
				}
			}
			
			Spacer()
			
			if isPinned {
				Image(systemName: "pin.fill")
					.font(.caption)
					.foregroundStyle(dominantColor)
					.padding(6)
					.background(
						Circle()
							.fill(dominantColor.opacity(0.12))
					)
			}
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 10)
		.background(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							dominantColor.opacity(0.08),
							dominantColor.opacity(0.04)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 12, style: .continuous)
				.stroke(dominantColor.opacity(0.15), lineWidth: 0.5)
		)
		.shadow(color: dominantColor.opacity(0.12), radius: 3, x: 0, y: 1.5)
		.swipeActions(edge: .leading) {
			Button {
				viewModel.togglePin(for: source)
			} label: {
				Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash.fill" : "pin.fill")
			}
			.tint(dominantColor)
		}
		.swipeActions(edge: .trailing) {
			_actions(for: source)
			_contextActions(for: source)
		}
		.contextMenu {
			Button {
				viewModel.togglePin(for: source)
			} label: {
				Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
			}
			
			_contextActions(for: source)
			Divider()
			_actions(for: source)
		}
	}
}

// MARK: - Extension: View
extension SourcesCellView {
	@ViewBuilder
	private func _actions(for source: AltSource) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteSource(for: source)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for source: AltSource) -> some View {
		Button(.localized("Copy"), systemImage: "doc.on.clipboard") {
			UIPasteboard.general.string = source.sourceURL?.absoluteString
		}
	}
}
