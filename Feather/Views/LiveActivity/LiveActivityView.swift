import SwiftUI
import ActivityKit
import WidgetKit

@available(iOS 16.1, *)
struct InstallationLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: InstallationActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenActivityLayout(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded region
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingContent(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingContent(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterContent(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomContent(context: context)
                }
            } compactLeading: {
                CompactLeadingContent(context: context)
            } compactTrailing: {
                CompactTrailingContent(context: context)
            } minimal: {
                MinimalContent(context: context)
            }
        }
    }
}

// MARK: - Lock Screen Layout
@available(iOS 16.1, *)
struct LockScreenActivityLayout: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                IconRenderer(iconData: context.attributes.appIcon, size: iconDimension)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.appName)
                        .font(typeface)
                        .fontWeight(typefaceWeight)
                    
                    HStack(spacing: 6) {
                        Image(systemName: context.state.status.icon)
                            .font(.caption2)
                        Text(context.state.status.rawValue)
                            .font(.caption)
                    }
                    .foregroundColor(context.state.status.color)
                }
                
                Spacer()
                
                Text(context.state.progressPercentage)
                    .font(.title3.bold())
                    .foregroundColor(accentTint)
            }
            
            ProgressRenderer(
                value: context.state.progress,
                style: context.attributes.progressBarStyle,
                color: accentTint
            )
            
            if context.attributes.detailDensity != "minimal" {
                HStack {
                    Text("\(context.state.formattedBytesDownloaded) / \(context.state.formattedTotalBytes)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let speed = context.state.formattedDownloadSpeed {
                        Text(speed)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if let eta = context.state.formattedTimeRemaining {
                        Text(eta)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .activityBackgroundTint(backgroundTint)
    }
    
    private var iconDimension: CGFloat {
        switch context.attributes.iconSize {
        case "small": return 32
        case "large": return 48
        default: return 40
        }
    }
    
    private var typeface: Font {
        switch context.attributes.fontFamily {
        case "rounded": return .system(size: 15, design: .rounded)
        case "monospaced": return .system(size: 15, design: .monospaced)
        case "serif": return .system(size: 15, design: .serif)
        default: return .system(size: 15)
        }
    }
    
    private var typefaceWeight: Font.Weight {
        switch context.attributes.fontWeight {
        case "bold": return .bold
        case "semibold": return .semibold
        case "regular": return .regular
        default: return .medium
        }
    }
    
    private var accentTint: Color {
        Color(hex: context.attributes.accentColor) ?? .blue
    }
    
    private var backgroundTint: Color {
        switch context.attributes.backgroundMaterial {
        case "thin": return Color.black.opacity(0.05)
        case "thick": return Color.black.opacity(0.15)
        case "ultraThin": return Color.black.opacity(0.02)
        case "ultraThick": return Color.black.opacity(0.25)
        default: return Color.black.opacity(0.1)
        }
    }
}

// MARK: - Dynamic Island Regions
@available(iOS 16.1, *)
struct ExpandedLeadingContent: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        IconRenderer(iconData: context.attributes.appIcon, size: 48)
    }
}

@available(iOS 16.1, *)
struct ExpandedTrailingContent: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.state.progressPercentage)
                .font(.title2.bold())
                .foregroundColor(Color(hex: context.attributes.accentColor) ?? .blue)
            
            if let speed = context.state.formattedDownloadSpeed {
                Text(speed)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 16.1, *)
struct ExpandedCenterContent: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            Text(context.attributes.appName)
                .font(.headline)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                Image(systemName: context.state.status.icon)
                    .font(.caption)
                Text(context.state.status.rawValue)
                    .font(.caption)
            }
            .foregroundColor(context.state.status.color)
        }
    }
}

@available(iOS 16.1, *)
struct ExpandedBottomContent: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressRenderer(
                value: context.state.progress,
                style: context.attributes.progressBarStyle,
                color: Color(hex: context.attributes.accentColor) ?? .blue
            )
            
            if context.attributes.detailDensity == "detailed" {
                HStack {
                    Text(context.state.formattedBytesDownloaded)
                        .font(.caption2)
                    Spacer()
                    if let eta = context.state.formattedTimeRemaining {
                        Text(eta)
                            .font(.caption2)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 16.1, *)
struct CompactLeadingContent: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        Image(systemName: context.state.status.icon)
            .foregroundColor(context.state.status.color)
    }
}

@available(iOS 16.1, *)
struct CompactTrailingContent: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        Text(context.state.progressPercentage)
            .font(.caption.bold())
            .foregroundColor(Color(hex: context.attributes.accentColor) ?? .blue)
    }
}

@available(iOS 16.1, *)
struct MinimalContent: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    var body: some View {
        Image(systemName: context.state.status.icon)
            .foregroundColor(context.state.status.color)
    }
}

// MARK: - Helper Views
@available(iOS 16.1, *)
struct IconRenderer: View {
    let iconData: Data?
    let size: CGFloat
    
    var body: some View {
        Group {
            if let data = iconData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}

@available(iOS 16.1, *)
struct ProgressRenderer: View {
    let value: Double
    let style: String
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(progressFill)
                    .frame(width: geo.size.width * CGFloat(value))
                    .animation(animationCurve, value: value)
            }
        }
        .frame(height: 6)
    }
    
    private var progressFill: some ShapeStyle {
        if style == "gradient" {
            return AnyShapeStyle(LinearGradient(
                colors: [color.opacity(0.8), color],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(color)
        }
    }
    
    private var animationCurve: Animation {
        switch style {
        case "spring": return .spring(response: 0.4, dampingFraction: 0.7)
        case "instant": return .linear(duration: 0)
        default: return .easeInOut(duration: 0.3)
        }
    }
}
