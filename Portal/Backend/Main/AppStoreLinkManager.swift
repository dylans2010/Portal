import Foundation

@MainActor
class AppStoreLinkManager: ObservableObject {
    static let shared = AppStoreLinkManager()

    private init() {}

    func fetchAppStoreURL(bundleId: String) async -> URL? {
        // Use the iTunes Search API to lookup by bundleId
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let result = try JSONDecoder().decode(AppStoreLookupResult.self, from: data)

            if let firstApp = result.results.first {
                return URL(string: firstApp.trackViewUrl)
            }
        } catch {
            print("❌ App Store lookup failed for \(bundleId): \(error.localizedDescription)")
        }

        return nil
    }
}

// MARK: - Models for iTunes API

struct AppStoreLookupResult: Codable {
    let resultCount: Int
    let results: [AppStoreAppInfo]
}

struct AppStoreAppInfo: Codable {
    let trackViewUrl: String
    let bundleId: String
}
