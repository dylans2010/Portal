import SwiftUI
import NimbleViews

// MARK: - Top View Appearance
/// Dedicated settings view for customizing the Portal Top View that appears
/// at the top of screenshots and certain screens.
///
/// Options include background color, text color, material style, version
/// display, and visual effects like gradients and glass overlays.
struct TopViewAppearance: View {
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("Feather.portalTopViewColor") private var portalTopViewColor: String = "#0077BE"
    @AppStorage("Feather.portalTopViewStyle") private var portalTopViewStyle: Int = 0
    @AppStorage("Feather.portalTopViewTextColor") private var portalTopViewTextColor: String = "#FFFFFF"
    @AppStorage("Feather.portalTopViewShowVersion") private var portalTopViewShowVersion: Bool = true
    @AppStorage("Feather.portalTopViewUseGradient") private var useGradient: Bool = false
    @AppStorage("Feather.portalTopViewGradientColor") private var gradientEndColor: String = "#5856D6"
    @AppStorage("Feather.portalTopViewGradientDirection") private var gradientDirection: Int = 0
    @AppStorage("Feather.portalTopViewGlassEffect") private var glassEffect: Bool = false
    @AppStorage("Feather.portalTopViewGlassIntensity") private var glassIntensity: Int = 0

    var body: some View {
        List {
            // MARK: - Preview
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .themedText(.secondary)
                        .padding(.leading, 4)

                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.secondary.opacity(0.05))
                            .frame(height: 100)

                        PortalTopView()
                            .scaleEffect(1.2)
                            .frame(height: 40)
                    }
                }
                .padding(.vertical, 8)
            }

            // MARK: - Enable Toggle (always enabled, cannot be disabled)
            Section {
                HStack {
                    Label("Enable Top View", systemImage: "uiwindow.split.2x1")
                        .font(.system(.body, design: .rounded, weight: .medium))
                    Spacer()
                    Text("Default")
                        .font(.system(.subheadline, design: .rounded))
                        .themedText(.secondary)
                }
            } footer: {
                Text("The Top View is always enabled to provide a consistent experience and show off Portal.")
            }

            // MARK: - Colors
            Section {
                HStack(spacing: 12) {
                    AppearanceRowLabel(icon: "paintpalette.fill", title: "Background Color", color: .purple)
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: portalTopViewColor) },
                        set: { portalTopViewColor = $0.toHex() ?? "#0077BE" }
                    ))
                    .labelsHidden()
                }

                HStack(spacing: 12) {
                    AppearanceRowLabel(icon: "paintbrush.fill", title: "Text Color", color: .pink)
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: portalTopViewTextColor) },
                        set: { portalTopViewTextColor = $0.toHex() ?? "#FFFFFF" }
                    ))
                    .labelsHidden()
                }
            } header: {
                Label("Colors", systemImage: "paintpalette.fill")
            }

            // MARK: - Material & Style
            Section {
                HStack(spacing: 12) {
                    AppearanceRowLabel(icon: "sparkles", title: "Material Style", color: .cyan)
                    Spacer()
                    Picker("", selection: $portalTopViewStyle) {
                        Text("Ultra Thin").tag(0)
                        Text("Thin").tag(1)
                        Text("Regular").tag(2)
                        Text("Thick").tag(3)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }

                Toggle(isOn: $portalTopViewShowVersion) {
                    AppearanceRowLabel(icon: "number", title: "Show Version", color: .green)
                }
            } header: {
                Label("Style", systemImage: "wand.and.stars")
            }

            // MARK: - Gradient
            Section {
                Toggle(isOn: $useGradient) {
                    AppearanceRowLabel(icon: "rectangle.fill.on.rectangle.fill", title: "Use Gradient", color: .indigo)
                }

                if useGradient {
                    HStack(spacing: 12) {
                        AppearanceRowLabel(icon: "paintpalette.fill", title: "Gradient End Color", color: .indigo)
                        Spacer()
                        ColorPicker("", selection: Binding(
                            get: { Color(hex: gradientEndColor) },
                            set: { gradientEndColor = $0.toHex() ?? "#5856D6" }
                        ))
                        .labelsHidden()
                    }

                    HStack(spacing: 12) {
                        AppearanceRowLabel(icon: "arrow.left.and.right", title: "Gradient Direction", color: .indigo)
                        Spacer()
                        Picker("", selection: $gradientDirection) {
                            Text("Horizontal").tag(0)
                            Text("Vertical").tag(1)
                            Text("Diagonal").tag(2)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
            } header: {
                Label("Gradient", systemImage: "rectangle.fill.on.rectangle.fill")
            } footer: {
                Text("Apply a gradient overlay to the Top View background using your selected colors.")
            }

            // MARK: - Glass Effect
            Section {
                Toggle(isOn: $glassEffect) {
                    AppearanceRowLabel(icon: "rectangle.on.rectangle.angled", title: "Glass Effect", color: .teal)
                }

                if glassEffect {
                    HStack(spacing: 12) {
                        AppearanceRowLabel(icon: "slider.horizontal.3", title: "Glass Intensity", color: .teal)
                        Spacer()
                        Picker("", selection: $glassIntensity) {
                            Text("Subtle").tag(0)
                            Text("Medium").tag(1)
                            Text("Strong").tag(2)
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }
            } header: {
                Label("Glass Effect", systemImage: "rectangle.on.rectangle.angled")
            } footer: {
                Text("Add a frosted glass blur effect for a modern, translucent appearance.")
            }
        }
        .globalTheme()
        .navigationTitle("Top View")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        TopViewAppearance()
    }
}
#endif
