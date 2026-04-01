import SwiftUI

// MARK: - Left Panel: Structure & Visibility
struct StructureVisibilityPanel: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var showConfigureLayouts = false
    @State private var showSavedStyles = false
    @State private var showLimitReachedAlert = false
    @State private var attemptedWidget: String = ""
    
    private let widgetLimit = 4
    
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
        if viewModel.showCPUUsage { count += 1 }
        if viewModel.showBrightness { count += 1 }
        if viewModel.showVolume { count += 1 }
        if viewModel.showChargingStatus { count += 1 }
        return count
    }
    
    private func widgetToggle(isOn: Binding<Bool>, name: String, icon: String) -> some View {
        Toggle(isOn: Binding(
            get: { isOn.wrappedValue },
            set: { newValue in
                if newValue && enabledWidgetCount >= widgetLimit {
                    attemptedWidget = name
                    showLimitReachedAlert = true
                    HapticsManager.shared.error()
                } else {
                    isOn.wrappedValue = newValue
                    HapticsManager.shared.softImpact()
                }
            }
        )) {
            Label(name, systemImage: icon)
        }
        .themedAccent()
    }
    
    var body: some View {
        List {
            Section {
                widgetToggle(isOn: $viewModel.showTime, name: "Time", icon: "clock.fill")
                widgetToggle(isOn: $viewModel.showDate, name: "Date", icon: "calendar")
                widgetToggle(isOn: $viewModel.showBattery, name: "Battery", icon: "battery.100")
                widgetToggle(isOn: $viewModel.showCustomText, name: "Custom Text", icon: "textformat")
                widgetToggle(isOn: $viewModel.showSFSymbol, name: "SF Symbol", icon: "star.fill")
            } header: {
                Label("Common Widgets", systemImage: "square.grid.2x2")
            } footer: {
                Text("Enable up to \(widgetLimit) widgets. Currently \(enabledWidgetCount) of \(widgetLimit).")
                    .foregroundStyle(enabledWidgetCount >= widgetLimit ? .orange : .secondary)
            }
            
            Section {
                widgetToggle(isOn: $viewModel.showNetworkStatus, name: "Network Status", icon: "wifi")
                widgetToggle(isOn: $viewModel.showMemoryUsage, name: "Memory Usage", icon: "memorychip")
                widgetToggle(isOn: $viewModel.showCPUUsage, name: "CPU Usage", icon: "cpu")
                widgetToggle(isOn: $viewModel.showBrightness, name: "Brightness", icon: "sun.max.fill")
                widgetToggle(isOn: $viewModel.showVolume, name: "Volume", icon: "speaker.wave.2.fill")
                widgetToggle(isOn: $viewModel.showChargingStatus, name: "Charging Status", icon: "bolt.fill")
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
            Text("You can only enable \(widgetLimit) status bar widgets at a time. Please disable one before enabling \(attemptedWidget).")
        }
    }
}
