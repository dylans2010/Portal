import SwiftUI

struct ColorTheme: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var bg: String
    var ui: String
    var text: String
    var tint: String
    var secondaryText: String?
    var cardRadius: Double?
    var fontDesign: String?

    var navBarColor: String?
    var tabBarColor: String?
    var dividerColor: String?
    var sheetBackgroundColor: String?
    var successColor: String?
    var warningColor: String?
    var errorColor: String?
    var glowIntensity: Double?
    var borderWidth: Double?
    var cardOpacity: Double?

    var appearanceMode: Int? = 0
    var scheduleMode: Int? = 0
    var highContrast: Bool? = false
    var colorBlindnessFilter: Int? = 0
    var autoContrastCorrection: Bool? = true
    var hapticIntensity: Double? = 0.5
    var visualFeedbackStrength: Double? = 0.5
    var layerBlendMode: Int? = 0
    var parallaxEnabled: Bool? = false
    var motionGradients: Bool? = true
    var dynamicLighting: Bool? = false
}

struct ColorCustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    @State private var showingAppWideColorPicker = false

    var body: some View {
        FeatherScreen(title: "Customization") {
            ThemedScreenContent {
                ThemedSection("APPEARANCE", symbol: "paintpalette") {
                    ThemedPickerRow(
                        label: "Section Style",
                        symbol: "square.grid.2x2",
                        selection: Binding(
                            get: { styleManager.currentStyle },
                            set: { styleManager.setStyle($0) }
                        ),
                        options: SectionStyle.allCases.map { ($0, $0.displayName) },
                        isLast: false
                    )

                    ThemedRow(
                        label: "App Wide Colors",
                        symbol: "slider.horizontal.3",
                        subtitle: themeManager.appWideColors == nil
                        ? "Using \(themeManager.currentTheme.displayName) defaults"
                        : "Custom app-wide overrides active",
                        value: themeManager.appWideColors == nil ? "Default" : "Custom",
                        showChevron: true,
                        isLast: true
                    ) {
                        showingAppWideColorPicker = true
                    }
                }

                ThemedSection("ALL THEMES", symbol: "swatchpalette") {
                    VStack(spacing: 12) {
                        ForEach(AppTheme.allCases) { theme in
                            ThemeSelectionCard(theme: theme)
                                .environmentObject(themeManager)
                                .environmentObject(styleManager)
                        }
                    }
                    .padding(12)
                }
            }
        }
        .sheet(isPresented: $showingAppWideColorPicker) {
            AppWideColorPickerSheet()
                .environmentObject(themeManager)
                .environmentObject(styleManager)
        }
    }
}

private struct ThemeSelectionCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let theme: AppTheme

    var colors: AppWideColors {
        AppWideColors.default(for: theme)
    }

    var isActive: Bool {
        themeManager.currentTheme == theme && themeManager.appWideColors == nil
    }

    var body: some View {
        Button {
            themeManager.setTheme(theme)
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(theme.displayName)
                        .font(.headline)
                        .foregroundStyle(Color(hex: colors.primaryText))
                    Spacer()
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(themeManager.accentColor)
                    }
                }

                HStack(spacing: 6) {
                    ForEach([
                        colors.accent,
                        colors.cardBackground,
                        colors.primaryText,
                        colors.secondaryText,
                        colors.iconTint,
                        colors.buttonBackground
                    ], id: \.self) { hex in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: hex))
                            .frame(height: 8)
                    }
                }

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: colors.appBackground))
                    .frame(height: 70)
                    .overlay {
                        VStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: colors.cardBackground))
                                .frame(height: 22)
                                .overlay(
                                    HStack {
                                        Circle()
                                            .fill(Color(hex: colors.iconTint))
                                            .frame(width: 8, height: 8)
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(hex: colors.primaryText))
                                            .frame(width: 72, height: 5)
                                        Spacer()
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(hex: colors.secondaryText))
                                            .frame(width: 26, height: 5)
                                    }
                                        .padding(.horizontal, 8)
                                )

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: colors.buttonBackground))
                                .frame(height: 16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color(hex: colors.buttonText))
                                        .frame(width: 50, height: 4)
                                )
                        }
                        .padding(8)
                    }
            }
            .padding(12)
            .background(Color(hex: colors.cardBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isActive ? themeManager.accentColor : Color(hex: colors.separator), lineWidth: isActive ? 2 : 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

private struct AppWideColorPickerSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager
    @Environment(\.dismiss) var dismiss
    @State private var draft: AppWideColors

    init() {
        _draft = State(initialValue: ThemeManager.shared.resolvedColors)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("BACKGROUNDS") {
                    ColorPickerRow(label: "App Background", color: $draft.appBackground)
                    ColorPickerRow(label: "Navigation Bar", color: $draft.navigationBar)
                    ColorPickerRow(label: "Tab Bar", color: $draft.tabBar)
                    ColorPickerRow(label: "Card / Row", color: $draft.cardBackground)
                }

                Section("TEXT") {
                    ColorPickerRow(label: "Primary Text", color: $draft.primaryText)
                    ColorPickerRow(label: "Secondary Text", color: $draft.secondaryText)
                }

                Section("ACCENTS") {
                    ColorPickerRow(label: "Accent / Tint", color: $draft.accent)
                    ColorPickerRow(label: "Separator", color: $draft.separator)
                    ColorPickerRow(label: "Destructive", color: $draft.destructive)
                }

                Section("BUTTONS") {
                    ColorPickerRow(label: "Button Background", color: $draft.buttonBackground)
                    ColorPickerRow(label: "Button Text", color: $draft.buttonText)
                }

                Section("ICONS & INDICATORS") {
                    ColorPickerRow(label: "Icon Tint", color: $draft.iconTint)
                    ColorPickerRow(label: "Switch Tint", color: $draft.switchTint)
                    ColorPickerRow(label: "Selection / Check", color: $draft.selectionIndicator)
                }

                Section("STRUCTURE") {
                    ColorPickerRow(label: "Grouped Background", color: $draft.groupedBackground)
                    ColorPickerRow(label: "Section Headers", color: $draft.headerText)
                    ColorPickerRow(label: "Cell Highlight", color: $draft.cellHighlight)
                }

                Section("BADGES") {
                    ColorPickerRow(label: "Badge Background", color: $draft.badgeBackground)
                    ColorPickerRow(label: "Badge Text", color: $draft.badgeText)
                }
            }
            .navigationTitle("App Wide Colors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        themeManager.updateColor(keyPath: \.appBackground, hex: draft.appBackground)
                        themeManager.updateColor(keyPath: \.navigationBar, hex: draft.navigationBar)
                        themeManager.updateColor(keyPath: \.tabBar, hex: draft.tabBar)
                        themeManager.updateColor(keyPath: \.cardBackground, hex: draft.cardBackground)
                        themeManager.updateColor(keyPath: \.primaryText, hex: draft.primaryText)
                        themeManager.updateColor(keyPath: \.secondaryText, hex: draft.secondaryText)
                        themeManager.updateColor(keyPath: \.accent, hex: draft.accent)
                        themeManager.updateColor(keyPath: \.separator, hex: draft.separator)
                        themeManager.updateColor(keyPath: \.cellHighlight, hex: draft.cellHighlight)
                        themeManager.updateColor(keyPath: \.destructive, hex: draft.destructive)
                        themeManager.updateColor(keyPath: \.buttonBackground, hex: draft.buttonBackground)
                        themeManager.updateColor(keyPath: \.buttonText, hex: draft.buttonText)
                        themeManager.updateColor(keyPath: \.iconTint, hex: draft.iconTint)
                        themeManager.updateColor(keyPath: \.groupedBackground, hex: draft.groupedBackground)
                        themeManager.updateColor(keyPath: \.headerText, hex: draft.headerText)
                        themeManager.updateColor(keyPath: \.badgeBackground, hex: draft.badgeBackground)
                        themeManager.updateColor(keyPath: \.badgeText, hex: draft.badgeText)
                        themeManager.updateColor(keyPath: \.switchTint, hex: draft.switchTint)
                        themeManager.updateColor(keyPath: \.selectionIndicator, hex: draft.selectionIndicator)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ColorPickerRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager
    let label: String
    @Binding var color: String
    @State private var showingPicker = false

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: color))
                .frame(width: 28, height: 28)
                .onTapGesture {
                    showingPicker = true
                }
        }
        .sheet(isPresented: $showingPicker) {
            NavigationStack {
                VStack {
                    ColorPicker(label, selection: Binding(
                        get: { Color(hex: color) },
                        set: { color = $0.hexString }
                    ), supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(3)
                    .padding()
                }
                .navigationTitle(label)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showingPicker = false }
                    }
                }
            }
            .environmentObject(themeManager)
            .environmentObject(styleManager)
            .presentationDetents([.height(200)])
        }
    }
}
