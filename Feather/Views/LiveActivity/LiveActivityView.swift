import SwiftUI
import ActivityKit
import WidgetKit

@available(iOS 16.1, *)
struct InstallationLiveActivityView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let context: ActivityViewContext<InstallationActivityAttributes>

    private var settings: LiveActivitySettings {
        context.attributes.settings
    }

    private var currentStep: Int {
        switch context.state.status {
        case .preparing, .downloading, .unzipping:
            return 1
        case .signing, .rezipping:
            return 2
        case .installing, .verifying, .completed, .failed, .paused, .cancelled:
            return 3
        }
    }

    private var totalSteps: Int { 3 }

    private var accentColor: Color {
        settings.accentColor.color
    }

    private var progressGreen: Color {
        Color(red: 0.18, green: 0.8, blue: 0.44)
    }

    private var trackColor: Color {
        Color.white.opacity(0.15)
    }

    private var primaryTextColor: Color {
        settings.textColor?.color ?? .white
    }

    private var secondaryTextColor: Color {
        (settings.textColor?.color ?? .white).opacity(0.6)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                appIconView
                    .frame(width: settings.iconSize.size, height: settings.iconSize.size)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.appName)
                        .font(fontFor(.headline, settings: settings))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: context.state.status.icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(context.state.status.color)
                        Text(context.state.status.rawValue)
                            .font(fontFor(.caption2, settings: settings))
                            .foregroundColor(secondaryTextColor)
                    }
                }

                Spacer()

                if settings.showStatusBadge {
                    HStack(spacing: 4) {
                        Image(systemName: context.state.status.icon)
                            .font(.system(size: 10, weight: .bold))
                        Text(context.state.status.rawValue)
                            .font(fontFor(.caption2, settings: settings))
                    }
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
            }

            HStack(spacing: 10) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(trackColor)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressGreen)
                            .frame(width: min(geometry.size.width, max(0, geometry.size.width * CGFloat(min(1.0, context.state.progress)))))
                            .animation(animationFor(settings.animationStyle), value: context.state.progress)
                    }
                }
                .frame(height: 8)

                Text(context.state.progressPercentage)
                    .font(.system(size: 16, weight: .black, design: liveActivityFontDesign(for: settings.fontFamily)))
                    .foregroundColor(primaryTextColor)
                    .frame(minWidth: 44, alignment: .trailing)
            }

            HStack {
                Spacer()
                Text("Step \(currentStep)/\(totalSteps)")
                    .font(.system(size: 11, weight: .medium, design: liveActivityFontDesign(for: settings.fontFamily)))
                    .foregroundColor(secondaryTextColor)
                Spacer()
            }
        }
        .padding(16)
        .background {
            if #available(iOS 16.2, *) {
                liveActivityBackground(settings: settings)
            } else {
                Color.clear.background(.ultraThinMaterial)
            }
        }
    }

    private var appIconView: some View {
        Group {
            if let iconData = context.attributes.appIcon,
               let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Color.white.opacity(0.1)
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

fileprivate func liveActivityFontDesign(for family: LiveActivitySettings.FontFamily) -> Font.Design {
    switch family {
    case .system: return .default
    case .rounded: return .rounded
    case .monospaced: return .monospaced
    }
}

fileprivate func fontFor(_ textStyle: Font.TextStyle, settings: LiveActivitySettings) -> Font {
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

fileprivate func animationFor(_ style: LiveActivitySettings.AnimationStyle) -> Animation? {
    switch style {
    case .none:
        return nil
    case .smooth:
        return .easeInOut(duration: 0.3)
    case .spring:
        return .spring(response: 0.3, dampingFraction: 0.8)
    }
}

@available(iOS 16.2, *)
extension InstallationLiveActivityView {
    @ViewBuilder
    func liveActivityBackground(settings: LiveActivitySettings) -> some View {
        switch settings.backgroundTexture {
        case .blur:
            Color.clear.background(.ultraThinMaterial)
        case .material:
            Color.clear.background(.thinMaterial)
        case .solid:
            Color(uiColor: .systemBackground)
        case .gradient:
            liveActivityGradientView(settings: settings.gradientSettings, accentColor: settings.accentColor.color)
        case .glass:
            liveActivityGlassView(settings: settings.glassSettings, accentColor: settings.accentColor.color)
        }
    }

    @ViewBuilder
    private func liveActivityGradientView(settings: GradientSettings, accentColor: Color) -> some View {
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
    private func liveActivityGlassView(settings: GlassSettings, accentColor: Color) -> some View {
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
