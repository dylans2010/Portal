import Foundation

/// A reusable utility to parse custom Portal URL schemes.
struct URLActionHandler {

    /// Represents supported URL-based actions.
    enum Action {
        /// Adds a new source to the application.
        case addSource(String)
    }

    /// Parses a URL to determine if it matches a supported Portal action.
    ///
    /// Supported formats:
    /// - new-portal://sources-add:<domain-or-url>
    ///
    /// - Parameter url: The URL to parse.
    /// - Returns: A matching `Action` if the URL is valid and supported, otherwise `nil`.
    static func parse(_ url: URL) -> Action? {
        let absoluteString = url.absoluteString

        // Handle new-portal:// scheme
        if url.scheme == "new-portal" {
            // new-portal://sources-add:<domain-or-url>
            // We use range(of:) because the standard URL parser might not handle the second colon as expected for all inputs.
            if let range = absoluteString.range(of: "sources-add:") {
                let sourceValue = String(absoluteString[range.upperBound...])

                // Removing percent encoding ensures that passed URLs are correctly formatted before processing.
                if !sourceValue.isEmpty, let decodedValue = sourceValue.removingPercentEncoding {
                    // We return the raw value and let FR.handleSource handle normalization to ensure
                    // it uses the exact same logic as manual entry in SourcesAddView.
                    return .addSource(decodedValue)
                }
            }
        }

        return nil
    }
}
