import SwiftUI

struct KeyboardDynamicGradientView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var manager = KeyboardCustomizeManager.shared

    var body: some View {
        NavigationView {
            ZStack {
                // Background Preview
                KeyboardBackdropView(manager: manager)
                    .ignoresSafeArea()
                    .opacity(0.4)

                ScrollView {
                    VStack(spacing: 24) {
                        // Live Preview Card
                        VStack {
                            KeyboardBackdropView(manager: manager)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                                .shadow(color: .black.opacity(0.3), radius: 20)
                                .padding()

                            Text("Live Preview")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 20) {
                            // Primary Controls
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Movement & Animation")
                                    .font(.headline)

                                controlRow(title: "Frequency", value: $manager.dynamicGradientFrequency, range: 0.1...5.0, icon: "timer", subtitle: "Adjust how often the color points shift their positions.")
                                controlRow(title: "Amount", value: $manager.dynamicGradientAmount, range: 0.1...10.0, icon: "slider.horizontal.3", subtitle: "Control the distance each point can travel from its origin.")
                                controlRow(title: "Speed", value: $manager.dynamicGradientSpeed, range: 0.1...5.0, icon: "bolt.fill", subtitle: "The overall playback speed of the animation.")
                                controlRow(title: "Pulse", value: $manager.dynamicGradientPulseIntensity, range: 0.0...2.0, icon: "waveform.path.ecg", subtitle: "Intensity of the breathing scale effect.")
                            }
                            .padding()
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Appearance & Vibrancy
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Appearance & Vibrancy")
                                    .font(.headline)

                                controlRow(title: "Saturation", value: $manager.dynamicGradientSaturation, range: 0.0...2.0, icon: "drop.fill", subtitle: "Adjust the intensity of the colors.")
                                controlRow(title: "Contrast", value: $manager.dynamicGradientContrast, range: 0.5...1.5, icon: "circle.lefthalf.filled", subtitle: "Difference between light and dark areas.")
                                controlRow(title: "Brightness", value: $manager.dynamicGradientBrightness, range: -0.5...0.5, icon: "sun.max.fill", subtitle: "The overall light intensity of the gradient.")
                                controlRow(title: "Noise", value: $manager.dynamicGradientNoiseOpacity, range: 0.0...1.0, icon: "square.dotted", subtitle: "Add a grainy texture overlay for a vintage look.")
                            }
                            .padding()
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Mesh Controls
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Mesh Structure")
                                    .font(.headline)

                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Mesh Complexity", systemImage: "grid")
                                    Text("Control the number of control points in the mesh (\(manager.dynamicGradientMeshComplexity)x\(manager.dynamicGradientMeshComplexity)).")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Slider(value: Binding(get: { Double(manager.dynamicGradientMeshComplexity) }, set: { manager.dynamicGradientMeshComplexity = Int($0) }), in: 2...6, step: 1)
                                }
                            }
                            .padding()
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Direction Control
                            VStack(spacing: 15) {
                                Text("Gradient Direction")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Set the base rotation angle for the entire animation.")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                KeyboardDirectionPicker(direction: $manager.dynamicGradientDirection, color: .purple)
                            }
                            .padding()
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                            // Color Selection
                            VStack(alignment: .leading, spacing: 15) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Colors (\(manager.dynamicGradientColorCount))")
                                            .font(.headline)
                                        Spacer()
                                        Stepper("", value: Binding(get: { manager.dynamicGradientColorCount }, set: { manager.dynamicGradientColorCount = $0 }), in: 2...10)
                                    }
                                    Text("The specific palette used to generate the mesh.")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                                    ForEach(0..<manager.dynamicGradientColorCount, id: \.self) { index in
                                        colorPickerCircle(index: index)
                                    }
                                }

                                Toggle(isOn: $manager.dynamicGradientShuffle) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Shuffle Colors")
                                        Text("Enable to periodically rotate the color positions.")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.top, 8)
                            }
                            .padding()
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Dynamic Gradient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private func controlRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, icon: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.caption.monospacedDigit())
            }
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Slider(value: value, in: range)
        }
    }

    @ViewBuilder
    private func colorPickerCircle(index: Int) -> some View {
        let hex = index < manager.dynamicGradientColors.count ? manager.dynamicGradientColors[index] : "#FFFFFF"
        VStack {
            ColorPicker("", selection: Binding(
                get: { Color(hex: hex) },
                set: { newColor in
                    if index < manager.dynamicGradientColors.count {
                        manager.dynamicGradientColors[index] = newColor.toHex() ?? "#FFFFFF"
                    }
                }
            ))
            .labelsHidden()
            .frame(width: 44, height: 44)
            .background(Color(hex: hex))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))

            Text("\(index + 1)")
                .font(.caption2)
        }
    }
}
