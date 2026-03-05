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
        VStack(spacing: 12) {
            Image(systemName: isImportMode ? "arrow.down.doc.fill" : "arrow.up.doc.fill")
                .font(.system(size: 64))
                .foregroundStyle(isImportMode ? AnyShapeStyle(.cyan.gradient) : AnyShapeStyle(.purple.gradient))
                .pulseEffect(true)
                .padding(.top, 20)

            Text(isImportMode ? .localized("Import Sources") : .localized("Export Sources"))
                .font(.system(.title2, design: .rounded).bold())

            Text(isImportMode ? .localized("Paste your Portal Transfer code to import.") : .localized("Share your sources with a Portal Transfer code."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(), value: isImportMode)
    }

    private var exportSection: some View {
        Group {
            Section {
                if !exportData.isEmpty {
                    Text(exportData)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemFill).opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.vertical, 8)
                } else {
                    Text(.localized("No Data"))
                        .foregroundStyle(.secondary)
                }
            } header: {
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
                                Text(showCopiedFeedback ? .localized("Copied") : .localized("Copy"))
                            }
                            .font(.caption.bold())
                        }
                        .bounceEffect(showCopiedFeedback)
                    }
                }
            }
        }
    }

    private var importSection: some View {
        Group {
            Section {
                TextEditor(text: $importText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(UIColor.secondarySystemFill).opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.vertical, 8)
            } header: {
                HStack {
                    Label(.localized("Portal Code"), systemImage: "square.and.pencil")
                    Spacer()
                    Button {
                        if let clipboard = UIPasteboard.general.string {
                            withAnimation {
                                importText = clipboard
                            }
                            HapticsManager.shared.softImpact()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.clipboard.fill")
                            Text(.localized("Paste"))
                        }
                        .font(.caption.bold())
                    }
                }
            }

            Section {
                Button {
                    withAnimation(.spring()) {
                        performImport()
                    }
                } label: {
                    Label(.localized("Import Sources"), systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled(importText.isEmpty)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if let result = importResult {
                Section {
                    switch result {
                    case .success(let count):
                        Label(.localized("\(count) Sources Added"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    case .error(let message):
                        Label(message, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private func performImport() {
        guard let urls = PortalSourceExport.decode(importText) else {
            withAnimation { importResult = .error(message: .localized("Invalid Portal Transfer Code")) }
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

        withAnimation { importResult = .success(count: addedCount) }
        HapticsManager.shared.success()
    }
}
