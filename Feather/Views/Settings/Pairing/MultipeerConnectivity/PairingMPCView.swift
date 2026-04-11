import SwiftUI
import MultipeerConnectivity
import NimbleViews

struct PairingMPCView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    var isEmbedded: Bool = false

    @StateObject private var service = PairingMPCService()
    @Environment(\.dismiss) private var dismiss

    @State private var showSender = false
    @State private var showReceiver = false
    @State private var showPairedDevices = false
    @State private var showDemo = false

    // MARK: - Role Card Animation

    @State private var cardAppear = false

    var body: some View {
        mainContent
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    thisDeviceSection
                    iconSection
                    headingSection
                    roleCardsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
        }
        .navigationTitle(.localized("Pair Devices"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        showDemo = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    Button {
                        showPairedDevices = true
                    } label: {
                        Image(systemName: "personalhotspot.circle")
                    }
                }
            }
        }
        // Sender flow
        .fullScreenCover(isPresented: $showSender) {
            SenderView(service: service) {
                service.cancel()
                showSender = false
            }
            .preferredColorScheme(.dark)
        }
        // Receiver flow
        .fullScreenCover(isPresented: $showReceiver) {
            ReceiverView(service: service) {
                service.cancel()
                showReceiver = false
            }
            .preferredColorScheme(.dark)
        }
        // Paired devices history
        .sheet(isPresented: $showPairedDevices) {
            NavigationStack {
                PairedDevicesView()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(.localized("Done")) { showPairedDevices = false }
                        }
                    }
            }
        }
        // Demo walkthrough
        .sheet(isPresented: $showDemo) {
            MultipeerDemoView()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1)) {
                cardAppear = true
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(hue: 0.62, saturation: 0.15, brightness: 0.08),
                Color(hue: 0.65, saturation: 0.12, brightness: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - This Device Section

    private var thisDeviceSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(themeManager.accentColor.opacity(0.15))
                        .frame(width: 54, height: 54)

                    Image(systemName: "iphone.smartbatterycase.gen2")
                        .font(.title2)
                        .foregroundStyle(themeManager.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(.localized("This Device"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(themeManager.accentColor)
                        .textCase(.uppercase)

                    Text(UIDevice.current.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                }

                Spacer()

                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(themeManager.accentColor)
                    .pulseEffect()
            }
            .padding(18)
            .background(.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(themeManager.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .opacity(cardAppear ? 1 : 0)
        .offset(y: cardAppear ? 0 : -20)
    }

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.accentColor.opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            Image(systemName: "personalhotspot")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.accentColor,
                            themeManager.accentColor.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: themeManager.accentColor.opacity(0.5),
                    radius: 16
                )
                .pulseEffect()
        }
    }

    // MARK: - Heading Section

    private var headingSection: some View {
        VStack(spacing: 12) {
            Text(.localized("Ready to Pair"))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text(.localized("To pair with another device, make sure both devices are on this screen and connected to the same WiFi network."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)

                Text(.localized("Choose whether this device will act as the sender or receiver."))
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)
        }
        .opacity(cardAppear ? 1 : 0)
        .offset(y: cardAppear ? 0 : 12)
    }

    // MARK: - Role Cards Section

    private var roleCardsSection: some View {
        VStack(spacing: 14) {
            // Send Data card
            roleCard(
                icon: "arrow.up.circle.fill",
                title: .localized("Send Data"),
                detail: .localized("Transmit all apps, certificates, sources, and settings to another device."),
                gradientColors: [
                    themeManager.accentColor,
                    themeManager.accentColor.opacity(0.8)
                ],
                delay: 0.0
            ) {
                showSender = true
            }

            // Receive Data card
            roleCard(
                icon: "arrow.down.circle.fill",
                title: .localized("Receive Data"),
                detail: .localized("Accept a complete data transfer and mirror this device."),
                gradientColors: [
                    Color.blue,
                    Color.blue.opacity(0.8)
                ],
                delay: 0.08
            ) {
                showReceiver = true
            }
        }
    }

    private func roleCard(
        icon: String,
        title: String,
        detail: String,
        gradientColors: [Color],
        delay: Double,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 18) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: gradientColors.first?.opacity(0.3) ?? .clear,
                radius: 10,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .opacity(cardAppear ? 1 : 0)
        .offset(y: cardAppear ? 0 : 20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7).delay(0.15 + delay),
            value: cardAppear
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PairingMPCView()
        .preferredColorScheme(.dark)
}
#endif
