import SwiftUI
import Combine

struct PortalTopView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    @AppStorage("Feather.portalTopViewEnabled") private var portalTopViewEnabled: Bool = true
    @AppStorage("Feather.portalTopViewColor") private var portalTopViewColor: String = "#0077BE"
    @AppStorage("Feather.portalTopViewStyle") private var portalTopViewStyle: Int = 0 // 0: Ultra Thin, 1: Thin, 2: Regular, 3: Thick
    @AppStorage("Feather.portalTopViewTitle") private var portalTopViewTitle: String = "Portal"
    @AppStorage("Feather.portalTopViewTextColor") private var portalTopViewTextColor: String = "#FFFFFF"
    @AppStorage("Feather.portalTopViewShowIcon") private var portalTopViewShowIcon: Bool = true
    @AppStorage("Feather.portalTopViewShowVersion") private var portalTopViewShowVersion: Bool = true
    @AppStorage("Feather.portalTopViewUseGradient") private var useGradient: Bool = false
    @AppStorage("Feather.portalTopViewGradientColor") private var gradientEndColor: String = "#5856D6"
    @AppStorage("Feather.portalTopViewGradientDirection") private var gradientDirection: Int = 0
    @AppStorage("Feather.portalTopViewGlassEffect") private var glassEffect: Bool = false
    @AppStorage("Feather.portalTopViewGlassIntensity") private var glassIntensity: Int = 0
    @AppStorage("feature_forceHideTopView") private var forceHideTopView: Bool = false

    @State private var isScreenshotting = false
    private var material: Material {
        switch portalTopViewStyle {
        case 1: return .thinMaterial
        case 2: return .regularMaterial
        case 3: return .thickMaterial
        default: return .ultraThinMaterial
        }
    }

    private var gradientStartPoint: UnitPoint {
        switch gradientDirection {
        case 1: return .top      // Vertical
        case 2: return .topLeading // Diagonal
        default: return .leading  // Horizontal
        }
    }

    private var gradientEndPoint: UnitPoint {
        switch gradientDirection {
        case 1: return .bottom
        case 2: return .bottomTrailing
        default: return .trailing
        }
    }

    private var glassMaterial: Material {
        switch glassIntensity {
        case 1: return .thinMaterial
        case 2: return .regularMaterial
        default: return .ultraThinMaterial
        }
    }

    var body: some View {
        GeometryReader { geometry in
            if shouldRenderTopView(safeAreaTop: geometry.safeAreaInsets.top) {
                overlayContent(hasDynamicIsland: hasDynamicIsland(safeAreaTop: geometry.safeAreaInsets.top))
                    .allowsHitTesting(false)
                    .zIndex(999_999)
                    .ignoresSafeArea(.all, edges: .top)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            guard portalTopViewEnabled, !forceHideTopView else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isScreenshotting = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.25)) {
                    isScreenshotting = false
                }
            }
        }
    }

    @ViewBuilder
    private func overlayContent(hasDynamicIsland: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                topPill(hasDynamicIsland: hasDynamicIsland)
                Spacer()
            }
            .shadow(color: themeManager.primaryTextColor.opacity(0.12), radius: 12, x: 0, y: 6)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    private func topPill(hasDynamicIsland: Bool) -> some View {
        HStack(spacing: 10) {
            if portalTopViewShowIcon,
               let iconName = Bundle.main.iconFileName,
               let icon = UIImage(named: iconName) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .shadow(color: themeManager.primaryTextColor.opacity(0.1), radius: 2, x: 0, y: 1)
            }

            VStack(alignment: .leading, spacing: -1) {
                Text(portalTopViewTitle.isEmpty ? "Portal" : portalTopViewTitle)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: portalTopViewTextColor))

                if portalTopViewShowVersion {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .opacity(0.8)
                }
            }
        }
        .frame(width: hasDynamicIsland ? 126 : nil, height: hasDynamicIsland ? 37.33 : nil)
        .padding(.horizontal, hasDynamicIsland ? 0 : 14)
        .padding(.vertical, 8)
        .background(pillBackground)
    }

    private var pillBackground: some View {
        ZStack {
            Capsule()
                .fill(material)

            if useGradient {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: portalTopViewColor), Color(hex: gradientEndColor)],
                            startPoint: gradientStartPoint,
                            endPoint: gradientEndPoint
                        )
                    )
                    .opacity(0.45)
            } else {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: portalTopViewColor).opacity(0.1), themeManager.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            if glassEffect {
                Capsule()
                    .fill(glassMaterial)
                    .opacity(glassIntensity == 0 ? 0.3 : (glassIntensity == 1 ? 0.5 : 0.7))
            }
        }
        .overlay {
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: useGradient
                            ? [Color(hex: portalTopViewColor).opacity(0.6), Color(hex: gradientEndColor).opacity(0.4), Color(hex: portalTopViewColor).opacity(0.1)]
                            : [Color(hex: portalTopViewColor).opacity(0.5), themeManager.accentColor.opacity(0.3), Color(hex: portalTopViewColor).opacity(0.1)],
                        startPoint: gradientStartPoint,
                        endPoint: gradientEndPoint
                    ),
                    lineWidth: 0.5
                )
        }
    }

    private func shouldRenderTopView(safeAreaTop: CGFloat) -> Bool {
        portalTopViewEnabled
            && !forceHideTopView
            && isScreenshotting
            && !hasDynamicIsland(safeAreaTop: safeAreaTop)
    }

    private func hasDynamicIsland(safeAreaTop: CGFloat) -> Bool {
        let dynamicIslandThreshold: CGFloat = 51
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        return isPhone && safeAreaTop >= dynamicIslandThreshold
    }
}
