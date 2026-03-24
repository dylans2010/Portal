import SwiftUI
import NimbleViews

struct MultipeerDemoView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0

    private let pages = DemoPage.all

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            backgroundForPage(currentPage)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Page content
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { idx in
                    pageView(pages[idx])
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.35), value: currentPage)

            // Bottom controls overlay
            bottomControls
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Background

    @ViewBuilder
    private func backgroundForPage(_ idx: Int) -> some View {
        let page = pages[idx]
        LinearGradient(
            colors: [
                page.accentColor.opacity(0.18),
                Color(hue: 0.62, saturation: 0.15, brightness: 0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Page View

    private func pageView(_ page: DemoPage) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 40)

            // Illustration
            demoIllustration(page)
                .frame(height: 200)

            // Text content
            VStack(spacing: 12) {
                Text(page.stepLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(page.accentColor)
                    .textCase(.uppercase)
                    .tracking(1.5)

                Text(page.title)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(page.detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .lineSpacing(3)

                if !page.tips.isEmpty {
                    tipPill(page.tips)
                }
            }

            Spacer(minLength: 120)
        }
    }

    // MARK: - Illustration

    @ViewBuilder
    private func demoIllustration(_ page: DemoPage) -> some View {
        switch page.illustration {
        case .overview:
            OverviewIllustration(accentColor: page.accentColor)
        case .sender:
            SenderIllustration(accentColor: page.accentColor)
        case .receiver:
            ReceiverIllustration(accentColor: page.accentColor)
        case .transfer:
            TransferIllustration(accentColor: page.accentColor)
        case .history:
            HistoryIllustration(accentColor: page.accentColor)
        }
    }

    // MARK: - Tip Pill

    private func tipPill(_ text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.07))
        .clipShape(Capsule())
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 16) {
            // Page dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { idx in
                    Capsule()
                        .fill(idx == currentPage ? Color.white : Color.white.opacity(0.28))
                        .frame(width: idx == currentPage ? 20 : 8, height: 8)
                        .animation(.spring(response: 0.35), value: currentPage)
                }
            }

            // Primary button
            if currentPage < pages.count - 1 {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        currentPage += 1
                    }
                } label: {
                    HStack {
                        Text(.localized("Next"))
                            .font(.headline)
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(pages[currentPage].accentColor.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)

                Button {
                    dismiss()
                } label: {
                    Text(.localized("Skip"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Label(.localized("Get Started"), systemImage: "arrow.right.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(pages[currentPage].accentColor.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.bottom, 36)
        .background(
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .ignoresSafeArea(),
            alignment: .bottom
        )
    }
}

// MARK: - Demo Page Model

private struct DemoPage {
    enum Illustration { case overview, sender, receiver, transfer, history }

    let stepLabel: String
    let title: String
    let detail: String
    let tips: String
    let illustration: Illustration
    let accentColor: Color

    static let all: [DemoPage] = [
        DemoPage(
            stepLabel: .localized("Overview"),
            title: .localized("Pair Devices Wirelessly"),
            detail: .localized("Pairing uses your Wi-Fi network to securely transfer your certificates, sources, and settings to another device."),
            tips: .localized("Both devices must be on the same Wi-Fi network."),
            illustration: .overview,
            accentColor: Color(hue: 0.60, saturation: 0.75, brightness: 0.90)
        ),
        DemoPage(
            stepLabel: .localized("Step 1 — Sender"),
            title: .localized("Send Your Data"),
            detail: .localized("Tap \"Send Data\" on the device you want to transfer the data. It will broadcast itself so nearby devices can find it automatically."),
            tips: .localized("Keep the screen on while waiting for the receiver."),
            illustration: .sender,
            accentColor: Color(hue: 0.70, saturation: 0.75, brightness: 0.90)
        ),
        DemoPage(
            stepLabel: .localized("Step 2 — Receiver"),
            title: .localized("Receive on Another Device"),
            detail: .localized("On the receiving device, tap \"Receive Data\". It will scan for senders and list them. Tap the sender's name to connect."),
            tips: .localized("A secure encrypted channel is created instantly."),
            illustration: .receiver,
            accentColor: Color(hue: 0.55, saturation: 0.70, brightness: 0.90)
        ),
        DemoPage(
            stepLabel: .localized("Step 3 — Transfer"),
            title: .localized("Watch the Transfer"),
            detail: .localized("A live progress screen appears on both devices, showing phase details and estimated time remaining. Just keep both devices nearby."),
            tips: .localized("Do not close Portal during transfer."),
            illustration: .transfer,
            accentColor: Color(hue: 0.42, saturation: 0.65, brightness: 0.88)
        ),
        DemoPage(
            stepLabel: .localized("Done"),
            title: .localized("Review Paired Devices"),
            detail: .localized("After pairing, tap **Paired Devices** (top-right in the pairing screen) to see everything that was transferred — certificates, sources, settings, and more."),
            tips: .localized("History is kept for 7 days, then removed automatically."),
            illustration: .history,
            accentColor: Color(hue: 0.37, saturation: 0.65, brightness: 0.88)
        )
    ]
}

// MARK: - Illustration Views

private struct OverviewIllustration: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let accentColor: Color
    @State private var pulse: CGFloat = 1.0
    @State private var orbit: Double = 0

    var body: some View {
        ZStack {
            // Orbit ring
            Circle()
                .stroke(accentColor.opacity(0.2), lineWidth: 1.5)
                .frame(width: 160, height: 160)

            // Two devices
            ForEach([0, 1], id: \.self) { i in
                let angle = Double(i) * 180.0 + orbit
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 32, height: 44)
                    .overlay(
                        Image(systemName: "iphone")
                            .font(.title3)
                            .foregroundStyle(accentColor)
                    )
                    .offset(
                        x: cos(angle * .pi / 180) * 72,
                        y: sin(angle * .pi / 180) * 72
                    )
            }

            // Center Wi-Fi icon
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulse)
                Image(systemName: "wifi")
                    .font(.title2)
                    .foregroundStyle(accentColor)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = 1.15
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                orbit = 360
            }
        }
    }
}

private struct SenderIllustration: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let accentColor: Color
    @State private var rings: [CGFloat] = [1, 1, 1]
    @State private var ringOpacities: [Double] = [0.6, 0.6, 0.6]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(accentColor.opacity(ringOpacities[i]), lineWidth: 1.5)
                    .frame(width: CGFloat(70 + i * 44), height: CGFloat(70 + i * 44))
                    .scaleEffect(rings[i])
            }
            Circle()
                .fill(accentColor.opacity(0.15))
                .frame(width: 64, height: 64)
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 34))
                .foregroundStyle(accentColor)
        }
        .onAppear {
            for i in 0..<3 {
                withAnimation(
                    .easeOut(duration: 1.8)
                    .repeatForever(autoreverses: false)
                    .delay(Double(i) * 0.5)
                ) {
                    rings[i] = 1.5
                    ringOpacities[i] = 0
                }
            }
        }
    }
}

private struct ReceiverIllustration: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let accentColor: Color
    @State private var peerOffset: CGFloat = 30
    @State private var peerOpacity: Double = 0

    var body: some View {
        ZStack {
            // Receiver device
            VStack(spacing: 6) {
                Image(systemName: "dot.radiowaves.up.forward")
                    .font(.system(size: 34))
                    .foregroundStyle(accentColor)
                Text(.localized("Receiver"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor.opacity(0.8))
            }
            .frame(width: 80, height: 80)
            .background(accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .offset(x: -60)

            // Found peer row appearing
            HStack(spacing: 10) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundStyle(accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("My iPhone"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(.localized("Tap To Connect"))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(10)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .offset(x: 36, y: peerOffset)
            .opacity(peerOpacity)
        }
        .onAppear {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.65)
                .delay(0.3)
                .repeatForever(autoreverses: true)
            ) {
                peerOffset = 0
                peerOpacity = 1
            }
        }
    }
}

private struct TransferIllustration: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let accentColor: Color
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 30) {
                deviceIcon(systemName: "iphone", label: .localized("Sender"))
                Image(systemName: "arrow.right")
                    .font(.title3)
                    .foregroundStyle(accentColor)
                deviceIcon(systemName: "iphone", label: .localized("Receiver"))
            }

            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(maxWidth: 200, minHeight: 8, maxHeight: 8)

                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .onAppear {
            withAnimation(
                .linear(duration: 2.5)
                .repeatForever(autoreverses: true)
            ) {
                progress = 1.0
            }
        }
    }

    private func deviceIcon(systemName: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemName)
                .font(.system(size: 30))
                .foregroundStyle(accentColor)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

private struct HistoryIllustration: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let accentColor: Color
    @State private var rowsVisible = false

    private let sampleRows = [
        ("My iPhone", "Received", Color.green, "3 Certs · 12 Sources"),
        ("My iPad", "Sent", Color.blue, "5 Certs · 8 Sources")
    ]

    var body: some View {
        VStack(spacing: 10) {
            ForEach(Array(sampleRows.enumerated()), id: \.offset) { idx, row in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(row.2.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: row.1 == "Sent"
                              ? "arrow.up.circle.fill"
                              : "arrow.down.circle.fill")
                            .foregroundStyle(row.2)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(row.0)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(row.3)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    Text(row.1)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(row.2.opacity(0.15)))
                        .foregroundStyle(row.2)
                }
                .padding(12)
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .offset(y: rowsVisible ? 0 : 20)
                .opacity(rowsVisible ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7).delay(Double(idx) * 0.15),
                    value: rowsVisible
                )
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            rowsVisible = true
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    MultipeerDemoView()
}
#endif
