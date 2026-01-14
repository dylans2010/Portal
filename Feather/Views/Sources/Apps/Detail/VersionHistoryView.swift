import SwiftUI
import AltSourceKit

// MARK: - VersionHistoryView
struct VersionHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var dominantColor: Color = .accentColor
    @State private var expandedVersions: Set<String> = []
    
    let app: ASRepository.App
    let versions: [ASRepository.App.Version]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Version List
                LazyVStack(spacing: 0) {
                    ForEach(Array(versions.enumerated()), id: \.element.id) { index, version in
                        VStack(spacing: 0) {
                            versionCard(version: version, isLatest: index == 0)
                            
                            if index < versions.count - 1 {
                                // Timeline connector
                                HStack {
                                    Rectangle()
                                        .fill(dominantColor.opacity(0.2))
                                        .frame(width: 2, height: 20)
                                        .padding(.leading, 33)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(.localized("Version History"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if let iconURL = app.iconURL {
                extractDominantColor(from: iconURL)
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Group {
                if let iconURL = app.iconURL {
                    AsyncImage(url: iconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            iconPlaceholder
                        }
                    }
                } else {
                    iconPlaceholder
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: dominantColor.opacity(0.3), radius: 12, x: 0, y: 6)
            
            VStack(spacing: 4) {
                Text(app.currentName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                
                Text("\(versions.count) \(versions.count == 1 ? "Version" : "Versions")")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.15),
                    dominantColor.opacity(0.05),
                    Color(UIColor.systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            )
    }
    
    // MARK: - Version Card
    @ViewBuilder
    private func versionCard(version: ASRepository.App.Version, isLatest: Bool) -> some View {
        let isExpanded = expandedVersions.contains(version.version)
        
        VStack(alignment: .leading, spacing: 0) {
            // Main Row
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedVersions.remove(version.version)
                    } else {
                        expandedVersions.insert(version.version)
                    }
                }
                HapticsManager.shared.softImpact()
            } label: {
                HStack(spacing: 14) {
                    // Timeline dot
                    ZStack {
                        Circle()
                            .fill(isLatest ? dominantColor : dominantColor.opacity(0.2))
                            .frame(width: 12, height: 12)
                        
                        if isLatest {
                            Circle()
                                .stroke(dominantColor.opacity(0.3), lineWidth: 4)
                                .frame(width: 20, height: 20)
                        }
                    }
                    .frame(width: 24)
                    
                    // Version Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("v\(version.version)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)
                            
                            if isLatest {
                                Text("LATEST")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(dominantColor)
                                    )
                            }
                        }
                        
                        if let date = version.date?.date {
                            Text(date, style: .date)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.leading, 38)
                    
                    // Release Notes
                    if let description = version.localizedDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                    .foregroundStyle(dominantColor)
                                Text(.localized("Release Notes"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 38)
                            
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.leading, 38)
                        }
                    } else {
                        Text(.localized("No release notes available"))
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .italic()
                            .padding(.leading, 38)
                    }
                    
                    // Action Buttons
                    if let downloadURL = version.downloadURL {
                        HStack(spacing: 12) {
                            Button {
                                _ = DownloadManager.shared.startDownload(
                                    from: downloadURL,
                                    id: app.currentUniqueId
                                )
                                HapticsManager.shared.success()
                                dismiss()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: 14))
                                    Text(.localized("Download"))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(dominantColor)
                                )
                            }
                            
                            Button {
                                UIPasteboard.general.string = downloadURL.absoluteString
                                HapticsManager.shared.success()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 14))
                                    Text(.localized("Copy URL"))
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundStyle(dominantColor)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .stroke(dominantColor, lineWidth: 1.5)
                                )
                            }
                        }
                        .padding(.leading, 38)
                    }
                }
                .padding(.bottom, 16)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isLatest ? dominantColor.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
    
    // MARK: - Color Extraction
    private func extractDominantColor(from url: URL) {
        Task {
            guard let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else { return }
            
            let ciImage = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CIAreaAverage")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
            
            guard let outputImage = filter?.outputImage else { return }
            
            var pixel = [UInt8](repeating: 0, count: 4)
            CIContext().render(
                outputImage,
                toBitmap: &pixel,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: nil
            )
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dominantColor = Color(red: Double(pixel[0]) / 255.0, green: Double(pixel[1]) / 255.0, blue: Double(pixel[2]) / 255.0)
                }
            }
        }
    }
}
