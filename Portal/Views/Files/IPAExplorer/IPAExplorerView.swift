import SwiftUI
import NimbleViews

struct IPAExplorerView: View {
    @StateObject var viewModel: IPAExplorerViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NBNavigationView(.localized("Explore IPA"), displayMode: .inline) {
            Group {
                switch viewModel.state {
                case .idle, .hashing, .extracting, .indexing:
                    loadingView
                case .ready:
                    mainContent
                case .error(let message):
                    errorView(message)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.start()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: viewModel.progress)
                .progressViewStyle(.linear)
                .frame(width: 200)

            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusMessage: String {
        switch viewModel.state {
        case .hashing: return .localized("Hashing IPA...")
        case .extracting: return .localized("Extracting Payload...")
        case .indexing: return .localized("Indexing content...")
        default: return .localized("Starting...")
        }
    }

    private var mainContent: some View {
        List {
            if let summary = viewModel.summary {
                Section {
                    IPAExplorerSummaryHeader(summary: summary, isModified: viewModel.isModified, isValid: viewModel.checkIntegrity())
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section(.localized("Content")) {
                if let extractionURL = viewModel.extractionURL {
                    NavigationLink {
                        IPAExplorerFileBrowser(rootURL: extractionURL, currentURL: extractionURL, viewModel: viewModel)
                    } label: {
                        Label(.localized("Browse Files"), systemImage: "folder.fill")
                    }
                }

                if let appBundleURL = viewModel.appBundleURL {
                    NavigationLink {
                        IPAExplorerPlistViewer(fileURL: appBundleURL.appendingPathComponent("Info.plist"), viewModel: viewModel)
                    } label: {
                        Label("Info.plist", systemImage: "doc.badge.gearshape.fill")
                    }

                    let provisionURL = appBundleURL.appendingPathComponent("embedded.mobileprovision")
                    if FileManager.default.fileExists(atPath: provisionURL.path) {
                        NavigationLink {
                            IPAExplorerProvisionViewer(fileURL: provisionURL)
                        } label: {
                            Label("embedded.mobileprovision", systemImage: "doc.badge.key.fill")
                        }
                    }
                }
            }

            Section(.localized("Tools")) {
                Button {
                    exportIPA()
                } label: {
                    Label(.localized("Export IPA"), systemImage: "square.and.arrow.up")
                }
                .foregroundStyle(.blue)
            }

            Section(.localized("Hash")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHA-256")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.ipaHash)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
            .scrollContentBackground(.hidden)
    }

    private func exportIPA() {
        guard let appBundleURL = viewModel.appBundleURL else { return }
        // For exploration mode, we can export the original IPA URL
        // In a real scenario, we might want to repackage if modified, but for now we export the source
        UIActivityViewController.show(activityItems: [viewModel.ipaURL])
        HapticsManager.shared.success()
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            Text(.localized("Exploration Failed"))
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
