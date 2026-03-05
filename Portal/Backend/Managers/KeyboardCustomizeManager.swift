// Made by dylan, made for Portal
// When doing a fork, please credit me so DO NOT remove these comments.
// This manager works by adding a UIWindow above the keyboard window and works ONLY for iOS 26
// Customizations can be done through the KeyboardCustomizationView.swift so add a file view for that as well

import SwiftUI
import Combine
import simd

class KeyboardCustomizeManager: ObservableObject {
    static let shared = KeyboardCustomizeManager()

    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "Feather.keyboard.isEnabled") }
    }
    @Published var opacity: Double {
        didSet { UserDefaults.standard.set(opacity, forKey: "Feather.keyboard.opacity") }
    }
    @Published var blurRadius: Double {
        didSet { UserDefaults.standard.set(blurRadius, forKey: "Feather.keyboard.blurRadius") }
    }
    @Published var gradientStart: String {
        didSet { UserDefaults.standard.set(gradientStart, forKey: "Feather.keyboard.gradientStart") }
    }
    @Published var gradientEnd: String {
        didSet { UserDefaults.standard.set(gradientEnd, forKey: "Feather.keyboard.gradientEnd") }
    }
    @Published var useGradient: Bool {
        didSet { UserDefaults.standard.set(useGradient, forKey: "Feather.keyboard.useGradient") }
    }
    @Published var showAnimatedOrbs: Bool {
        didSet { UserDefaults.standard.set(showAnimatedOrbs, forKey: "Feather.keyboard.showAnimatedOrbs") }
    }
    @Published var orbCount: Int {
        didSet { UserDefaults.standard.set(orbCount, forKey: "Feather.keyboard.orbCount") }
    }
    @Published var orbSpeed: Double {
        didSet { UserDefaults.standard.set(orbSpeed, forKey: "Feather.keyboard.orbSpeed") }
    }
    @Published var backgroundColor: String {
        didSet { UserDefaults.standard.set(backgroundColor, forKey: "Feather.keyboard.backgroundColor") }
    }
    @Published var backgroundImageData: Data? {
        didSet { UserDefaults.standard.set(backgroundImageData, forKey: "Feather.keyboard.backgroundImageData") }
    }

    // MARK: - Dynamic Gradient Properties
    @Published var isDynamicGradientEnabled: Bool {
        didSet { UserDefaults.standard.set(isDynamicGradientEnabled, forKey: "Feather.keyboard.isDynamicGradientEnabled") }
    }
    @Published var dynamicGradientAmount: Double {
        didSet { UserDefaults.standard.set(dynamicGradientAmount, forKey: "Feather.keyboard.dynamicGradientAmount") }
    }
    @Published var dynamicGradientFrequency: Double {
        didSet { UserDefaults.standard.set(dynamicGradientFrequency, forKey: "Feather.keyboard.dynamicGradientFrequency") }
    }
    @Published var dynamicGradientColorCount: Int {
        didSet { UserDefaults.standard.set(dynamicGradientColorCount, forKey: "Feather.keyboard.dynamicGradientColorCount") }
    }
    @Published var dynamicGradientShuffle: Bool {
        didSet { UserDefaults.standard.set(dynamicGradientShuffle, forKey: "Feather.keyboard.dynamicGradientShuffle") }
    }
    @Published var dynamicGradientDirection: Double {
        didSet { UserDefaults.standard.set(dynamicGradientDirection, forKey: "Feather.keyboard.dynamicGradientDirection") }
    }
    @Published var dynamicGradientPulseIntensity: Double {
        didSet { UserDefaults.standard.set(dynamicGradientPulseIntensity, forKey: "Feather.keyboard.dynamicGradientPulseIntensity") }
    }
    @Published var dynamicGradientPreset: Int {
        didSet { UserDefaults.standard.set(dynamicGradientPreset, forKey: "Feather.keyboard.dynamicGradientPreset") }
    }
    @Published var dynamicGradientColors: [String] {
        didSet { UserDefaults.standard.set(dynamicGradientColors, forKey: "Feather.keyboard.dynamicGradientColors") }
    }
    @Published var dynamicGradientSpeed: Double {
        didSet { UserDefaults.standard.set(dynamicGradientSpeed, forKey: "Feather.keyboard.dynamicGradientSpeed") }
    }
    @Published var dynamicGradientNoiseOpacity: Double {
        didSet { UserDefaults.standard.set(dynamicGradientNoiseOpacity, forKey: "Feather.keyboard.dynamicGradientNoiseOpacity") }
    }
    @Published var dynamicGradientSaturation: Double {
        didSet { UserDefaults.standard.set(dynamicGradientSaturation, forKey: "Feather.keyboard.dynamicGradientSaturation") }
    }
    @Published var dynamicGradientContrast: Double {
        didSet { UserDefaults.standard.set(dynamicGradientContrast, forKey: "Feather.keyboard.dynamicGradientContrast") }
    }
    @Published var dynamicGradientBrightness: Double {
        didSet { UserDefaults.standard.set(dynamicGradientBrightness, forKey: "Feather.keyboard.dynamicGradientBrightness") }
    }
    @Published var dynamicGradientMeshComplexity: Int {
        didSet { UserDefaults.standard.set(dynamicGradientMeshComplexity, forKey: "Feather.keyboard.dynamicGradientMeshComplexity") }
    }
    @Published var layoutDensity: Double {
        didSet { UserDefaults.standard.set(layoutDensity, forKey: "Feather.keyboard.layoutDensity") }
    }
    @Published var keyCornerRadius: Double {
        didSet { UserDefaults.standard.set(keyCornerRadius, forKey: "Feather.keyboard.keyCornerRadius") }
    }
    @Published var accentColor: String {
        didSet { UserDefaults.standard.set(accentColor, forKey: "Feather.keyboard.accentColor") }
    }
    @Published var animationIntensity: Double {
        didSet { UserDefaults.standard.set(animationIntensity, forKey: "Feather.keyboard.animationIntensity") }
    }
    @Published var hapticEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticEnabled, forKey: "Feather.keyboard.hapticEnabled") }
    }
    @Published var fontWeight: String {
        didSet { UserDefaults.standard.set(fontWeight, forKey: "Feather.keyboard.fontWeight") }
    }

    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var backdropWindow: UIWindow?

    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "Feather.keyboard.isEnabled") as? Bool ?? false
        self.opacity = UserDefaults.standard.object(forKey: "Feather.keyboard.opacity") as? Double ?? 0.5
        self.blurRadius = UserDefaults.standard.object(forKey: "Feather.keyboard.blurRadius") as? Double ?? 10.0
        self.gradientStart = UserDefaults.standard.string(forKey: "Feather.keyboard.gradientStart") ?? "#0077BE"
        self.gradientEnd = UserDefaults.standard.string(forKey: "Feather.keyboard.gradientEnd") ?? "#00AEEF"
        self.useGradient = UserDefaults.standard.object(forKey: "Feather.keyboard.useGradient") as? Bool ?? true
        self.showAnimatedOrbs = UserDefaults.standard.object(forKey: "Feather.keyboard.showAnimatedOrbs") as? Bool ?? true
        self.orbCount = UserDefaults.standard.object(forKey: "Feather.keyboard.orbCount") as? Int ?? 3
        self.layoutDensity = UserDefaults.standard.object(forKey: "Feather.keyboard.layoutDensity") as? Double ?? 0.5
        self.keyCornerRadius = UserDefaults.standard.object(forKey: "Feather.keyboard.keyCornerRadius") as? Double ?? 10.0
        self.accentColor = UserDefaults.standard.string(forKey: "Feather.keyboard.accentColor") ?? "#007AFF"
        self.animationIntensity = UserDefaults.standard.object(forKey: "Feather.keyboard.animationIntensity") as? Double ?? 1.0
        self.hapticEnabled = UserDefaults.standard.object(forKey: "Feather.keyboard.hapticEnabled") as? Bool ?? true
        self.fontWeight = UserDefaults.standard.string(forKey: "Feather.keyboard.fontWeight") ?? "Semibold"
        self.orbSpeed = UserDefaults.standard.object(forKey: "Feather.keyboard.orbSpeed") as? Double ?? 5.0
        self.backgroundColor = UserDefaults.standard.string(forKey: "Feather.keyboard.backgroundColor") ?? "#1A1A1A"
        self.backgroundImageData = UserDefaults.standard.data(forKey: "Feather.keyboard.backgroundImageData")

        self.isDynamicGradientEnabled = UserDefaults.standard.bool(forKey: "Feather.keyboard.isDynamicGradientEnabled")
        self.dynamicGradientAmount = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientAmount") as? Double ?? 1.0
        self.dynamicGradientFrequency = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientFrequency") as? Double ?? 1.0
        self.dynamicGradientColorCount = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientColorCount") as? Int ?? 3
        self.dynamicGradientShuffle = UserDefaults.standard.bool(forKey: "Feather.keyboard.dynamicGradientShuffle")
        self.dynamicGradientDirection = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientDirection") as? Double ?? 0.0
        self.dynamicGradientPulseIntensity = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientPulseIntensity") as? Double ?? 1.0
        self.dynamicGradientPreset = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientPreset") as? Int ?? 0
        self.dynamicGradientSpeed = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientSpeed") as? Double ?? 1.0
        self.dynamicGradientNoiseOpacity = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientNoiseOpacity") as? Double ?? 0.0
        self.dynamicGradientSaturation = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientSaturation") as? Double ?? 1.0
        self.dynamicGradientContrast = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientContrast") as? Double ?? 1.0
        self.dynamicGradientBrightness = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientBrightness") as? Double ?? 0.0
        self.dynamicGradientMeshComplexity = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientMeshComplexity") as? Int ?? 3
        self.layoutDensity = UserDefaults.standard.object(forKey: "Feather.keyboard.layoutDensity") as? Double ?? 0.5
        self.keyCornerRadius = UserDefaults.standard.object(forKey: "Feather.keyboard.keyCornerRadius") as? Double ?? 10.0
        self.accentColor = UserDefaults.standard.string(forKey: "Feather.keyboard.accentColor") ?? "#007AFF"
        self.animationIntensity = UserDefaults.standard.object(forKey: "Feather.keyboard.animationIntensity") as? Double ?? 1.0
        self.hapticEnabled = UserDefaults.standard.object(forKey: "Feather.keyboard.hapticEnabled") as? Bool ?? true
        self.fontWeight = UserDefaults.standard.string(forKey: "Feather.keyboard.fontWeight") ?? "Semibold"

        let savedColors = UserDefaults.standard.stringArray(forKey: "Feather.keyboard.dynamicGradientColors") ?? []
        var colors = savedColors
        let defaults = ["#FF0000", "#00FF00", "#0000FF", "#FFFF00", "#00FFFF", "#FF00FF", "#FFA500", "#800080", "#008000", "#000080"]
        while colors.count < 10 {
            colors.append(defaults[colors.count])
        }
        self.dynamicGradientColors = colors

        setupObservers()
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: false)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] notification in
                self?.handleKeyboard(notification: notification, visible: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.hideWindow(duration: 0)
            }
            .store(in: &cancellables)

        $isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                if !enabled {
                    self?.isKeyboardVisible = false
                    self?.keyboardHeight = 0
                    self?.hideWindow()
                }
            }
            .store(in: &cancellables)
    }

    private func handleKeyboard(notification: Notification, visible: Bool) {
        guard isEnabled else {
            hideWindow()
            return
        }

        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let screenSize = UIScreen.main.bounds.size

        let isActuallyVisible = visible && keyboardFrame.origin.y < screenSize.height
        let height = isActuallyVisible ? (screenSize.height - keyboardFrame.origin.y) : 0

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25

        withAnimation(.easeOut(duration: duration)) {
            self.keyboardHeight = height
            self.isKeyboardVisible = isActuallyVisible && height > 0
        }

        if self.isKeyboardVisible && height > 0 {
            updateWindow(height: height, duration: duration)
        } else {
            hideWindow(duration: duration)
        }
    }

    private func updateWindow(height: CGFloat, duration: Double) {
        if backdropWindow == nil {
            setupWindow()
        }

        guard let window = backdropWindow else { return }

        let screenSize = UIScreen.main.bounds.size

        let overscan: CGFloat = 40
        let frame = CGRect(x: 0, y: screenSize.height - height - overscan, width: screenSize.width, height: height + overscan + 100)

        window.isHidden = false

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            window.frame = frame
            window.alpha = 1.0
        }
    }

    private func hideWindow(duration: Double = 0.25) {
        guard let window = backdropWindow else { return }

        if duration == 0 {
            window.alpha = 0
            let screenSize = UIScreen.main.bounds.size
            window.frame.origin.y = screenSize.height
            window.isHidden = true
            return
        }

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            window.alpha = 0
            let screenSize = UIScreen.main.bounds.size
            window.frame.origin.y = screenSize.height
        }) { [weak self] _ in
            if self?.isKeyboardVisible == false {
                window.isHidden = true
            }
        }
    }

    private func setupWindow() {
        guard let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first ?? (UIApplication.shared.connectedScenes.first as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        // Set window level to be just above the normal window but below the keyboard window (which is much higher)
        window.windowLevel = UIWindow.Level(rawValue: 1)
        window.isUserInteractionEnabled = false
        window.backgroundColor = .clear

        let controller = UIHostingController(rootView: KeyboardBackdropView(manager: self))
        controller.view.backgroundColor = .clear
        window.rootViewController = controller

        self.backdropWindow = window
    }
}

// MARK: - Views and Modifiers

struct DynamicGradientView: View {
    @ObservedObject var manager: KeyboardCustomizeManager = .shared

    var body: some View {
        TimelineView(.animation) { timeline in
            let date = timeline.date.timeIntervalSinceReferenceDate
            let frequency = manager.dynamicGradientFrequency
            let amount = manager.dynamicGradientAmount
            let speed = manager.dynamicGradientSpeed

            let baseColors = getColors(for: date)
            let angle = Angle(degrees: manager.dynamicGradientDirection + (date * 20 * frequency * speed))

            ZStack {
                if #available(iOS 18.0, *) {
                    let w = max(2, manager.dynamicGradientMeshComplexity)
                    let h = max(2, manager.dynamicGradientMeshComplexity)

                    MeshGradient(
                        width: w,
                        height: h,
                        points: (0..<h).flatMap { row in
                            (0..<w).map { col in
                                let x = Float(col) / Float(w - 1)
                                let y = Float(row) / Float(h - 1)
                                let offset = Double(row * w + col) * 0.5
                                let dx = sin(date * frequency * speed + offset) * 0.1 * amount
                                let dy = cos(date * frequency * speed + offset) * 0.1 * amount
                                return simd_float2(max(0, min(1, x + Float(dx))), max(0, min(1, y + Float(dy))))
                            }
                        },
                        colors: (0..<(w*h)).map { baseColors[$0 % baseColors.count] }
                    )
                    .hueRotation(.degrees(amount * date * 10))
                } else {
                    LinearGradient(
                        colors: baseColors,
                        startPoint: UnitPoint(x: 0.5 + 0.5 * cos(angle.radians), y: 0.5 + 0.5 * sin(angle.radians)),
                        endPoint: UnitPoint(x: 0.5 - 0.5 * cos(angle.radians), y: 0.5 - 0.5 * sin(angle.radians))
                    )
                    .hueRotation(.degrees(amount * date * 10))
                }

                if manager.dynamicGradientNoiseOpacity > 0 {
                    Color.black.opacity(0.01)
                        .overlay(
                            Canvas { context, size in
                                for _ in 0..<1000 {
                                    let x = CGFloat.random(in: 0...size.width)
                                    let y = CGFloat.random(in: 0...size.height)
                                    context.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)), with: .color(.white.opacity(0.5)))
                                }
                            }
                        )
                        .blendMode(.overlay)
                        .opacity(manager.dynamicGradientNoiseOpacity)
                }
            }
            .saturation(manager.dynamicGradientSaturation)
            .contrast(manager.dynamicGradientContrast)
            .brightness(manager.dynamicGradientBrightness)
            .scaleEffect(1.0 + sin(date * frequency * speed) * 0.1 * manager.dynamicGradientPulseIntensity)
        }
    }

    private func getColors(for date: TimeInterval) -> [Color] {
        let baseColors: [Color]

        switch manager.dynamicGradientPreset {
        case 1: // Aurora
            baseColors = [.green, .teal, .blue, .purple]
        case 2: // Sunset
            baseColors = [.orange, .pink, .red, .purple]
        case 3: // Ocean
            baseColors = [.blue, .cyan, .indigo, .blue]
        case 4: // Nebula
            baseColors = [.purple, .blue, .pink, .indigo]
        default: // Custom / Default
            // Use only the colors defined by dynamicGradientColorCount
            let customColors = manager.dynamicGradientColors.prefix(manager.dynamicGradientColorCount).map { Color(hex: $0) }
            baseColors = customColors.isEmpty ? [.blue, .purple] : Array(customColors)
        }

        var colors = baseColors
        if manager.dynamicGradientShuffle && baseColors.count > 1 {
            // Pseudo-shuffle based on date
            let offset = Int(date) % colors.count
            for _ in 0..<offset {
                let first = colors.removeFirst()
                colors.append(first)
            }
        }

        let count = max(2, min(colors.count, manager.dynamicGradientColorCount))
        return Array(colors.prefix(count))
    }
}

struct KeyboardBackdropView: View {
    @ObservedObject var manager: KeyboardCustomizeManager = .shared
    @State private var floatingAnimation = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            if manager.isEnabled && manager.isKeyboardVisible && ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 16 {
                // Base Background
                Group {
                    if manager.isDynamicGradientEnabled {
                        DynamicGradientView(manager: manager)
                    } else if let imageData = manager.backgroundImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if manager.useGradient {
                        LinearGradient(
                            colors: [Color(hex: manager.gradientStart), Color(hex: manager.gradientEnd)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        Color(hex: manager.backgroundColor)
                    }
                }

                // Dynamic Animated Orbs
                Group {
                    if manager.showAnimatedOrbs {
                        GeometryReader { geo in
                            ZStack {
                                ForEach(0..<manager.orbCount, id: \.self) { index in
                                    orbView(for: index, in: geo.size)
                                }
                            }
                        }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 11.0 - manager.orbSpeed).repeatForever(autoreverses: true)) {
                                floatingAnimation = true
                            }
                        }
                        .onChange(of: manager.orbSpeed) { _ in
                            withAnimation(.easeInOut(duration: 11.0 - manager.orbSpeed).repeatForever(autoreverses: true)) {
                                floatingAnimation.toggle()
                            }
                        }
                    }
                }
                .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: manager.isKeyboardVisible)
        .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
        .offset(y: 40) 
        .compositingGroup()
        .scaleEffect(1.1) 
        .blur(radius: manager.blurRadius)
        .opacity(manager.opacity)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func orbView(for index: Int, in size: CGSize) -> some View {
        let colors: [Color] = [.accentColor, .purple, .cyan, .blue, .pink, .indigo, .mint]
        let color = colors[index % colors.count]
        let orbSize = CGFloat.random(in: 100...250, seed: index)
        let xPos = CGFloat.random(in: 0...size.width, seed: index)
        let yPos = CGFloat.random(in: 0...size.height, seed: index)

        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.4),
                        color.opacity(0.1),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: orbSize / 2
                )
            )
            .frame(width: orbSize, height: orbSize)
            .blur(radius: orbSize / 5)
            .offset(x: floatingAnimation ? CGFloat.random(in: -40...40, seed: index + 100) : CGFloat.random(in: -40...40, seed: index + 200),
                    y: floatingAnimation ? CGFloat.random(in: -30...30, seed: index + 300) : CGFloat.random(in: -30...30, seed: index + 400))
            .position(x: xPos, y: yPos)
    }
}

extension CGFloat {
    static func random(in range: ClosedRange<CGFloat>, seed: Int) -> CGFloat {
        var g = SeededGenerator(seed: UInt64(seed))
        return CGFloat.random(in: range, using: &g)
    }
}

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        state = seed
    }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct KeyboardBackdropModifier: ViewModifier {
    @ObservedObject var manager = KeyboardCustomizeManager.shared

    func body(content: Content) -> some View {

        content
    }
}

extension View {
    func withKeyboardBackdrop() -> some View {
        self.modifier(KeyboardBackdropModifier())
    }
}
