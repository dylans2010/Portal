import SwiftUI
import AudioToolbox
import NimbleViews

struct MPCSuccessfulPairView: View {
    @EnvironmentObject var themeManager: ThemeManager

    let receivedURL: URL?
    let deviceName: String?
    let wasHost: Bool
    let onDone: () -> Void

    @State private var ringScales: [CGFloat]   = Array(repeating: 1.0, count: 5)
    @State private var ringOpacities: [Double] = Array(repeating: 0.0, count: 5)
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var checkmarkGlow: CGFloat  = 0.0
    @State private var sparkleAngle: Double    = 0.0
    @State private var sparklesVisible: Bool   = false
    @State private var contentOpacity: Double  = 0.0

    @State private var sourcesCount: Int      = 0
    @State private var certsCount: Int        = 0
    @State private var signedAppsCount: Int   = 0
    @State private var importedAppsCount: Int = 0
    @State private var settingsIncluded: Bool = false
    @State private var frameworksCount: Int   = 0
    @State private var archivesCount: Int     = 0


    var body: some View {
        ZStack {
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
                    successAnimation
                        .padding(.top, 48)

                    headlineSection
                        .opacity(contentOpacity)

                    transferredDataSection
                        .opacity(contentOpacity)

                    doneButton
                        .padding(.bottom, 40)
                        .opacity(contentOpacity)
                }
            }
        }
        .onAppear {
            triggerSuccessAnimation()
            Task { await loadTransferredData() }
        }
    }

    private var successAnimation: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.green, .teal, .cyan, .blue, .green],
                            center: .center
                        ),
                        lineWidth: max(0.5, 2.5 - Double(i) * 0.4)
                    )
                    .frame(
                        width: CGFloat(72 + i * 36),
                        height: CGFloat(72 + i * 36)
                    )
                    .scaleEffect(ringScales[i])
                    .opacity(ringOpacities[i])
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.teal.opacity(0.40), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 58
                    )
                )
                .frame(width: 116, height: 116)
                .blur(radius: checkmarkGlow)

            if sparklesVisible {
                ForEach(0..<8, id: \.self) { i in
                    let angle = Double(i) * 45.0 + sparkleAngle
                    let radius: Double = 88
                    Circle()
                        .fill(Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0))
                        .frame(width: 7, height: 7)
                        .offset(
                            x: cos(angle * .pi / 180.0) * radius,
                            y: sin(angle * .pi / 180.0) * radius
                        )
                        .shadow(
                            color: Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0).opacity(0.8),
                            radius: 5
                        )
                }
            }
            Image(systemName: wasHost ? "arrow.up.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(
                    LinearGradient(
                        colors: wasHost
                            ? [.teal, .cyan]
                            : [.green, .mint],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(checkmarkScale)
                .shadow(color: (wasHost ? Color.teal : Color.green).opacity(0.7), radius: 22)
        }
        .frame(height: 220)
    }

    // MARK: - Headline Section

    private var headlineSection: some View {
        VStack(spacing: 8) {
            Text(wasHost
                 ? .localized("Data Sent!")
                 : .localized("Transfer Complete!"))
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            if let name = deviceName, !name.isEmpty {
                Text(wasHost
                     ? String.localized("Successfully sent data to %@", arguments: name)
                     : String.localized("Successfully paired with %@", arguments: name))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }

    // MARK: - Transferred Data Section

    @ViewBuilder
    private var transferredDataSection: some View {
        let items = dataItems
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(wasHost
                     ? .localized("What Was Sent")
                     : .localized("What Was Received"))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 4)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                        HStack(spacing: 14) {
                            Image(systemName: item.icon)
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

                        if idx < items.count - 1 {
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

    // MARK: - Done Button

    private var doneButton: some View {
        Button(action: onDone) {
            Label(.localized("Done"), systemImage: "checkmark")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    LinearGradient(
                        colors: wasHost
                            ? [.teal, Color(hue: 0.50, saturation: 0.7, brightness: 0.75)]
                            : [.green, Color(hue: 0.40, saturation: 0.7, brightness: 0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Data Items

    private struct DataItem {
        let icon: String
        let color: Color
        let label: String
        let value: String
    }

    private var dataItems: [DataItem] {
        var items: [DataItem] = []

        if certsCount > 0 {
            items.append(DataItem(
                icon: "checkmark.seal.fill", color: .blue,
                label: .localized("Certificates"), value: "\(certsCount)"
            ))
        }
        if sourcesCount > 0 {
            items.append(DataItem(
                icon: "globe", color: .purple,
                label: .localized("Sources"), value: "\(sourcesCount)"
            ))
        }
        if signedAppsCount > 0 {
            items.append(DataItem(
                icon: "app.badge.fill", color: .green,
                label: .localized("Signed Apps"), value: "\(signedAppsCount)"
            ))
        }
        if importedAppsCount > 0 {
            items.append(DataItem(
                icon: "square.and.arrow.down.fill", color: .orange,
                label: .localized("Imported Apps"), value: "\(importedAppsCount)"
            ))
        }
        if frameworksCount > 0 {
            items.append(DataItem(
                icon: "puzzlepiece.extension.fill", color: .cyan,
                label: .localized("Default Frameworks"), value: "\(frameworksCount)"
            ))
        }
        if archivesCount > 0 {
            items.append(DataItem(
                icon: "archivebox.fill", color: .indigo,
                label: .localized("Archives"), value: "\(archivesCount)"
            ))
        }
        if settingsIncluded {
            items.append(DataItem(
                icon: "gearshape.2.fill", color: .gray,
                label: .localized("App Settings"), value: .localized("Included")
            ))
        }
        return items
    }

    // MARK: - Animation Trigger

    private func triggerSuccessAnimation() {
        HapticsManager.shared.success()
        AudioServicesPlaySystemSound(1057)

        // Staggered ring expansion
        for i in 0..<5 {
            ringOpacities[i] = 0.85
            withAnimation(.easeOut(duration: 1.4).delay(Double(i) * 0.14)) {
                ringScales[i]   = 2.2 + Double(i) * 0.25
                ringOpacities[i] = 0.0
            }
        }

        // Bounce checkmark in
        withAnimation(.spring(response: 0.45, dampingFraction: 0.50).delay(0.08)) {
            checkmarkScale = 1.0
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(0.1)) {
            checkmarkGlow = 26
        }

        // Sparkles
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            sparklesVisible = true
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                sparkleAngle = 360
            }
        }

        // Fade content in
        withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
            contentOpacity = 1.0
        }

        // Second haptic beat
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            HapticsManager.shared.impact(.light)
        }
    }

    // MARK: - Load Transferred Data

    private func loadTransferredData() async {
        guard let url = receivedURL else {
            settingsIncluded = true
            return
        }

        let fm = FileManager.default

        if let data = try? Data(contentsOf: url.appendingPathComponent("sources.json")),
           let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
            sourcesCount = arr.count
        }

        if let data = try? Data(contentsOf: url.appendingPathComponent("certificates_metadata.json")),
           let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            certsCount = arr.count
        }

        if let data = try? Data(contentsOf: url.appendingPathComponent("signed_apps_metadata.json")),
           let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
            signedAppsCount = arr.count
        }

        if let data = try? Data(contentsOf: url.appendingPathComponent("imported_apps_metadata.json")),
           let arr = try? JSONDecoder().decode([[String: String]].self, from: data) {
            importedAppsCount = arr.count
        }

        let fwDir = url.appendingPathComponent("default_frameworks")
        if let items = try? fm.contentsOfDirectory(atPath: fwDir.path) {
            frameworksCount = items.filter { !$0.hasPrefix(".") }.count
        }

        let archDir = url.appendingPathComponent("archives")
        if let items = try? fm.contentsOfDirectory(atPath: archDir.path) {
            archivesCount = items.filter { !$0.hasPrefix(".") }.count
        }

        settingsIncluded = fm.fileExists(
            atPath: url.appendingPathComponent("settings.plist").path
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    MPCSuccessfulPairView(
        receivedURL: nil,
        deviceName: "My iPhone",
        wasHost: false,
        onDone: {}
    )
    .preferredColorScheme(.dark)
}
#endif
