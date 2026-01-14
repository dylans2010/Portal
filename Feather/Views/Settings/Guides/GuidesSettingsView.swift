import SwiftUI
import NimbleViews

struct GuidesSettingsView: View {
    @ObservedObject private var settingsManager = GuideAISettingsManager.shared
    @State private var apiKeyInput: String = ""
    @State private var customModelInput: String = ""
    @State private var showingAPIKeyAlert = false
    @State private var showingDeleteKeyAlert = false
    @State private var guides: [Guide] = []
    @State private var isLoadingGuides = false
    @State private var guidesError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // AI Status Card
                aiStatusCard
                
                // OpenRouter Configuration
                openRouterCard
                
                // Model Selection
                modelSelectionCard
                
                // Per-Guide Settings
                perGuideCard
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(.localized("Guides"))
        .navigationBarTitleDisplayMode(.inline)
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
    private var aiStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Status")
                        .font(.headline)
                    Text(getOverallStatus())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(getStatusGradient())
                        .frame(width: 50, height: 50)
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            
            HStack(spacing: 12) {
                StatusPill(
                    title: "Apple Intelligence",
                    isAvailable: AppleIntelligenceService.shared.isAvailable,
                    icon: "apple.logo"
                )
                StatusPill(
                    title: "OpenRouter",
                    isAvailable: settingsManager.hasAPIKey,
                    icon: "cloud"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var openRouterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.orange)
                Text("OpenRouter API")
                    .font(.headline)
            }
            
            if settingsManager.hasAPIKey {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.green)
                        Text("API Key Configured")
                            .font(.subheadline)
                    }
                    Spacer()
                    Button {
                        showingDeleteKeyAlert = true
                    } label: {
                        Text("Remove")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                Button {
                    showingAPIKeyAlert = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add API Key")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
            }
            
            Text("Get your API key from openrouter.ai")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var modelSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundStyle(.purple)
                Text("AI Model")
                    .font(.headline)
            }
            
            // Model Picker
            Menu {
                ForEach(settingsManager.allModels, id: \.self) { model in
                    Button {
                        settingsManager.saveOpenRouterModel(model)
                        HapticsManager.shared.softImpact()
                    } label: {
                        HStack {
                            Text(formatModelName(model))
                            if model == settingsManager.openRouterModel {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(formatModelName(settingsManager.openRouterModel))
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            // Custom Model Input
            HStack {
                TextField("Custom Model", text: $customModelInput)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                Button {
                    if !customModelInput.isEmpty {
                        settingsManager.saveOpenRouterModel(customModelInput)
                        customModelInput = ""
                        HapticsManager.shared.success()
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(customModelInput.isEmpty ? Color.secondary : Color.blue)
                }
                .disabled(customModelInput.isEmpty)
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var perGuideCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.blue)
                Text("Per Guide Settings")
                    .font(.headline)
            }
            
            if isLoadingGuides {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if let error = guidesError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
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
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else if guides.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No Guides Available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(guides) { guide in
                        GuideAISettingsRow(guide: guide, settingsManager: settingsManager)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    private func getOverallStatus() -> String {
        if AppleIntelligenceService.shared.isAvailable && settingsManager.hasAPIKey {
            return "All AI Features Available"
        } else if AppleIntelligenceService.shared.isAvailable {
            return "Apple Intelligence Ready"
        } else if settingsManager.hasAPIKey {
            return "OpenRouter Ready"
        } else {
            return "Configure API Key To Enable AI"
        }
    }
    
    private func getStatusGradient() -> LinearGradient {
        if AppleIntelligenceService.shared.isAvailable || settingsManager.hasAPIKey {
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.gray, .secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
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
            AppLogManager.shared.info("OpenRouter API key saved successfully", category: "GuidesSettings")
        } catch {
            AppLogManager.shared.error("Failed to save API key: \(error.localizedDescription)", category: "GuidesSettings")
        }
    }
    
    private func deleteAPIKey() {
        do {
            try settingsManager.deleteAPIKey()
            HapticsManager.shared.success()
            AppLogManager.shared.info("OpenRouter API key deleted", category: "GuidesSettings")
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

struct StatusPill: View {
    let title: String
    let isAvailable: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isAvailable ? Color.green.opacity(0.15) : Color.secondary.opacity(0.15))
        .foregroundStyle(isAvailable ? .green : .secondary)
        .cornerRadius(20)
    }
}

struct GuideAISettingsRow: View {
    let guide: Guide
    @ObservedObject var settingsManager: GuideAISettingsManager
    @State private var isExpanded = false
    
    private var preference: GuideAIPreference {
        settingsManager.getPreference(for: guide.id)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(.blue)
                    Text(guide.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer()
                    if preference.aiEnabled {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.purple)
                            .font(.caption)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 12) {
                    Toggle(isOn: Binding(
                        get: { preference.aiEnabled },
                        set: { settingsManager.setAIEnabled($0, for: guide.id) }
                    )) {
                        Label("Enable AI", systemImage: "sparkles")
                            .font(.subheadline)
                    }
                    .tint(.purple)
                    
                    if preference.aiEnabled {
                        HStack {
                            Label("Engine", systemImage: "cpu")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: Binding(
                                get: { preference.selectedEngine },
                                set: { settingsManager.setEngine($0, for: guide.id) }
                            )) {
                                ForEach(AIEngine.allCases, id: \.self) { engine in
                                    Text(engine.displayName).tag(engine)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                .padding()
                .background(Color(.tertiarySystemGroupedBackground).opacity(0.5))
                .cornerRadius(10)
                .padding(.top, 4)
            }
        }
    }
}

struct GuidesSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            GuidesSettingsView()
        }
    }
}
