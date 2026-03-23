import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import UIKit

struct AppAddView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var downloadManager = DownloadManager.shared

    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false

    // State for tracking the import process (matching LibraryView's needs)
    @State private var _importedAppName: String = ""
    @State private var _currentDownloadId: String = ""
    @State private var _downloadProgress: Double = 0.0
    @State private var _importStatus: ImportStatus = .loading
    @State private var _importErrorMessage: String = ""

    enum ImportStatus {
        case loading
        case downloading
        case processing
        case success
        case failed
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(String.localized("Sign App"))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .themedText(.primary)

                Text(String.localized("Choose between importing from files or downloading from a URL."))
                    .font(.subheadline)
                    .themedText(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            HStack(spacing: 20) {
                ImportOptionButton(
                    title: String.localized("From Files"),
                    icon: "folder.fill.badge.plus",
                    color: .blue,
                    action: {
                        _isImportingPresenting = true
                    }
                )

                ImportOptionButton(
                    title: String.localized("From URL"),
                    icon: "link.badge.plus",
                    color: .purple,
                    action: {
                        _isDownloadingPresenting = true
                    }
                )
            }
        }
        .padding(30)
        .globalTheme()
        .sheet(isPresented:  $_isImportingPresenting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.ipa, .tipa],
                allowsMultipleSelection: true,
                onDocumentsPicked: { urls in
                    guard !urls.isEmpty else { return }

                    for url in urls {
                        let id = "FeatherManualDownload_\(UUID().uuidString)"
                        let dl = downloadManager.startArchive(from: url, id: id)

                        _importedAppName = url.deletingPathExtension().lastPathComponent
                        _currentDownloadId = id
                        _importStatus = .processing
                        _importErrorMessage = ""

                        do {
                            try downloadManager.handlePachageFile(url: url, dl: dl)
                        } catch {
                            _importErrorMessage = error.localizedDescription
                        }
                    }
                    dismiss()
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $_isDownloadingPresenting) {
            ModernImportURLView { url in
                let downloadId = "FeatherManualDownload_\(UUID().uuidString)"
                _currentDownloadId = downloadId
                _importedAppName = url.deletingPathExtension().lastPathComponent
                _downloadProgress = 0.0
                _importStatus = .downloading
                _importErrorMessage = ""

                _ = downloadManager.startDownload(from: url, id: downloadId)
                dismiss()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct ImportOptionButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .themedText(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .themedCard()
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(color.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
