import SwiftUI
import NimbleViews

/// Settings view for customizing Live Activity appearance and behavior
struct LiveActivitySettingsView: View {
    @AppStorage("liveActivityStyle") private var style: LiveActivityStyle = .modern
    @AppStorage("liveActivityShowTimeRemaining") private var showTimeRemaining: Bool = true
    @AppStorage("liveActivityShowIcon") private var showIcon: Bool = true
    @AppStorage("liveActivityEnabled") private var liveActivityEnabled: Bool = true
    @AppStorage("liveActivityAccentColor") private var accentColor: String = "#007AFF"
    @AppStorage("liveActivityBackgroundMaterial") private var backgroundMaterial: String = "regular"
    @AppStorage("liveActivityFontFamily") private var fontFamily: String = "system"
    @AppStorage("liveActivityFontWeight") private var fontWeight: String = "medium"
    @AppStorage("liveActivityProgressBarStyle") private var progressBarStyle: String = "gradient"
    @AppStorage("liveActivityIconSize") private var iconSize: String = "medium"
    @AppStorage("liveActivityDetailDensity") private var detailDensity: String = "normal"
    @AppStorage("liveActivityAnimationStyle") private var animationStyle: String = "smooth"
    
    @State private var showPreview = false
    @State private var showColorPicker = false
    
    var body: some View {
        NBNavigationView("Live Activity Settings") {
            List {
                enabledSection
                styleSection
                appearanceSection
                displayOptionsSection
                previewSection
                infoSection
            }
            .listStyle(.insetGrouped)
        }
    }
    
    // MARK: - Sections
    
    private var enabledSection: some View {
        Section {
            Toggle(isOn: $liveActivityEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(liveActivityEnabled ? .green : .gray)
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable Live Activities")
                            .font(.body)
                        
                        Text("Show installation progress in Dynamic Island and Lock Screen")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Status")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            if #available(iOS 16.1, *) {
                Text("Live Activities require iOS 16.1 or later.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Live Activities are not available on this iOS version. Requires iOS 16.1+")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private var styleSection: some View {
        Section {
            ForEach(LiveActivityStyle.allCases, id: \.self) { activityStyle in
                Button {
                    withAnimation {
                        style = activityStyle
                        HapticsManager.shared.light()
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: activityStyle.icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(style == activityStyle ? .blue : .gray)
                            .frame(width: 28, height: 28)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activityStyle.rawValue)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Text(activityStyle.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if style == activityStyle {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Style")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Choose how installation progress appears in Live Activities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var appearanceSection: some View {
        Section {
            // Accent Color
            Button {
                showColorPicker.toggle()
                HapticsManager.shared.light()
            } label: {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: accentColor) ?? .blue)
                        .frame(width: 28, height: 28)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accent Color")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Text(accentColor)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            // Background Material
            Picker("Background Material", selection: $backgroundMaterial) {
                Text("Regular").tag("regular")
                Text("Thin").tag("thin")
                Text("Thick").tag("thick")
                Text("Ultra Thin").tag("ultraThin")
                Text("Ultra Thick").tag("ultraThick")
            }
            
            // Font Family
            Picker("Font Family", selection: $fontFamily) {
                Text("System").tag("system")
                Text("Rounded").tag("rounded")
                Text("Monospaced").tag("monospaced")
                Text("Serif").tag("serif")
            }
            
            // Font Weight
            Picker("Font Weight", selection: $fontWeight) {
                Text("Regular").tag("regular")
                Text("Medium").tag("medium")
                Text("Semibold").tag("semibold")
                Text("Bold").tag("bold")
            }
            
            // Progress Bar Style
            Picker("Progress Bar Style", selection: $progressBarStyle) {
                Text("Linear").tag("linear")
                Text("Gradient").tag("gradient")
                Text("Circular").tag("circular")
            }
            
            // Icon Size
            Picker("Icon Size", selection: $iconSize) {
                Text("Small").tag("small")
                Text("Medium").tag("medium")
                Text("Large").tag("large")
            }
            
            // Detail Density
            Picker("Detail Density", selection: $detailDensity) {
                Text("Minimal").tag("minimal")
                Text("Normal").tag("normal")
                Text("Detailed").tag("detailed")
            }
            
            // Animation Style
            Picker("Animation Style", selection: $animationStyle) {
                Text("Smooth").tag("smooth")
                Text("Spring").tag("spring")
                Text("Instant").tag("instant")
            }
        } header: {
            Text("Appearance")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Customize the visual appearance of Live Activities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .sheet(isPresented: $showColorPicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("Choose Accent Color")
                        .font(.title2.bold())
                        .padding(.top)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                        ForEach(["#007AFF", "#FF3B30", "#34C759", "#FF9500", "#AF52DE", "#FF2D55", "#5856D6", "#FFCC00"], id: \.self) { hex in
                            Button {
                                accentColor = hex
                                showColorPicker = false
                                HapticsManager.shared.light()
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex) ?? .blue)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(accentColor == hex ? Color.primary : Color.clear, lineWidth: 3)
                                    )
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showColorPicker = false
                        }
                    }
                }
            }
        }
    }
    
    private var displayOptionsSection: some View {
        Section {
            Toggle(isOn: $showIcon) {
                HStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                    
                    Text("Show App Icon")
                        .font(.body)
                }
            }
            
            Toggle(isOn: $showTimeRemaining) {
                HStack(spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                    
                    Text("Show Time Remaining")
                        .font(.body)
                }
            }
        } header: {
            Text("Display Options")
                .font(.system(size: 11, weight: .semibold))
        } footer: {
            Text("Customize what information is displayed in Live Activities")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var previewSection: some View {
        Section {
            Button {
                showPreview.toggle()
                HapticsManager.shared.light()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.purple)
                        .frame(width: 28, height: 28)
                    
                    Text("Preview Live Activity")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Preview")
                .font(.system(size: 11, weight: .semibold))
        }
        .sheet(isPresented: $showPreview) {
            LiveActivityPreviewView(style: style, showTimeRemaining: showTimeRemaining, showIcon: showIcon)
        }
    }
    
    private var infoSection: some View {
        Section {
            LiveActivityInfoRow(
                icon: "info.circle.fill",
                title: "Dynamic Island",
                description: "On iPhone 14 Pro and later, Live Activities appear in the Dynamic Island"
            )
            
            LiveActivityInfoRow(
                icon: "lock.fill",
                title: "Lock Screen",
                description: "Live Activities also appear on the Lock Screen for all supported devices"
            )
            
            LiveActivityInfoRow(
                icon: "app.badge.fill",
                title: "Background Updates",
                description: "Live Activities can be updated even when Portal is in the background"
            )
        } header: {
            Text("About Live Activities")
                .font(.system(size: 11, weight: .semibold))
        }
    }
}

// MARK: - Supporting Views

private struct LiveActivityInfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.blue)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Preview view for Live Activity styles
struct LiveActivityPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let style: LiveActivityStyle
    let showTimeRemaining: Bool
    let showIcon: Bool
    
    @State private var progress: Double = 0.0
    @State private var isAnimating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Live Activity Preview")
                    .font(.title2.bold())
                    .padding(.top, 20)
                
                Text("This is how your Live Activity will appear during app installations")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Mock Live Activity preview
                mockLiveActivityView
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(uiColor: .secondarySystemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                    .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 3.0)) {
                        isAnimating.toggle()
                        progress = isAnimating ? 1.0 : 0.0
                    }
                    HapticsManager.shared.light()
                } label: {
                    HStack {
                        Image(systemName: isAnimating ? "pause.fill" : "play.fill")
                        Text(isAnimating ? "Reset Animation" : "Start Animation")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            progress = 0.45
        }
    }
    
    private var mockLiveActivityView: some View {
        Group {
            switch style {
            case .modern:
                modernMockView
            case .compact:
                compactMockView
            case .minimal:
                minimalMockView
            }
        }
    }
    
    private var modernMockView: some View {
        HStack(spacing: 12) {
            if showIcon {
                appIconPlaceholder
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Portal")
                    .font(.system(size: 14, weight: .semibold))
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    
                    Text("Downloading")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                progressBar
                
                HStack {
                    Text("45 MB of 100 MB")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if showTimeRemaining {
                        Text("2 min")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(String(format: "%.0f%%", progress * 100))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
        }
        .padding(12)
    }
    
    private var compactMockView: some View {
        HStack(spacing: 10) {
            if showIcon {
                appIconPlaceholder
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Portal")
                    .font(.system(size: 13, weight: .semibold))
                
                progressBar
                
                HStack {
                    Text("Downloading")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", progress * 100))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(10)
    }
    
    private var minimalMockView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Portal")
                    .font(.system(size: 12, weight: .semibold))
                
                Spacer()
                
                Text(String(format: "%.0f%%", progress * 100))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            progressBar
        }
        .padding(8)
    }
    
    private var appIconPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Image(systemName: "app.badge.fill")
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
        .frame(width: 40, height: 40)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.8), .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * CGFloat(progress))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Preview
#Preview {
    LiveActivitySettingsView()
}
