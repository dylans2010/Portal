import SwiftUI
import Combine

class ColorBackgroundManager: ObservableObject {
    static let shared = ColorBackgroundManager()

    @AppStorage("Feather.appearance.baseColorData") private var baseColorData: Data = Data()
    @AppStorage("Feather.appearance.currentThemeId") private var currentThemeId: String = ""
    @AppStorage("Feather.appearance.scheduleMorning") private var scheduleMorning: String = "06:00"
    @AppStorage("Feather.appearance.scheduleSunset") private var scheduleSunset: String = "18:00"
    @AppStorage("Feather.appearance.scheduleNight") private var scheduleNight: String = "21:00"

    @AppStorage("Feather.appearance.timeBasedTheming") private var timeBasedTheming: Bool = false
    @AppStorage("Feather.appearance.morningTheme") private var morningThemeId: String = ""
    @AppStorage("Feather.appearance.sunsetTheme") private var sunsetThemeId: String = ""
    @AppStorage("Feather.appearance.nightTheme") private var nightThemeId: String = ""

    @AppStorage("Feather.appearance.contextTheming") private var contextTheming: Bool = false
    @AppStorage("Feather.appearance.lowPowerTheme") private var lowPowerThemeId: String = ""

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
        _setupTimer()
    }

    private func _setupTimer() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?._checkThemeSchedule()
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
            self?._checkContextTheming()
        }
    }

    private func _checkThemeSchedule() {
        guard timeBasedTheming else { return }

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let currentTime = formatter.string(from: now)

        var targetThemeId = ""

        if currentTime >= scheduleNight || currentTime < scheduleMorning {
            targetThemeId = nightThemeId
        } else if currentTime >= scheduleSunset {
            targetThemeId = sunsetThemeId
        } else if currentTime >= scheduleMorning {
            targetThemeId = morningThemeId
        }

        if !targetThemeId.isEmpty && targetThemeId != currentThemeId {
            _applyTheme(withId: targetThemeId)
        }
    }

    private func _checkContextTheming() {
        guard contextTheming else { return }

        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            if !lowPowerThemeId.isEmpty && lowPowerThemeId != currentThemeId {
                _applyTheme(withId: lowPowerThemeId)
            }
        }
    }

    private func _applyTheme(withId themeId: String) {
        currentThemeId = themeId

        // Fetch all themes to find the matching ID
        guard let data = UserDefaults.standard.data(forKey: "Feather.userThemes"),
              let allThemes = try? JSONDecoder().decode([ColorTheme].self, from: data),
              let theme = allThemes.first(where: { $0.id.uuidString == themeId }) else {
            return
        }

        // Update all relevant appearance settings
        baseColor = Color(hex: theme.bg)

        let defaults = UserDefaults.standard
        defaults.set(theme.ui, forKey: UserDefaults.Keys.uiElement)
        defaults.set(theme.text, forKey: UserDefaults.Keys.text)
        if let st = theme.secondaryText { defaults.set(st, forKey: UserDefaults.Keys.secondaryText) }
        if let cr = theme.cardRadius { defaults.set(cr, forKey: UserDefaults.Keys.cardCornerRadius) }
        if let fd = theme.fontDesign { defaults.set(fd, forKey: UserDefaults.Keys.fontDesign) }
        if let nb = theme.navBarColor { defaults.set(nb, forKey: UserDefaults.Keys.navBarColor) }
        if let tb = theme.tabBarColor { defaults.set(tb, forKey: UserDefaults.Keys.tabBarColor) }
        if let dc = theme.dividerColor { defaults.set(dc, forKey: UserDefaults.Keys.dividerColor) }
        if let sb = theme.sheetBackgroundColor { defaults.set(sb, forKey: UserDefaults.Keys.sheetBackgroundColor) }
        if let sc = theme.successColor { defaults.set(sc, forKey: UserDefaults.Keys.successColor) }
        if let wc = theme.warningColor { defaults.set(wc, forKey: UserDefaults.Keys.warningColor) }
        if let ec = theme.errorColor { defaults.set(ec, forKey: UserDefaults.Keys.errorColor) }
        if let gi = theme.glowIntensity { defaults.set(gi, forKey: UserDefaults.Keys.glowIntensity) }
        if let bw = theme.borderWidth { defaults.set(bw, forKey: UserDefaults.Keys.borderWidth) }
        if let co = theme.cardOpacity { defaults.set(co, forKey: UserDefaults.Keys.cardOpacity) }
        defaults.set(theme.tint, forKey: "Feather.userTintColor")

        NotificationCenter.default.post(name: NSNotification.Name("Feather.appearance.themeChanged"), object: nil, userInfo: ["themeId": themeId])
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
