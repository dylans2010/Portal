//
//  ExperimentalSettingsView.swift
//  Portal
//
//  Experimental UI redesigned Settings view
//

import SwiftUI

struct ExperimentalSettingsView: View {
    @State private var developerTapCount = 0
    @State private var lastTapTime: Date?
    @State private var showDeveloperConfirmation = false
    @AppStorage("isDeveloperModeEnabled") private var isDeveloperModeEnabled = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ExperimentalUITheme.Spacing.lg) {
                    // Hero Header
                    ExperimentalHeroHeader(
                        title: "Settings",
                        subtitle: "Customize your experience",
                        icon: "gearshape.2"
                    )
                    .onTapGesture {
                        handleDeveloperModeTap()
                    }
                    
                    // Profile Card
                    ExperimentalProfileCard()
                    
                    // Settings Sections
                    VStack(spacing: ExperimentalUITheme.Spacing.md) {
                        ExperimentalSettingsSection(
                            title: "Appearance",
                            items: [
                                SettingItem(icon: "paintbrush.fill", title: "Theme", subtitle: "Light"),
                                SettingItem(icon: "textformat.size", title: "Text Size", subtitle: "Default")
                            ]
                        )
                        
                        ExperimentalSettingsSection(
                            title: "Features",
                            items: [
                                SettingItem(icon: "checkmark.seal.fill", title: "Certificates", subtitle: nil),
                                SettingItem(icon: "signature", title: "Signing Options", subtitle: nil),
                                SettingItem(icon: "archivebox.fill", title: "Archive & Compression", subtitle: nil),
                                SettingItem(icon: "arrow.down.circle.fill", title: "Installation", subtitle: nil)
                            ]
                        )
                        
                        ExperimentalSettingsSection(
                            title: "About",
                            items: [
                                SettingItem(icon: "info.circle.fill", title: "Version", subtitle: "1.0.0"),
                                SettingItem(icon: "heart.fill", title: "Support", subtitle: nil)
                            ]
                        )
                        
                        if isDeveloperModeEnabled {
                            ExperimentalSettingsSection(
                                title: "Developer",
                                items: [
                                    SettingItem(icon: "hammer.fill", title: "Developer Tools", subtitle: nil)
                                ]
                            )
                        }
                    }
                    .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
        .alert("Enable Developer Mode", isPresented: $showDeveloperConfirmation) {
            Button("Cancel", role: .cancel) {
                developerTapCount = 0
            }
            Button("Enable", role: .none) {
                isDeveloperModeEnabled = true
                developerTapCount = 0
                HapticsManager.shared.success()
                AppLogManager.shared.info("Developer mode enabled", category: "Settings")
            }
        } message: {
            Text("Developer mode provides advanced tools and diagnostics. This is intended for developers and advanced users only. Are you sure you want to enable it?")
        }
    }
    
    private func handleDeveloperModeTap() {
        let now = Date()
        
        if let lastTap = lastTapTime, now.timeIntervalSince(lastTap) > 5.0 {
            developerTapCount = 0
        }
        
        lastTapTime = now
        developerTapCount += 1
        
        if developerTapCount >= 5 && developerTapCount < 10 {
            HapticsManager.shared.softImpact()
        }
        
        if developerTapCount >= 10 {
            showDeveloperConfirmation = true
        }
    }
}

// MARK: - Profile Card
struct ExperimentalProfileCard: View {
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(ExperimentalUITheme.Gradients.primary)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Feather User")
                    .font(ExperimentalUITheme.Typography.headline)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Text("Free Plan")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(ExperimentalUITheme.Colors.accentPrimary.opacity(0.15))
                    )
            }
        }
        .padding(ExperimentalUITheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                .fill(ExperimentalUITheme.Colors.cardBackground)
                .shadow(
                    color: ExperimentalUITheme.Shadow.sm.color,
                    radius: ExperimentalUITheme.Shadow.sm.radius,
                    x: ExperimentalUITheme.Shadow.sm.x,
                    y: ExperimentalUITheme.Shadow.sm.y
                )
        )
        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
    }
}

// MARK: - Settings Section
struct ExperimentalSettingsSection: View {
    let title: String
    let items: [SettingItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.sm) {
            Text(title)
                .font(ExperimentalUITheme.Typography.title3)
                .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { index in
                    ExperimentalSettingRow(item: items[index])
                    
                    if index < items.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                    .fill(ExperimentalUITheme.Colors.cardBackground)
                    .shadow(
                        color: ExperimentalUITheme.Shadow.sm.color,
                        radius: ExperimentalUITheme.Shadow.sm.radius,
                        x: ExperimentalUITheme.Shadow.sm.x,
                        y: ExperimentalUITheme.Shadow.sm.y
                    )
            )
        }
    }
}

// MARK: - Setting Item Model
struct SettingItem {
    let icon: String
    let title: String
    let subtitle: String?
}

// MARK: - Setting Row
struct ExperimentalSettingRow: View {
    let item: SettingItem
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: ExperimentalUITheme.Spacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.sm)
                        .fill(ExperimentalUITheme.Gradients.accent.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                }
                
                // Title
                Text(item.title)
                    .font(ExperimentalUITheme.Typography.callout)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Spacer()
                
                // Subtitle or Chevron
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(ExperimentalUITheme.Typography.callout)
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ExperimentalUITheme.Colors.textTertiary)
            }
            .padding(ExperimentalUITheme.Spacing.md)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
