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
        return count
    }
    
    var body: some View {
        List {
            Section {
                Toggle("Show Custom Text", isOn: Binding(
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
                ))
                
                Toggle("Show SF Symbol", isOn: Binding(
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
                ))
                
                Toggle("Show Time", isOn: Binding(
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
                ))
                
                Toggle("Show Battery", isOn: Binding(
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
                ))
            } header: {
                Text("Visibility")
            } footer: {
                Text("You can enable up to 2 status bar options at a time. Currently \(enabledWidgetCount) of 2 enabled.")
                    .foregroundStyle(enabledWidgetCount >= 2 ? .orange : .secondary)
            }
            
            Section(header: Text("Saved Styles")) {
                Button {
                    showSavedStyles = true
                } label: {
                    HStack {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(.blue)
                        Text("Manage Saved Styles")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Layout Configuration")) {
                Button {
                    showConfigureLayouts = true
                } label: {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.blue)
                        Text("Configure Layouts")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("System Integration")) {
                Toggle("Hide Default Status Bar", isOn: $viewModel.hideDefaultStatusBar)
                    .onChange(of: viewModel.hideDefaultStatusBar) { newValue in
                        viewModel.handleHideDefaultStatusBarChange(newValue)
                    }
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
