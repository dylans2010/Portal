import SwiftUI
import IDeviceSwift

struct ExportingIPAView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let app: AppInfoPresentable
    let onDismiss: () -> Void

    enum ExportPhase {
        case idle
        case packaging
        case failed(String)
    }

    @StateObject private var _exportStatus = InstallerStatusViewModel(isIdevice: false)
    @State private var _phase: ExportPhase = .idle
    @State private var _appeared = false
    @State private var _ringRotation: Double = 0
    @State private var _appSizeString: String = ""

    var body: some View {
        ZStack {
            ZStack {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                Color.clear
                    .background(.ultraThinMaterial)
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
            .onTapGesture {}

            VStack {
                Spacer()
                _sheetCard()
                    .offset(y: _appeared ? 0 : 400)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: _appeared)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .onAppear {
            withAnimation { _appeared = true }
            _computeAppSize()
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func _sheetCard() -> some View {
        VStack(spacing: 0) {
            _headerRow()
                .padding(.bottom, 20)
            _appInfoCard()
            _actionArea()
                .padding(.top, 28)
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 30)
        .background { _liquidGlassBackground(cornerRadius: 32) }
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 30, x: 0, y: -4)
        .shadow(color: .white.opacity(0.06), radius: 2, x: 0, y: -1)
    }

    @ViewBuilder
    private func _headerRow() -> some View {
        HStack {
            Text("Export IPA")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
            Button { onDismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background {
                        ZStack {
                            Circle().fill(.ultraThinMaterial)
                            Circle().fill(Color.primary.opacity(0.04))
                            Circle().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                        }
                    }
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private func _appInfoCard() -> some View {
        HStack(spacing: 14) {
            FRAppIconView(app: app, size: 60)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(app.name ?? "App")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    if !_appSizeString.isEmpty {
                        Text(_appSizeString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.primary.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                }
                if let version = app.version {
                    Text("Version \(version)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if let bundleID = app.identifier {
                    Text(bundleID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background { _liquidGlassBackground(cornerRadius: 22, tintOpacity: 0.03, borderOpacity: 0.15) }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - Action Area

    @ViewBuilder
    private func _actionArea() -> some View {
        switch _phase {
        case .idle:
            _exportButton()
        case .packaging:
            _packagingProgress()
        case .failed(let message):
            _failedSection(message: message)
        }
    }

    @ViewBuilder
    private func _exportButton() -> some View {
        Button { _startExport() } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Export IPA")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 220, height: 48)
            .background(Color.blue)
            .clipShape(Capsule())
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func _packagingProgress() -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: max(_exportStatus.packageProgress, 0.05))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90 + _ringRotation))
                    .animation(.easeInOut(duration: 0.4), value: _exportStatus.packageProgress)

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    _ringRotation = 360
                }
            }

            Text("Packaging IPA…")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func _failedSection(message: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.2), lineWidth: 4)
                    .frame(width: 56, height: 56)
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
            }
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
            Button { _startExport() } label: {
                Text("Retry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 220, height: 48)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Logic

    private func _startExport() {
        // Signed apps already have their IPA packaged – share directly.
        if let archiveURL = app.archiveURL {
            onDismiss()
            UIActivityViewController.show(activityItems: [archiveURL])
            HapticsManager.shared.success()
            return
        }

        // Unsigned/imported apps need to be packaged first.
        _phase = .packaging
        let handler = ArchiveHandler(app: app, viewModel: _exportStatus)

        Task.detached {
            do {
                try await handler.move()
                let packageUrl = try await handler.archive()

                let name = await app.name ?? "App"
                let version = await app.version ?? "1.0"
                let ipaFileName = "\(name)_\(version)_\(Int(Date().timeIntervalSince1970)).ipa"
                let dest = FileManager.default.archives.appendingPathComponent(ipaFileName)
                try FileManager.default.moveItem(at: packageUrl, to: dest)

                await MainActor.run {
                    onDismiss()
                    UIActivityViewController.show(activityItems: [dest])
                    HapticsManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    _phase = .failed(error.localizedDescription)
                }
            }
        }
    }

    private func _computeAppSize() {
        if let url = app.archiveURL {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? UInt64, size > 0 {
                _appSizeString = _formatBytes(size)
                return
            }
        }
        if let uuidDir = Storage.shared.getUuidDirectory(for: app) {
            let size = _directorySize(url: uuidDir)
            if size > 0 { _appSizeString = _formatBytes(UInt64(size)) }
        }
    }

    private func _formatBytes(_ bytes: UInt64) -> String {
        let mb = Double(bytes) / (1024 * 1024)
        let gb = mb / 1024
        return gb >= 1.0 ? String(format: "%.1f GB", gb) : String(format: "%.0f MB", max(mb, 1))
    }

    private func _directorySize(url: URL) -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let size = values.fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    // MARK: - Liquid Glass Background (matches InstallProgressView style)

    @ViewBuilder
    private func _liquidGlassBackground(
        cornerRadius: CGFloat,
        tintOpacity: Double = 0.08,
        borderOpacity: Double = 0.2
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.systemBackground).opacity(tintOpacity * 0.5))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(borderOpacity * 1.5),
                            Color.white.opacity(borderOpacity * 0.2),
                            Color.white.opacity(borderOpacity * 0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
}
