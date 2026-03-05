import SwiftUI
import PhotosUI

struct KeyboardCustomizationView: View {
    @StateObject private var manager = KeyboardCustomizeManager.shared
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true

    @State private var startColor: Color = .blue
    @State private var endColor: Color = .cyan
    @State private var bgColor: Color = .black
    @State private var selectedItem: PhotosPickerItem?

    @FocusState private var isKeyboardFocused: Bool
    @State private var dummyText: String = ""
    @State private var showingAdvancedGradient = false

    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    KeyboardHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Toggle(isOn: $manager.isEnabled) {
                    AppearanceRowLabel(icon: "keyboard", title: "Enable Backdrop", color: .purple)
                }
            } header: {
                AppearanceSectionHeader(title: "Status", icon: "power")
            } footer: {
                Text("When enabled, a custom dynamic background will appear behind the keyboard. This works best to the transparent keyboard on iOS 26.")
            }

            if manager.isEnabled {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(alignment: .leading, spacing: 4) {
                            AppearanceRowLabel(icon: "photo.fill", title: "Custom Image", color: .green)
                            Text("Set a image as the backdrop for your keyboard.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
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
                            VStack(alignment: .leading, spacing: 4) {
                                AppearanceRowLabel(icon: "trash", title: "Remove Image", color: .red)
                                Text("Clear the current image and return to using colors or gradients.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Media", icon: "photo")
                }

                Section {
                    Toggle(isOn: $manager.showAnimatedOrbs) {
                        VStack(alignment: .leading, spacing: 4) {
                            AppearanceRowLabel(icon: "sparkles", title: "Animated Orbs", color: .blue)
                            Text("Floating glowing circles that move dynamically behind the keys.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if manager.showAnimatedOrbs {
                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "circle.dotted", title: "Orb Count: \(manager.orbCount)", color: .blue)
                            Text("Adjust the total number of orbs appearing on screen.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(value: Binding(get: { Double(manager.orbCount) }, set: { manager.orbCount = Int($0) }), in: 1...10, step: 1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "bolt.fill", title: "Orb Speed: \(Int(manager.orbSpeed))", color: .yellow)
                            Text("Change how quickly the orbs float and bounce around.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(value: $manager.orbSpeed, in: 1...10)
                        }
                        .padding(.vertical, 4)
                    }

                    Toggle(isOn: $manager.useGradient) {
                        VStack(alignment: .leading, spacing: 4) {
                            AppearanceRowLabel(icon: "paintpalette", title: "Custom Gradient", color: .orange)
                            Text("Switch between a solid color and a two color linear gradient.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if manager.useGradient {
                        ColorPicker(selection: $startColor, supportsOpacity: false) {
                            VStack(alignment: .leading, spacing: 4) {
                                AppearanceRowLabel(icon: "1.circle", title: "Start Color", color: .orange)
                                Text("The beginning color for the linear gradient transition.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: startColor) { manager.gradientStart = $0.toHex() ?? "#0077BE" }

                        ColorPicker(selection: $endColor, supportsOpacity: false) {
                            VStack(alignment: .leading, spacing: 4) {
                                AppearanceRowLabel(icon: "2.circle", title: "End Color", color: .orange)
                                Text("The final color for the linear gradient transition.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: endColor) { manager.gradientEnd = $0.toHex() ?? "#00AEEF" }
                    } else {
                        ColorPicker(selection: $bgColor, supportsOpacity: false) {
                            VStack(alignment: .leading, spacing: 4) {
                                AppearanceRowLabel(icon: "paintbrush.fill", title: "Background Color", color: .orange)
                                Text("The base solid color for your keyboard background.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .onChange(of: bgColor) { manager.backgroundColor = $0.toHex() ?? "#1A1A1A" }
                    }
                } header: {
                    AppearanceSectionHeader(title: "Background Type", icon: "square.fill")
                }

                Section {
                    Toggle(isOn: $manager.isDynamicGradientEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            AppearanceRowLabel(icon: "sparkles.rectangle.stack", title: "Dynamic Gradient", color: .purple)
                            Text("A high performance mesh gradient that moves and shifts over time.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if manager.isDynamicGradientEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "timer", title: "Frequency: \(String(format: "%.1f", manager.dynamicGradientFrequency))", color: .blue)
                            Text("Adjust the speed of the color shifting and warping animation.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(value: $manager.dynamicGradientFrequency, in: 0.1...5.0, step: 0.1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "slider.horizontal.3", title: "Amount: \(String(format: "%.1f", manager.dynamicGradientAmount))", color: .green)
                            Text("Control how much the colors distort and spread across the screen.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(value: $manager.dynamicGradientAmount, in: 0.1...10.0, step: 0.1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "number", title: "Color Count: \(manager.dynamicGradientColorCount)", color: .orange)
                            Text("Select how many unique colors are used in the mesh generation.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(value: Binding(get: { Double(manager.dynamicGradientColorCount) }, set: { manager.dynamicGradientColorCount = Int($0) }), in: 2...10, step: 1)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                                ForEach(0..<manager.dynamicGradientColorCount, id: \.self) { index in
                                    ColorPicker("", selection: Binding(
                                        get: { Color(hex: manager.dynamicGradientColors[index]) },
                                        set: { manager.dynamicGradientColors[index] = $0.toHex() ?? "#FFFFFF" }
                                    ))
                                    .labelsHidden()
                                    .frame(width: 40, height: 40)
                                    .background(Color(hex: manager.dynamicGradientColors[index]))
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "waveform.path.ecg", title: "Pulse Intensity: \(String(format: "%.1f", manager.dynamicGradientPulseIntensity))", color: .red)
                            Text("Add a subtle 'breathing' scale effect to the background.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Slider(value: $manager.dynamicGradientPulseIntensity, in: 0.0...2.0, step: 0.1)
                        }
                        .padding(.vertical, 4)

                        VStack(alignment: .leading, spacing: 8) {
                            AppearanceRowLabel(icon: "arrow.up.right.circle", title: "Direction", color: .cyan)
                            Text("Set the primary flow angle for the gradient's movement.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            HStack {
                                Spacer()
                                KeyboardDirectionPicker(direction: $manager.dynamicGradientDirection, color: .cyan)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)

                        Button {
                            showingAdvancedGradient = true
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                AppearanceRowLabel(icon: "slider.horizontal.2.square", title: "Modify Advanced Controls", color: .purple)
                                Text("Access granular settings like speed, noise, and color vibrancy.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Toggle(isOn: $manager.dynamicGradientShuffle) {
                            VStack(alignment: .leading, spacing: 4) {
                                AppearanceRowLabel(icon: "shuffle", title: "Shuffle Colors", color: .indigo)
                                Text("Randomize the color order over time for a more organic feel.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Picker(selection: $manager.dynamicGradientPreset) {
                            Text("Custom").tag(0)
                            Text("Aurora").tag(1)
                            Text("Sunset").tag(2)
                            Text("Ocean").tag(3)
                            Text("Nebula").tag(4)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                AppearanceRowLabel(icon: "wand.and.stars", title: "Preset", color: .pink)
                                Text("Select from pre designed high quality color combinations.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    AppearanceSectionHeader(title: "Dynamic Gradient", icon: "sparkles")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "rectangle.3.group", title: "Layout Density", color: .indigo)
                        Text("Adjust how tightly the keys are packed together.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Slider(value: $manager.layoutDensity, in: 0...1)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "square.dashed", title: "Key Corner Radius: \(Int(manager.keyCornerRadius))", color: .orange)
                        Text("Change the roundness of individual keyboard keys.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Slider(value: $manager.keyCornerRadius, in: 0...20)
                    }
                    .padding(.vertical, 4)

                    Picker(selection: $manager.fontWeight) {
                        Text("Regular").tag("Regular")
                        Text("Medium").tag("Medium")
                        Text("Semibold").tag("Semibold")
                        Text("Bold").tag("Bold")
                    } label: {
                        AppearanceRowLabel(icon: "textformat", title: "Font Weight", color: .blue)
                    }
                } header: {
                    AppearanceSectionHeader(title: "Keyboard Layout", icon: "keyboard")
                }

                Section {
                    ColorPicker(selection: Binding(
                        get: { Color(hex: manager.accentColor) },
                        set: { manager.accentColor = $0.toHex() ?? "#007AFF" }
                    )) {
                        AppearanceRowLabel(icon: "paintpalette.fill", title: "Accent Color", color: .pink)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "speedometer", title: "Animation Intensity: \(String(format: "%.1f", manager.animationIntensity))", color: .red)
                        Text("Control the strength of background motion and shifts.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Slider(value: $manager.animationIntensity, in: 0...2, step: 0.1)
                    }
                    .padding(.vertical, 4)

                    Toggle(isOn: $manager.hapticEnabled) {
                        AppearanceRowLabel(icon: "waveform.path.ecg", title: "Haptic Feedback", color: .green)
                    }
                } header: {
                    AppearanceSectionHeader(title: "Advanced Settings", icon: "slider.horizontal.3")
                }
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "drop", title: "Opacity: \(Int(manager.opacity * 100))%", color: .blue)
                        Text("Set the overall transparency of the keyboard backdrop layer.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Slider(value: $manager.opacity, in: 0...1)
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 8) {
                        AppearanceRowLabel(icon: "fossil.shell", title: "Blur: \(Int(manager.blurRadius))", color: .cyan)
                        Text("Apply a Gaussian blur to the background for better key readability.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Slider(value: $manager.blurRadius, in: 0...30)
                    }
                    .padding(.vertical, 4)
                } header: {
                    AppearanceSectionHeader(title: "Effects", icon: "wand.and.stars")
                }

                Section {
                    Button {
                        isKeyboardFocused = true
                    } label: {
                        AppearanceRowLabel(icon: "keyboard", title: "Open Keyboard", color: .blue)
                    }

                    TextField("Tap here to see the Keyboard Backdrop.", text: $dummyText)
                        .focused($isKeyboardFocused)
                } header: {
                    AppearanceSectionHeader(title: "Test Backdrop", icon: "pencil")
                } footer: {
                    Text("Tap to open the keyboard and see your custom backdrop in action.")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
        .navigationTitle("Keyboard Backdrop")
        .fullScreenCover(isPresented: $showingAdvancedGradient) {
            KeyboardDynamicGradientView()
        }
        .onAppear {
            startColor = Color(hex: manager.gradientStart)
            endColor = Color(hex: manager.gradientEnd)
            bgColor = Color(hex: manager.backgroundColor)
        }
    }
}
