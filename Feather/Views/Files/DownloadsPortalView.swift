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
    
    var id: String { url + name }
    
    enum CodingKeys: String, CodingKey {
        case name, description, url, icon, category, version, size
        case downloadURL 
        case note 
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)

        if let dURL = try? container.decode(String.self, forKey: .downloadURL) {
            url = dURL
        } else {
            url = try container.decode(String.self, forKey: .url)
        }

        if let note = try? container.decodeIfPresent(String.self, forKey: .note) {
            description = note
        } else {
            description = try? container.decodeIfPresent(String.self, forKey: .description)
        }

        icon = try? container.decodeIfPresent(String.self, forKey: .icon)
        category = try? container.decodeIfPresent(String.self, forKey: .category)
        version = try? container.decodeIfPresent(String.self, forKey: .version)
        size = try? container.decodeIfPresent(String.self, forKey: .size)
    }

    init(name: String, url: String, description: String?, icon: String?, category: String?) {
        self.name = name
        self.url = url
        self.description = description
        self.icon = icon
        self.category = category
        self.version = nil
        self.size = nil
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encodeIfPresent(size, forKey: .size)
    }
}

struct DownloadsPortalApp: Codable {
    let name: String
    let image: String?
    let certs: [DownloadsPortalCert]?
}

struct DownloadsPortalCert: Codable {
    let certName: String
    let downloadURL: String
}

struct DownloadsPortalResponse: Codable {
    var downloads: [DownloadsPortalItem] = []
    
    enum CodingKeys: String, CodingKey {
        case downloads, items, files, data, apps
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var allItems: [DownloadsPortalItem] = []

        if let files = try? container.decode([DownloadsPortalItem].self, forKey: .files) {
            allItems.append(contentsOf: files)
        }

        if let apps = try? container.decode([DownloadsPortalApp].self, forKey: .apps) {
            for app in apps {
                if let certs = app.certs {
                    for cert in certs {
                        allItems.append(DownloadsPortalItem(
                            name: "\(app.name) - \(cert.certName)",
                            url: cert.downloadURL,
                            description: "App From Downloads",
                            icon: "app.badge.fill",
                            category: "App"
                        ))
                    }
                }
            }
        }
        
        // Try other standard keys
        if let items = try? container.decode([DownloadsPortalItem].self, forKey: .downloads) {
            allItems.append(contentsOf: items)
        } else if let items = try? container.decode([DownloadsPortalItem].self, forKey: .items) {
            allItems.append(contentsOf: items)
        } else if let items = try? container.decode([DownloadsPortalItem].self, forKey: .data) {
            allItems.append(contentsOf: items)
        }
        
        // If still empty, try decoding the entire JSON as an array
        if allItems.isEmpty {
            let singleContainer = try decoder.singleValueContainer()
            if let items = try? singleContainer.decode([DownloadsPortalItem].self) {
                allItems.append(contentsOf: items)
            }
        }

        self.downloads = allItems
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(downloads, forKey: .downloads)
    }
}

struct DownloadQueueItem: Identifiable {
    let id: UUID = UUID()
    let item: DownloadsPortalItem
    var progress: Double = 0
    var status: DownloadStatus = .waiting

    enum DownloadStatus {
        case waiting, downloading, completed, failed
    }
}


class DownloadsPortalService: ObservableObject {
    @Published var items: [DownloadsPortalItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var rawJSONResponse: String?
    @Published var downloadQueue: [DownloadQueueItem] = []
    
    // placeholer link, will be updated later once this data is on the WSF repo
    private let githubURL = "https://raw.githubusercontent.com/WhySooooFurious/Ultimate-Sideloading-Guide/refs/heads/main/raw-files/downloads.json"
    
    func fetchDownloads() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        AppLogManager.shared.info("Starting Downloads fetch from: \(githubURL)", category: "Downloads")
        
        do {
            guard let url = URL(string: githubURL) else {
                throw NSError(domain: "DownloadsPortal", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            let jsonString = String(data: data, encoding: .utf8) ?? "Unable To Decode"
            await MainActor.run {
                self.rawJSONResponse = jsonString
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(DownloadsPortalResponse.self, from: data)
            
            await MainActor.run {
                self.items = decodedResponse.downloads
                self.isLoading = false
            }
            
            AppLogManager.shared.success("Successfully Loaded \(decodedResponse.downloads.count) Items", category: "Downloads")
            
        } catch {
            AppLogManager.shared.error("Fetch Error: \(error.localizedDescription)", category: "Downloads")
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
        NBNavigationView(.localized("Downloads"), displayMode: .inline) {
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
            
            Text(.localized("Loading Downloads"))
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
            
            Text(.localized("Check back here later for available downloads."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if !service.downloadQueue.isEmpty {
                    Section {
                        ForEach(service.downloadQueue) { queueItem in
                            HStack {
                                Image(systemName: "doc.fill")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading) {
                                    Text(queueItem.item.name)
                                        .font(.caption.bold())
                                    ProgressView(value: queueItem.progress)
                                        .progressViewStyle(.linear)
                                }
                                Text(queueItem.status == .downloading ? "\(Int(queueItem.progress * 100))%" : "Waiting")
                                    .font(.caption2)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } header: {
                        HStack {
                            Text("Downloads Queue")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }

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
                    
                    Text(.localized("Downloads"))
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(.localized("Download useful resources like public certificates, other signers, or .dylibs"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Download items
                ForEach(service.items) { item in
                    DownloadItemCard(item: item, service: service)
                }
            }
            .padding()
        }
    }
}

// MARK: - Download Item Card
struct DownloadItemCard: View {
    let item: DownloadsPortalItem
    @ObservedObject var service: DownloadsPortalService // Pass service to manage queue
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var showFileExporter = false
    @State private var tempFileURL: URL?
    
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
                addToQueueAndDownload()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.body)
                    Text(.localized("Download"))
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
        .overlay {
            if isDownloading {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)

                    VStack(spacing: 12) {
                        Circle()
                            .trim(from: 0, to: downloadProgress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .overlay {
                                Text("\(Int(downloadProgress * 100))%")
                                    .font(.caption2.bold())
                            }

                        Text("Downloading...")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .transition(AnyTransition.opacity)
            }
        }
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .fileExporter(isPresented: $showFileExporter, document: DataDocument(url: tempFileURL), contentType: .data) { result in
            switch result {
            case .success(let url):
                AppLogManager.shared.success("File Saved To: \(url.path)", category: "Downloads")
            case .failure(let error):
                AppLogManager.shared.error("Failed To Save File: \(error.localizedDescription)", category: "Downloads")
            }
            // Cleanup temp file
            if let tempURL = tempFileURL {
                try? FileManager.default.removeItem(at: tempURL)
            }
            tempFileURL = nil
        }
    }
    
    private func addToQueueAndDownload() {
        let queueItem = DownloadQueueItem(item: item, status: .waiting)
        service.downloadQueue.append(queueItem)

        downloadFile(queueItemID: queueItem.id)
    }

    private func downloadFile(queueItemID: UUID) {
        guard let url = URL(string: item.url) else { return }
        
        isDownloading = true
        downloadProgress = 0
        HapticsManager.shared.impact()
        
        // Update queue status
        if let index = service.downloadQueue.firstIndex(where: { $0.id == queueItemID }) {
            service.downloadQueue[index].status = .downloading
        }

        Task {
            do {

                let (data, _) = try await URLSession.shared.data(from: url)
                
                for i in 1...10 {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    await MainActor.run {
                        downloadProgress = Double(i) / 10.0
                        if let index = service.downloadQueue.firstIndex(where: { $0.id == queueItemID }) {
                            service.downloadQueue[index].progress = downloadProgress
                        }
                    }
                }

                let fileName = URL(string: item.url)?.lastPathComponent ?? "download"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                try data.write(to: tempURL)
                
                await MainActor.run {
                    self.tempFileURL = tempURL
                    self.isDownloading = false
                    if let index = service.downloadQueue.firstIndex(where: { $0.id == queueItemID }) {
                        service.downloadQueue[index].status = .completed
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            service.downloadQueue.removeAll(where: { $0.id == queueItemID })
                        }
                    }
                    HapticsManager.shared.success()
                    showFileExporter = true
                }
            } catch {
                await MainActor.run {
                    isDownloading = false
                    if let index = service.downloadQueue.firstIndex(where: { $0.id == queueItemID }) {
                        service.downloadQueue[index].status = .failed
                    }
                    HapticsManager.shared.error()
                    AppLogManager.shared.error("Failed to download file: \(error.localizedDescription)", category: "Files")
                }
            }
        }
    }
}

import UniformTypeIdentifiers
struct DataDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    var url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {

    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url else { throw NSError(domain: "DataDocument", code: -1) }
        return try FileWrapper(url: url)
    }
}
