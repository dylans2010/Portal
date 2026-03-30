import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import UIKit

struct AppAddView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var downloadManager = DownloadManager.shared

    @State private var _isImportingPresenting = false
    @State private var _isDownloadingPresenting = false

    var body: some View {
        VStack(spacing: 24) {
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
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 24)
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
                        do {
                            try downloadManager.handlePachageFile(url: url, dl: dl)
                        } catch {
                            AppLogManager.shared.error(error.localizedDescription, category: "Import")
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
                _ = downloadManager.startDownload(from: url, id: downloadId)
                dismiss()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

struct ImportOptionButton: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 54, height: 54)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(color)
                }

                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .themedText(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .themedCard()
        }
        .buttonStyle(.plain)
    }
}
