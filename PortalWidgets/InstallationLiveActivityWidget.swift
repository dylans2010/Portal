import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Installation Live Activity Widget

@available(iOS 16.2, *)
struct InstallationLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: InstallationActivityAttributes.self) { context in
            InstallationLiveActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
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

    private var settings: LiveActivitySettings {
        context.attributes.settings
    }

    private var progressGreen: Color { InstallationWidgetUI.progressTint }
    private var trackColor: Color { Color.gray.opacity(InstallationWidgetUI.trackBackgroundOpacity) }

    private var primaryTextColor: Color {
        settings.textColor?.color ?? .primary
    }

    private var secondaryTextColor: Color {
        (settings.textColor?.color ?? .secondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let iconData = context.attributes.appIcon,
                   let uiImage = UIImage(data: iconData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: settings.iconSize.size,
                               height: settings.iconSize.size)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    placeholderIcon
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.appName)
                        .font(fontFor(.subheadline, settings: settings))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: context.state.status.icon)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(context.state.status.color)

                        Text(context.state.status.rawValue)
                            .font(fontFor(.caption2, settings: settings))
                            .foregroundColor(secondaryTextColor)
                    }
                }

                Spacer()

                Text(context.state.progressPercentage)
                    .font(.system(size: InstallationWidgetUI.lockProgressFontSize, weight: .bold, design: widgetFontDesign(for: settings.fontFamily)))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(settings.accentColor.color.opacity(InstallationWidgetUI.badgeBackgroundOpacity)))
            }

            HStack(spacing: 8) {
                progressBar(context: context, progressColor: progressGreen, trackColor: trackColor)
            }

            if settings.detailDensity != .minimal {
                detailsView(context: context)
            }
        }
        .padding(14)
        .liveActivityBackground(settings: settings)
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
        .frame(width: settings.iconSize.size,
               height: settings.iconSize.size)
    }

    private func detailsView(context: ActivityViewContext<InstallationActivityAttributes>) -> some View {
        HStack(spacing: 6) {
            Text("\(context.state.formattedBytesDownloaded) / \(context.state.formattedTotalBytes)")
                .lineLimit(1)
            if let speed = context.state.formattedSpeed {
                Text("• \(speed)")
                    .lineLimit(1)
            }
            if settings.showEstimatedTime, let eta = context.state.formattedTimeRemaining {
                Text("• \(eta)")
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .font(fontFor(.caption2, settings: settings))
        .foregroundColor(secondaryTextColor)
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
                .frame(width: 34, height: 34)
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
            .frame(width: 34, height: 34)
        }
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityExpandedTrailing: View {
    let context: ActivityViewContext<InstallationActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.state.progressPercentage)
                .font(.system(size: InstallationWidgetUI.expandedProgressFontSize, weight: .bold, design: widgetFontDesign(for: context.attributes.settings.fontFamily)))
                .foregroundColor(context.attributes.settings.accentColor.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(context.attributes.settings.accentColor.color.opacity(InstallationWidgetUI.badgeBackgroundOpacity)))

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
        VStack(spacing: 4) {
            HStack {
                Text(context.attributes.appName)
                    .font(fontFor(.subheadline, settings: context.attributes.settings))
                    .lineLimit(1)

                Spacer()
            }

            HStack(spacing: 4) {
                Image(systemName: context.state.status.icon)
                    .font(.system(size: 10, weight: .semibold))
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
    private var progressGreen: Color { InstallationWidgetUI.progressTint }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                progressBar(context: context, progressColor: progressGreen, trackColor: Color.gray.opacity(InstallationWidgetUI.trackBackgroundOpacity))

                if let speed = context.state.formattedSpeed {
                    Text(speed)
                        .font(fontFor(.caption2, settings: context.attributes.settings))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityCompactLeading: View {
    let context: ActivityViewContext<InstallationActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(context.state.status.color.opacity(0.2))
            Image(systemName: context.state.status.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(context.state.status.color)
        }
        .frame(width: 22, height: 22)
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityCompactTrailing: View {
    let context: ActivityViewContext<InstallationActivityAttributes>

    var body: some View {
        Text(context.state.progressPercentage)
            .font(.system(size: InstallationWidgetUI.compactProgressFontSize, weight: .semibold, design: widgetFontDesign(for: context.attributes.settings.fontFamily)))
            .monospacedDigit()
            .foregroundColor(context.attributes.settings.accentColor.color)
    }
}

@available(iOS 16.2, *)
struct InstallationLiveActivityMinimal: View {
    let context: ActivityViewContext<InstallationActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .fill(context.state.status.color.opacity(0.2))
            Image(systemName: context.state.status.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(context.state.status.color)
        }
        .frame(width: 22, height: 22)
    }
}

// MARK: - Extensions & Helper Views

@available(iOS 16.2, *)
extension View {
    @ViewBuilder
    func liveActivityBackground(settings: LiveActivitySettings) -> some View {
        switch settings.backgroundTexture {
        case .blur:
            self.background(.ultraThinMaterial)
        case .material:
            self.background(.thinMaterial)
        case .solid:
            self.background(Color(uiColor: .systemBackground))
        case .gradient:
            self.background(
                gradientView(settings: settings.gradientSettings, accentColor: settings.accentColor.color)
            )
        case .glass:
            self.background(
                glassView(settings: settings.glassSettings, accentColor: settings.accentColor.color)
            )
        }
    }

    @ViewBuilder
    private func gradientView(settings: GradientSettings, accentColor: Color) -> some View {
        let colors: [Color] = (0..<settings.colorCount).map { i in
            accentColor.opacity(1.0 - Double(i) * 0.15)
        }

        switch settings.pattern {
        case .linear:
            LinearGradient(colors: colors,
                           startPoint: settings.direction == .topToBottom ? .top : (settings.direction == .leftToRight ? .leading : .topLeading),
                           endPoint: settings.direction == .topToBottom ? .bottom : (settings.direction == .leftToRight ? .trailing : .bottomTrailing))
        case .radial:
            RadialGradient(colors: colors, center: .center, startRadius: 0, endRadius: 200)
        case .angular:
            AngularGradient(colors: colors, center: .center)
        }
    }

    @ViewBuilder
    private func glassView(settings: GlassSettings, accentColor: Color) -> some View {
        ZStack {
            if settings.isTinted {
                accentColor.opacity(settings.intensity * 0.2)
            }

            Color.white.opacity(0.05)
                .blur(radius: settings.glassEffectAmount * 15)

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.8 + (settings.glassEffectAmount * 0.2))
        }
    }
}

// MARK: - Helper Functions

private enum InstallationWidgetUI {
    static let badgeBackgroundOpacity: Double = 0.15
    static let trackBackgroundOpacity: Double = 0.22
    static let progressTint = Color(red: 0.18, green: 0.8, blue: 0.44)
    static let lockProgressFontSize: CGFloat = 15
    static let expandedProgressFontSize: CGFloat = 16
    static let compactProgressFontSize: CGFloat = 12
}

@available(iOS 16.2, *)
private func progressBar(context: ActivityViewContext<InstallationActivityAttributes>, progressColor: Color, trackColor: Color) -> some View {
    GeometryReader { geometry in
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .fill(trackColor)

            RoundedRectangle(cornerRadius: 4)
                .fill(progressColor)
                .frame(width: min(geometry.size.width, max(0, geometry.size.width * CGFloat(min(1.0, context.state.progress)))))
                .animation(animationFor(context.attributes.settings.animationStyle), value: context.state.progress)
        }
    }
    .frame(height: 8)
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

private func widgetFontDesign(for family: LiveActivitySettings.FontFamily) -> Font.Design {
    switch family {
    case .system: return .default
    case .rounded: return .rounded
    case .monospaced: return .monospaced
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
