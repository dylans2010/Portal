import SwiftUI
import NimbleViews

// MARK: - Pairing Demo View
/// A multi-page splash-screen walkthrough demonstrating the full device-pairing
/// feature with simulated data.  Accessible from the "See Demo" button on the
/// Pair Devices screen.
///
/// Pages:
///  1. Introduction — what the Pairing feature does
///  2. Sender side  — the animated sphere + QR code being shown
///  3. Receiver side — camera scanner pointing at the QR code
///  4. Transfer in progress — animated progress with simulated data
///  5. Success        — the SuccessfulPairView recreation with sample data
struct PairingDemoView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    @State private var animating: Bool = false

    private let totalPages = 5

    var body: some View {
        ZStack {
            backgroundGradient(for: currentPage)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: currentPage)

            VStack(spacing: 0) {
                // Top toolbar
                HStack {
                    Button(.localized("Close")) { dismiss() }
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.leading, 20)
                    Spacer()
                    Text(.localized("Demo"))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    // Page indicator
                    Text("\(currentPage + 1) / \(totalPages)")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.65))
                        .padding(.trailing, 20)
                }
                .frame(height: 52)
                .background(.black.opacity(0.25))

                // Page content
                TabView(selection: $currentPage) {
                    IntroPage().tag(0)
                    SenderPage().tag(1)
                    ReceiverPage().tag(2)
                    TransferPage().tag(3)
                    SuccessPage().tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                // Navigation buttons
                bottomBar
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 20) {
            // Back
            Button {
                withAnimation { currentPage = max(0, currentPage - 1) }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(currentPage == 0 ? .white.opacity(0.25) : .white)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .disabled(currentPage == 0)

            // Dot indicators
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { idx in
                    Capsule()
                        .fill(idx == currentPage ? Color.white : Color.white.opacity(0.30))
                        .frame(width: idx == currentPage ? 22 : 8, height: 8)
                        .animation(.spring(response: 0.35), value: currentPage)
                }
            }

            // Next / Done
            Button {
                if currentPage < totalPages - 1 {
                    withAnimation { currentPage += 1 }
                } else {
                    dismiss()
                }
            } label: {
                Group {
                    if currentPage == totalPages - 1 {
                        Text(.localized("Done"))
                            .font(.headline)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.headline)
                    }
                }
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(currentPage == totalPages - 1
                    ? LinearGradient(colors: [.green, .cyan], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.white.opacity(0.15), .white.opacity(0.15)],
                                     startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(Circle())
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 32)
        .background(.black.opacity(0.25))
    }

    // MARK: - Background Gradient

    private func backgroundGradient(for page: Int) -> some View {
        let gradients: [(Color, Color)] = [
            (Color(hue: 0.62, saturation: 0.22, brightness: 0.12),
             Color(hue: 0.65, saturation: 0.18, brightness: 0.08)),
            (Color(hue: 0.70, saturation: 0.22, brightness: 0.10),
             Color(hue: 0.75, saturation: 0.18, brightness: 0.07)),
            (Color(hue: 0.55, saturation: 0.22, brightness: 0.10),
             Color(hue: 0.60, saturation: 0.18, brightness: 0.07)),
            (Color(hue: 0.58, saturation: 0.22, brightness: 0.11),
             Color(hue: 0.50, saturation: 0.18, brightness: 0.08)),
            (Color(hue: 0.38, saturation: 0.22, brightness: 0.10),
             Color(hue: 0.40, saturation: 0.18, brightness: 0.07))
        ]
        let pair = gradients[min(page, gradients.count - 1)]
        return LinearGradient(
            colors: [pair.0, pair.1],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Page 1: Introduction

private struct IntroPage: View {
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 24)

                // Hero icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hue: 0.65, saturation: 0.6, brightness: 0.5).opacity(0.4), .clear],
                                center: .center, startRadius: 0, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "personalhotspot")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hue: 0.65, saturation: 0.8, brightness: 0.9),
                                         Color(hue: 0.75, saturation: 0.7, brightness: 0.85)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hue: 0.65, saturation: 0.8, brightness: 0.9).opacity(0.5), radius: 20)
                }
                .scaleEffect(appeared ? 1.0 : 0.5)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1), value: appeared)

                VStack(spacing: 10) {
                    Text(.localized("Pair Devices"))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text(.localized("Transfer everything to a new device wirelessly."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.4).delay(0.3), value: appeared)

                // Feature tiles
                VStack(spacing: 12) {
                    featureTile(
                        icon: "checkmark.seal.fill", color: .blue,
                        title: .localized("Certificates"),
                        detail: .localized("All your signing certificates move over instantly.")
                    )
                    featureTile(
                        icon: "globe", color: .purple,
                        title: .localized("Sources"),
                        detail: .localized("Your saved app sources and repositories.")
                    )
                    featureTile(
                        icon: "app.badge.fill", color: .green,
                        title: .localized("Apps"),
                        detail: .localized("Signed & imported apps, archives and frameworks.")
                    )
                    featureTile(
                        icon: "gearshape.fill", color: .gray,
                        title: .localized("Settings"),
                        detail: .localized("Your preferences and configuration.")
                    )
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1.0 : 0.0)
                .animation(.easeIn(duration: 0.4).delay(0.5), value: appeared)

                Spacer(minLength: 24)
            }
        }
        .onAppear { appeared = true }
    }

    private func featureTile(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 42, height: 42)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold()).foregroundStyle(.white)
                Text(detail).font(.caption).foregroundStyle(.white.opacity(0.55))
            }
            Spacer()
        }
        .padding(14)
        .background(.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Page 2: Sender Side

private struct SenderPage: View {
    @State private var morphProgress: Double = 0.0
    @State private var appeared = false
    @State private var showQR = false
    private let demoCode = "473829"

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                // Step badge
                stepBadge(number: 1, label: .localized("On the sending device"))

                // Sphere animation + QR overlay
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hue: 0.65, saturation: 0.6, brightness: 0.45).opacity(0.25), .clear
                                ],
                                center: .center, startRadius: 10, endRadius: 140
                            )
                        )
                        .frame(width: 280, height: 280)

                    PairingCodeSphere(morphProgress: morphProgress, pairingStatus: .waiting)
                        .frame(width: 260, height: 260)

                    // QR code overlay in top-right corner
                    if showQR {
                        VStack {
                            HStack {
                                Spacer()
                                DemoQRCodeView(code: demoCode)
                                    .transition(.scale.combined(with: .opacity))
                            }
                            Spacer()
                        }
                        .frame(width: 260, height: 260)
                    }
                }

                VStack(spacing: 8) {
                    Text(.localized("Animated Pairing Code"))
                        .font(.headline).foregroundStyle(.white)
                    Text(.localized("Tap \"Pair Devices\" — a unique QR code\nappears in the corner of the animation."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    // Simulated code label
                    Text(.localized("Code:") + " \(demoCode)")
                        .font(.system(.title3, design: .monospaced, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hue: 0.55, saturation: 0.9, brightness: 1.0),
                                         Color(hue: 0.75, saturation: 0.8, brightness: 0.9)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .padding(.top, 4)
                }

                // Simulated device status card
                deviceCard(
                    name: "Dylan's iPhone 15 Pro",
                    status: .localized("Generating pairing code…"),
                    icon: "iphone",
                    color: .blue
                )
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .onAppear {
            appeared = true
            withAnimation(.easeInOut(duration: 2.5)) { morphProgress = 0.72 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring()) { showQR = true }
            }
        }
    }
}

// MARK: - Page 3: Receiver Side

private struct ReceiverPage: View {
    @State private var appeared = false
    @State private var scanLineOffset: CGFloat = -100
    @State private var bracketPulse = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                stepBadge(number: 2, label: .localized("On the receiving device"))

                // Simulated camera scanner UI
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.7))
                        .frame(width: 280, height: 280)

                    // Fake camera "blurry background"
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.25, brightness: 0.18),
                                    Color(hue: 0.65, saturation: 0.20, brightness: 0.14)
                                ],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 240, height: 240)

                    // Simulated QR code in the viewfinder
                    DemoQRCodeView(code: "473829")
                        .opacity(0.85)

                    // Scanning line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .cyan.opacity(0.8), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: 200, height: 2)
                        .offset(y: scanLineOffset)
                        .clipShape(Rectangle().size(width: 240, height: 240).offset(x: -120, y: -120))

                    // Corner brackets
                    scannerBrackets
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

                VStack(spacing: 8) {
                    Text(.localized("Scan with Camera"))
                        .font(.headline).foregroundStyle(.white)
                    Text(.localized("Tap \"Scan Pairing Code\" on the other device —\npoint your camera at the animated code."))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Simulated action buttons
                VStack(spacing: 12) {
                    simulatedButton(
                        label: .localized("Scan Pairing Code"),
                        icon: "qrcode.viewfinder",
                        gradient: [Color(hue: 0.70, saturation: 0.75, brightness: 0.90),
                                   Color(hue: 0.82, saturation: 0.65, brightness: 0.85)]
                    )
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .onAppear {
            appeared = true
            withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: true)) {
                scanLineOffset = 100
            }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                bracketPulse = true
            }
        }
    }

    private var scannerBrackets: some View {
        ZStack {
            // TL
            cornerBracket(x: -100, y: -100, xFlip: 1, yFlip: 1)
            // TR
            cornerBracket(x: 100, y: -100, xFlip: -1, yFlip: 1)
            // BL
            cornerBracket(x: -100, y: 100, xFlip: 1, yFlip: -1)
            // BR
            cornerBracket(x: 100, y: 100, xFlip: -1, yFlip: -1)
        }
        .opacity(bracketPulse ? 1.0 : 0.5)
    }

    private func cornerBracket(x: CGFloat, y: CGFloat, xFlip: CGFloat, yFlip: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20 * yFlip))
            path.addLine(to: CGPoint(x: 0, y: 4 * yFlip))
            path.addLine(to: CGPoint(x: 20 * xFlip, y: 0))
        }
        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .offset(x: x, y: y)
    }
}

// MARK: - Page 4: Transfer In Progress

private struct TransferPage: View {
    @State private var progress: Double = 0.0
    @State private var appeared = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                stepBadge(number: 3, label: .localized("Transfer in progress"))

                // Simulated transfer animation
                ZStack {
                    // Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hue: 0.55, saturation: 0.7, brightness: 0.5).opacity(0.3), .clear],
                                center: .center, startRadius: 0, endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    // Rotating ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color(hue: 0.55, saturation: 0.8, brightness: 0.9),
                                    Color(hue: 0.42, saturation: 0.7, brightness: 0.85),
                                    Color(hue: 0.55, saturation: 0.8, brightness: 0.9).opacity(0)
                                ],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 3, dash: [6, 4])
                        )
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(rotationAngle))

                    // Center icon
                    Image(systemName: "arrow.up.arrow.down.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hue: 0.55, saturation: 0.8, brightness: 0.95),
                                         Color(hue: 0.42, saturation: 0.7, brightness: 0.90)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(hue: 0.55, saturation: 0.8, brightness: 0.9).opacity(0.5), radius: 12)
                }
                .frame(width: 160, height: 160)

                // Progress bar
                VStack(spacing: 8) {
                    Text(.localized("Transferring Data"))
                        .font(.headline).foregroundStyle(.white)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hue: 0.55, saturation: 0.8, brightness: 0.9),
                                                 Color(hue: 0.42, saturation: 0.7, brightness: 0.85)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * progress, height: 8)
                                .animation(.easeInOut(duration: 0.4), value: progress)
                        }
                    }
                    .frame(maxWidth: 280, minHeight: 8, maxHeight: 8)
                    .padding(.horizontal, 32)

                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                }

                // Simulated transfer details
                VStack(spacing: 0) {
                    transferRow(icon: "checkmark.seal.fill", color: .blue,
                                label: .localized("Certificates"), value: "3", done: progress > 0.2)
                    Divider().overlay(Color.white.opacity(0.08))
                    transferRow(icon: "globe", color: .purple,
                                label: .localized("Sources"), value: "12", done: progress > 0.4)
                    Divider().overlay(Color.white.opacity(0.08))
                    transferRow(icon: "app.badge.fill", color: .green,
                                label: .localized("Apps"), value: "8", done: progress > 0.65)
                    Divider().overlay(Color.white.opacity(0.08))
                    transferRow(icon: "gearshape.fill", color: .gray,
                                label: .localized("Settings"), value: .localized("Included"), done: progress > 0.9)
                }
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 24)

                Spacer(minLength: 24)
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true)) {
                progress = 1.0
            }
        }
    }

    private func transferRow(icon: String, color: Color, label: String, value: String, done: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.body).foregroundStyle(color).frame(width: 26)
            Text(label).font(.subheadline).foregroundStyle(.white.opacity(0.9))
            Spacer()
            if done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .transition(.scale.combined(with: .opacity))
            }
            Text(value)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.easeIn(duration: 0.3), value: done)
    }
}

// MARK: - Page 5: Success

private struct SuccessPage: View {
    @State private var appeared = false
    @State private var checkmarkScale: CGFloat = 0.0
    @State private var ringScales: [CGFloat] = Array(repeating: 1.0, count: 4)
    @State private var ringOpacities: [Double] = Array(repeating: 0.0, count: 4)
    @State private var sparkleAngle: Double = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 24)

                // Animation
                ZStack {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [.green, .cyan, .blue, .purple, .green],
                                    center: .center
                                ),
                                lineWidth: max(0.5, 2.5 - Double(i) * 0.5)
                            )
                            .frame(width: CGFloat(70 + i * 36), height: CGFloat(70 + i * 36))
                            .scaleEffect(ringScales[i])
                            .opacity(ringOpacities[i])
                    }

                    // Sparkles
                    ForEach(0..<8, id: \.self) { i in
                        let angle = Double(i) * 45.0 + sparkleAngle
                        Circle()
                            .fill(Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0))
                            .frame(width: 7, height: 7)
                            .offset(
                                x: cos(angle * .pi / 180) * 88,
                                y: sin(angle * .pi / 180) * 88
                            )
                            .shadow(color: Color(hue: Double(i) / 8.0, saturation: 0.9, brightness: 1.0).opacity(0.8), radius: 5)
                    }

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom))
                        .scaleEffect(checkmarkScale)
                        .shadow(color: .green.opacity(0.7), radius: 24)
                }
                .frame(height: 200)

                VStack(spacing: 8) {
                    Text(.localized("Transfer Complete!"))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                    Text(.localized("Successfully paired with Dylan's iPad Pro"))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                }

                // Sample transferred data
                VStack(spacing: 0) {
                    successRow(icon: "checkmark.seal.fill", color: .blue,
                               label: .localized("Certificates"), value: "3")
                    Divider().overlay(Color.white.opacity(0.08))
                    successRow(icon: "globe", color: .purple,
                               label: .localized("Sources"), value: "12")
                    Divider().overlay(Color.white.opacity(0.08))
                    successRow(icon: "app.badge.fill", color: .green,
                               label: .localized("Signed Apps"), value: "5")
                    Divider().overlay(Color.white.opacity(0.08))
                    successRow(icon: "square.and.arrow.down.fill", color: .orange,
                               label: .localized("Imported Apps"), value: "3")
                    Divider().overlay(Color.white.opacity(0.08))
                    successRow(icon: "gearshape.2.fill", color: .gray,
                               label: .localized("App Settings"), value: .localized("Included"))
                }
                .background(.white.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)

                Text(.localized("That's all there is to it! Pair Devices makes\nmoving your setup effortless."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer(minLength: 24)
            }
        }
        .onAppear { triggerAnimation() }
    }

    private func successRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.body).foregroundStyle(color).frame(width: 26)
            Text(label).font(.subheadline).foregroundStyle(.white.opacity(0.9))
            Spacer()
            Text(value).font(.subheadline.monospacedDigit()).foregroundStyle(.white.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func triggerAnimation() {
        for i in 0..<4 {
            ringOpacities[i] = 0.8
            withAnimation(.easeOut(duration: 1.6).delay(Double(i) * 0.15).repeatForever(autoreverses: false)) {
                ringScales[i] = 2.4 + Double(i) * 0.3
                ringOpacities[i] = 0.0
            }
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55).delay(0.08)) {
            checkmarkScale = 1.0
        }
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            sparkleAngle = 360
        }
    }
}

// MARK: - Shared Helpers

/// A small QR code image generated from `code` using CoreImage.
struct DemoQRCodeView: View {
    let code: String
    private let size: CGFloat = 80

    var body: some View {
        if let img = generateQRCode(from: code) {
            Image(uiImage: img)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(6)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.4), radius: 6)
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let ciImage = filter.outputImage else { return nil }
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

private func stepBadge(number: Int, label: String) -> some View {
    HStack(spacing: 10) {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hue: 0.65, saturation: 0.8, brightness: 0.9),
                                 Color(hue: 0.75, saturation: 0.7, brightness: 0.85)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
            Text("\(number)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
        }
        Text(label)
            .font(.subheadline.bold())
            .foregroundStyle(.white.opacity(0.85))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(.white.opacity(0.10))
    .clipShape(Capsule())
}

private func deviceCard(name: String, status: String, icon: String, color: Color) -> some View {
    HStack(spacing: 14) {
        Image(systemName: icon)
            .font(.title2)
            .foregroundStyle(color)
            .frame(width: 42, height: 42)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(.subheadline.bold()).foregroundStyle(.white)
            Text(status).font(.caption).foregroundStyle(.white.opacity(0.55))
        }
        Spacer()
        Image(systemName: "circle.fill")
            .font(.caption2)
            .foregroundStyle(.green)
    }
    .padding(14)
    .background(.white.opacity(0.07))
    .clipShape(RoundedRectangle(cornerRadius: 14))
}

private func simulatedButton(label: String, icon: String, gradient: [Color]) -> some View {
    Label(label, systemImage: icon)
        .font(.headline)
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 14))
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairingDemoView()
}
#endif
