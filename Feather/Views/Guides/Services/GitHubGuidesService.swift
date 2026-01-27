import Foundation

// MARK: - GitHub Guides Service
class GitHubGuidesService {
    static let shared = GitHubGuidesService()
    
    private let baseURL = "https://api.github.com/repos/WSF-Team/WSF/contents/portal/guides"
    private let rawBaseURL = "https://raw.githubusercontent.com/WSF-Team/WSF/main/portal/guides"
    private let plistURL = "https://raw.githubusercontent.com/WSF-Team/WSF/main/portal/guides/markdown_filenames.plist"
    
    private init() {}
    
    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case noData
        case decodingError(Error)
        case contentNotAvailable
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid GitHub URL"
            case .networkError(let error):
                return "Network Error: \(error.localizedDescription)"
            case .noData:
                return "No Data Received"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .contentNotAvailable:
                return "Content Not Available"
            }
        }
    }
    
    // Fetch the ordering plist from GitHub
    private func fetchGuidesOrder() async throws -> [GuidePlistEntry] {
        guard let url = URL(string: plistURL) else {
            throw ServiceError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        do {
            let decoder = PropertyListDecoder()
            let entries = try decoder.decode([GuidePlistEntry].self, from: data)
            return entries
        } catch {
            throw ServiceError.decodingError(error)
        }
    }
    
    // Fetch list of guides from the GitHub repository using plist for ordering
    func fetchGuides() async throws -> [Guide] {
        // Fetch the plist for ordering and display names
        let plistEntries = try await fetchGuidesOrder()
        
        // Create guides based on plist order
        var guides: [Guide] = []
        
        for (index, entry) in plistEntries.enumerated() {
            let guide = Guide(
                id: "\(index)-\(entry.fileName)",
                name: entry.fileName,
                path: "Portal/Guides/\(entry.fileName)",
                type: .file,
                content: nil,
                customDisplayName: entry.fileTitle
            )
            guides.append(guide)
        }
        
        return guides
    }
    
    // Fetch content of a specific guide
    func fetchGuideContent(guide: Guide) async throws -> String {
        // For files, use the raw GitHub URL
        guard guide.type == .file else {
            throw ServiceError.contentNotAvailable
        }
        
        let contentURL = "\(rawBaseURL)/\(guide.name)"
        
        guard let url = URL(string: contentURL) else {
            throw ServiceError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let content = String(data: data, encoding: .utf8) else {
            throw ServiceError.noData
        }
        
        return content
    }
}
