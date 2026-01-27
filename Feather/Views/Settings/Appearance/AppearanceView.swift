import SwiftUI
import NimbleViews
import UIKit

// MARK: - Appearance View
struct AppearanceView: View {
    @AppStorage("Feather.userInterfaceStyle") private var userInterfaceStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
    @AppStorage("Feather.storeCellAppearance") private var storeCellAppearance: Int = 0
    @AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck") private var ignoreSolariumLinkedOnCheck: Bool = false
    @AppStorage("Feather.showNews") private var showNews: Bool = true
    @AppStorage("Feather.showIconsInAppearance") private var showIconsInAppearance: Bool = true
    @AppStorage("Feather.useNewAllAppsView") private var useNewAllAppsView: Bool = true
    @AppStorage("Feather.greetingsName") private var greetingsName: String = ""
    @StateObject private var hapticsManager = HapticsManager.shared
    
    var body: some View {
        List {
            themeSection
            accentColorSection
            displaySection
            hapticsSection
            personalizationSection
            customizationSection
            experimentsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Appearance")
        .onChange(of: userInterfaceStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
            }
        }
        .onChange(of: ignoreSolariumLinkedOnCheck) { _ in
            UIApplication.shared.suspendAndReopen()
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        Section {
            Picker("Appearance", selection: $userInterfaceStyle) {
                ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                    Label(style.label, systemImage: style.iconName).tag(style.rawValue)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            AppearanceSectionHeader(title: "Theme", icon: "paintbrush.fill")
        }
    }
    
    // MARK: - Accent Color Section
    
    private var accentColorSection: some View {
        Section {
            AppearanceTintColorView()
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        } header: {
            AppearanceSectionHeader(title: "Accent Color", icon: "paintpalette.fill")
        }
    }
    
    // MARK: - Display Section
    
    private var displaySection: some View {
        Section {
            AppearanceToggle(icon: "square.grid.2x2", title: "Show Icons", isOn: $showIconsInAppearance, color: .blue)
            AppearanceToggle(icon: "rectangle.grid.1x2", title: "New Apps View", isOn: $useNewAllAppsView, color: .purple)
            AppearanceToggle(icon: "newspaper", title: "Show News", isOn: $showNews, color: .orange)
        } header: {
            AppearanceSectionHeader(title: "Display", icon: "eye.fill")
        }
    }
    
    // MARK: - Haptics Section
    
    private var hapticsSection: some View {
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
            AppearanceSectionHeader(title: "Haptics", icon: "waveform")
        }
    }
    
    // MARK: - Personalization Section
    
    private var personalizationSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.green)
                    .frame(width: 24)
                
                Text("Your Name")
                
                Spacer()
                
                TextField("Enter Name", text: $greetingsName)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
        } header: {
            AppearanceSectionHeader(title: "Personalization", icon: "person.crop.circle.fill")
        } footer: {
            Text("Personalize the Home Screen greeting.")
        }
    }
    
    // MARK: - Customization Section
    
    private var customizationSection: some View {
        Section {
            AppearanceNavRow(icon: "rectangle.topthird.inset.filled", title: "Status Bar", color: .cyan, destination: StatusBarCustomizationView())
            AppearanceNavRow(icon: "dock.rectangle", title: "Tab Bar", color: .indigo, destination: TabBarCustomizationView())
        } header: {
            AppearanceSectionHeader(title: "Customization", icon: "slider.horizontal.3")
        }
    }
    
    // MARK: - Experiments Section
    
    @ViewBuilder
    private var experimentsSection: some View {
        if #available(iOS 19.0, *) {
            Section {
                AppearanceToggle(icon: "sparkles", title: "Liquid Glass", isOn: $ignoreSolariumLinkedOnCheck, color: .pink)
            } header: {
                AppearanceSectionHeader(title: "Experiments", icon: "flask.fill")
            } footer: {
                Text("Requires Portal to restart so Liquid Glass can be applied.")
            }
        }
    }
}

// MARK: - Appearance Components

private struct AppearanceSectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.secondary)
    }
}

private struct AppearanceRowLabel: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(title)
        }
    }
}

private struct AppearanceToggle: View {
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

private struct AppearanceNavRow<Destination: View>: View {
    let icon: String
    let title: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            AppearanceRowLabel(icon: icon, title: title, color: color)
        }
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
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.medium)
                }
            }
        }
    }
}
