// handler for custom URL schemes (new-portal://sources-add:source link here)

import Foundation

struct URLActionHandler {

    enum Action {
        
        case addSource(String)
    }

    static func parse(_ url: URL) -> Action? {
        let absoluteString = url.absoluteString

        if url.scheme == "new-portal" {

            if let range = absoluteString.range(of: "sources-add:") {
                let sourceValue = String(absoluteString[range.upperBound...])

                if !sourceValue.isEmpty, let decodedValue = sourceValue.removingPercentEncoding {

                    return .addSource(decodedValue)
                }
            }
        }

        return nil
    }
}
