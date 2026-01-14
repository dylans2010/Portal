import SwiftUI
import NimbleViews

// MARK: - Downloads Portal Models
struct DownloadsPortalItem: Codable, Identifiable {
    let name: String
    let description: String?
    let url: String
    let icon: String?
    let category: String?
    let version: String?
    let size: String?
    
    var id: String { url }
    
    enum CodingKeys: String, CodingKey {
        case name, description, url, icon, category, version, size
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        url = try container.decode(String.self, forKey: .url)
        icon = try? container.decodeIfPresent(String.self, forKey: .icon)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        version = try? container.decodeIfPresent(String.self, forKey: .version)
        size = try? container.decodeIfPresent(String.self, forKey: .size)
    }
}

struct DownloadsPortalResponse: Codable {
    let downloads: [DownloadsPortalItem]
    
    enum CodingKeys: String, CodingKey {
        case downloads, items, files, data
    }
    
    init(downloads: [DownloadsPortalItem] = []) {
        self.downloads = downloads
    }
    
    init(from decoder: Decoder) throws {
        // Try multiple possible JSON structures
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            // Try "downloads" key first
            if let items = try? container.decode([DownloadsPortalItem].self, forKey: .downloads) {
                downloads = items
                return
            }
            // Try "items" key
            if let items = try? container.decode([DownloadsPortalItem].self, forKey: .items) {
                downloads = items
                return
            }
            // Try "files" key
            if let items = try? container.decode([DownloadsPortalItem].self, forKey: .files) {
                downloads = items
                return
            }
            // Try "data" key
            if let items = try? container.decode([DownloadsPortalItem].self, forKey: .data) {
                downloads = items
                return
            }
        }
        
        // Try decoding the entire JSON as an array
        let singleContainer = try decoder.singleValueContainer()
        if let items = try? singleContainer.decode([DownloadsPortalItem].self) {
            downloads = items
            return
        }
        
        // If all else fails, return empty array
        downloads = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloads, forKey: .downloads)
    }
}

// MARK: - Downloads Portal Service
class DownloadsPortalService: ObservableObject {
    @Published var items: [DownloadsPortalItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var rawJSONResponse: String?
    
    private let githubURL = "https://raw.githubusercontent.com/WSF-Team/WSF/main/Portal/ConfigurationFiles/Downloads.json"
    
    func fetchDownloads() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            rawJSONResponse = nil
        }
        
        AppLogManager.shared.info("Starting Downloads Portal fetch from: \(githubURL)", category: "Downloads")
        
        do {
            guard let url = URL(string: githubURL) else {
                let error = "Invalid URL: \(githubURL)"
                AppLogManager.shared.error(error, category: "Downloads")
                throw NSError(domain: "DownloadsPortal", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
            }
            
            AppLogManager.shared.debug("Fetching data from URL...", category: "Downloads")
            
            let (data, urlResponse) = try await URLSession.shared.data(from: url)
            
            // Log HTTP response
            if let httpResponse = urlResponse as? HTTPURLResponse {
                AppLogManager.shared.info("HTTP Status Code: \(httpResponse.statusCode)", category: "Downloads")
                
                if httpResponse.statusCode != 200 {
                    let error = "HTTP Error: Status code \(httpResponse.statusCode)"
                    AppLogManager.shared.error(error, category: "Downloads")
                    throw NSError(domain: "DownloadsPortal", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: error])
                }
            }
            
            // Log raw JSON for debugging
            let jsonString = String(data: data, encoding: .utf8) ?? "Unable to decode as UTF-8"
            AppLogManager.shared.debug("Raw JSON Response (\(data.count) bytes):\n\(jsonString.prefix(1000))...", category: "Downloads")
            
            await MainActor.run {
                self.rawJSONResponse = jsonString
            }
            
            // Check if data is empty
            if data.isEmpty {
                let error = "Empty response from server"
                AppLogManager.shared.error(error, category: "Downloads")
                throw NSError(domain: "DownloadsPortal", code: -2, userInfo: [NSLocalizedDescriptionKey: error])
            }
            
            // Try to parse as JSON first to check structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) {
                AppLogManager.shared.debug("JSON Type: \(type(of: jsonObject))", category: "Downloads")
                
                if let dict = jsonObject as? [String: Any] {
                    AppLogManager.shared.debug("JSON Keys: \(dict.keys.joined(separator: ", "))", category: "Downloads")
                } else if let array = jsonObject as? [[String: Any]] {
                    AppLogManager.shared.debug("JSON is array with \(array.count) items", category: "Downloads")
                }
            }
            
            // Try to decode the response
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(DownloadsPortalResponse.self, from: data)
            
            await MainActor.run {
                self.items = decodedResponse.downloads
                self.isLoading = false
            }
            
            AppLogManager.shared.success("Successfully loaded \(decodedResponse.downloads.count) download items", category: "Downloads")
            
            // Log each item
            for (index, item) in decodedResponse.downloads.enumerated() {
                AppLogManager.shared.debug("Item \(index + 1): \(item.name) - \(item.url)", category: "Downloads")
            }
            
        } catch let decodingError as DecodingError {
            let errorDescription = formatDecodingError(decodingError)
            AppLogManager.shared.error("Decoding Error: \(errorDescription)", category: "Downloads")
            
            await MainActor.run {
                self.errorMessage = errorDescription
                self.isLoading = false
            }
        } catch let urlError as URLError {
            let errorDescription = "Network Error: \(urlError.localizedDescription) (Code: \(urlError.code.rawValue))"
            AppLogManager.shared.error(errorDescription, category: "Downloads")
            
            await MainActor.run {
                self.errorMessage = errorDescription
                self.isLoading = false
            }
        } catch {
            let errorDescription = "Error: \(error.localizedDescription)"
            AppLogManager.shared.error(errorDescription, category: "Downloads")
            
            await MainActor.run {
                self.errorMessage = errorDescription
                self.isLoading = false
            }
        }
    }
    
    private func formatDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .keyNotFound(let key, let context):
            return "Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))"
        case .typeMismatch(let type, let context):
            return "Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> ")). \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "Missing value for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))"
        case .dataCorrupted(let context):
            return "Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> ")). \(context.debugDescription)"
        @unknown default:
            return "Unknown decoding error: \(error)"
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
