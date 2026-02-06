import SwiftUI
import NimbleViews

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    var body: some View {
        NBNavigationView(.localized("Change Language")) {
            List {
                // Button to open iOS Settings for Portal's Language section
                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "gear")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(.blue)
                                .frame(width: 28, height: 28)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String.localized("Open Portal Settings"))
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Text(String.localized("Open iOS Settings for Portal to change system-level language and region preferences."))
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
                    Text(String.localized("To change Portal's language, go to iOS Settings > Portal > Language."))
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
