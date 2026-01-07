import SwiftUI
import NimbleViews

// MARK: - Downloads Portal Models
struct DownloadsPortalItem: Codable, Identifiable {
    let name: String
    let description: String?
    let url: String
    let icon: String?
    let category: String?
    
    var id: String { url }
}

struct DownloadsPortalResponse: Codable {
    let downloads: [DownloadsPortalItem]?
    
    enum CodingKeys: String, CodingKey {
        case downloads
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        downloads = try container.decodeIfPresent([DownloadsPortalItem].self, forKey: .downloads) ?? []
    }
}

// MARK: - Downloads Portal Service
class DownloadsPortalService: ObservableObject {
    @Published var items: [DownloadsPortalItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let githubURL = "https://raw.githubusercontent.com/WSF-Team/WSF/main/Portal/ConfigurationFiles/Downloads.json"
    
    func fetchDownloads() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            guard let url = URL(string: githubURL) else {
                throw NSError(domain: "DownloadsPortal", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Try to decode the response
            let response = try JSONDecoder().decode(DownloadsPortalResponse.self, from: data)
            
            await MainActor.run {
                self.items = response.downloads ?? []
                self.isLoading = false
            }
        } catch let decodingError as DecodingError {
            // Provide more specific error messages for decoding errors
            let errorDescription: String
            switch decodingError {
            case .keyNotFound(let key, _):
                errorDescription = "Missing key '\(key.stringValue)' in JSON data"
            case .typeMismatch(let type, _):
                errorDescription = "Type mismatch for expected type \(type)"
            case .valueNotFound(let type, _):
                errorDescription = "Missing value for type \(type)"
            case .dataCorrupted:
                errorDescription = "Data corrupted or invalid JSON format"
            @unknown default:
                errorDescription = "Unknown decoding error"
            }
            
            await MainActor.run {
                self.errorMessage = errorDescription
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Downloads Portal View
struct DownloadsPortalView: View {
    @StateObject private var service = DownloadsPortalService()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NBNavigationView(.localized("Downloads Portal"), displayMode: .inline) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color.accentColor.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if service.isLoading {
                    loadingView
                } else if let error = service.errorMessage {
                    errorView(error: error)
                } else if service.items.isEmpty {
                    emptyView
                } else {
                    contentView
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
            }
            .task {
                await service.fetchDownloads()
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(.localized("Loading Downloads..."))
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text(.localized("Error Loading Downloads"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                Task {
                    await service.fetchDownloads()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(.localized("Retry"))
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(Capsule())
            }
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(.localized("No Downloads Available"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(.localized("Check back later for available downloads"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.15),
                                        Color.accentColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    Text(.localized("Downloads Portal"))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(.localized("Browse and download files from the WSF portal"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Download items
                ForEach(service.items) { item in
                    DownloadItemCard(item: item)
                }
            }
            .padding()
        }
    }
}

// MARK: - Download Item Card
struct DownloadItemCard: View {
    let item: DownloadsPortalItem
    @State private var isDownloading = false
    @State private var showShareSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0.15),
                                    Color.accentColor.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: item.icon ?? "doc.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let description = item.description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let category = item.category {
                        Text(category)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
            
            // Download button
            Button {
                downloadFile()
            } label: {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.body)
                    }
                    Text(isDownloading ? .localized("Downloading...") : .localized("Download"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isDownloading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func downloadFile() {
        guard let url = URL(string: item.url) else { return }
        
        isDownloading = true
        HapticsManager.shared.impact()
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let fileName = URL(string: item.url)?.lastPathComponent ?? "download"
                let destinationURL = FileManagerService.shared.currentDirectory.appendingPathComponent(fileName)
                
                try data.write(to: destinationURL)
                
                await MainActor.run {
                    isDownloading = false
                    HapticsManager.shared.success()
                    FileManagerService.shared.loadFiles()
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    HapticsManager.shared.error()
                    AppLogManager.shared.error("Failed to download file: \(error.localizedDescription)", category: "Files")
                }
            }
        }
    }
}

// MARK: - Preview
struct DownloadsPortalView_Previews: PreviewProvider {
    static var previews: some View {
        DownloadsPortalView()
    }
}
