
import SwiftUI
import AltSourceKit

// MARK: - VersionHistoryView
struct VersionHistoryView: View {
	@Environment(\.dismiss) var dismiss
	@State private var dominantColor: Color = .accentColor
	
    let app: ASRepository.App
    let versions: [ASRepository.App.Version]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(versions) { version in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            // Version badge
                            ZStack {
                                Circle()
                                    .fill(dominantColor.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(dominantColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                // Version number
                                Text(version.version)
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                // Date
                                if let date = version.date?.date {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Download button
                            if let downloadURL = version.downloadURL {
                                Menu {
                                    Button {
                                        _ = DownloadManager.shared.startDownload(
                                            from: downloadURL,
                                            id: app.currentUniqueId
                                        )
                                        dismiss()
                                    } label: {
                                        Label("Download", systemImage: "arrow.down.circle")
                                    }
                                    
                                    Button {
                                        UIPasteboard.general.string = downloadURL.absoluteString
                                    } label: {
                                        Label(.localized("Copy Download URL"), systemImage: "doc.on.clipboard")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(dominantColor)
                                }
                            }
                        }
                        
                        // Release notes
                        if let description = version.localizedDescription, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("Release Notes")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text(description)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 4)
                        } else {
                            Text(.localized("No Release Notes Available"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(dominantColor.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(color: dominantColor.opacity(0.08), radius: 4, x: 0, y: 2)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            if let iconURL = app.iconURL {
                extractDominantColor(from: iconURL)
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
            
            let r = Double(pixel[0]) / 255.0
            let g = Double(pixel[1]) / 255.0
            let b = Double(pixel[2]) / 255.0
            
            await MainActor.run {
                dominantColor = Color(red: r, green: g, blue: b)
            }
        }
    }
}

