import SwiftUI
import AudioToolbox
import NimbleViews

struct SuccessfulPairView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    // MARK: - Input

    let receivedURL: URL?
    let deviceName: String?
    let onDone: () -> Void

    // MARK: - Animation State

    @State private var ringScales: [CGFloat]   = Array(repeating: 1.0,  count: 5)
    @State private var ringOpacities: [Double] = Array(repeating: 0.0,  count: 5)
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var checkmarkGlow: CGFloat  = 0.0
    @State private var sparkleAngle: Double    = 0.0
    @State private var sparklesVisible: Bool   = false
    @State private var contentOpacity: Double  = 0.0

    // MARK: - Data State

    @State private var sourcesCount: Int       = 0
    @State private var certsCount: Int         = 0
    @State private var signedAppsCount: Int    = 0
    @State private var importedAppsCount: Int  = 0
    @State private var settingsIncluded: Bool  = false
    @State private var frameworksCount: Int    = 0
    @State private var archivesCount: Int      = 0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(hue: 0.37, saturation: 0.20, brightness: 0.08),
                    Color(hue: 0.40, saturation: 0.15, brightness: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Hero animation area
                    successAnimation
                        .padding(.top, 48)

                    // Headline text
                    VStack(spacing: 8) {
                        Text(.localized("Transfer Complete!"))
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)

                        if let name = deviceName, !name.isEmpty {
                            Text(String.localized("Successfully paired with %@", arguments: name))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.65))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .opacity(contentOpacity)

                    // Transferred data summary
                    transferredDataSection
                        .opacity(contentOpacity)

                    // Done button
                    Button(action: onDone) {
                        Label(.localized("Done"), systemImage: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(
                                LinearGradient(
                                    colors: [.green, Color(hue: 0.40, saturation: 0.7, brightness: 0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .opacity(contentOpacity)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            triggerSuccessAnimation()
            Task { await loadTransferredData() }
        }
    }

    // MARK: - Success Animation

    private var successAnimation: some View {
        ZStack {
            // 5 staggered expanding rings
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.green, .cyan, .blue, .purple, .green],
                            center: .center
                        ),
                        lineWidth: max(0.5, 2.5 - Double(i) * 0.4)
                    )
                    .frame(
                        width: CGFloat(70 + i * 38),
                        height: CGFloat(70 + i * 38)
                    )
                    .scaleEffect(ringScales[i])
                    .opacity(ringOpacities[i])
            }

            // Central glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.green.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: checkmarkGlow)

            // 8 orbiting rainbow sparkles
            if sparklesVisible {
                ForEach(0..<8, id: \.self) { i in
                    let angle = Double(i) * 45.0 + sparkleAngle
                    let rad: Double = 92
                    Circle()
                        .fill(Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0))
                        .frame(width: 7, height: 7)
                        .offset(
                            x: cos(angle * .pi / 180.0) * rad,
                            y: sin(angle * .pi / 180.0) * rad
                        )
                        .shadow(
                            color: Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0).opacity(0.8),
                            radius: 5
                        )
                }
            }

            // Bouncing checkmark
            Image(systemName: "checkmark.circle.fill")
                .bounceEffect()
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(checkmarkScale)
                .shadow(color: .green.opacity(0.7), radius: 24)
        }
        .frame(height: 220)
    }

    // MARK: - Transferred Data Section

    @ViewBuilder
    private var transferredDataSection: some View {
        let items = dataItems
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(.localized("What Was Transferred"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
                                .pulseEffect()
                                .font(.body)
                                .foregroundStyle(item.color)
                                .frame(width: 28)

                            Text(item.label)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))

                            Spacer()

                            Text(item.value)
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.white.opacity(0.55))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        if item.id != items.last?.id {
                            Divider()
                                .overlay(Color.white.opacity(0.08))
                                .padding(.leading, 58)
                        }
                    }
                }
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Data Items Model

    struct DataItem: Identifiable {
        let id: Int
        let icon: String
        let color: Color
        let label: String
        let value: String
    }

    private var dataItems: [DataItem] {
        var items: [DataItem] = []
        var idx = 0

        if certsCount > 0 {
            items.append(DataItem(
                id: idx, icon: "checkmark.seal.fill", color: .blue,
                label: .localized("Certificates"),
                value: "\(certsCount)"
            ))
            idx += 1
        }
        if sourcesCount > 0 {
            items.append(DataItem(
                id: idx, icon: "globe", color: .purple,
                label: .localized("Sources"),
                value: "\(sourcesCount)"
            ))
            idx += 1
        }
        if signedAppsCount > 0 {
            items.append(DataItem(
                id: idx, icon: "app.badge.fill", color: .green,
                label: .localized("Signed Apps"),
                value: "\(signedAppsCount)"
            ))
            idx += 1
        }
        if importedAppsCount > 0 {
            items.append(DataItem(
                id: idx, icon: "square.and.arrow.down.fill", color: .orange,
                label: .localized("Imported Apps"),
                value: "\(importedAppsCount)"
            ))
            idx += 1
        }
        if frameworksCount > 0 {
            items.append(DataItem(
                id: idx, icon: "puzzlepiece.extension.fill", color: .cyan,
                label: .localized("Default Frameworks"),
                value: "\(frameworksCount)"
            ))
            idx += 1
        }
        if archivesCount > 0 {
            items.append(DataItem(
                id: idx, icon: "archivebox.fill", color: .indigo,
                label: .localized("Archives"),
                value: "\(archivesCount)"
            ))
            idx += 1
        }
        if settingsIncluded {
            items.append(DataItem(
                id: idx, icon: "gearshape.2.fill", color: .gray,
                label: .localized("App Settings"),
                value: .localized("Included")
            ))
        }
        return items
    }

    // MARK: - Animation Trigger

    private func triggerSuccessAnimation() {
        // Haptic feedback
        HapticsManager.shared.success()

        // System success sound (camera shutter — pleasant and brief)
        AudioServicesPlaySystemSound(1057)

        // Expand rings with staggered delays
        for i in 0..<5 {
            ringOpacities[i] = 0.85
            let delay = Double(i) * 0.14
            withAnimation(.easeOut(duration: 1.4).delay(delay)) {
                ringScales[i] = 2.2 + Double(i) * 0.25
                ringOpacities[i] = 0.0
            }
        }

        // Bounce checkmark in
        withAnimation(.spring(response: 0.45, dampingFraction: 0.50).delay(0.08)) {
            checkmarkScale = 1.0
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.1)) {
            checkmarkGlow = 28
        }

        // Sparkles appear and spin
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            sparklesVisible = true
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                sparkleAngle = 360
            }
        }

        // Fade in the content below
        withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
            contentOpacity = 1.0
        }

        // Second haptic beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            HapticsManager.shared.impact(.light)
        }
    }

    private func loadTransferredData() async {
        guard let url = receivedURL else {
            // Host device — mark settings as included, no counts available
            settingsIncluded = true
            return
        }

        let fm = FileManager.default

        // Sources
        if let data = try? Data(contentsOf: url.appendingPathComponent("sources.json")),
           let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
            sourcesCount = arr.count
        }

        // Certificates
        if let data = try? Data(contentsOf: url.appendingPathComponent("certificates_metadata.json")),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            certsCount = arr.count
        }

        // Signed apps
        if let data = try? Data(contentsOf: url.appendingPathComponent("signed_apps_metadata.json")),
           let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
            signedAppsCount = arr.count
        }

        // Imported apps
        if let data = try? Data(contentsOf: url.appendingPathComponent("imported_apps_metadata.json")),
           let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
            importedAppsCount = arr.count
        }

        // Default frameworks
        let fwDir = url.appendingPathComponent("default_frameworks")
        if let items = try? fm.contentsOfDirectory(atPath: fwDir.path) {
            frameworksCount = items.filter { !$0.hasPrefix(".") }.count
        }

        // Archives
        let archDir = url.appendingPathComponent("archives")
        if let items = try? fm.contentsOfDirectory(atPath: archDir.path) {
            archivesCount = items.filter { !$0.hasPrefix(".") }.count
        }

        // Settings
        settingsIncluded = fm.fileExists(atPath: url.appendingPathComponent("settings.plist").path)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    SuccessfulPairView(
        receivedURL: nil,
        deviceName: "My iPhone",
        onDone: {}
    )
    .preferredColorScheme(.dark)
}
#endif
