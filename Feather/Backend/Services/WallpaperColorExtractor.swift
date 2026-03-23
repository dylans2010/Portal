import SwiftUI
import UIKit

final class WallpaperColorExtractor {
    static let shared = WallpaperColorExtractor()

    private init() {}

    func extractDominantColors(from image: UIImage) -> (primary: Color, secondary: Color, accent: Color) {
        // Simplified dominant color extraction logic
        // In a real app, this would use a more sophisticated algorithm like K-Means

        // Resize image to improve performance
        let size = CGSize(width: 50, height: 50)
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = resizedImage?.cgImage,
              let dataProvider = cgImage.dataProvider,
              let pixelData = dataProvider.data else {
            return (.blue, .cyan, .purple)
        }

        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let length = CFDataGetLength(pixelData)

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0

        for i in stride(from: 0, to: length, by: 4) {
            r += CGFloat(data[i])
            g += CGFloat(data[i+1])
            b += CGFloat(data[i+2])
        }

        let count = CGFloat(length / 4)
        let avgColor = Color(red: r/count/255.0, green: g/count/255.0, blue: b/count/255.0)

        // Generate a palette based on the average color
        let primary = avgColor
        let secondary = avgColor.opacity(0.7)
        let accent = Color(red: 1.0 - r/count/255.0, green: 1.0 - g/count/255.0, blue: 1.0 - b/count/255.0)

        return (primary, secondary, accent)
    }
}
