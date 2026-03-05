import SwiftUI
import UIKit

class AppIconColorManager: ObservableObject {
    static let shared = AppIconColorManager()

    @Published var dominantColors: [Color] = [.blue, .purple, .cyan]

    private var colorCache: [String: [Color]] = [:]

    var primaryColor: Color {
        dominantColors.first ?? .blue
    }

    var secondaryColor: Color {
        dominantColors.indices.contains(1) ? dominantColors[1] : primaryColor.opacity(0.8)
    }

    var tertiaryColor: Color {
        dominantColors.indices.contains(2) ? dominantColors[2] : secondaryColor.opacity(0.8)
    }

    var adaptiveForeground: Color {
        primaryColor.brightness > 0.5 ? .black : .white
    }

    func extractColors(from image: UIImage?, for identifier: String?) {
        guard let image = image, let id = identifier else { return }

        if let cached = colorCache[id] {
            self.dominantColors = cached
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let colors = image.getDominantColors(count: 3)
            DispatchQueue.main.async {
                if !colors.isEmpty {
                    self.colorCache[id] = colors
                    self.dominantColors = colors
                }
            }
        }
    }
}
