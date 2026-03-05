import SwiftUI
import NukeUI
import NimbleViews

// MARK: - View
struct FRIconCellView: View {
	var title: String
	var subtitle: String
	var iconUrl: URL?
	var size: CGFloat = 56
	var isCircle: Bool = false
	var onColorExtracted: ((Color) -> Void)? = nil
	
	@State private var extractedColor: Color = .accentColor
	
	// MARK: Body
	var body: some View {
		HStack(spacing: 18) {
			if let iconURL = iconUrl {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image.appIconStyle(size: size, isCircle: isCircle)
							.onAppear {
								if let uiImage = state.imageContainer?.image {
									extractDominantColor(from: uiImage)
								}
							}
					} else {
						standardIcon
					}
				}
			} else {
				standardIcon
			}
			
			NBTitleWithSubtitleView(
				title: title,
				subtitle: subtitle,
				linelimit: 0
			)
		}
	}
	
	private func extractDominantColor(from image: UIImage) {
		guard let inputImage = CIImage(image: image) else { return }
		let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
		
		guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return }
		guard let outputImage = filter.outputImage else { return }
		
		var bitmap = [UInt8](repeating: 0, count: 4)
		let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
		context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
		
		let color = Color(red: Double(bitmap[0]) / 255.0, green: Double(bitmap[1]) / 255.0, blue: Double(bitmap[2]) / 255.0)
		onColorExtracted?(color)
	}
	
	var standardIcon: some View {
		ZStack {
			RoundedRectangle(cornerRadius: isCircle ? size / 2.0 : size * 0.2237, style: .continuous)
				.fill(Color.accentColor.opacity(0.15))
				.frame(width: size, height: size)
			
			Image(systemName: "globe")
				.font(.system(size: size * 0.5))
				.foregroundStyle(Color.accentColor)
		}
	}
}
