// Made by dylan on 2/22/26

import SwiftUI

struct PortalTopView: View {
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    HStack(spacing: 10) {
                        if let iconName = Bundle.main.iconFileName,
                           let icon = UIImage(named: iconName) {
                            Image(uiImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 18, height: 18)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }

                        VStack(alignment: .leading, spacing: -1) {
                            Text("Portal")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)

                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "3.0")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .opacity(0.8)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background {
                        ZStack {
                            Capsule()
                                .fill(.ultraThinMaterial)

                            Capsule()
                                .fill(LinearGradient(colors: [Color.accentColor.opacity(0.05), Color.blue.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        }
                        .overlay {
                            Capsule()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.accentColor.opacity(0.5), Color.blue.opacity(0.3), Color.accentColor.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 0.5
                                )
                        }
                    }
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
                    .offset(y: 2)

                    Spacer()
                }
                .frame(height: max(safeAreaTop, 20))

                Spacer()
            }
        }
        .allowsHitTesting(false)
        .zIndex(1000)
        .ignoresSafeArea(edges: .top)
    }
}
