import SwiftUI
import Combine

struct PortalTopView: View {
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
        Group {
            if !portalTopViewEnabled {
                EmptyView()
            } else {
                GeometryReader { geometry in
                    let safeAreaTop = geometry.safeAreaInsets.top
                    let dynamicIslandThreshold: CGFloat = 54
                    let hasDynamicIsland = safeAreaTop >= dynamicIslandThreshold

                    // When screenshotting, we move the pill into the Dynamic Island area (topClearance = 0)
                    // and ignore safe areas. Normally, we respect safe area (handled by the .ignoresSafeArea modifier below)
                    // and shift it below the island to be visible.
                    let topClearance = isScreenshotting ? 0 : (hasDynamicIsland ? safeAreaTop + 14 : max((safeAreaTop - 30) / 2, 6))

                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        HStack {
                            Spacer()

                            // Premium Floating Pill
                            HStack(spacing: 10) {
                                if portalTopViewShowIcon,
                                   let iconName = Bundle.main.iconFileName,
                                   let icon = UIImage(named: iconName) {
                                    Image(uiImage: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 18, height: 18)
                                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background {
                                ZStack {
                                    Capsule()
                                        .fill(material)

                                    // Gradient or solid color depth layer
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
                                            .fill(LinearGradient(colors: [Color(hex: portalTopViewColor).opacity(0.1), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    }

                                    // Glass effect overlay
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
                                                    : [Color(hex: portalTopViewColor).opacity(0.5), Color.blue.opacity(0.3), Color(hex: portalTopViewColor).opacity(0.1)],
                                                startPoint: gradientStartPoint,
                                                endPoint: gradientEndPoint
                                            ),
                                            lineWidth: 0.5
                                        )
                                }
                            }

                            Spacer()
                        }
                        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)

                        Spacer(minLength: 0)
                    }
                    // On Dynamic Island devices the pill sits below the island;
                    // on notch / no-notch devices it is vertically centred inside
                    // the top inset as before.
                    .frame(height: max(safeAreaTop + 70, 88))
                    .padding(.top, topClearance)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isScreenshotting)

                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
        .zIndex(isScreenshotting ? 999999 : 1000)
        .ignoresSafeArea(isScreenshotting ? .all : [], edges: .top)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isScreenshotting = true
            }
            // Return to normal state after capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isScreenshotting = false
                }
            }
        }
    }
}
