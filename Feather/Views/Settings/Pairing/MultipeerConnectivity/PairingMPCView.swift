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
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack {
            backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
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
            ToolbarItem(placement: .cancellationAction) {
                Button(.localized("Cancel")) {
                    dismiss()
                }
            }
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

    // MARK: - Icon Section

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hue: 0.58, saturation: 0.5, brightness: 0.4).opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            Image(systemName: "iphone.and.arrow.right..outward")
                .font(.system(size: 64))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(hue: 0.55, saturation: 0.7, brightness: 0.95),
                            Color(hue: 0.42, saturation: 0.6, brightness: 0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(
                    color: Color(hue: 0.55, saturation: 0.7, brightness: 0.9).opacity(0.5),
                    radius: 16
                )
        }
    }

    // MARK: - Heading Section

    private var headingSection: some View {
        VStack(spacing: 8) {
            Text(.localized("Choose Your Action"))
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)

            Text(.localized("Both devices must be on the same WiFi network. Choose whether this device will send its data or receive data from another device."))
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
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
                detail: .localized("Send your certificates, sources, and settings to another device."),
                gradientColors: [
                    Color(hue: 0.70, saturation: 0.75, brightness: 0.88),
                    Color(hue: 0.82, saturation: 0.65, brightness: 0.83)
                ],
                delay: 0.0
            ) {
                showSender = true
            }

            // Receive Data card
            roleCard(
                icon: "arrow.down.circle.fill",
                title: .localized("Receive Data"),
                detail: .localized("Accept a full data transfer from a nearby sender."),
                gradientColors: [
                    Color(hue: 0.55, saturation: 0.70, brightness: 0.83),
                    Color(hue: 0.42, saturation: 0.65, brightness: 0.78)
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
