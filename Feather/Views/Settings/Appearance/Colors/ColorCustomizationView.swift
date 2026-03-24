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
    var appearanceMode: Int?
    var scheduleMode: Int?
    var highContrast: Bool?
    var colorBlindnessFilter: Int?
    var autoContrastCorrection: Bool?
    var hapticIntensity: Double?
    var visualFeedbackStrength: Double?
    var layerBlendMode: Int?
    var parallaxEnabled: Bool?
    var motionGradients: Bool?
    var dynamicLighting: Bool?
}

struct ColorCustomizationView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager
    @State private var showingAppWideColorPicker = false

    var body: some View {
        FeatherScreen(title: "Customization") {
            ThemedScreenContent {
                ThemedSection("APPEARANCE", symbol: "paintpalette") {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 7)
                                .fill(themeManager.iconTintColor.opacity(0.15))
                                .frame(width: 30, height: 30)
                            Image(systemName: "rectangle.3.group")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(themeManager.iconTintColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Section Style")
                                .font(.body)
                                .foregroundStyle(themeManager.primaryTextColor)
                            Text(styleManager.currentStyle.description)
                                .font(.caption)
                                .foregroundStyle(themeManager.secondaryTextColor)
                        }

                        Spacer()

                        Picker("", selection: Binding(
                            get: { styleManager.currentStyle },
                            set: { styleManager.setStyle($0) }
                        )) {
                            ForEach(SectionStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(themeManager.accentColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(themeManager.cardBackgroundColor)

                    Rectangle()
                        .fill(themeManager.separatorColor)
                        .frame(height: 0.5)
                        .padding(.leading, 58)

                    Button {
                        showingAppWideColorPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("App Wide")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(themeManager.primaryTextColor)
                                Text("Customize all app colors")
                                    .font(.system(size: 11))
                                    .foregroundStyle(themeManager.secondaryTextColor)
                            }

                            Spacer()

                            HStack(spacing: 0) {
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(themeManager.appBackgroundColor)
                                    .frame(width: 12, height: 24)
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(themeManager.navigationBarColor)
                                    .frame(width: 12, height: 24)
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(themeManager.accentColor)
                                    .frame(width: 12, height: 24)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            if themeManager.appWideColors != nil {
                                Button {
                                    themeManager.resetToThemeDefaults()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(themeManager.secondaryTextColor)
                                }
                                .buttonStyle(.plain)
                            }

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(themeManager.secondaryTextColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(themeManager.cardBackgroundColor)
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingAppWideColorPicker) {
                        AppWideColorPickerSheet()
                            .environmentObject(themeManager)
                            .environmentObject(styleManager)
                    }
                }
                .environmentObject(themeManager)
                .environmentObject(styleManager)

                ThemedSection("ALL THEMES", symbol: "swatchpalette") {
                    ForEach(AppTheme.allCases) { theme in
                        themeCard(for: theme)
                    }
                }
                .environmentObject(themeManager)
                .environmentObject(styleManager)
            }
            .environmentObject(themeManager)
            .environmentObject(styleManager)
        }
        .environmentObject(themeManager)
        .environmentObject(styleManager)
    }

    private func themeCard(for theme: AppTheme) -> some View {
        let colors = AppWideColors.default(for: theme)
        let isActive = themeManager.currentTheme == theme && themeManager.appWideColors == nil

        return Button(action: {
            themeManager.setTheme(theme)
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(theme.displayName)
                            .font(.subheadline).bold()
                            .foregroundStyle(Color(hex: colors.primaryText))
                        Text("\(AppWideColors.slotCount) color slots")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: colors.secondaryText))
                    }
                    Spacer()
                    if isActive {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption).bold()
                            .foregroundStyle(Color(hex: colors.accent))
                    }
                }

                HStack(spacing: 5) {
                    ForEach([
                        colors.accent,
                        colors.cardBackground,
                        colors.primaryText,
                        colors.secondaryText,
                        colors.iconTint,
                        colors.buttonBackground,
                        colors.badgeBackground,
                        colors.headerText
                    ], id: \.self) { hex in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: hex))
                            .frame(width: 28, height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(hex: colors.separator), lineWidth: 0.5)
                            )
                    }
                    Spacer()
                }

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: colors.cardBackground))
                        .frame(width: 80, height: 36)
                        .overlay(
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: colors.iconTint))
                                    .frame(width: 10, height: 10)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color(hex: colors.primaryText).opacity(0.8))
                                    .frame(width: 36, height: 6)
                            }
                            .padding(.leading, 8),
                            alignment: .leading
                        )

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: colors.buttonBackground))
                        .frame(width: 52, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: colors.buttonText).opacity(0.9))
                                .frame(width: 28, height: 6)
                        )

                    Capsule()
                        .fill(Color(hex: colors.badgeBackground))
                        .frame(width: 44, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: colors.badgeText).opacity(0.9))
                                .frame(width: 24, height: 5)
                        )
                }
            }
            .padding(16)
            .background(Color(hex: colors.appBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? Color(hex: colors.accent) : Color(hex: colors.border), lineWidth: isActive ? 2 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AppWideColorPickerSheet: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AppWideColors

    init() {
        _draft = State(initialValue: ThemeManager.shared.resolvedColors)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("App Wide") {
                    ColorPickerRow(label: "App Background", color: $draft.appBackground)
                    ColorPickerRow(label: "Navigation Bar", color: $draft.navigationBar)
                    ColorPickerRow(label: "Tab Bar", color: $draft.tabBar)
                    ColorPickerRow(label: "Primary Text", color: $draft.primaryText)
                    ColorPickerRow(label: "Secondary Text", color: $draft.secondaryText)
                    ColorPickerRow(label: "Card Background", color: $draft.cardBackground)
                    ColorPickerRow(label: "Accent", color: $draft.accent)
                }
            }
            .navigationTitle("App Wide Colors")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        themeManager.appWideColors = draft
                        themeManager.applyUIKitAppearance()
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ColorPickerRow: View {
    let label: String
    @Binding var color: String

    var body: some View {
        ColorPicker(label, selection: Binding(
            get: { Color(hex: color) },
            set: { color = $0.hexString }
        ))
    }
}
