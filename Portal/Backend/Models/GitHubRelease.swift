import Foundation

// MARK: - GitHub Release Model
struct GitHubRelease: Codable, Identifiable {
    let id: Int
    let tagName: String
    let name: String
    let body: String?
    let prerelease: Bool
    let draft: Bool
    let publishedAt: Date?
    let htmlUrl: String
    let assets: [GitHubAsset]

    enum CodingKeys: String, CodingKey {
        case id
        case tagName = "tag_name"
        case name
        case body
        case prerelease
        case draft
        case publishedAt = "published_at"
        case htmlUrl = "html_url"
        case assets
    }
}

struct GitHubAsset: Codable, Identifiable {
    let id: Int
    let name: String
    let size: Int
    let downloadCount: Int
    let browserDownloadUrl: String

    enum CodingKeys: String, CodingKey {
        case id, name, size
        case downloadCount = "download_count"
        case browserDownloadUrl = "browser_download_url"
    }
}
