import SwiftUI
import PhotosUI

struct KeyboardCustomizationView: View {
    @StateObject private var manager = KeyboardCustomizeManager.shared

    @State private var startColor: Color = .blue
    @State private var endColor: Color = .cyan
    @State private var bgColor: Color = .black
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        List {
            Section {
                Toggle(isOn: $manager.isEnabled) {
                    AppearanceRowLabel(icon: "keyboard", title: "Enable Backdrop", color: .purple)
                }
            } header: {
                AppearanceSectionHeader(title: "Status", icon: "power")
            } footer: {
                Text("When enabled, a custom dynamic background will appear behind the system keyboard. This works best with the system keyboard's natural translucency.")
            }

            if manager.isEnabled {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        AppearanceRowLabel(icon: "photo.fill", title: "Custom Image", color: .green)
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                manager.backgroundImageData = data
                            }
                        }
                    }

                    if manager.backgroundImageData != nil {
                        Button(role: .destructive) {
                            manager.backgroundImageData = nil
                            selectedItem = nil
                        } label: {
                            AppearanceRowLabel(icon: "trash", title: "Remove Image", color: .red)
                        }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Media", icon: "photo")
                }

                if #available(iOS 26.0, *) {
                    Section {
                        Toggle(isOn: $manager.dynamicGradientEnabled) {
                            AppearanceRowLabel(icon: "wind", title: "Dynamic Gradient", color: .indigo)
                        }

                        if manager.dynamicGradientEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                AppearanceRowLabel(icon: "list.bullet.rectangle.fill", title: "Preset: \(manager.dynamicGradientPreset)", color: .indigo)
                                Picker("Preset", selection: $manager.dynamicGradientPreset) {
                                    Text("Default").tag(0)
                                    Text("Vibrant").tag(1)
                                    Text("Sunset").tag(2)
                                    Text("Ocean").tag(3)
                                    Text("Autumn").tag(4)
                                    Text("Monochrome").tag(5)
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                AppearanceRowLabel(icon: "wave.3.right", title: "Amount: \(Int(manager.dynamicGradientAmount * 100))%", color: .blue)
                                Slider(value: $manager.dynamicGradientAmount, in: 0...1)
                            }
                            .padding(.vertical, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                AppearanceRowLabel(icon: "timer", title: "Frequency: \(String(format: "%.1f", manager.dynamicGradientFrequency))", color: .cyan)
                                Slider(value: $manager.dynamicGradientFrequency, in: 0.1...5)
                            }
                            .padding(.vertical, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                AppearanceRowLabel(icon: "number", title: "Color Count: \(manager.dynamicGradientColorCount)", color: .purple)
                                Slider(value: Binding(get: { Double(manager.dynamicGradientColorCount) }, set: { manager.dynamicGradientColorCount = Int($0) }), in: 1...9, step: 1)
                            }
                            .padding(.vertical, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                AppearanceRowLabel(icon: "safari", title: "Direction: \(Int(manager.dynamicGradientDirection))°", color: .green)
                                Slider(value: $manager.dynamicGradientDirection, in: 0...360)
                            }
                            .padding(.vertical, 4)

                            VStack(alignment: .leading, spacing: 8) {
                                AppearanceRowLabel(icon: "heart.fill", title: "Pulse Intensity: \(Int(manager.dynamicGradientPulseIntensity * 100))%", color: .red)
                                Slider(value: $manager.dynamicGradientPulseIntensity, in: 0...1)
                            }
                            .padding(.vertical, 4)

                            Toggle(isOn: $manager.dynamicGradientShuffle) {
                                AppearanceRowLabel(icon: "shuffle", title: "Shuffle Colors", color: .orange)
                            }
                        }
                    } header: {
                        AppearanceSectionHeader(title: "Dynamic Gradient", icon: "wind")
                    }
                }

                Section {
                    Toggle(isOn: $manager.showAnimatedOrbs) {
                        AppearanceRowLabel(icon: "sparkles", title: "Animated Orbs", color: .blue)
                    }

                    if manager.showAnimatedOrbs {
                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "circle.dotted", title: "Orb Count: \(manager.orbCount)", color: .blue)
                            Slider(value: Binding(get: { Double(manager.orbCount) }, set: { manager.orbCount = Int($0) }), in: 1...10, step: 1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "bolt.fill", title: "Orb Speed: \(Int(manager.orbSpeed))", color: .yellow)
                            Slider(value: $manager.orbSpeed, in: 1...10)
                        }
                        .padding(.vertical, 4)
                    }

                    Toggle(isOn: $manager.useGradient) {
                        AppearanceRowLabel(icon: "paintpalette", title: "Custom Gradient", color: .orange)
                    }

                    if manager.useGradient {
                        ColorPicker(selection: $startColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "1.circle", title: "Start Color", color: .orange)
                        }
                        .onChange(of: startColor) { manager.gradientStart = $0.toHex() ?? "#0077BE" }

                        ColorPicker(selection: $endColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "2.circle", title: "End Color", color: .orange)
                        }
                        .onChange(of: endColor) { manager.gradientEnd = $0.toHex() ?? "#00AEEF" }
                    } else {
                        ColorPicker(selection: $bgColor, supportsOpacity: false) {
                            AppearanceRowLabel(icon: "paintbrush.fill", title: "Background Color", color: .orange)
                        }
                        .onChange(of: bgColor) { manager.backgroundColor = $0.toHex() ?? "#1A1A1A" }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Background Type", icon: "square.fill")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "drop", title: "Opacity: \(Int(manager.opacity * 100))%", color: .blue)
                        Slider(value: $manager.opacity, in: 0...1)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "fossil.shell", title: "Blur: \(Int(manager.blurRadius))", color: .cyan)
                        Slider(value: $manager.blurRadius, in: 0...30)
                    }
                    .padding(.vertical, 4)
                } header: {
                    AppearanceSectionHeader(title: "Effects", icon: "wand.and.stars")
                }

                Section {
                    KeyboardBackdropView()
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            Text("Preview")
                                .font(.caption.bold())
                                .padding(4)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(8),
                            alignment: .topLeading
                        )
                } header: {
                    AppearanceSectionHeader(title: "Preview", icon: "eye")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Keyboard Backdrop")
        .onAppear {
            startColor = Color(hex: manager.gradientStart)
            endColor = Color(hex: manager.gradientEnd)
            bgColor = Color(hex: manager.backgroundColor)
        }
    }
}
