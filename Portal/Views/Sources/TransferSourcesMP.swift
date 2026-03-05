import SwiftUI
import MultipeerConnectivity
import AltSourceKit

struct TransferSourcesMP: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var transferService = SourcesTransferService()
    var sourceURLs: [String] = []

    @State private var isReceiveMode = false
    @State private var showSuccess = false
    @State private var receivedCount = 0

    // Additional states for menu actions
    @State private var _showManageSources = false
    @State private var _showQRMode = false
    @State private var _showPortalExport = false
    @State private var _portalExportData = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                headerSection

                Picker("Mode", selection: $isReceiveMode) {
                    Text("Send").tag(false)
                    Text("Receive").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: isReceiveMode) { newValue in
                    transferService.stop()
                    if newValue {
                        transferService.startReceiveMode()
                    } else {
                        transferService.startSendMode()
                    }
                    HapticsManager.shared.softImpact()
                }

                if isReceiveMode {
                    receiveContent
                } else {
                    sendContent
                }

                Spacer()
            }
            .padding(.vertical, 20)
            .navigationTitle("Wireless Transfer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            _showManageSources = true
                        } label: {
                            Label(.localized("Manage Sources"), systemImage: "list.bullet.rectangle.portrait")
                        }

                        Button {
                            _importFromClipboard()
                        } label: {
                            Label(.localized("Import From Clipboard"), systemImage: "square.and.arrow.down")
                        }

                        Menu {
                            Button {
                                _exportThroughPortal()
                            } label: {
                                Label(.localized("Portal Transfer"), systemImage: "arrow.up.doc.fill")
                            }

                            Button {
                                _exportThroughQR()
                            } label: {
                                Label(.localized("QR Code"), systemImage: "qrcode")
                            }

                            Button {
                                _exportAsPlainURLs()
                            } label: {
                                Label(.localized("Plain URLs"), systemImage: "link")
                            }

                            Button {
                                isReceiveMode = false
                                transferService.stop()
                                transferService.startSendMode()
                            } label: {
                                Label(.localized("Share Wirelessly"), systemImage: "antenna.radiowaves.left.and.right")
                            }
                        } label: {
                            Label(.localized("Export Mode"), systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        transferService.stop()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $_showManageSources) {
                EditSourcesView(sources: _sourcesFetchedResults)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $_showQRMode) {
                SourcesQRView(data: _portalExportData)
            }
            .sheet(isPresented: $_showPortalExport) {
                PortalTransferView(exportData: $_portalExportData)
            }
            .onAppear {
                transferService.startSendMode()
                transferService.onSourcesReceived = { urls in
                    var added = 0
                    for url in urls {
                        if !Storage.shared.sourceExists(url) {
                            Storage.shared.addSource(url: url)
                            added += 1
                        }
                    }
                    receivedCount = added
                    withAnimation {
                        showSuccess = true
                    }
                    HapticsManager.shared.success()
                }
            }
            .onDisappear {
                transferService.stop()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isReceiveMode ? Color.cyan.opacity(0.15) : Color.blue.opacity(0.15))
                    .frame(width: 90, height: 90)

                if #available(iOS 18.0, *) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundStyle(isReceiveMode ? Color.cyan : Color.blue)
                        .symbolEffect(.variableColor.reversing)
                } else {
                    Image(systemName: isReceiveMode ? "wave.3.left.circle.fill" : "dot.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundStyle(isReceiveMode ? Color.cyan : Color.blue)
                }
            }
            .padding(.top, 10)

            VStack(spacing: 4) {
                Text(isReceiveMode ? "Ready To Receive" : "Sharing \(sourceURLs.count) Sources")
                    .font(.system(.title3, design: .rounded).bold())

                Text(isReceiveMode ? "Stay on this screen so Portal can search for nearby devices." : "Select a nearby device to send sources to.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    private var sendContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Nearby Devices")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.secondary)

                Spacer()

                if !transferService.discoveredPeers.isEmpty {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(.horizontal, 20)

            if transferService.discoveredPeers.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.accentColor.opacity(0.1), lineWidth: 2)
                            .frame(width: 100, height: 100)

                        Circle()
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 2)
                            .frame(width: 140, height: 140)
                            .scaleEffect(1.2)

                        ProgressView()
                            .scaleEffect(1.5)
                    }
                    .padding(.vertical, 20)

                    Text("Looking For Devices...")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(transferService.discoveredPeers, id: \.self) { peer in
                            Button {
                                transferService.sendSources(sourceURLs, to: peer)
                                HapticsManager.shared.impact()
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.accentColor.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "iphone")
                                            .font(.system(size: 20))
                                            .foregroundStyle(Color.accentColor)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(peer.displayName)
                                            .font(.system(.body, design: .rounded, weight: .bold))
                                        Text("Available For Transfer")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if case .connecting = transferService.state {
                                        ProgressView()
                                    } else {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.secondary.opacity(0.05)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Button {
                _exportThroughQR()
            } label: {
                HStack {
                    Image(systemName: "qrcode")
                        .font(.system(size: 18, weight: .bold))
                    Text("Share QR Code")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.accentColor.opacity(0.1)))
                .foregroundStyle(Color.accentColor)
            }
            .padding(.horizontal, 20)

            if case .completed = transferService.state {
                HStack(spacing: 12) {
                    if #available(iOS 18.0, *) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Text("Sent Successfully!")
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Capsule().fill(Color.green.opacity(0.1)))
                .padding(.horizontal, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private var receiveContent: some View {
        VStack(spacing: 32) {
            if showSuccess {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.15))
                            .frame(width: 100, height: 100)

                        if #available(iOS 18.0, *) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                                .symbolEffect(.bounce)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                        }
                    }

                    VStack(spacing: 8) {
                        Text("\(receivedCount) Sources Added")
                            .font(.system(.title3, design: .rounded).bold())

                        Text("Your sources are ready to use on the other device!")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                .padding(32)
                .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(Color.secondary.opacity(0.05)))
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.cyan.opacity(0.1), lineWidth: 4)
                            .frame(width: 120, height: 120)

                        Circle()
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 4)
                            .frame(width: 160, height: 160)
                            .scaleEffect(1.2)

                        ProgressView()
                            .scaleEffect(2.0)
                    }
                    .padding(.vertical, 20)

                    VStack(spacing: 8) {
                        Text("Discoverable As")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)

                        Text(UIDevice.current.name)
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.cyan.opacity(0.1)))
                            .foregroundStyle(.cyan)
                    }
                }
                .padding(.vertical, 20)
            }
        }
    }

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var _sourcesFetchedResults: FetchedResults<AltSource>

    private func _importFromClipboard() {
        guard let clipboard = UIPasteboard.general.string else { return }
        let handler = ASDeobfuscator(with: clipboard)
        let repoUrls = handler.decode()

        for url in repoUrls {
            Storage.shared.addSource(url: url)
        }

        HapticsManager.shared.success()
    }

    private func _exportThroughPortal() {
        _portalExportData = PortalSourceExport.encode(urls: sourceURLs)
        _showPortalExport = true
    }

    private func _exportThroughQR() {
        _portalExportData = PortalSourceExport.encode(urls: sourceURLs)
        _showQRMode = true
    }

    private func _exportAsPlainURLs() {
        let text = sourceURLs.joined(separator: "\n")
        UIPasteboard.general.string = text
        HapticsManager.shared.success()
    }

}
