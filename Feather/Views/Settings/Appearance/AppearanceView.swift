import SwiftUI
import NimbleViews
import UIKit

// MARK: - View
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
            // Appearance Mode
            Section {
                appearancePicker
            } header: {
                sectionHeader("Theme", icon: "paintbrush.fill")
            } footer: {
                Text("Choose your preferred appearance mode")
                    .font(.caption)
            }
            
            // Accent Color
            Section {
                AppearanceTintColorView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } header: {
                sectionHeader("Accent Color", icon: "paintpalette.fill")
            }
            
            // Display Options
            Section {
                settingToggle(icon: "square.grid.2x2", title: "Show Icons", isOn: $showIconsInAppearance, color: .blue)
                settingToggle(icon: "rectangle.grid.1x2", title: "New Apps View", isOn: $useNewAllAppsView, color: .purple)
                settingToggle(icon: "newspaper", title: "Show News", isOn: $showNews, color: .orange)
            } header: {
                sectionHeader("Display", icon: "eye.fill")
            }
            
            // Haptics
            Section {
                Toggle(isOn: $hapticsManager.isEnabled) {
                    HStack(spacing: 12) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.purple)
                            .frame(width: 24)
                        Text("Enable Haptics")
                            .font(.system(size: 15))
                    }
                }
                .onChange(of: hapticsManager.isEnabled) { newValue in
                    if newValue {
                        HapticsManager.shared.impact()
                    }
                }
                
                if hapticsManager.isEnabled {
                    ForEach(HapticsManager.HapticIntensity.allCases, id: \.self) { intensity in
                        Button {
                            hapticsManager.intensity = intensity
                            HapticsManager.shared.impact()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: iconForIntensity(intensity))
                                    .foregroundStyle(hapticsManager.intensity == intensity ? Color.accentColor : Color.secondary)
                                    .font(.body)
                                    .frame(width: 24)
                                Text(intensity.title)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if hapticsManager.intensity == intensity {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }
            } header: {
                sectionHeader("Haptics", icon: "waveform")
            } footer: {
                Text("Enable haptic feedback throughout the app.")
                    .font(.caption)
            }
            
            // Personalization
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.green)
                        .frame(width: 24)
                    
                    Text("Your Name")
                        .font(.system(size: 15))
                    
                    Spacer()
                    
                    TextField("Enter Name", text: $greetingsName)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            } header: {
                sectionHeader("Personalization", icon: "person.crop.circle.fill")
            } footer: {
                Text("Personalize the Home Screen greeting.")
                    .font(.caption)
            }
            
            // Customization
            Section {
                navigationRow(icon: "rectangle.topthird.inset.filled", title: "Status Bar", color: .cyan, destination: StatusBarCustomizationView())
                navigationRow(icon: "dock.rectangle", title: "Tab Bar", color: .indigo, destination: TabBarCustomizationView())
            } header: {
                sectionHeader("Customization", icon: "slider.horizontal.3")
            }
            
            // Experiments
            if #available(iOS 19.0, *) {
                Section {
                    settingToggle(icon: "sparkles", title: "Liquid Glass", isOn: $ignoreSolariumLinkedOnCheck, color: .pink)
                } header: {
                    sectionHeader("Experiments", icon: "flask.fill")
                } footer: {
                    Text("Requires Portal to restart so Liquid Glass can be applied.")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Appearance & Haptics")
        .onChange(of: userInterfaceStyle) { value in
            if let style = UIUserInterfaceStyle(rawValue: value) {
                UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
            }
        }
        .onChange(of: ignoreSolariumLinkedOnCheck) { _ in
            UIApplication.shared.suspendAndReopen()
        }
    }
    
    // MARK: - Appearance Picker
    private var appearancePicker: some View {
        Picker("Appearance", selection: $userInterfaceStyle) {
            ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
                Label(style.label, systemImage: style.iconName)
                    .tag(style.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Section Header
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Setting Toggle
    private func settingToggle(icon: String, title: String, isOn: Binding<Bool>, color: Color) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15))
            }
        }
    }
    
    // MARK: - Navigation Row
    private func navigationRow<Destination: View>(icon: String, title: String, color: Color, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15))
            }
        }
    }
    
    // MARK: - Haptic Intensity Icon
    private func iconForIntensity(_ intensity: HapticsManager.HapticIntensity) -> String {
        switch intensity {
        case .slow: return "waveform.path.ecg"
        case .defaultIntensity: return "waveform.path.ecg"
        case .hard: return "waveform.path.ecg.rectangle"
        case .extreme: return "waveform.path.ecg.rectangle"
        }
    }
}
