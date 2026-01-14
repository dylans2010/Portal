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
						.frame(width: 36, height: 36)
						.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
						.shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
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
			RoundedRectangle(cornerRadius: 8, style: .continuous)
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
				.frame(width: 36, height: 36)
			
			Image(systemName: "globe")
				.font(.system(size: 18))
				.foregroundStyle(Color.accentColor)
		}
		.shadow(color: Color.accentColor.opacity(0.1), radius: 1, x: 0, y: 0.5)
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
		
		HStack(spacing: 10) {
			// Icon - compact
			iconView
			
			// Title with app count
			VStack(alignment: .leading, spacing: 1) {
				Text(source.name ?? .localized("Unknown"))
					.font(.system(size: 13, weight: .medium))
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				if let appCount = viewModel.sources[source]?.apps.count, appCount > 0 {
					Text("\(appCount) \(appCount == 1 ? "App" : "Apps")")
						.font(.system(size: 10, weight: .regular))
						.foregroundStyle(.secondary)
				}
			}
			
			Spacer()
			
			if isPinned {
				Image(systemName: "pin.fill")
					.font(.system(size: 8))
					.foregroundStyle(dominantColor)
			}
			
			Image(systemName: "chevron.right")
				.font(.system(size: 10, weight: .medium))
				.foregroundStyle(.tertiary)
		}
		.padding(.horizontal, 8)
		.padding(.vertical, 6)
		.contentShape(Rectangle())
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
		if !viewModel.isRequiredSource(source) {
			Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
				Storage.shared.deleteSource(for: source)
			}
		} else {
			// Required source - show locked indicator
			Button {
				// Do nothing - source is required
			} label: {
				Label(.localized("Required"), systemImage: "lock.fill")
			}
			.disabled(true)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for source: AltSource) -> some View {
		Button(.localized("Copy"), systemImage: "doc.on.clipboard") {
			UIPasteboard.general.string = source.sourceURL?.absoluteString
		}
		
		if viewModel.isRequiredSource(source) {
			Divider()
			Label(.localized("Default Source (Cannot Remove)"), systemImage: "lock.shield.fill")
				.foregroundStyle(.secondary)
		}
	}
}
