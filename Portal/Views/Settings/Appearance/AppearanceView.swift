import SwiftUI
import NimbleViews
import UIKit

// MARK: - Appearance View
struct AppearanceView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("Feather.userInterfaceStyle") private var userInterfaceStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
    @AppStorage(UserDefaults.Keys.installTrigger) private var installTrigger: Int = 0 // 0: Manual, 1: Automatic
    @AppStorage("Feather.shouldTintIcons") private var _shouldTintIcons: Bool = false
    @AppStorage("Feather.storeCellAppearance") private var storeCellAppearance: Int = 0
    @AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck") private var ignoreSolariumLinkedOnCheck: Bool = false
    @AppStorage("Feather.showNews") private var showNews: Bool = true
    @AppStorage("Feather.showIconsInAppearance") private var showIconsInAppearance: Bool = true
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews: Bool = true
    @AppStorage("Feather.portalTopViewEnabled") private var portalTopViewEnabled: Bool = true
    @AppStorage("Feather.portalTopViewColor") private var portalTopViewColor: String = "#0077BE"
    @AppStorage("Feather.portalTopViewStyle") private var portalTopViewStyle: Int = 0 // 0: Ultra Thin, 1: Thin, 2: Regular, 3: Thick
    @AppStorage("Feather.portalTopViewTitle") private var portalTopViewTitle: String = "Portal"
    @AppStorage("Feather.portalTopViewTextColor") private var portalTopViewTextColor: String = "#FFFFFF"
    @AppStorage("Feather.portalTopViewShowIcon") private var portalTopViewShowIcon: Bool = true
    @AppStorage("Feather.portalTopViewShowVersion") private var portalTopViewShowVersion: Bool = true
    @AppStorage("Feather.useNewAllAppsView") private var useNewAllAppsView: Bool = true
    @AppStorage("Feather.greetingsName") private var greetingsName: String = ""
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
    @StateObject private var hapticsManager = HapticsManager.shared
    
    private var isEnterprise: Bool { certificateExperience == CertificateExperience.enterprise.rawValue }

    var body: some View {
        List {
            if showHeaderViews {
                Section {
                    AppearanceHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            // MARK: - Theme
            Section {
                Picker("Appearance", selection: $userInterfaceStyle) {
                    ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                        Label(style.label, systemImage: style.iconName).tag(style.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            } header: {
                Label("Theme", systemImage: "paintbrush.fill")
            }

            // MARK: - Color
            Section {
                NavigationLink(destination: ColorCustomizationView()) {
                    Label("Customization", systemImage: "paintpalette.fill")
                        .foregroundStyle(Color.accentColor)
                }
            } header: {
                Label("Color", systemImage: "paintpalette.fill")
            }

            // MARK: - Tint Icons
            if #available(iOS 18.0, *) {
                Section {
                    Toggle(isOn: $_shouldTintIcons) {
                        Label("Tint App Icons", systemImage: "paintpalette")
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Label("Tint Icons", systemImage: "paintpalette")
                } footer: {
                    Text("Allow Portal to tint your app icons when signing apps with the current accent color set.")
                }
            } else {
                EmptyView()
            }

            // MARK: - Top View
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    // Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
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
                    .padding(.top, 8)

                    Toggle(isOn: $portalTopViewEnabled) {
                        Label("Enable Top View", systemImage: "uiwindow.split.2x1")
                            .font(.system(.body, design: .rounded, weight: .medium))
                    }
                    .tint(Color.accentColor)

                    if portalTopViewEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Customization")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            HStack(spacing: 12) {
                                AppearanceRowLabel(icon: "textformat", title: "Custom Title", color: .blue)
                                Spacer()
                                TextField("Portal", text: $portalTopViewTitle)
                                    .multilineTextAlignment(.trailing)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }

                            Divider()

                            HStack(spacing: 12) {
                                AppearanceRowLabel(icon: "paintpalette.fill", title: "Background Color", color: .purple)
                                Spacer()
                                ColorPicker("", selection: Binding(
                                    get: { Color(hex: portalTopViewColor) },
                                    set: { portalTopViewColor = $0.toHex() ?? "#0077BE" }
                                ))
                                .labelsHidden()
                            }

                            Divider()

                            HStack(spacing: 12) {
                                AppearanceRowLabel(icon: "paintbrush.fill", title: "Text Color", color: .pink)
                                Spacer()
                                ColorPicker("", selection: Binding(
                                    get: { Color(hex: portalTopViewTextColor) },
                                    set: { portalTopViewTextColor = $0.toHex() ?? "#FFFFFF" }
                                ))
                                .labelsHidden()
                            }

                            Divider()

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

                            Divider()

                            Toggle(isOn: $portalTopViewShowIcon) {
                                AppearanceRowLabel(icon: "app.badge.fill", title: "Show App Icon", color: .orange)
                            }

                            Divider()

                            Toggle(isOn: $portalTopViewShowVersion) {
                                AppearanceRowLabel(icon: "number", title: "Show Version", color: .green)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            } header: {
                Label("Top View", systemImage: "rectangle.inset.topthird.filled")
            } footer: {
                Text("Customize the Top View that shows on the top of when you take screenshots")
            }

            // MARK: - Display
            Section {
                Toggle(isOn: $showIconsInAppearance) {
                    Label("Show Icons", systemImage: "square.grid.2x2")
                        .foregroundStyle(Color.accentColor)
                }
                Toggle(isOn: $showNews) {
                    Label("Show News", systemImage: "newspaper")
                        .foregroundStyle(Color.accentColor)
                }
                Toggle(isOn: $showHeaderViews) {
                    Label("Show Header Views", systemImage: "dock.rectangle")
                        .foregroundStyle(Color.accentColor)
                }
            } header: {
                Label("Display", systemImage: "eye.fill")
            }

            // MARK: - Haptics
            Section {
                Toggle(isOn: $hapticsManager.isEnabled) {
                    Label("Enable Haptics", systemImage: "iphone.radiowaves.left.and.right")
                        .foregroundStyle(Color.accentColor)
                }

                if hapticsManager.isEnabled {
                    ForEach(HapticsManager.HapticIntensity.allCases, id: \.self) { intensity in
                        HapticIntensityRow(
                            intensity: intensity,
                            isSelected: hapticsManager.intensity == intensity
                        ) {
                            hapticsManager.intensity = intensity
                            HapticsManager.shared.impact()
                        }
                    }
                }
            } header: {
                Label("App Haptics", systemImage: "waveform")
            }

            // MARK: - Personalization
            Section {
                HStack {
                    Label("Your Name", systemImage: "person.fill")
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    TextField("Enter Name", text: $greetingsName)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Personalization", systemImage: "person.crop.circle.fill")
            } footer: {
                Text("Personalize the Home Screen greeting.")
            }

            // MARK: - Customization
            Section {
                if !isEnterprise {
                    NavigationLink(destination: AppIconView()) {
                        Label("App Icons", systemImage: "app.badge.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                NavigationLink(destination: AllAppsCustomizationView()) {
                    Label("All Apps", systemImage: "square.grid.2x2.fill")
                        .foregroundStyle(Color.accentColor)
                }
                NavigationLink(destination: AppHideElementsView()) {
                    Label("Hide UI Elements", systemImage: "eye.slash.fill")
                        .foregroundStyle(Color.accentColor)
                }
                NavigationLink(destination: StatusBarCustomizationView()) {
                    Label("Status Bar", systemImage: "rectangle.topthird.inset.filled")
                        .foregroundStyle(Color.accentColor)
                }
                NavigationLink(destination: TabBarCustomizationView()) {
                    Label("Tab Bar", systemImage: "dock.rectangle")
                        .foregroundStyle(Color.accentColor)
                }
                NavigationLink(destination: LostView(onGoBack: { dismiss() })) {
                    Label("Gestures", systemImage: "hand.tap.fill")
                        .foregroundStyle(Color.accentColor)
                }

                if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 16 {
                    NavigationLink(destination: KeyboardCustomizationView()) {
                        Label("Keyboard Backdrop", systemImage: "keyboard")
                            .foregroundStyle(Color.accentColor)
                    }
                }
            } header: {
                Label("Customization", systemImage: "slider.horizontal.3")
            }

            // MARK: - Experiments
            if #available(iOS 19.0, *) {
                Section {
                    Toggle(isOn: $ignoreSolariumLinkedOnCheck) {
                        Label("Enable Liquid Glass", systemImage: "sparkles")
                            .foregroundStyle(Color.accentColor)
                    }
                } header: {
                    Label("Liquid Glass", systemImage: "sparkle")
                } footer: {
                    Text("Requires Portal to restart so Liquid Glass can be applied.")
                }
            } else {
                EmptyView()
            }
        }
        .background(Color.clear)
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: userInterfaceStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .forEach { $0.overrideUserInterfaceStyle = style }
            }
        }
        .onChange(of: ignoreSolariumLinkedOnCheck) { _ in
            UIApplication.shared.suspendAndReopen()
        }
    }
    
    // MARK: - Helper Views
    
    private func appearanceCard<Content: View>(title: String, icon: String, footer: String? = nil, onIconLongPress: (() -> Void)? = nil, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AppearanceSectionHeader(title: title, icon: icon)
                .padding(.leading, 8)
                .onLongPressGesture {
                    onIconLongPress?()
                }
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.clear)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)

            if let footer = footer {
                Text(footer)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 2)
            }
        }
    }
}

// MARK: - Appearance Components

struct AppearanceSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

struct AppearanceRowLabel: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(.body, design: .rounded))
        }
    }
}

struct AppearanceToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    
    var body: some View {
        Toggle(isOn: $isOn) {
            AppearanceRowLabel(icon: icon, title: title, color: color)
        }
    }
}

struct AppearanceNavRow<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                AppearanceRowLabel(icon: icon, title: title, color: color)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

private struct HapticIntensityRow: View {
    let intensity: HapticsManager.HapticIntensity
    let isSelected: Bool
    let action: () -> Void
    
    private var icon: String {
        switch intensity {
        case .slow, .defaultIntensity: return "waveform.path.ecg"
        case .hard, .extreme: return "waveform.path.ecg.rectangle"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 24)
                Text(intensity.title)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.medium)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
