import Foundation

// MARK: - Guide Plist Entry (for ordering and display names)
struct GuidePlistEntry: Codable {
    let fileTitle: String
    let fileName: String
    
    enum CodingKeys: String, CodingKey {
        case fileTitle = "file_title"
        case fileName = "file_name"
    }
}

// MARK: - Guide Model
struct Guide: Identifiable, Codable {
    let id: String
    let name: String
    let path: String
    let type: GuideType
    var content: String?
    var customDisplayName: String?
    
    enum GuideType: String, Codable {
        case file
        case directory = "dir"
    }
    
    var displayName: String {
        // Use custom display name from plist if available
        if let custom = customDisplayName {
            return custom
        }
        // Fallback: Remove .md extension and format name
        let nameWithoutExtension = name.replacingOccurrences(of: ".md", with: "")
        return nameWithoutExtension.replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
}

// MARK: - GitHub API Response
struct GitHubContent: Codable {
    let name: String
    let path: String
    let sha: String
    let size: Int?
    let url: String
    let htmlUrl: String?
    let gitUrl: String?
    let downloadUrl: String?
    let type: String
    
    enum CodingKeys: String, CodingKey {
        case name, path, sha, size, url, type
        case htmlUrl = "html_url"
        case gitUrl = "git_url"
        case downloadUrl = "download_url"
    }
}

// MARK: - Parsed Guide Content
struct ParsedGuideContent {
    var elements: [GuideElement]
}

// Inline content segment (text or link)
enum InlineContent: Identifiable {
    case text(String)
    case link(url: String, text: String)
    case accentText(String)  // Text that should use accent color
    case accentLink(url: String, text: String)  // Link with accent color
    
    var id: String {
        switch self {
        case .text(let text):
            return "text-\(text.hashValue)"
        case .link(let url, let text):
            return "link-\(url.hashValue)-\(text.hashValue)"
        case .accentText(let text):
            return "accent-text-\(text.hashValue)"
        case .accentLink(let url, let text):
            return "accent-link-\(url.hashValue)-\(text.hashValue)"
        }
    }
}

enum GuideElement: Identifiable {
    case heading(level: Int, text: String, isAccent: Bool)
    case paragraph(content: [InlineContent])
    case codeBlock(language: String?, code: String)
    case image(url: String, altText: String?)
    case link(url: String, text: String)
    case listItem(level: Int, content: [InlineContent])
    case blockquote(content: [InlineContent])
    
    var id: String {
        switch self {
        case .heading(let level, let text, let isAccent):
            return "heading-\(level)-\(text.hashValue)-\(isAccent)"
        case .paragraph(let content):
            return "paragraph-\(content.map { $0.id }.joined().hashValue)"
        case .codeBlock(let language, let code):
            return "code-\(language ?? "none")-\(code.hashValue)"
        case .image(let url, _):
            return "image-\(url.hashValue)"
        case .link(let url, let text):
            return "link-\(url)-\(text.hashValue)"
        case .listItem(let level, let content):
            return "list-\(level)-\(content.map { $0.id }.joined().hashValue)"
        case .blockquote(let content):
            return "quote-\(content.map { $0.id }.joined().hashValue)"
        }
    }
}
