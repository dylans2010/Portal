import SwiftUI

// MARK: - Left Panel: Structure & Visibility
struct StructureVisibilityPanel: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var showConfigureLayouts = false
    @State private var showSavedStyles = false
    @State private var showLimitReachedAlert = false
    @State private var attemptedWidget: String = ""
    
    // Count enabled widgets
    private var enabledWidgetCount: Int {
        var count = 0
        if viewModel.showCustomText { count += 1 }
        if viewModel.showSFSymbol { count += 1 }
        if viewModel.showTime { count += 1 }
        if viewModel.showBattery { count += 1 }
        if viewModel.showDate { count += 1 }
        if viewModel.showNetworkStatus { count += 1 }
        if viewModel.showMemoryUsage { count += 1 }
        if viewModel.showCPU { count += 1 }
        if viewModel.showStorage { count += 1 }
        if viewModel.showAppVersion { count += 1 }
        if viewModel.showDeviceName { count += 1 }
        return count
    }
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.showCustomText },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Custom Text"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showCustomText = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Custom Text", systemImage: "textformat")
                }
                .themedAccent()
                
                Toggle(isOn: Binding(
                    get: { viewModel.showSFSymbol },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "SF Symbol"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showSFSymbol = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("SF Symbol", systemImage: "star.fill")
                }
                .themedAccent()
                
                Toggle(isOn: Binding(
                    get: { viewModel.showTime },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Time"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showTime = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Time", systemImage: "clock.fill")
                }
                .themedAccent()
                
                Toggle(isOn: Binding(
                    get: { viewModel.showDate },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Date"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showDate = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Date", systemImage: "calendar")
                }
                .themedAccent()
                
                Toggle(isOn: Binding(
                    get: { viewModel.showBattery },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Battery"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showBattery = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Battery", systemImage: "battery.100")
                }
                .themedAccent()
            } header: {
                Label("Widgets", systemImage: "square.grid.2x2")
            } footer: {
                Text("Enable up to 5 widgets. Currently \(enabledWidgetCount) of 5.")
                    .foregroundStyle(enabledWidgetCount >= 5 ? .orange : .secondary)
            }
            
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.showNetworkStatus },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Network Status"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showNetworkStatus = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Network Status", systemImage: "wifi")
                }
                .themedAccent()
                
                Toggle(isOn: Binding(
                    get: { viewModel.showMemoryUsage },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Memory Usage"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showMemoryUsage = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Memory Usage", systemImage: "memorychip")
                }
                .themedAccent()

                Toggle(isOn: Binding(
                    get: { viewModel.showCPU },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "CPU Usage"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showCPU = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("CPU Usage", systemImage: "cpu")
                }
                .themedAccent()

                Toggle(isOn: Binding(
                    get: { viewModel.showStorage },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Storage"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showStorage = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Storage", systemImage: "internaldrive")
                }
                .themedAccent()

                Toggle(isOn: Binding(
                    get: { viewModel.showAppVersion },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "App Version"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showAppVersion = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("App Version", systemImage: "number")
                }
                .themedAccent()

                Toggle(isOn: Binding(
                    get: { viewModel.showDeviceName },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 5 {
                            attemptedWidget = "Device Name"
                            showLimitReachedAlert = true
                            HapticsManager.shared.error()
                        } else {
                            viewModel.showDeviceName = newValue
                            HapticsManager.shared.softImpact()
                        }
                    }
                )) {
                    Label("Device Name", systemImage: "iphone")
                }
                .themedAccent()
            } header: {
                Label("System Info", systemImage: "info.circle")
            }
            
            Section {
                Button {
                    showSavedStyles = true
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(themeManager.accentColor)
                        Text("Saved Styles")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    showConfigureLayouts = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(themeManager.accentColor)
                        Text("Configure Layouts")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Label("Customization", systemImage: "paintbrush")
            }
            
            Section {
                Toggle("Hide Default Status Bar", isOn: $viewModel.hideDefaultStatusBar)
                    .onChange(of: viewModel.hideDefaultStatusBar) { newValue in
                        viewModel.handleHideDefaultStatusBarChange(newValue)
                    }
                    .themedAccent()
            } header: {
                Label("System", systemImage: "gearshape")
            }
        }
        .globalTheme()
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showConfigureLayouts) {
            ConfigureLayoutsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSavedStyles) {
            SavedStylesView(viewModel: viewModel)
        }
        .alert("Widget Limit Reached", isPresented: $showLimitReachedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You can only enable 5 status bar options at a time. Please disable one of the currently enabled options before enabling \(attemptedWidget).")
        }
    }
}
