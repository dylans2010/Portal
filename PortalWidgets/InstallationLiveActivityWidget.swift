import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Installation Live Activity Widget

@available(iOS 16.2, *)
struct InstallationLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: InstallationActivityAttributes.self) { context in
            // Lock Screen view
            InstallationLiveActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    InstallationLiveActivityExpandedLeading(context: context)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    InstallationLiveActivityExpandedTrailing(context: context)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    InstallationLiveActivityExpandedCenter(context: context)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    InstallationLiveActivityExpandedBottom(context: context)
                }
            } compactLeading: {
                InstallationLiveActivityCompactLeading(context: context)
            } compactTrailing: {
                InstallationLiveActivityCompactTrailing(context: context)
            } minimal: {
                InstallationLiveActivityMinimal(context: context)
            }
        }
    }
}

// MARK: - Lock Screen View

@available(iOS 16.2, *)
struct InstallationLiveActivityLockScreenView: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // App Icon
                if let iconData = context.attributes.appIcon,
                   let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: context.attributes.settings.iconSize.size,
                               height: context.attributes.settings.iconSize.size)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    placeholderIcon
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.appName)
                        .font(fontFor(.body, settings: context.attributes.settings))
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Image(systemName: context.state.status.icon)
                            .font(.system(size: 11))
                            .foregroundColor(context.state.status.color)
                        
                        Text(context.state.status.rawValue)
                            .font(fontFor(.caption, settings: context.attributes.settings))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(context.state.progressPercentage)
                    .font(fontFor(.title3, settings: context.attributes.settings))
                    .foregroundColor(context.attributes.settings.accentColor.color)
            }
            
            // Progress Bar
            progressBar(context: context)
            
            // Details based on density
            if context.attributes.settings.detailDensity != .minimal {
                detailsView(context: context)
            }
        }
        .padding(16)
    }
    
    private var placeholderIcon: some View {
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
        .frame(width: context.attributes.settings.iconSize.size,
               height: context.attributes.settings.iconSize.size)
    }
    
    private func detailsView(context: ActivityViewContext<InstallationActivityAttributes>) -> some View {
        VStack(spacing: 6) {
            HStack {
                if context.attributes.settings.detailDensity == .detailed {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(context.state.formattedBytesDownloaded) / \(context.state.formattedTotalBytes)")
                            .font(fontFor(.caption2, settings: context.attributes.settings))
                            .foregroundColor(.secondary)
                        
                        if let speed = context.state.formattedSpeed {
                            Text(speed)
                                .font(fontFor(.caption2, settings: context.attributes.settings))
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("\(context.state.formattedBytesDownloaded) / \(context.state.formattedTotalBytes)")
                        .font(fontFor(.caption2, settings: context.attributes.settings))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let eta = context.state.eta {
                    Text("ETA: \(eta)")
                        .font(fontFor(.caption2, settings: context.attributes.settings))
                        .foregroundColor(.secondary)
                }
            }
            
            // Auto-sign indicator
            if context.state.isAutoSigning {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("Auto-signing enabled")
                        .font(fontFor(.caption2, settings: context.attributes.settings))
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Dynamic Island Views

@available(iOS 16.2, *)
struct InstallationLiveActivityExpandedLeading: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        if let iconData = context.attributes.appIcon,
           let uiImage = UIImage(data: iconData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
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
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
        }
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityExpandedTrailing: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(context.state.progressPercentage)
                .font(fontFor(.title3, settings: context.attributes.settings))
                .foregroundColor(context.attributes.settings.accentColor.color)
            
            if let timeRemaining = context.state.formattedTimeRemaining {
                Text(timeRemaining)
                    .font(fontFor(.caption2, settings: context.attributes.settings))
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityExpandedCenter: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(context.attributes.appName)
                    .font(fontFor(.headline, settings: context.attributes.settings))
                    .lineLimit(1)
                
                Spacer()
            }
            
            HStack(spacing: 4) {
                Image(systemName: context.state.status.icon)
                    .font(.system(size: 11))
                    .foregroundColor(context.state.status.color)
                
                Text(context.state.status.rawValue)
                    .font(fontFor(.caption, settings: context.attributes.settings))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityExpandedBottom: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            progressBar(context: context)
            
            if context.attributes.settings.detailDensity != .minimal {
                HStack {
                    Text("\(context.state.formattedBytesDownloaded) / \(context.state.formattedTotalBytes)")
                        .font(fontFor(.caption2, settings: context.attributes.settings))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let speed = context.state.formattedSpeed {
                        Text(speed)
                            .font(fontFor(.caption2, settings: context.attributes.settings))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityCompactLeading: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        Image(systemName: context.state.status.icon)
            .foregroundColor(context.state.status.color)
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityCompactTrailing: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        Text(context.state.progressPercentage)
            .font(fontFor(.caption, settings: context.attributes.settings))
            .foregroundColor(context.attributes.settings.accentColor.color)
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityMinimal: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        Image(systemName: context.state.status.icon)
            .foregroundColor(context.state.status.color)
    }
}

// MARK: - Helper Functions

@available(iOS 16.2, *)
private func progressBar(context: ActivityViewContext<InstallationActivityAttributes>) -> some View {
    GeometryReader { geometry in
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: progressBarRadius(for: context.attributes.settings.progressBarStyle))
                .fill(Color.gray.opacity(0.2))
            
            // Progress
            progressFill(settings: context.attributes.settings, statusColor: context.state.status.color)
                .frame(width: geometry.size.width * CGFloat(context.state.progress))
                .animation(animationFor(context.attributes.settings.animationStyle), value: context.state.progress)
        }
    }
    .frame(height: 6)
}

@available(iOS 16.2, *)
private func progressFill(settings: LiveActivitySettings, statusColor: Color) -> some View {
    Group {
        switch settings.progressBarStyle {
        case .solid:
            RoundedRectangle(cornerRadius: 4)
                .fill(settings.accentColor.color)
        case .gradient:
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [settings.accentColor.color.opacity(0.8), settings.accentColor.color],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        case .capsule:
            Capsule()
                .fill(settings.accentColor.color)
        }
    }
}

private func progressBarRadius(for style: LiveActivitySettings.ProgressBarStyle) -> CGFloat {
    switch style {
    case .solid, .gradient:
        return 4
    case .capsule:
        return 3
    }
}

private func fontFor(_ textStyle: Font.TextStyle, settings: LiveActivitySettings) -> Font {
    let weight = settings.fontWeight.fontWeight
    
    switch settings.fontFamily {
    case .system:
        return .system(textStyle, design: .default, weight: weight)
    case .rounded:
        return .system(textStyle, design: .rounded, weight: weight)
    case .monospaced:
        return .system(textStyle, design: .monospaced, weight: weight)
    }
}

private func animationFor(_ style: LiveActivitySettings.AnimationStyle) -> Animation? {
    switch style {
    case .none:
        return nil
    case .smooth:
        return .easeInOut(duration: 0.3)
    case .spring:
        return .spring(response: 0.3, dampingFraction: 0.8)
    }
}
