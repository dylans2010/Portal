import SwiftUI
import NimbleViews

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    var body: some View {
        NBNavigationView(.localized("Translation")) {
            List {
                // Button to open iOS Settings to Language & Region
                Section {
                    Button {
                        // Open iOS Settings app
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.blue)
                                .frame(width: 28, height: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String.localized("Change Language"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(String.localized("Open iOS Settings to change Portal's language and region."))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } footer: {
                    Text(.localized("Portal uses your iOS system language settings. Changes made in iOS Settings will apply when you restart Portal."))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Preview
#Preview {
    LanguageSettingsView()
}
