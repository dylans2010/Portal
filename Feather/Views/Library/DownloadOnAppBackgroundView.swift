import SwiftUI

struct DownloadOnAppBackgroundView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @ObservedObject var downloadManager = DownloadManager.shared

    var body: some View {
        Group {
            if let download = downloadManager.downloads.first {
                VStack(spacing: 0) {
                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(themeManager.accentColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(download.fileName)
                                .font(.system(size: 14, weight: .bold))
                                .themedText(.primary)
                                .lineLimit(1)

                            HStack(spacing: 8) {
                                ProgressView(value: download.overallProgress)
                                    .themedAccent()
                                    .frame(width: 100)

                                Text("\(Int(download.overallProgress * 100))%")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .themedText(.secondary)
                            }
                        }

                        Spacer()

                        Button {
                            downloadManager.cancelDownload(download)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(), value: downloadManager.downloads.count)
    }
}
