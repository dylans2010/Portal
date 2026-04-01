import SwiftUI

struct DynamicIslandView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var showGlowColorPicker = false
    @State private var showBorderColorPicker = false
    @State private var showContentColorPicker = false

    var body: some View {
        List {
            Section {
                Toggle(isOn: $viewModel.diEnableGlow) {
                    Label("Enable Glow", systemImage: "sparkles")
                }
                .themedAccent()

                if viewModel.diEnableGlow {
                    Button {
                        showGlowColorPicker = true
                    } label: {
                        HStack {
                            Label("Glow Color", systemImage: "paintpalette")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.diGlowColorHex))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Glow Radius")
                            Spacer()
                            Text("\(Int(viewModel.diGlowRadius)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $viewModel.diGlowRadius, in: 5...50, step: 1)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Glow Intensity")
                            Spacer()
                            Text("\(Int(viewModel.diGlowIntensity * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $viewModel.diGlowIntensity, in: 0.1...1.0, step: 0.05)
                    }
                }
            } header: {
                Label("Glow Effect", systemImage: "sun.max.fill")
            } footer: {
                Text("Add a beautiful glow around your Dynamic Island.")
            }

            Section {
                Toggle(isOn: $viewModel.diEnableBorder) {
                    Label("Enable Border", systemImage: "square.inset.filled")
                }
                .themedAccent()

                if viewModel.diEnableBorder {
                    Button {
                        showBorderColorPicker = true
                    } label: {
                        HStack {
                            Label("Border Color", systemImage: "paintpalette")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.diBorderColorHex))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Border Width")
                            Spacer()
                            Text("\(String(format: "%.1f", viewModel.diBorderWidth)) pt")
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $viewModel.diBorderWidth, in: 0.5...5.0, step: 0.5)
                    }
                }
            } header: {
                Label("Border", systemImage: "rectangle.inset.filled")
            }

            Section {
                Toggle(isOn: $viewModel.diShowCustomContent) {
                    Label("Show Custom Content", systemImage: "text.quote")
                }
                .themedAccent()

                if viewModel.diShowCustomContent {
                    TextField("Enter Content (Text or Emoji)", text: $viewModel.diCustomContent)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        showContentColorPicker = true
                    } label: {
                        HStack {
                            Label("Content Color", systemImage: "paintpalette")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.diContentColorHex))
                                .frame(width: 28, height: 28)
                                .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                    }
                }
            } header: {
                Label("Custom Content", systemImage: "pencil.and.outline")
            } footer: {
                Text("Display custom text or emojis within the Dynamic Island area.")
            }
        }
        .globalTheme()
        .navigationTitle("Dynamic Island")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showGlowColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedDIGlowColor, colorHex: $viewModel.diGlowColorHex)
        }
        .sheet(isPresented: $showBorderColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedDIBorderColor, colorHex: $viewModel.diBorderColorHex)
        }
        .sheet(isPresented: $showContentColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedDIContentColor, colorHex: $viewModel.diContentColorHex)
        }
    }
}
