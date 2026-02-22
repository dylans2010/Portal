import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct UILayoutDevView: View {
    @AppStorage("dev.showLayoutBoundaries") private var showLayoutBoundaries = false
    @AppStorage("dev.slowAnimations") private var slowAnimations = false
    @AppStorage("dev.animationSpeed") private var animationSpeed: Double = 1.0
    @AppStorage("dev.forceDarkMode") private var forceDarkMode = false
    @AppStorage("dev.forceLightMode") private var forceLightMode = false
    @AppStorage("dev.forceReducedMotion") private var forceReducedMotion = false
    @AppStorage("dev.dynamicTypeSize") private var dynamicTypeSize: String = "default"
    @AppStorage("dev.showBannerPreview") private var showBannerPreview = false

    var body: some View {
        List {
            // Appearance Overrides
            Section(header: Text("Appearance Overrides")) {
                Toggle("Force Dark Mode", isOn: $forceDarkMode)
                    .onChange(of: forceDarkMode) { newValue in
                        if newValue { forceLightMode = false }
                        applyAppearanceOverride()
                    }

                Toggle("Force Light Mode", isOn: $forceLightMode)
                    .onChange(of: forceLightMode) { newValue in
                        if newValue { forceDarkMode = false }
                        applyAppearanceOverride()
                    }

                Button("Reset To System") {
                    forceDarkMode = false
                    forceLightMode = false
                    applyAppearanceOverride()
                }
            }

            // Dynamic Type
            Section(header: Text("Dynamic Type")) {
                Picker("Text Size", selection: $dynamicTypeSize) {
                    Text("Default").tag("default")
                    Text("Extra Small").tag("xSmall")
                    Text("Small").tag("small")
                    Text("Medium").tag("medium")
                    Text("Large").tag("large")
                    Text("Extra Large").tag("xLarge")
                    Text("XXL").tag("xxLarge")
                    Text("XXXL").tag("xxxLarge")
                    Text("Accessibility M").tag("accessibility1")
                    Text("Accessibility L").tag("accessibility2")
                    Text("Accessibility XL").tag("accessibility3")
                }
            }

            // Motion & Animations
            Section(header: Text("Motion & Animations")) {
                Toggle("Reduced Motion", isOn: $forceReducedMotion)

                Toggle("Slow Animations", isOn: $slowAnimations)
                    .onChange(of: slowAnimations) { newValue in
                        applyAnimationSpeed(newValue ? 0.1 : animationSpeed)
                    }

                VStack(alignment: .leading) {
                    Text("Animation Speed: \(String(format: "%.1fx", animationSpeed))")
                    Slider(value: $animationSpeed, in: 0.1...2.0, step: 0.1)
                        .onChange(of: animationSpeed) { newValue in
                            if !slowAnimations {
                                applyAnimationSpeed(newValue)
                            }
                        }
                }
            }

            // Layout Debugging
            Section(header: Text("Layout Debugging")) {
                Toggle("Show Layout Boundaries", isOn: $showLayoutBoundaries)
                    .onChange(of: showLayoutBoundaries) { newValue in
                        UserDefaults.standard.set(newValue, forKey: "_UIConstraintBasedLayoutPlayground")
                    }
            }

            // Banner Injection
            Section(header: Text("Banner Injection")) {
                Toggle("Show Test Banner", isOn: $showBannerPreview)

                Button("Inject Update Banner") {
                    injectUpdateBanner()
                }

                Button("Inject Error Banner") {
                    injectErrorBanner()
                }

                Button("Clear All Banners") {
                    clearBanners()
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("UI & Layout")
    }

    private func applyAppearanceOverride() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        if forceDarkMode {
            window.overrideUserInterfaceStyle = .dark
        } else if forceLightMode {
            window.overrideUserInterfaceStyle = .light
        } else {
            window.overrideUserInterfaceStyle = .unspecified
        }
    }

    private func applyAnimationSpeed(_ speed: Double) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        window.layer.speed = Float(speed)
    }

    private func injectUpdateBanner() {
        NotificationCenter.default.post(
            name: Notification.Name("Feather.showBanner"),
            object: nil,
            userInfo: ["type": "update", "message": "A new Portal version is now available!"]
        )
        ToastManager.shared.show("✅ Update Banner Injected", type: .success)
        AppLogManager.shared.info("Update Banner Injected", category: "Developer")
    }

    private func injectErrorBanner() {
        NotificationCenter.default.post(
            name: Notification.Name("Feather.showBanner"),
            object: nil,
            userInfo: ["type": "error", "message": "Test Error Banner"]
        )
        ToastManager.shared.show("✅ Error Banner Injected", type: .success)
        AppLogManager.shared.info("Error Banner Injected", category: "Developer")
    }

    private func clearBanners() {
        NotificationCenter.default.post(name: Notification.Name("Feather.clearBanners"), object: nil)
        ToastManager.shared.show("✅ Banners Cleared", type: .success)
        AppLogManager.shared.info("Banners Cleared", category: "Developer")
    }
}
