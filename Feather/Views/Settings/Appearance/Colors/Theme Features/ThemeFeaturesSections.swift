import SwiftUI

struct IntelligentThemeFeaturesView: View {
    @Binding var contextTheming: Bool
    @Binding var lowPowerThemeId: String
    @Binding var focusThemeId: String
    @Binding var timeBasedTheming: Bool
    @Binding var morningThemeId: String
    @Binding var sunsetThemeId: String
    @Binding var nightThemeId: String
    @Binding var showImagePicker: Bool
    let allThemes: [ColorTheme]

    var body: some View {
        Group {
            Section {
                Toggle(isOn: $contextTheming) {
                    Label(String.localized("Context-Aware Theming"), systemImage: "bolt.badge.automatic.fill")
                }

                if contextTheming {
                    Picker(String.localized("Low Power Theme"), selection: $lowPowerThemeId) {
                        Text(String.localized("None")).tag("")
                        ForEach(allThemes) { theme in
                            Text(theme.name).tag(theme.id.uuidString)
                        }
                    }

                    Picker(String.localized("Focus Theme"), selection: $focusThemeId) {
                        Text(String.localized("None")).tag("")
                        ForEach(allThemes) { theme in
                            Text(theme.name).tag(theme.id.uuidString)
                        }
                    }
                }
            } header: {
                Text(String.localized("System Integration"))
            } footer: {
                Text(String.localized("Automatically switch themes based on Low Power Mode or Focus filters."))
            }

            Section {
                Toggle(isOn: $timeBasedTheming) {
                    Label(String.localized("Schedule Themes"), systemImage: "clock.fill")
                }

                if timeBasedTheming {
                    Picker(String.localized("Morning Theme"), selection: $morningThemeId) {
                        ForEach(allThemes) { theme in
                            Text(theme.name).tag(theme.id.uuidString)
                        }
                    }
                    Picker(String.localized("Sunset Theme"), selection: $sunsetThemeId) {
                        ForEach(allThemes) { theme in
                            Text(theme.name).tag(theme.id.uuidString)
                        }
                    }
                    Picker(String.localized("Night Theme"), selection: $nightThemeId) {
                        ForEach(allThemes) { theme in
                            Text(theme.name).tag(theme.id.uuidString)
                        }
                    }
                }
            } header: {
                Text(String.localized("Time-Based Theming"))
            }

            Section {
                Button {
                    showImagePicker = true
                } label: {
                    Label(String.localized("Generate From Image"), systemImage: "photo.on.rectangle.angled")
                }
            } header: {
                Text(String.localized("Dynamic Wallpaper Integration"))
            } footer: {
                Text(String.localized("Auto-generate a theme palette from your favorite wallpaper or image."))
            }

            Section {
                NavigationLink {
                    PerScreenThemeView(allThemes: allThemes)
                } label: {
                    Label(String.localized("Per-Screen Overrides"), systemImage: "rectangle.3.group")
                }
            } header: {
                Text(String.localized("View Overrides"))
            }
        }
    }
}

struct AdvancedThemeFeaturesView: View {
    @Binding var highContrast: Bool
    @Binding var autoContrastCorrection: Bool
    @Binding var colorBlindnessFilter: Int
    @Binding var hapticIntensity: Double
    @Binding var visualFeedbackStrength: Double
    @Binding var layerBlendMode: Int
    @Binding var parallaxEnabled: Bool
    @Binding var motionGradients: Bool
    @Binding var performanceMode: Bool
    let advancedSliderRow: (_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, _ step: Double, _ unit: String, _ isPercent: Bool, _ icon: String) -> AnyView
    let onExportTheme: () -> Void
    let onImportTheme: () -> Void

    var body: some View {
        Group {
            Section {
                Toggle(String.localized("High Contrast Mode"), isOn: $highContrast)
                Toggle(String.localized("Auto Contrast Correction"), isOn: $autoContrastCorrection)

                Picker(String.localized("Color Blindness Filter"), selection: $colorBlindnessFilter) {
                    Text(String.localized("None")).tag(0)
                    Text(String.localized("Protanopia")).tag(1)
                    Text(String.localized("Deuteranopia")).tag(2)
                    Text(String.localized("Tritanopia")).tag(3)
                }
            } header: {
                Text(String.localized("Accessibility"))
            }

            Section {
                advancedSliderRow(String.localized("Haptic Intensity"), $hapticIntensity, 0...1, 0.1, "", true, "waveform")
                advancedSliderRow(String.localized("Visual Feedback"), $visualFeedbackStrength, 0...1, 0.1, "", true, "sparkles")
            } header: {
                Text(String.localized("Haptic & Visual Feedback"))
            }

            Section {
                Picker(String.localized("Layer Blending"), selection: $layerBlendMode) {
                    Text(String.localized("Normal")).tag(0)
                    Text(String.localized("Overlay")).tag(1)
                    Text(String.localized("Multiply")).tag(2)
                    Text(String.localized("Screen")).tag(3)
                }
                Toggle(String.localized("Parallax Depth Effect"), isOn: $parallaxEnabled)
                Toggle(String.localized("Motion Gradients"), isOn: $motionGradients)
                Toggle(String.localized("Performance Mode"), isOn: $performanceMode)
            } header: {
                Text(String.localized("Experimental Effects"))
            } footer: {
                Text(String.localized("Performance mode reduces heavy blurs and shadows to save battery and increase responsiveness."))
            }

            Section {
                Button(action: onExportTheme) {
                    Label(String.localized("Export Current Theme Code"), systemImage: "square.and.arrow.up")
                }

                Button(action: onImportTheme) {
                    Label(String.localized("Import Theme From Clipboard"), systemImage: "square.and.arrow.down")
                }
            } header: {
                Text(String.localized("Theme Sharing"))
            }
        }
    }
}
