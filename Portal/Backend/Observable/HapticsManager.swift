import Foundation
import UIKit

// MARK: - HapticsManager
class HapticsManager: ObservableObject {
    static let shared = HapticsManager()
    
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "Feather.hapticsEnabled")
        }
    }
    
    @Published var intensity: HapticIntensity {
        didSet {
            UserDefaults.standard.set(intensity.rawValue, forKey: "Feather.hapticsIntensity")
        }
    }
    
    enum HapticIntensity: String, CaseIterable {
        case slow = "Slow"
        case defaultIntensity = "Default"
        case hard = "Hard"
        case extreme = "Extreme"
        
        var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .slow:
                return .light
            case .defaultIntensity:
                return .medium
            case .hard:
                return .heavy
            case .extreme:
                return .rigid
            }
        }
        
        var title: String {
            switch self {
            case .slow:
                return .localized("Slow")
            case .defaultIntensity:
                return .localized("Default")
            case .hard:
                return .localized("Hard")
            case .extreme:
                return .localized("Extreme")
            }
        }
    }
    
    private init() {
        let hasValue = UserDefaults.standard.object(forKey: "Feather.hapticsEnabled") != nil
        let initialEnabled = hasValue ? UserDefaults.standard.bool(forKey: "Feather.hapticsEnabled") : true
        self.isEnabled = initialEnabled

        let intensityRaw = UserDefaults.standard.string(forKey: "Feather.hapticsIntensity") ?? "Default"
        self.intensity = HapticIntensity(rawValue: intensityRaw) ?? .defaultIntensity
    }
    
    // MARK: - Public Methods
    func impact() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: intensity.impactStyle)
        generator.prepare()
        generator.impactOccurred()
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func softImpact() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func light() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    func error() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
    
    func warning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
    }
    
    func selection() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    func selectionChanged() {
        guard isEnabled else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}
