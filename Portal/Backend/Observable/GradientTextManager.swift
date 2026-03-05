import SwiftUI
import Combine

// MARK: - Gradient Text Manager
/// Manages gradient text rendering across the app for both SwiftUI and UIKit
class GradientTextManager: ObservableObject {
	static let shared = GradientTextManager()
	
	@AppStorage("Feather.gradientTextEnabled") var isGradientTextEnabled: Bool = false
	@AppStorage("Feather.gradientTextStartColor") var gradientStartColorHex: String = "#0077BE"
	@AppStorage("Feather.gradientTextEndColor") var gradientEndColorHex: String = "#848ef9"
	@AppStorage("Feather.gradientTextDirection") var gradientDirection: String = "horizontal"
	@AppStorage("Feather.useAccessibilityFallback") var useAccessibilityFallback: Bool = false
	
	private init() {}
	
	var gradientColors: [Color] {
		let colors: [Color] = [Color(hex: gradientStartColorHex), Color(hex: gradientEndColorHex)]
		return colors
	}
	
	var gradientStartPoint: UnitPoint {
		switch gradientDirection {
		case "horizontal": return .leading
		case "vertical": return .top
		case "diagonal": return .topLeading
		default: return .leading
		}
	}
	
	var gradientEndPoint: UnitPoint {
		switch gradientDirection {
		case "horizontal": return .trailing
		case "vertical": return .bottom
		case "diagonal": return .bottomTrailing
		default: return .trailing
		}
	}
	
	func shouldUseGradient() -> Bool {
		return isGradientTextEnabled && !useAccessibilityFallback
	}
}

// MARK: - SwiftUI Text Modifier
struct GradientTextModifier: ViewModifier {
	@ObservedObject private var manager = GradientTextManager.shared
	
	func body(content: Content) -> some View {
		if manager.shouldUseGradient() {
			content
				.foregroundStyle(
					LinearGradient(
						colors: manager.gradientColors,
						startPoint: manager.gradientStartPoint,
						endPoint: manager.gradientEndPoint
					)
				)
		} else {
			content
		}
	}
}

extension View {
	func gradientText() -> some View {
		self.modifier(GradientTextModifier())
	}
}

// MARK: - UIKit Support
extension UILabel {
	private static var gradientImageCache = [String: UIImage]()
	
	func applyGradientText() {
		let manager = GradientTextManager.shared
		
		guard manager.shouldUseGradient() else {
			// Reset to default if gradient is disabled
			self.textColor = .label
			return
		}
		
		// Create cache key from gradient parameters
		let cacheKey = "\(manager.gradientStartColorHex)_\(manager.gradientEndColorHex)_\(manager.gradientDirection)_\(Int(self.bounds.width))_\(Int(self.bounds.height))"
		
		// Check cache first
		if let cachedImage = UILabel.gradientImageCache[cacheKey] {
			self.textColor = UIColor(patternImage: cachedImage)
			return
		}
		
		// Create gradient layer
		let gradientLayer = CAGradientLayer()
		gradientLayer.frame = self.bounds.isEmpty ? CGRect(x: 0, y: 0, width: 200, height: 50) : self.bounds
		
		let startColor = UIColor(Color(hex: manager.gradientStartColorHex))
		let endColor = UIColor(Color(hex: manager.gradientEndColorHex))
		
		gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
		
		// Set gradient direction
		switch manager.gradientDirection {
		case "horizontal":
			gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
			gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
		case "vertical":
			gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
			gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
		case "diagonal":
			gradientLayer.startPoint = CGPoint(x: 0, y: 0)
			gradientLayer.endPoint = CGPoint(x: 1, y: 1)
		default:
			gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
			gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
		}
		
		// Create image from gradient
		UIGraphicsBeginImageContextWithOptions(gradientLayer.bounds.size, false, 0)
		guard let context = UIGraphicsGetCurrentContext() else { return }
		gradientLayer.render(in: context)
		let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		// Apply as text color and cache
		if let image = gradientImage {
			UILabel.gradientImageCache[cacheKey] = image
			self.textColor = UIColor(patternImage: image)
			
			// Limit cache size to prevent memory issues
			if UILabel.gradientImageCache.count > 20 {
				UILabel.gradientImageCache.removeAll()
			}
		}
	}
}

// MARK: - Notification for live updates
extension Notification.Name {
	static let gradientTextSettingsChanged = Notification.Name("Feather.gradientTextSettingsChanged")
}
