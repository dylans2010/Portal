import SwiftUI
import NimbleViews
import UIKit

// MARK: - Appearance View
struct AppearanceView: View {
    @AppStorage("Feather.userInterfaceStyle") private var userInterfaceStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
    @AppStorage(UserDefaults.Keys.installTrigger) private var installTrigger: Int = 0 // 0: Manual, 1: Automatic
    @AppStorage("Feather.shouldTintIcons") private var _shouldTintIcons: Bool = false
    @AppStorage("Feather.storeCellAppearance") private var storeCellAppearance: Int = 0
    @AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck") private var ignoreSolariumLinkedOnCheck: Bool = false
    @AppStorage("Feather.showNews") private var showNews: Bool = true
    @AppStorage("Feather.showIconsInAppearance") private var showIconsInAppearance: Bool = true
    @AppStorage("Feather.useNewAllAppsView") private var useNewAllAppsView: Bool = true
    @AppStorage("Feather.greetingsName") private var greetingsName: String = ""
    @StateObject private var hapticsManager = HapticsManager.shared
    
    var body: some View {
        List {
            // MARK: - Theme
            Section {
                VStack(spacing: 16) {
                    Picker("Appearance", selection: $userInterfaceStyle) {
                        ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                            Label(style.label, systemImage: style.iconName).tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 8)

                Button {
                    cycleAppIcon()
                } label: {
                    AppearanceRowLabel(icon: "app.dashed", title: "Cycle App Icon", color: .orange)
                }
            } header: {
                Text("Theme")
            }

            // MARK: - Color
            Section {
                AppearanceNavRow(icon: "paintpalette.fill", title: "Customization", color: .pink, destination: ColorCustomizationView())
            } header: {
                Text("Color")
            }

            // MARK: - Tint Icons
            if #available(iOS 18.0, *) {
                Section {
                    AppearanceToggle(icon: "paintpalette", title: "Tint App Icons", isOn: $_shouldTintIcons, color: .pink)
                } header: {
                    Text("Tint Icons")
                } footer: {
                    Text("Allow Portal to tint your app icons when signing apps with the current accent color set.")
                }
            }

            // MARK: - Display
            Section {
                AppearanceToggle(icon: "square.grid.2x2", title: "Show Icons", isOn: $showIconsInAppearance, color: .blue)
                AppearanceToggle(icon: "newspaper", title: "Show News", isOn: $showNews, color: .orange)
            } header: {
                Text("Display")
            }

            // MARK: - Haptics
            Section {
                Toggle(isOn: $hapticsManager.isEnabled) {
                    AppearanceRowLabel(icon: "iphone.radiowaves.left.and.right", title: "Enable Haptics", color: .purple)
                }
                .onChange(of: hapticsManager.isEnabled) { newValue in
                    if newValue { HapticsManager.shared.impact() }
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
                Text("App Haptics")
            }

            // MARK: - Personalization
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.green)
                        .frame(width: 32, height: 32)
                        .background(.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("Your Name")
                        .font(.body)

                    Spacer()

                    TextField("Enter Name", text: $greetingsName)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Personalization")
            } footer: {
                Text("Personalize the Home Screen greeting.")
            }

            // MARK: - Customization
            Section {
                AppearanceNavRow(icon: "square.grid.2x2.fill", title: "All Apps", color: .blue, destination: AllAppsCustomizationView())
                AppearanceNavRow(icon: "eye.slash.fill", title: "Hide UI Elements", color: .red, destination: AppHideElementsView())
                AppearanceNavRow(icon: "rectangle.topthird.inset.filled", title: "Status Bar", color: .cyan, destination: StatusBarCustomizationView())
                AppearanceNavRow(icon: "dock.rectangle", title: "Tab Bar", color: .indigo, destination: TabBarCustomizationView())

                if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 16 {
                    AppearanceNavRow(icon: "keyboard", title: "Keyboard Backdrop", color: .purple, destination: KeyboardCustomizationView())
                }
            } header: {
                Text("Customization")
            }

            // MARK: - Experiments
            if #available(iOS 19.0, *) {
                Section {
                    AppearanceToggle(icon: "sparkles", title: "Enable Liquid Glass", isOn: $ignoreSolariumLinkedOnCheck, color: .pink)
                } header: {
                    Text("Liquid Glass")
                } footer: {
                    Text("Requires Portal to restart so Liquid Glass can be applied.")
                }
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
    
    private func cycleAppIcon() {
        let icons = ["AppIcon", "AppIcon-1", "AppIcon-2", "AppIcon-3"]
        let current = UIApplication.shared.alternateIconName ?? "AppIcon"
        let next = icons[(icons.firstIndex(of: current) ?? 0 + 1) % icons.count]
        UIApplication.shared.setAlternateIconName(next == "AppIcon" ? nil : next)
        ToastManager.shared.show("🎭 Icon Cycle: \(next)", type: .success)
        HapticsManager.shared.success()
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
