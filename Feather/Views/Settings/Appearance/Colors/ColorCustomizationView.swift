import SwiftUI
import NimbleViews

struct ColorTheme: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let bg: String
    let ui: String
    let text: String
    let tint: String
    var secondaryText: String?
    var cardRadius: Double?
    var fontDesign: String?
}

struct ColorCustomizationView: View {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage(UserDefaults.Keys.secondaryText) private var secondaryTextColorHex: String = "#8E8E93"
    @AppStorage(UserDefaults.Keys.cardCornerRadius) private var cardCornerRadius: Double = 16.0
    @AppStorage(UserDefaults.Keys.buttonCornerRadius) private var buttonCornerRadius: Double = 12.0
    @AppStorage(UserDefaults.Keys.fontDesign) private var fontDesign: String = "default"
    @AppStorage(UserDefaults.Keys.shadowIntensity) private var shadowIntensity: Double = 5.0
    @AppStorage(UserDefaults.Keys.blurOpacity) private var blurOpacity: Double = 1.0
    @AppStorage("Feather.userTintColor") private var tintColorHex: String = "#0077BE"
    @AppStorage("Feather.userThemes") private var userThemesData: Data = Data()

    @State private var bgColor: Color = .white
    @State private var uiElementColor: Color = .blue
    @State private var textColor: Color = .black
    @State private var secondaryTextColor: Color = .gray
    @State private var tintColor: Color = .blue

    @State private var showAllThemes = false
    @State private var themeName: String = ""
    @State private var showSaveAlert = false
    @State private var showResetAlert = false
    @ObservedObject private var appState = AppStateManager.shared
    @Environment(\.colorScheme) var colorScheme

    private let presetThemes: [ColorTheme] = [
        ColorTheme(name: "Classic", bg: "#F2F2F7", ui: "#007AFF", text: "#000000", tint: "#007AFF", secondaryText: "#8E8E93", cardRadius: 16, fontDesign: "default"),
        ColorTheme(name: "Midnight", bg: "#1C1C1E", ui: "#0A84FF", text: "#FFFFFF", tint: "#0A84FF", secondaryText: "#8E8E93", cardRadius: 16, fontDesign: "rounded"),
        ColorTheme(name: "OLED Black", bg: "#000000", ui: "#30D158", text: "#FFFFFF", tint: "#30D158", secondaryText: "#A1A1A1", cardRadius: 12, fontDesign: "monospaced"),
        ColorTheme(name: "Nordic", bg: "#2E3440", ui: "#88C0D0", text: "#ECEFF4", tint: "#88C0D0", secondaryText: "#D8DEE9", cardRadius: 8, fontDesign: "default"),
        ColorTheme(name: "Forest", bg: "#1B2E1D", ui: "#74C69D", text: "#D8F3DC", tint: "#74C69D", secondaryText: "#95D5B2", cardRadius: 20, fontDesign: "serif"),
        ColorTheme(name: "Crimson", bg: "#1A0A0A", ui: "#FF453A", text: "#FFD6D6", tint: "#FF453A", secondaryText: "#FFBABA", cardRadius: 14, fontDesign: "default"),
        ColorTheme(name: "Vibrant", bg: "#0F172A", ui: "#F43F5E", text: "#F8FAFC", tint: "#F43F5E", secondaryText: "#E2E8F0", cardRadius: 18, fontDesign: "rounded"),
        ColorTheme(name: "Sepia", bg: "#F4ECD8", ui: "#8B4513", text: "#433422", tint: "#8B4513", secondaryText: "#5D4037", cardRadius: 4, fontDesign: "serif"),
        ColorTheme(name: "Lavender", bg: "#F3E5F5", ui: "#9C27B0", text: "#4A148C", tint: "#9C27B0", secondaryText: "#7B1FA2", cardRadius: 24, fontDesign: "rounded"),
        ColorTheme(name: "Ocean", bg: "#E0F7FA", ui: "#00BCD4", text: "#006064", tint: "#00BCD4", secondaryText: "#00838F", cardRadius: 16, fontDesign: "default"),
        ColorTheme(name: "Rose Gold", bg: "#FFF1F0", ui: "#FF85C0", text: "#5C0011", tint: "#FF85C0", secondaryText: "#9E1068", cardRadius: 30, fontDesign: "serif"),
        ColorTheme(name: "Slate", bg: "#263238", ui: "#90A4AE", text: "#ECEFF1", tint: "#90A4AE", secondaryText: "#B0BEC5", cardRadius: 0, fontDesign: "monospaced"),
        ColorTheme(name: "Mint", bg: "#E8F5E9", ui: "#4CAF50", text: "#1B5E20", tint: "#4CAF50", secondaryText: "#2E7D32", cardRadius: 16, fontDesign: "rounded")
    ]

    private var userThemes: [ColorTheme] {
        get {
            guard let themes = try? JSONDecoder().decode([ColorTheme].self, from: userThemesData) else { return [] }
            return themes
        }
        nonmutating set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                userThemesData = encoded
            }
        }
    }

    private var allThemes: [ColorTheme] {
        presetThemes + userThemes
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // MARK: - Live Preview Header
                previewHeader
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 20) {
                    // MARK: - Theme Gallery
                    themeGallerySection

                    // MARK: - Custom Colors
                    customColorsSection

                    // MARK: - Advanced Styling
                    advancedStylingSection

                    // MARK: - Actions
                    actionsSection
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadColors()
        }
        .sheet(isPresented: $showAllThemes) {
            ThemeLibraryView(themes: allThemes) { theme in
                applyTheme(theme)
                showAllThemes = false
            }
            .presentationDetents([.medium, .large])
        }
        .alert("Save Theme", isPresented: $showSaveAlert) {
            TextField("Theme Name", text: $themeName)
            Button("Save") {
                saveStyle()
                themeName = ""
            }
            Button("Cancel", role: .cancel) {
                themeName = ""
            }
        } message: {
            Text("Enter a name for your custom theme.")
        }
        .alert("Reset Appearance", isPresented: $showResetAlert) {
            Button("Reset Everything", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will restore all colors to their original system defaults. Your saved custom themes will not be deleted.")
        }
        .onChange(of: bgColor) { newValue in bgColorHex = newValue.toHex() ?? Color.defaultBackground }
        .onChange(of: uiElementColor) { newValue in uiElementColorHex = newValue.toHex() ?? Color.defaultUIElement }
        .onChange(of: textColor) { newValue in textColorHex = newValue.toHex() ?? Color.defaultText }
        .onChange(of: secondaryTextColor) { newValue in secondaryTextColorHex = newValue.toHex() ?? "#8E8E93" }
        .onChange(of: tintColor) { newValue in tintColorHex = newValue.toHex() ?? "#0077BE" }
    }

    // MARK: - Component Views

    private var previewHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Preview")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(bgColor)
                    .shadow(color: .black.opacity(shadowIntensity / 100.0), radius: shadowIntensity, x: 0, y: shadowIntensity / 2.0)

                VStack(spacing: 0) {
                    // Fake Nav Bar
                    HStack {
                        Circle().fill(uiElementColor.opacity(0.2)).frame(width: 32, height: 32)
                        Spacer()
                        Text("Preview").font(.headline).foregroundStyle(textColor)
                        Spacer()
                        Image(systemName: "magnifyingglass").foregroundStyle(uiElementColor)
                    }
                    .padding()

                    Divider().background(textColor.opacity(0.1))

                    ScrollView {
                        VStack(spacing: 16) {
                            // Fake List Item
                            HStack(spacing: 16) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(uiElementColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(Image(systemName: "app.fill").foregroundStyle(uiElementColor))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Application Name").font(.headline).foregroundStyle(textColor).applyFontDesign(selectedDesign)
                                    Text("Version 1.0.0 • 42 MB").font(.caption).foregroundStyle(secondaryTextColor).applyFontDesign(selectedDesign)
                                }
                                Spacer()
                                Button("Open") {}
                                    .font(.system(size: 12, weight: .bold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(uiElementColor)
                                    .foregroundStyle(.white)
                                    .cornerRadius(buttonCornerRadius)
                            }
                            .padding()
                            .background(textColor.opacity(0.05))
                            .cornerRadius(cardCornerRadius)

                            // Fake Tab Bar
                            HStack(spacing: 40) {
                                Image(systemName: "house.fill").foregroundStyle(uiElementColor)
                                Image(systemName: "square.stack.3d.up.fill").foregroundStyle(textColor.opacity(0.3))
                                Image(systemName: "person.fill").foregroundStyle(textColor.opacity(0.3))
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                    .disabled(true)
                }
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    private var themeGallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Theme Gallery")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("View All") {
                    showAllThemes = true
                }
                .font(.caption)
                .fontWeight(.bold)
            }
            .padding(.horizontal, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(allThemes.prefix(8)) { theme in
                        ModernThemeCard(theme: theme) {
                            if !appState.isSigning {
                                applyTheme(theme)
                            }
                        }
                        .disabled(appState.isSigning)
                        .opacity(appState.isSigning ? 0.6 : 1.0)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
    }

    private var customColorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Colors")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            VStack(spacing: 0) {
                colorPickerRow(title: "Background", color: $bgColor, icon: "square.fill")
                Divider().padding(.leading, 44)
                colorPickerRow(title: "UI Elements", color: $uiElementColor, icon: "app.fill")
                Divider().padding(.leading, 44)
                colorPickerRow(title: "Primary Text", color: $textColor, icon: "textformat")
                Divider().padding(.leading, 44)
                colorPickerRow(title: "Secondary Text", color: $secondaryTextColor, icon: "textformat.size")
                Divider().padding(.leading, 44)
                colorPickerRow(title: "Accent", color: $tintColor, icon: "sparkles")
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    private func colorPickerRow(title: String, color: Binding<Color>, icon: String) -> some View {
        ColorPicker(selection: color, supportsOpacity: false) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.wrappedValue.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color.wrappedValue)
                }
                Text(title)
                    .font(.body)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showSaveAlert = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Save Current Style")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .font(.headline)
                .cornerRadius(16)
            }
            .disabled(appState.isSigning)

            Button {
                showResetAlert = true
            } label: {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset To Defaults")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundStyle(.red)
                .font(.headline)
                .cornerRadius(16)
            }
            .disabled(appState.isSigning)
        }
    }

    private var advancedStylingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced Styling")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Fonts", systemImage: "text.cursor")
                        Spacer()
                        Picker("Design", selection: $fontDesign) {
                            Text("Default").tag("default")
                            Text("Rounded").tag("rounded")
                            Text("Serif").tag("serif")
                            Text("Monospaced").tag("monospaced")
                        }
                        .pickerStyle(.menu)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Card Corners", systemImage: "square.dashed")
                        Spacer()
                        Text("\(Int(cardCornerRadius))pt").font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(value: $cardCornerRadius, in: 0...40, step: 2)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Button Corners", systemImage: "rectangle.roundedbottom")
                        Spacer()
                        Text("\(Int(buttonCornerRadius))pt").font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(value: $buttonCornerRadius, in: 0...20, step: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Shadow Intensity", systemImage: "shadow")
                        Spacer()
                        Text("\(Int(shadowIntensity))").font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(value: $shadowIntensity, in: 0...20, step: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Blur Opacity", systemImage: "drop.halffull")
                        Spacer()
                        Text("\(Int(blurOpacity * 100))%").font(.caption).foregroundStyle(.secondary)
                    }
                    Slider(value: $blurOpacity, in: 0...1, step: 0.05)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
    }

    private var selectedDesign: Font.Design {
        switch fontDesign {
        case "rounded": return .rounded
        case "serif": return .serif
        case "monospaced": return .monospaced
        default: return .default
        }
    }

    // MARK: - Helper Methods

    private func loadColors() {
        bgColor = Color(hex: bgColorHex)
        uiElementColor = Color(hex: uiElementColorHex)

        // Handle dark mode default text color specifically in UI
        if colorScheme == .dark && (textColorHex == Color.defaultText || textColorHex == "#000000") {
            textColor = .white
        } else {
            textColor = Color(hex: textColorHex)
        }

        secondaryTextColor = Color(hex: secondaryTextColorHex)
        tintColor = Color(hex: tintColorHex)
    }

    private func applyTheme(_ theme: ColorTheme) {
        bgColorHex = theme.bg
        uiElementColorHex = theme.ui
        textColorHex = theme.text
        tintColorHex = theme.tint

        if let st = theme.secondaryText { secondaryTextColorHex = st }
        if let cr = theme.cardRadius { cardCornerRadius = cr }
        if let fd = theme.fontDesign { fontDesign = fd }

        loadColors()
        HapticsManager.shared.success()
    }

    private func saveStyle() {
        let newTheme = ColorTheme(
            name: themeName.isEmpty ? "My Theme \(userThemes.count + 1)" : themeName,
            bg: bgColor.toHex() ?? Color.defaultBackground,
            ui: uiElementColor.toHex() ?? Color.defaultUIElement,
            text: textColor.toHex() ?? Color.defaultText,
            tint: tintColor.toHex() ?? "#0077BE",
            secondaryText: secondaryTextColor.toHex() ?? "#8E8E93",
            cardRadius: cardCornerRadius,
            fontDesign: fontDesign
        )
        var updatedThemes = userThemes
        updatedThemes.append(newTheme)
        userThemes = updatedThemes
        HapticsManager.shared.success()
    }

    private func resetToDefaults() {
        bgColorHex = Color.defaultBackground
        uiElementColorHex = Color.defaultUIElement
        textColorHex = Color.defaultText
        secondaryTextColorHex = "#8E8E93"
        cardCornerRadius = 16.0
        buttonCornerRadius = 12.0
        fontDesign = "default"
        shadowIntensity = 5.0
        blurOpacity = 1.0
        tintColorHex = "#0077BE"
        loadColors()
        HapticsManager.shared.success()
    }
}

// MARK: - Modern Theme Card

struct ModernThemeCard: View {
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: theme.bg))
                        .frame(width: 130, height: 90)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: theme.ui))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color(hex: theme.tint))
                                .frame(width: 16, height: 16)
                        }

                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: theme.text))
                            .frame(width: 50, height: 6)
                    }
                }

                Text(theme.name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .padding(.leading, 4)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Theme Library View

struct ThemeLibraryView: View {
    @Environment(\.dismiss) var dismiss
    let themes: [ColorTheme]
    let onSelect: (ColorTheme) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(themes) { theme in
                        ModernThemeCard(theme: theme) {
                            onSelect(theme)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("All Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}
