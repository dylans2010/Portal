import SwiftUI
import NimbleViews

// MARK: - Language Settings View
struct LanguageSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "en"
    @State private var showRestartAlert = false
    @State private var selectedLanguage: AppLanguage = .english
    
    var body: some View {
        NBNavigationView(.localized("Translation")) {
            List {
                // Button to open iOS Settings
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
                }
                
            }
            .listStyle(.insetGrouped)
        }
        .alert(.localized("Restart Required"), isPresented: $showRestartAlert) {
            Button(.localized("Cancel"), role: .cancel) { }
            Button(.localized("Restart App")) {
                changeLanguageAndRestart(to: selectedLanguage)
            }
        } message: {
            Text(String.localized("The app needs to restart to change the language to %@. Do you want to continue?", arguments: selectedLanguage.displayName))
        }
        .onAppear {
            // Set current language on appear
            if let currentLang = AppLanguage.allCases.first(where: { $0.code == appLanguage }) {
                selectedLanguage = currentLang
            }
        }
    }
    
    private func changeLanguageAndRestart(to language: AppLanguage) {
        // Save the language preference
        appLanguage = language.code
        TranslationService.shared.setLanguage(language.code)
        
        // Give a moment for settings to save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Exit and restart the app
            exit(0)
        }
    }
}

// MARK: - Preview
#Preview {
    LanguageSettingsView()
}
