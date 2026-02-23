import SwiftUI
import OSLog

struct PortalTransferView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exportData: String

    @State private var showCopiedFeedback = false
    @State private var importText = ""
    @State private var isImportMode = false
    @State private var importResult: ImportResult?

    enum ImportResult {
        case success(count: Int)
        case error(message: String)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    headerSection
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    Picker("Mode", selection: $isImportMode) {
                        Text(.localized("Export")).tag(false)
                        Text(.localized("Import")).tag(true)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isImportMode) { _ in
                        importResult = nil
                        HapticsManager.shared.softImpact()
                    }
                }

                if isImportMode {
                    importSection
                } else {
                    exportSection
                }

                Section {
                    Label {
                        Text(isImportMode ? .localized("Paste the Portal code you received") : .localized("Copy the transfer code to share"))
                    } icon: {
                        Image(systemName: "1.circle.fill").foregroundStyle(.orange)
                    }

                    Label {
                        Text(isImportMode ? .localized("Tap Import to add the sources") : .localized("Send it to friends or save it"))
                    } icon: {
                        Image(systemName: "2.circle.fill").foregroundStyle(.orange)
                    }
                } header: {
                    Text(.localized("Quick Tips"))
                }
            }
            .navigationTitle(.localized("Portal Transfer"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isImportMode ? Color.cyan.opacity(0.1) : Color.purple.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: isImportMode ? "arrow.down.doc.fill" : "arrow.up.doc.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(isImportMode ? .cyan : .purple)
                    .symbolEffect(.bounce, value: isImportMode)
            }
            .padding(.top, 24)

            VStack(spacing: 8) {
                Text(isImportMode ? .localized("Import Sources") : .localized("Export Sources"))
                    .font(.title2.bold())
                
                Text(isImportMode ? .localized("Paste your Portal Transfer code to import.") : .localized("Share your sources with a Portal Transfer code."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }

    private var exportSection: some View {
        Group {
            Section {
                HStack {
                    Label(.localized("Transfer Code"), systemImage: "key.fill")
                    Spacer()
                    if !exportData.isEmpty {
                        Button {
                            UIPasteboard.general.string = exportData
                            HapticsManager.shared.success()
                            withAnimation { showCopiedFeedback = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopiedFeedback = false }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                Text(showCopiedFeedback ? .localized("Copied") : .localized("Copy Code"))
                            }
                            .font(.caption.bold())
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                        .controlSize(.small)
                    }
                }
            }

            Section {
                if !exportData.isEmpty {
                    Text(exportData)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                } else {
                    Text(.localized("No Data"))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var importSection: some View {
        Group {
            Section {
                HStack {
                    Label(.localized("Portal Code"), systemImage: "square.and.pencil")
                    Spacer()
                    Button {
                        if let clipboard = UIPasteboard.general.string {
                            importText = clipboard
                            HapticsManager.shared.softImpact()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard")
                            Text(.localized("Paste"))
                        }
                        .font(.caption.bold())
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)
                    .controlSize(.small)
                }
            }

            Section {
                ZStack(alignment: .topLeading) {
                    if importText.isEmpty {
                        Text("Paste code here...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.placeholder)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    TextEditor(text: $importText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                }
                .padding(8)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
            }

            Section {
                Button {
                    performImport()
                } label: {
                    Label(.localized("Import Sources"), systemImage: "arrow.down.circle.fill")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(importText.isEmpty)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowBackground(Color.clear)
            }

            if let result = importResult {
                Section {
                    switch result {
                    case .success(let count):
                        Label(.localized("\(count) Sources Added"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .symbolEffect(.appear, when: true)
                    case .error(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func performImport() {
        guard let urls = PortalSourceExport.decode(importText) else {
            withAnimation(.spring()) { importResult = .error(message: .localized("Invalid Portal Transfer Code")) }
            return
        }

        // Record session as authenticated (Manual method)
        SecureTransferSessionManager.shared.recordSessionAuthenticated(method: "Manual", remoteDeviceName: "Imported Code")

        var addedCount = 0
        for urlString in urls {
            if !Storage.shared.sourceExists(urlString) {
                Storage.shared.addSource(url: urlString)
                addedCount += 1
            }
        }

        if #available(iOS 17.0, *) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                importResult = .success(count: addedCount)
            }
        } else {
            withAnimation { importResult = .success(count: addedCount) }
        }
        HapticsManager.shared.success()
    }
}
