import SwiftUI
import Combine

class ColorBackgroundManager: ObservableObject {
    static let shared = ColorBackgroundManager()

    @AppStorage("Feather.appearance.baseColorData") private var baseColorData: Data = Data()

    @Published var baseColor: Color = Color(hex: Color.defaultBackground) {
        didSet {
            _saveBaseColor()
        }
    }

    var resolvedColor: Color {
        baseColor
    }

    private init() {
        _loadBaseColor()
    }

    private func _loadBaseColor() {
        if let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: baseColorData) {
            baseColor = Color(uiColor)
        } else {
            baseColor = Color(hex: Color.defaultBackground)
        }
    }

    private func _saveBaseColor() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(baseColor), requiringSecureCoding: true)
            baseColorData = data
        } catch {
            print("Failed to save base color: \(error)")
        }
    }
}
