import SwiftUI
import NimbleViews

struct ColorTheme: Identifiable, Codable, Equatable {
    var id = UUID()
    let name: String
    let bg: String
    let ui: String
    let text: String
    let tint: String
}

struct ColorCustomizationView: View {
    @AppStorage(UserDefaults.Keys.background) private var bgColorHex: String = Color.defaultBackground
    @AppStorage(UserDefaults.Keys.uiElement) private var uiElementColorHex: String = Color.defaultUIElement
    @AppStorage(UserDefaults.Keys.text) private var textColorHex: String = Color.defaultText
    @AppStorage("Feather.userTintColor") private var tintColorHex: String = "#0077BE"
    @AppStorage("Feather.userThemes") private var userThemesData: Data = Data()

    @State private var bgColor: Color = .white
    @State private var uiElementColor: Color = .blue
    @State private var textColor: Color = .black
    @State private var tintColor: Color = .blue

    @State private var showAllThemes = false
    @State private var themeName: String = ""
    @State private var showSaveAlert = false
    @ObservedObject private var appState = AppStateManager.shared

    private let presetThemes: [ColorTheme] = [
        ColorTheme(name: "Classic", bg: "#F2F2F7", ui: "#007AFF", text: "#000000", tint: "#007AFF"),
        ColorTheme(name: "Midnight", bg: "#1C1C1E", ui: "#0A84FF", text: "#FFFFFF", tint: "#0A84FF"),
        ColorTheme(name: "OLED Black", bg: "#000000", ui: "#30D158", text: "#FFFFFF", tint: "#30D158"),
        ColorTheme(name: "Nordic", bg: "#2E3440", ui: "#88C0D0", text: "#ECEFF4", tint: "#88C0D0"),
        ColorTheme(name: "Forest", bg: "#1B2E1D", ui: "#74C69D", text: "#D8F3DC", tint: "#74C69D"),
        ColorTheme(name: "Crimson", bg: "#1A0A0A", ui: "#FF453A", text: "#FFD6D6", tint: "#FF453A"),
        ColorTheme(name: "Vibrant", bg: "#0F172A", ui: "#F43F5E", text: "#F8FAFC", tint: "#F43F5E"),
        ColorTheme(name: "Sepia", bg: "#F4ECD8", ui: "#8B4513", text: "#433422", tint: "#8B4513"),
        ColorTheme(name: "Lavender", bg: "#F3E5F5", ui: "#9C27B0", text: "#4A148C", tint: "#9C27B0"),
        ColorTheme(name: "Ocean", bg: "#E0F7FA", ui: "#00BCD4", text: "#006064", tint: "#00BCD4"),
        ColorTheme(name: "Rose Gold", bg: "#FFF1F0", ui: "#FF85C0", text: "#5C0011", tint: "#FF85C0"),
        ColorTheme(name: "Slate", bg: "#263238", ui: "#90A4AE", text: "#ECEFF1", tint: "#90A4AE"),
        ColorTheme(name: "Mint", bg: "#E8F5E9", ui: "#4CAF50", text: "#1B5E20", tint: "#4CAF50")
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
                // Header Information
                VStack(alignment: .leading, spacing: 8) {
                    Text("Themes & Colors")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    Text("Customize your app appearance with presets or custom colors.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)

                // Presets Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Presets", systemImage: "paintpalette.fill")
                            .font(.headline)
                        Spacer()
                        Button {
                            showAllThemes = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("View All")
                                Image(systemName: "chevron.right")
                            }
                            .font(.subheadline.bold())
                        }
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(allThemes.prefix(8)) { theme in
                                ThemeCard(theme: theme) {
                                    if !appState.isSigning {
                                        applyTheme(theme)
                                    }
                                }
                                .frame(width: 140)
                                .disabled(appState.isSigning)
                                .opacity(appState.isSigning ? 0.6 : 1.0)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Custom Colors Section
                VStack(alignment: .leading, spacing: 16) {
                    Label("Custom Colors", systemImage: "slider.horizontal.3")
                        .font(.headline)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ColorPickerRow(title: "Background", color: $bgColor, icon: "square.fill")
                        Divider().padding(.leading, 44)
                        ColorPickerRow(title: "UI Elements", color: $uiElementColor, icon: "app.fill")
                        Divider().padding(.leading, 44)
                        ColorPickerRow(title: "Text Color", color: $textColor, icon: "text.alignleft")
                        Divider().padding(.leading, 44)
                        ColorPickerRow(title: "Accent / Tint", color: $tintColor, icon: "sparkles")
                    }
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .padding(.horizontal)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        showSaveAlert = true
                    } label: {
                        Label("Save Theme", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accentColor)
                    .disabled(appState.isSigning)

                    Button {
                        shareStyle()
                    } label: {
                        Label("Share Configuration", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.isSigning)
                }
                .padding(.horizontal)

                // Live Preview
                VStack(alignment: .leading, spacing: 16) {
                    Label("Live Preview", systemImage: "eye.fill")
                        .font(.headline)
                        .padding(.horizontal)

                    ModernPreviewView(bgColor: bgColor, uiColor: uiElementColor, textColor: textColor, tintColor: tintColor)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    resetToDefaults()
                }
                .font(.subheadline.bold())
            }
        }
        .onAppear {
            loadColors()
        }
        .sheet(isPresented: $showAllThemes) {
            ThemeLibraryView(themes: allThemes) { theme in
                applyTheme(theme)
                showAllThemes = false
            } onDelete: { theme in
                deleteTheme(theme)
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
        .onChange(of: bgColor) { bgColorHex = $0.toHex() ?? Color.defaultBackground }
        .onChange(of: uiElementColor) { uiElementColorHex = $0.toHex() ?? Color.defaultUIElement }
        .onChange(of: textColor) { textColorHex = $0.toHex() ?? Color.defaultText }
        .onChange(of: tintColor) { tintColorHex = $0.toHex() ?? "#0077BE" }
    }

    private func loadColors() {
        bgColor = Color(hex: bgColorHex)
        uiElementColor = Color(hex: uiElementColorHex)
        textColor = Color(hex: textColorHex)
        tintColor = Color(hex: tintColorHex)
    }

    private func applyTheme(_ theme: ColorTheme) {
        bgColorHex = theme.bg
        uiElementColorHex = theme.ui
        textColorHex = theme.text
        tintColorHex = theme.tint
        loadColors()
        HapticsManager.shared.success()
    }

    private func saveStyle() {
        let newTheme = ColorTheme(
            name: themeName.isEmpty ? "My Theme \(userThemes.count + 1)" : themeName,
            bg: bgColor.toHex() ?? Color.defaultBackground,
            ui: uiElementColor.toHex() ?? Color.defaultUIElement,
            text: textColor.toHex() ?? Color.defaultText,
            tint: tintColor.toHex() ?? "#0077BE"
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
        tintColorHex = "#0077BE"
        loadColors()
        HapticsManager.shared.success()
    }

    private func deleteTheme(_ theme: ColorTheme) {
        userThemes.removeAll(where: { $0.id == theme.id })
        HapticsManager.shared.success()
    }

    private func shareStyle() {
        let theme = ColorTheme(
            name: "Shared Theme",
            bg: bgColor.toHex() ?? "",
            ui: uiElementColor.toHex() ?? "",
            text: textColor.toHex() ?? "",
            tint: tintColor.toHex() ?? ""
        )

        guard let data = try? JSONEncoder().encode(theme),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        let activityVC = UIActivityViewController(activityItems: [jsonString], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.system(.body, design: .rounded))

            Spacer()

            ColorPicker("", selection: $color, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct ModernPreviewView: View {
    let bgColor: Color
    let uiColor: Color
    let textColor: Color
    let tintColor: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(bgColor)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 8)

            VStack(spacing: 16) {
                // Mock Header
                HStack {
                    Circle().fill(uiColor).frame(width: 32, height: 32)
                        .overlay(Image(systemName: "person.fill").foregroundStyle(.white).font(.system(size: 14)))
                    VStack(alignment: .leading, spacing: 2) {
                        RoundedRectangle(cornerRadius: 4).fill(textColor.opacity(0.7)).frame(width: 80, height: 8)
                        RoundedRectangle(cornerRadius: 4).fill(textColor.opacity(0.4)).frame(width: 50, height: 6)
                    }
                    Spacer()
                    Image(systemName: "bell.fill").foregroundStyle(tintColor)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Mock Content
                VStack(spacing: 10) {
                    ForEach(0..<2) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10).fill(uiColor.opacity(0.15)).frame(width: 44, height: 44)
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 4).fill(textColor).frame(width: 120, height: 10)
                                RoundedRectangle(cornerRadius: 4).fill(textColor.opacity(0.5)).frame(width: 180, height: 8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(uiColor.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // Mock Button
                Capsule()
                    .fill(uiColor)
                    .frame(height: 44)
                    .overlay(Text("Apply Changes").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(.white))
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .frame(height: 240)
    }
}

struct ThemeCard: View {
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: theme.bg))
                        .frame(height: 90)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: theme.ui))
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(Color(hex: theme.tint))
                                .frame(width: 16, height: 16)
                        }

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: theme.text))
                            .frame(width: 40, height: 4)
                            .opacity(0.6)
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

struct ThemeLibraryView: View {
    @Environment(\.dismiss) var dismiss
    let themes: [ColorTheme]
    let onSelect: (ColorTheme) -> Void
    let onDelete: (ColorTheme) -> Void

    @State private var searchText = ""

    var filteredThemes: [ColorTheme] {
        if searchText.isEmpty { return themes }
        return themes.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search themes...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(12)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(filteredThemes) { theme in
                            ThemeCard(theme: theme) {
                                onSelect(theme)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    onDelete(theme)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Theme Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.headline)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}
