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
        List {
            // Header Section
            Section {
                headerSection
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            // Version List
            Section {
                ForEach(Array(versions.enumerated()), id: \.element.id) { index, version in
                    versionCard(version: version, isLatest: index == 0)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .background(
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        dominantColor.opacity(0.25),
                        dominantColor.opacity(0.15),
                        dominantColor.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                
                Color.clear
            }
            .ignoresSafeArea()
        )
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
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedVersions.remove(version.version)
                    } else {
                        expandedVersions.insert(version.version)
                    }
                }
                HapticsManager.shared.softImpact()
            } label: {
                HStack(spacing: 16) {
                    // Modern status indicator
                    Circle()
                        .fill(isLatest ? dominantColor : Color.secondary.opacity(0.2))
                        .frame(width: 8, height: 8)
                        .overlay {
                            if isLatest {
                                Circle()
                                    .stroke(dominantColor.opacity(0.3), lineWidth: 4)
                                    .frame(width: 16, height: 16)
                            }
                        }
                        .frame(width: 20)
                    
                    // Version Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Version \(version.version)")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            if isLatest {
                                Text("Latest")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(dominantColor))
                            }
                        }
                        
                        if let date = version.date?.date {
                            Text(date, style: .date)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 20) {
                    // Release Notes
                    if let description = version.localizedDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Release Notes", systemImage: "doc.text.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(dominantColor)
                            
                            Text(description)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.leading, 36)
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
                                HStack(spacing: 8) {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("Download")
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(dominantColor))
                            }
                            
                            Button {
                                UIPasteboard.general.string = downloadURL.absoluteString
                                HapticsManager.shared.success()
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(dominantColor)
                                    .padding(10)
                                    .background(Circle().fill(dominantColor.opacity(0.1)))
                            }
                        }
                        .padding(.leading, 36)
                    }
                }
                .padding(.bottom, 24)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if !isLatest {
                Divider().padding(.leading, 36)
            }
        }
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
