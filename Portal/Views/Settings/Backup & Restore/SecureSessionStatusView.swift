import SwiftUI

struct SecureSessionStatusView: View {
    @ObservedObject private var manager = SecureTransferSessionManager.shared
    @Environment(\.dismiss) var dismiss

    @State private var isInitializing = false

    var onStartTransfer: () -> Void

    var body: some View {
        List {
            if let session = manager.currentSession {
                Section {
                    HStack {
                        Text("Device Name")
                        Spacer()
                        Text(session.remoteDeviceName)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Method")
                        Spacer()
                        Text(session.transferMethod)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(session.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Encryption")
                        Spacer()
                        Text(session.encryptionType)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Fingerprint")
                        Spacer()
                        Text(session.sessionFingerprint)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Status")
                        Spacer()
                        if manager.isSessionValid(session) {
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else {
                            Label("Expired", systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Session Details")
                }

                Section {
                    Button(role: .destructive) {
                        manager.deleteSession()
                    } label: {
                        Label("Reset Session", systemImage: "trash")
                    }
                }
            } else {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)

                        Text("Secure Transfer")
                            .font(.headline)

                        Text("No active secure session. Start a secure transfer to generate pairing data.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)

                        Button {
                            isInitializing = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                onStartTransfer()
                                isInitializing = false
                            }
                        } label: {
                            HStack {
                                if isInitializing {
                                    ProgressView()
                                        .padding(.trailing, 8)
                                }
                                Text("Start Secure Transfer")
                                    .fontWeight(.semibold)
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isInitializing)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Secure Session Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
