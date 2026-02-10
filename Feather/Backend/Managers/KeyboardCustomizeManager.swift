import SwiftUI
import Combine

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

    @Published var dynamicGradientEnabled: Bool {
        didSet { UserDefaults.standard.set(dynamicGradientEnabled, forKey: "Feather.keyboard.dynamicGradientEnabled") }
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
        self.orbSpeed = UserDefaults.standard.object(forKey: "Feather.keyboard.orbSpeed") as? Double ?? 5.0
        self.backgroundColor = UserDefaults.standard.string(forKey: "Feather.keyboard.backgroundColor") ?? "#1A1A1A"
        self.backgroundImageData = UserDefaults.standard.data(forKey: "Feather.keyboard.backgroundImageData")

        self.dynamicGradientEnabled = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientEnabled") as? Bool ?? false
        self.dynamicGradientAmount = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientAmount") as? Double ?? 0.5
        self.dynamicGradientFrequency = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientFrequency") as? Double ?? 2.0
        self.dynamicGradientColorCount = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientColorCount") as? Int ?? 3
        self.dynamicGradientShuffle = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientShuffle") as? Bool ?? false
        self.dynamicGradientDirection = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientDirection") as? Double ?? 0.0
        self.dynamicGradientPulseIntensity = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientPulseIntensity") as? Double ?? 0.5
        self.dynamicGradientPreset = UserDefaults.standard.object(forKey: "Feather.keyboard.dynamicGradientPreset") as? Int ?? 0

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

        // Watch for isEnabled changes to hide window immediately if toggled off
        $isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                if !enabled {
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
        // In some cases, keyboardFrame.origin.y is equal to screenSize.height when hidden
        let isActuallyVisible = keyboardFrame.origin.y < screenSize.height
        let height = isActuallyVisible ? (screenSize.height - keyboardFrame.origin.y) : 0

        let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25

        withAnimation(.easeOut(duration: duration)) {
            self.keyboardHeight = height
            self.isKeyboardVisible = isActuallyVisible && height > 0
        }

        if self.isKeyboardVisible {
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
        // Ensure the window is always at the bottom of the screen and slightly larger to prevent edges from showing
        // Modified to have +40 overscan height and -40 Y offset to accommodate the 30pt corner radius without clipping
        let frame = CGRect(x: 0, y: screenSize.height - height - 40, width: screenSize.width, height: height + 40)

        window.isHidden = false

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseOut]) {
            window.frame = frame
            window.alpha = 1.0
        }
    }

    private func hideWindow(duration: Double = 0.25) {
        guard let window = backdropWindow else { return }

        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            window.alpha = 0
            let screenSize = UIScreen.main.bounds.size
            window.frame.origin.y = screenSize.height
        }) { _ in
            if window.alpha == 0 {
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
    let amount: Double
    let frequency: Double
    let colorCount: Int
    let shuffle: Bool
    let direction: Double
    let pulseIntensity: Double
    let preset: Int

    @State private var start = Date()

    var body: some View {
        if #available(iOS 18.0, *) {
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSince(start)
                let animOffset = time * frequency

                MeshGradient(width: 3, height: 3, points: [
                    SIMD2<Float>(0.0, 0.0), SIMD2<Float>(0.5, 0.0), SIMD2<Float>(1.0, 0.0),
                    SIMD2<Float>(0.0, 0.5), SIMD2<Float>(0.5, 0.5), SIMD2<Float>(1.0, 0.5),
                    SIMD2<Float>(0.0, 1.0), SIMD2<Float>(0.5, 1.0), SIMD2<Float>(1.0, 1.0)
                ].map { point in
                    let x = point.x
                    let y = point.y

                    // Apply dynamic movement based on direction and time
                    let angle = (Float(direction) * .pi / 180.0)
                    let dx = cos(angle) * Float(animOffset) * 0.1
                    let dy = sin(angle) * Float(animOffset) * 0.1

                    let noise = sin(Float(animOffset) + (x + dx + y + dy) * Float(amount) * 5.0) * 0.05 * Float(pulseIntensity)
                    // Clamp points to [0, 1] range as required by MeshGradient
                    let finalX = max(0.0, min(1.0, x + noise))
                    let finalY = max(0.0, min(1.0, y + noise))
                    return SIMD2<Float>(finalX, finalY)
                }, colors: getColors())
            }
        } else {
            // Fallback for older iOS if somehow reached (though feature gated for iOS 26+)
            Rectangle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
    }

    private func getColors() -> [Color] {
        var baseColors: [Color]
        switch preset {
        case 1: baseColors = [.purple, .blue, .cyan, .mint, .green, .yellow, .orange, .red, .pink]
        case 2: baseColors = [.orange, .red, .pink, .purple, .indigo]
        case 3: baseColors = [.mint, .teal, .cyan, .blue]
        case 4: baseColors = [.yellow, .orange, .red]
        case 5: baseColors = [.white, .gray, .black]
        default: baseColors = [.blue, .cyan, .indigo, .purple]
        }

        if shuffle {
            // Deterministic shuffle using a simple shift based on colorCount
            let shift = (preset + colorCount) % baseColors.count
            for _ in 0..<shift {
                let last = baseColors.removeLast()
                baseColors.insert(last, at: 0)
            }
        }

        // Ensure we have exactly 9 colors for a 3x3 MeshGradient
        var finalColors: [Color] = []
        for i in 0..<9 {
            finalColors.append(baseColors[i % min(baseColors.count, colorCount)])
        }
        return finalColors
    }
}

struct KeyboardBackdropView: View {
    @ObservedObject var manager = KeyboardCustomizeManager.shared
    @State private var floatingAnimation = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Base Background
            if let imageData = manager.backgroundImageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if manager.dynamicGradientEnabled {
                if #available(iOS 26.0, *) {
                    DynamicGradientView(
                        amount: manager.dynamicGradientAmount,
                        frequency: manager.dynamicGradientFrequency,
                        colorCount: manager.dynamicGradientColorCount,
                        shuffle: manager.dynamicGradientShuffle,
                        direction: manager.dynamicGradientDirection,
                        pulseIntensity: manager.dynamicGradientPulseIntensity,
                        preset: manager.dynamicGradientPreset
                    )
                } else {
                    // Fallback to static gradient if iOS 26+ not met
                    LinearGradient(
                        colors: [Color(hex: manager.gradientStart), Color(hex: manager.gradientEnd)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
            } else if manager.useGradient {
                LinearGradient(
                    colors: [Color(hex: manager.gradientStart), Color(hex: manager.gradientEnd)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(hex: manager.backgroundColor)
            }

            // Dynamic Animated Orbs
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
        .scaleEffect(1.2) // Scale up to cover blur edges
        .blur(radius: manager.blurRadius)
        .compositingGroup()
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
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

// Helper for deterministic random numbers with seed
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
        // The backdrop is now managed globally via a UIWindow in KeyboardCustomizeManager.
        // This modifier remains for compatibility but no longer adds its own backdrop view.
        content
    }
}

extension View {
    func withKeyboardBackdrop() -> some View {
        self.modifier(KeyboardBackdropModifier())
    }
}
