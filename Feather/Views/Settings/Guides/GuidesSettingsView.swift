import SwiftUI
import NimbleViews

struct GuidesSettingsView: View {
    @StateObject private var settingsManager = GuideAISettingsManager.shared
    @State private var apiKeyInput: String = ""
    @State private var customModelInput: String = ""
    @State private var showingAPIKeyAlert = false
    @State private var showingDeleteKeyAlert = false
    @State private var guides: [Guide] = []
    @State private var isLoadingGuides = false
    @State private var guidesError: String?
    
    var body: some View {
        NBNavigationView(.localized("Guides Settings"), displayMode: .inline) {
            Form {
                openRouterSection
                perGuideSection
            }
        }
        .task {
            await loadGuides()
        }
        .alert("Save API Key", isPresented: $showingAPIKeyAlert) {
            SecureField("API Key", text: $apiKeyInput)
            Button("Cancel", role: .cancel) {
                apiKeyInput = ""
            }
            Button("Save") {
                saveAPIKey()
            }
        } message: {
            Text("Enter your OpenRouter API key. It will be stored securely in the Keychain.")
        }
        .alert("Delete API Key", isPresented: $showingDeleteKeyAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAPIKey()
            }
        } message: {
            Text("Are you sure you want to delete your OpenRouter API key?")
        }
    }
    
    @ViewBuilder
    private var openRouterSection: some View {
        NBSection(.localized("OpenRouter Configuration")) {
            // API Key
            HStack {
                ConditionalLabel(title: .localized("API Key"), systemImage: "key.fill")
                Spacer()
                if settingsManager.hasAPIKey {
                    HStack(spacing: 8) {
                        Text("••••••••")
                            .foregroundStyle(.secondary)
                        Button {
                            showingDeleteKeyAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                    }
                } else {
                    Button("Add Key") {
                        showingAPIKeyAlert = true
                    }
                }
            }
            
            // Model Selection
            Picker(selection: Binding(
                get: { settingsManager.openRouterModel },
                set: { settingsManager.saveOpenRouterModel($0) }
            )) {
                ForEach(GuideAISettingsManager.defaultModels, id: \.self) { model in
                    Text(formatModelName(model))
                        .tag(model)
                }
            } label: {
                ConditionalLabel(title: .localized("AI Model"), systemImage: "cpu")
            }
            .pickerStyle(.menu)
            
            // Custom Model Input
            HStack {
                ConditionalLabel(title: .localized("Custom Model"), systemImage: "pencil")
                Spacer()
                TextField("model/name", text: $customModelInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 180)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onSubmit {
                        if !customModelInput.isEmpty {
                            settingsManager.saveOpenRouterModel(customModelInput)
                            customModelInput = ""
                            HapticsManager.shared.success()
                        }
                    }
            }
        } footer: {
            Text(.localized("Configure your OpenRouter API key and select the AI model to use. Get your API key from openrouter.ai"))
        }
        
        NBSection(.localized("Apple Intelligence")) {
            HStack {
                ConditionalLabel(title: .localized("Availability"), systemImage: "apple.logo")
                Spacer()
                if AppleIntelligenceService.shared.isAvailable {
                    Label("Available", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                } else {
                    Label("Not Available", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        } footer: {
            if AppleIntelligenceService.shared.isAvailable {
                Text(.localized("Apple Intelligence is available on this device. You can select it as the AI engine for individual guides."))
            } else {
                Text(.localized("Apple Intelligence is not available on this device. OpenRouter will be used as the AI engine."))
            }
        }
    }
    
    @ViewBuilder
    private var perGuideSection: some View {
        NBSection(.localized("Per-Guide AI Settings")) {
            if isLoadingGuides {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = guidesError {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            await loadGuides()
                        }
                    }
                    .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if guides.isEmpty {
                Text("No guides available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(guides) { guide in
                    GuideAISettingsRow(guide: guide, settingsManager: settingsManager)
                }
            }
        } footer: {
            Text(.localized("Enable or disable AI features and select the AI engine for each guide individually."))
        }
    }
    
    private func formatModelName(_ model: String) -> String {
        let parts = model.split(separator: "/")
        if parts.count == 2 {
            return String(parts[1]).replacingOccurrences(of: "-", with: " ").capitalized
        }
        return model
    }
    
    private func saveAPIKey() {
        guard !apiKeyInput.isEmpty else { return }
        do {
            try settingsManager.saveAPIKey(apiKeyInput)
            apiKeyInput = ""
            HapticsManager.shared.success()
        } catch {
            AppLogManager.shared.error("Failed to save API key: \(error.localizedDescription)", category: "GuidesSettings")
        }
    }
    
    private func deleteAPIKey() {
        do {
            try settingsManager.deleteAPIKey()
            HapticsManager.shared.success()
        } catch {
            AppLogManager.shared.error("Failed to delete API key: \(error.localizedDescription)", category: "GuidesSettings")
        }
    }
    
    private func loadGuides() async {
        isLoadingGuides = true
        guidesError = nil
        
        do {
            guides = try await GitHubGuidesService.shared.fetchGuides()
            isLoadingGuides = false
        } catch {
            guidesError = error.localizedDescription
            isLoadingGuides = false
        }
    }
}

struct GuideAISettingsRow: View {
    let guide: Guide
    @ObservedObject var settingsManager: GuideAISettingsManager
    
    private var preference: GuideAIPreference {
        settingsManager.getPreference(for: guide.id)
    }
    
    var body: some View {
        DisclosureGroup {
            VStack(spacing: 12) {
                // AI Enabled Toggle
                Toggle(isOn: Binding(
                    get: { preference.aiEnabled },
                    set: { settingsManager.setAIEnabled($0, for: guide.id) }
                )) {
                    Label("Enable AI", systemImage: "sparkles")
                        .font(.subheadline)
                }
                
                // Engine Selection
                if preference.aiEnabled {
                    Picker(selection: Binding(
                        get: { preference.selectedEngine },
                        set: { settingsManager.setEngine($0, for: guide.id) }
                    )) {
                        ForEach(AIEngine.allCases, id: \.self) { engine in
                            HStack {
                                if engine == .appleIntelligence && !AppleIntelligenceService.shared.isAvailable {
                                    Text("\(engine.displayName) (Unavailable)")
                                } else {
                                    Text(engine.displayName)
                                }
                            }
                            .tag(engine)
                        }
                    } label: {
                        Label("AI Engine", systemImage: "cpu")
                            .font(.subheadline)
                    }
                    .pickerStyle(.menu)
                    
                    // Status
                    HStack {
                        Label("Status", systemImage: "info.circle")
                            .font(.subheadline)
                        Spacer()
                        Text(GuideAIService.shared.getAvailabilityStatus(for: guide.id))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)
        } label: {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
                Text(guide.displayName)
                    .lineLimit(1)
                Spacer()
                if preference.aiEnabled {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                        .font(.caption)
                }
            }
        }
    }
}

struct GuidesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GuidesSettingsView()
    }
}
