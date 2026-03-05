// Created by dylan on 1.4.26

import SwiftUI
import UIKit

extension UIImage {
    /// Extracts dominant colors from the image
    /// - Parameter count: The number of dominant colors to extract
    /// - Returns: An array of dominant Colors
    func getDominantColors(count: Int = 3) -> [Color] {
        guard let cgImage = self.cgImage else { return [] }

        let width = 50
        let height = 50
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        guard let context = CGContext(data: nil,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else {
            return []
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let data = context.data else { return [] }
        let pixelBuffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        var colorCounts: [UInt32: Int] = [:]

        for i in 0..<width * height {
            let offset = i * bytesPerPixel
            let r = pixelBuffer[offset]
            let g = pixelBuffer[offset + 1]
            let b = pixelBuffer[offset + 2]
            let a = pixelBuffer[offset + 3]

            // Ignore transparent or very dark/light pixels
            if a < 128 { continue }

            // Group colors slightly to reduce noise
            let roundedR = (UInt32(r) / 10) * 10
            let roundedG = (UInt32(g) / 10) * 10
            let roundedB = (UInt32(b) / 10) * 10

            let hex = (roundedR << 16) | (roundedG << 8) | roundedB
            colorCounts[hex, default: 0] += 1
        }

        let sortedColors = colorCounts.sorted { $0.value > $1.value }
            .prefix(count)
            .map { hex, _ in
                let r = Double((hex >> 16) & 0xFF) / 255.0
                let g = Double((hex >> 8) & 0xFF) / 255.0
                let b = Double(hex & 0xFF) / 255.0
                return Color(red: r, green: g, blue: b)
            }

        return Array(sortedColors)
    }
}

extension Image {
	/// Applies a certain style to an image
	func appIconStyle(
		size: CGFloat = 56,
		lineWidth: CGFloat = 1,
		isCircle: Bool = false,
		background: Color = .clear
	) -> some View {
		self.resizable()
			.scaledToFit()
			.frame(width: size, height: size)
			.background(
				RoundedRectangle(cornerRadius: isCircle ? (size * 2) : (size * 0.2237), style: .continuous)
					.fill(background)
			)
			.overlay {
				RoundedRectangle(cornerRadius: isCircle ? (size * 2) : (size * 0.2237), style: .continuous)
					.strokeBorder(.gray.opacity(0.3), lineWidth: lineWidth)
			}
			.clipShape(RoundedRectangle(cornerRadius: isCircle ? (size * 2) : (size * 0.2237), style: .continuous))
	}
}

