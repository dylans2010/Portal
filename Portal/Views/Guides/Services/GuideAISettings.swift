import Foundation
import SwiftUI

enum AIEngine: String, CaseIterable, Codable {
    case appleIntelligence = "apple_intelligence"
    case openRouter = "openrouter"
    
    var displayName: String {
        switch self {
        case .appleIntelligence:
            return "Apple Intelligence"
        case .openRouter:
            return "OpenRouter"
        }
    }
}

enum AIAction: String, CaseIterable, Identifiable {
    case simplify = "simplify"
    case translate = "translate"
    case explain = "explain"
    case summarize = "summarize"
    case keyPoints = "key_points"
    case stepByStep = "step_by_step"
    case proofread = "proofread"
    case describeGuide = "describe_guide"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .simplify:
            return "Simplify"
        case .translate:
            return "Translate"
        case .explain:
            return "Explain"
        case .summarize:
            return "Summarize"
        case .keyPoints:
            return "Key Points"
        case .stepByStep:
            return "Step by Step"
        case .proofread:
            return "Proofread"
        case .describeGuide:
            return "Custom Prompt"
        }
    }
    
    var systemImage: String {
        switch self {
        case .simplify:
            return "text.badge.minus"
        case .translate:
            return "globe"
        case .explain:
            return "lightbulb"
        case .summarize:
            return "doc.text.below.ecg"
        case .keyPoints:
            return "list.bullet.rectangle"
        case .stepByStep:
            return "list.number"
        case .proofread:
            return "checkmark.circle"
        case .describeGuide:
            return "text.bubble"
        }
    }
    
    var description: String {
        switch self {
        case .simplify:
            return "Make the text easier to understand"
        case .translate:
            return "Translate to another language"
        case .explain:
            return "Explain concepts in detail"
        case .summarize:
            return "Create a brief summary"
        case .keyPoints:
            return "Extract the main points"
        case .stepByStep:
            return "Convert to step-by-step instructions"
        case .proofread:
            return "Check for errors and improve clarity"
        case .describeGuide:
            return "Enter your own instructions"
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .simplify:
            return [Color.blue, Color.cyan]
        case .translate:
            return [Color.green, Color.mint]
        case .explain:
            return [Color.yellow, Color.orange]
        case .summarize:
            return [Color.purple, Color.pink]
        case .keyPoints:
            return [Color.indigo, Color.blue]
        case .stepByStep:
            return [Color.teal, Color.green]
        case .proofread:
            return [Color.red, Color.orange]
        case .describeGuide:
            return [Color.purple, Color.indigo]
        }
    }
}

struct GuideAIPreference: Codable, Identifiable {
    let guideId: String
    var aiEnabled: Bool
    var selectedEngine: AIEngine
    
    var id: String { guideId }
    
    init(guideId: String, aiEnabled: Bool = true, selectedEngine: AIEngine = .appleIntelligence) {
        self.guideId = guideId
        self.aiEnabled = aiEnabled
        self.selectedEngine = selectedEngine
    }
}

final class GuideAISettingsManager: ObservableObject {
    static let shared = GuideAISettingsManager()
    
    private let userDefaultsKey = "Feather.guideAIPreferences"
    private let openRouterModelKey = "Feather.openRouterModel"
    private let customModelsKey = "Feather.customOpenRouterModels"
    
    @Published var guidePreferences: [String: GuideAIPreference] = [:]
    @Published var openRouterModel: String = "openai/gpt-4o-mini"
    @Published var hasAPIKey: Bool = false
    @Published var customModels: [String] = []
    
    static let defaultModels: [String] = [
        "openai/gpt-4o-mini",
        "openai/gpt-4o",
        "anthropic/claude-3.5-sonnet",
        "anthropic/claude-3-haiku",
        "google/gemini-pro-1.5",
        "google/gemini-2.0-flash-exp:free",
        "meta-llama/llama-3.1-70b-instruct",
        "mistralai/mistral-large",
        "deepseek/deepseek-chat"
    ]
    
    var allModels: [String] {
        var models = Self.defaultModels
        for customModel in customModels {
            if !models.contains(customModel) {
                models.append(customModel)
            }
        }
        // Ensure current model is in the list
        if !models.contains(openRouterModel) {
            models.append(openRouterModel)
        }
        return models
    }
    
    private init() {
        loadPreferences()
        loadOpenRouterModel()
        loadCustomModels()
        checkAPIKeyExists()
    }
    
    private func loadPreferences() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let preferences = try? JSONDecoder().decode([String: GuideAIPreference].self, from: data) else {
            return
        }
        guidePreferences = preferences
    }
    
    private func savePreferences() {
        guard let data = try? JSONEncoder().encode(guidePreferences) else { return }
        UserDefaults.standard.set(data, forKey: userDefaultsKey)
    }
    
    private func loadOpenRouterModel() {
        if let model = UserDefaults.standard.string(forKey: openRouterModelKey) {
            openRouterModel = model
        }
    }
    
    private func loadCustomModels() {
        if let models = UserDefaults.standard.stringArray(forKey: customModelsKey) {
            customModels = models
        }
    }
    
    private func saveCustomModels() {
        UserDefaults.standard.set(customModels, forKey: customModelsKey)
    }
    
    func saveOpenRouterModel(_ model: String) {
        openRouterModel = model
        UserDefaults.standard.set(model, forKey: openRouterModelKey)
        
        // Add to custom models if not in default list
        if !Self.defaultModels.contains(model) && !customModels.contains(model) {
            customModels.append(model)
            saveCustomModels()
        }
    }
    
    func removeCustomModel(_ model: String) {
        customModels.removeAll { $0 == model }
        saveCustomModels()
        
        // If current model was removed, switch to default
        if openRouterModel == model {
            openRouterModel = Self.defaultModels.first ?? "openai/gpt-4o-mini"
            UserDefaults.standard.set(openRouterModel, forKey: openRouterModelKey)
        }
    }
    
    func checkAPIKeyExists() {
        hasAPIKey = KeychainManager.shared.exists(for: .openRouterAPIKey)
    }
    
    func getPreference(for guideId: String) -> GuideAIPreference {
        if let preference = guidePreferences[guideId] {
            return preference
        }
        return GuideAIPreference(guideId: guideId)
    }
    
    func setAIEnabled(_ enabled: Bool, for guideId: String) {
        var preference = getPreference(for: guideId)
        preference.aiEnabled = enabled
        guidePreferences[guideId] = preference
        savePreferences()
    }
    
    func setEngine(_ engine: AIEngine, for guideId: String) {
        var preference = getPreference(for: guideId)
        preference.selectedEngine = engine
        guidePreferences[guideId] = preference
        savePreferences()
    }
    
    func saveAPIKey(_ key: String) throws {
        try KeychainManager.shared.save(key, for: .openRouterAPIKey)
        hasAPIKey = true
    }
    
    func getAPIKey() -> String? {
        try? KeychainManager.shared.retrieve(for: .openRouterAPIKey)
    }
    
    func deleteAPIKey() throws {
        try KeychainManager.shared.delete(for: .openRouterAPIKey)
        hasAPIKey = false
    }
}
