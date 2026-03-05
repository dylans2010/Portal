import SwiftUI

struct PortalTopView: View {
    @AppStorage("Feather.portalTopViewEnabled") private var portalTopViewEnabled: Bool = true
    @AppStorage("Feather.portalTopViewColor") private var portalTopViewColor: String = "#0077BE"
    @AppStorage("Feather.portalTopViewStyle") private var portalTopViewStyle: Int = 0 // 0: Ultra Thin, 1: Thin, 2: Regular, 3: Thick
    @AppStorage("Feather.portalTopViewTitle") private var portalTopViewTitle: String = "Portal"
    @AppStorage("Feather.portalTopViewTextColor") private var portalTopViewTextColor: String = "#FFFFFF"
    @AppStorage("Feather.portalTopViewShowIcon") private var portalTopViewShowIcon: Bool = true
    @AppStorage("Feather.portalTopViewShowVersion") private var portalTopViewShowVersion: Bool = true

    private var material: Material {
        switch portalTopViewStyle {
        case 1: return .thinMaterial
        case 2: return .regularMaterial
        case 3: return .thickMaterial
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

                                    // Subtle Depth Layer
                                    Capsule()
                                        .fill(LinearGradient(colors: [Color(hex: portalTopViewColor).opacity(0.1), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color(hex: portalTopViewColor).opacity(0.5), Color.blue.opacity(0.3), Color(hex: portalTopViewColor).opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
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
                    .frame(height: max(safeAreaTop, 20))

                    Spacer()
                }
            }
        }
        .allowsHitTesting(false)
        .zIndex(1000)
        .ignoresSafeArea(edges: .top)
    }
}
