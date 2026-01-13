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
        case .describeGuide:
            return "Describe Guide"
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
        case .describeGuide:
            return "text.bubble"
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
    
    @Published var guidePreferences: [String: GuideAIPreference] = [:]
    @Published var openRouterModel: String = "openai/gpt-4o-mini"
    @Published var hasAPIKey: Bool = false
    
    static let defaultModels: [String] = [
        "openai/gpt-4o-mini",
        "openai/gpt-4o",
        "anthropic/claude-3.5-sonnet",
        "anthropic/claude-3-haiku",
        "google/gemini-pro-1.5",
        "meta-llama/llama-3.1-70b-instruct",
        "mistralai/mistral-large"
    ]
    
    private init() {
        loadPreferences()
        loadOpenRouterModel()
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
    
    func saveOpenRouterModel(_ model: String) {
        openRouterModel = model
        UserDefaults.standard.set(model, forKey: openRouterModelKey)
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
