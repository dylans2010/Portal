import SwiftUI

// MARK: - Left Panel: Structure & Visibility
struct StructureVisibilityPanel: View {
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
        return count
    }
    
    var body: some View {
        List {
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.showCustomText },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 2 {
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
                
                Toggle(isOn: Binding(
                    get: { viewModel.showSFSymbol },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 2 {
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
                
                Toggle(isOn: Binding(
                    get: { viewModel.showTime },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 2 {
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
                
                Toggle(isOn: Binding(
                    get: { viewModel.showDate },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 2 {
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
                
                Toggle(isOn: Binding(
                    get: { viewModel.showBattery },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 2 {
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
            } header: {
                Label("Widgets", systemImage: "square.grid.2x2")
            } footer: {
                Text("Enable up to 2 widgets. Currently \(enabledWidgetCount) of 2.")
                    .foregroundStyle(enabledWidgetCount >= 2 ? .orange : .secondary)
            }
            
            Section {
                Toggle(isOn: Binding(
                    get: { viewModel.showNetworkStatus },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 2 {
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
                
                Toggle(isOn: Binding(
                    get: { viewModel.showMemoryUsage },
                    set: { newValue in
                        if newValue && enabledWidgetCount >= 2 {
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
            } header: {
                Label("System Info", systemImage: "info.circle")
            }
            
            Section {
                Button {
                    showSavedStyles = true
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(.blue)
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
                            .foregroundStyle(.purple)
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
            } header: {
                Label("System", systemImage: "gearshape")
            }
        }
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
            Text("You can only enable 2 status bar options at a time. Please disable one of the currently enabled options before enabling '\(attemptedWidget)'.")
        }
    }
}
