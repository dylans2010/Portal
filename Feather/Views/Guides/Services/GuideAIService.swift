import Foundation

final class GuideAIService {
    static let shared = GuideAIService()
    
    private let settingsManager = GuideAISettingsManager.shared
    private let appleIntelligence = AppleIntelligenceService.shared
    private let openRouter = OpenRouterService.shared
    
    private init() {}
    
    enum GuideAIError: Error, LocalizedError {
        case aiDisabled
        case noAPIKey
        case processingFailed(String)
        case allEnginesFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .aiDisabled:
                return "AI is disabled for this guide"
            case .noAPIKey:
                return "OpenRouter API key is not configured"
            case .processingFailed(let message):
                return "Processing failed: \(message)"
            case .allEnginesFailed(let message):
                return "All AI engines failed: \(message)"
            }
        }
    }
    
    struct ProcessingResult {
        let content: String
        let engineUsed: AIEngine
        let didFallback: Bool
    }
    
    func processGuide(
        guideId: String,
        guideText: String,
        action: AIAction,
        customInstruction: String? = nil
    ) async throws -> ProcessingResult {
        let preference = settingsManager.getPreference(for: guideId)
        
        guard preference.aiEnabled else {
            throw GuideAIError.aiDisabled
        }
        
        let selectedEngine = preference.selectedEngine
        
        // Try selected engine first
        if selectedEngine == .appleIntelligence {
            return try await processWithAppleIntelligenceAndFallback(
                guideText: guideText,
                action: action,
                customInstruction: customInstruction
            )
        } else {
            return try await processWithOpenRouter(
                guideText: guideText,
                action: action,
                customInstruction: customInstruction
            )
        }
    }
    
    private func processWithAppleIntelligenceAndFallback(
        guideText: String,
        action: AIAction,
        customInstruction: String?
    ) async throws -> ProcessingResult {
        // Check if Apple Intelligence is available
        if appleIntelligence.isAvailable {
            do {
                let result = try await appleIntelligence.processText(
                    guideText,
                    action: action,
                    customInstruction: customInstruction
                )
                return ProcessingResult(
                    content: result,
                    engineUsed: .appleIntelligence,
                    didFallback: false
                )
            } catch {
                // Apple Intelligence failed, try fallback
                AppLogManager.shared.warning(
                    "Apple Intelligence failed, falling back to OpenRouter: \(error.localizedDescription)",
                    category: "GuideAI"
                )
            }
        }
        
        // Fallback to OpenRouter
        do {
            let result = try await processWithOpenRouter(
                guideText: guideText,
                action: action,
                customInstruction: customInstruction
            )
            return ProcessingResult(
                content: result.content,
                engineUsed: .openRouter,
                didFallback: true
            )
        } catch {
            throw GuideAIError.allEnginesFailed(error.localizedDescription)
        }
    }
    
    private func processWithOpenRouter(
        guideText: String,
        action: AIAction,
        customInstruction: String?
    ) async throws -> ProcessingResult {
        guard let apiKey = settingsManager.getAPIKey(), !apiKey.isEmpty else {
            throw GuideAIError.noAPIKey
        }
        
        let model = settingsManager.openRouterModel
        
        let result = try await openRouter.processText(
            guideText,
            action: action,
            customInstruction: customInstruction,
            apiKey: apiKey,
            model: model
        )
        
        return ProcessingResult(
            content: result,
            engineUsed: .openRouter,
            didFallback: false
        )
    }
    
    func isAIAvailable(for guideId: String) -> Bool {
        let preference = settingsManager.getPreference(for: guideId)
        
        guard preference.aiEnabled else {
            return false
        }
        
        if preference.selectedEngine == .appleIntelligence {
            // Apple Intelligence available or OpenRouter configured as fallback
            return appleIntelligence.isAvailable || settingsManager.hasAPIKey
        } else {
            return settingsManager.hasAPIKey
        }
    }
    
    func getAvailabilityStatus(for guideId: String) -> String {
        let preference = settingsManager.getPreference(for: guideId)
        
        if !preference.aiEnabled {
            return "AI disabled for this guide"
        }
        
        if preference.selectedEngine == .appleIntelligence {
            if appleIntelligence.isAvailable {
                return "Apple Intelligence ready"
            } else if settingsManager.hasAPIKey {
                return "Will use OpenRouter (Apple Intelligence unavailable)"
            } else {
                return "Configure OpenRouter API key for fallback"
            }
        } else {
            if settingsManager.hasAPIKey {
                return "OpenRouter ready"
            } else {
                return "Configure OpenRouter API key"
            }
        }
    }
}
