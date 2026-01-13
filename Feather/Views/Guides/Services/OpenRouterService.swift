import Foundation

final class OpenRouterService {
    static let shared = OpenRouterService()
    
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    private init() {}
    
    enum OpenRouterModel: String, CaseIterable {
        case gpt4oMini = "openai/gpt-4o-mini"
        case gpt4o = "openai/gpt-4o"
        case claude35Sonnet = "anthropic/claude-3.5-sonnet"
        case claude3Haiku = "anthropic/claude-3-haiku"
        case geminiPro = "google/gemini-pro-1.5"
        case llama31 = "meta-llama/llama-3.1-70b-instruct"
        case mistralLarge = "mistralai/mistral-large"
        
        var displayName: String {
            switch self {
            case .gpt4oMini: return "GPT-4o Mini"
            case .gpt4o: return "GPT-4o"
            case .claude35Sonnet: return "Claude 3.5 Sonnet"
            case .claude3Haiku: return "Claude 3 Haiku"
            case .geminiPro: return "Gemini Pro 1.5"
            case .llama31: return "Llama 3.1 70B"
            case .mistralLarge: return "Mistral Large"
            }
        }
    }
    
    enum OpenRouterError: Error, LocalizedError {
        case invalidAPIKey
        case networkError(Error)
        case invalidResponse
        case apiError(String)
        case noContent
        case rateLimited
        case insufficientCredits
        
        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "Invalid or missing OpenRouter API key"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from OpenRouter"
            case .apiError(let message):
                return "API error: \(message)"
            case .noContent:
                return "No content in response"
            case .rateLimited:
                return "Rate limited. Please try again later."
            case .insufficientCredits:
                return "Insufficient credits on OpenRouter account"
            }
        }
    }
    
    struct ChatCompletionRequest: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let maxTokens: Int
        
        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
        }
        
        struct Message: Encodable {
            let role: String
            let content: String
        }
    }
    
    struct ChatCompletionResponse: Decodable {
        let id: String?
        let choices: [Choice]?
        let error: APIError?
        
        struct Choice: Decodable {
            let message: Message
            let finishReason: String?
            
            enum CodingKeys: String, CodingKey {
                case message
                case finishReason = "finish_reason"
            }
            
            struct Message: Decodable {
                let role: String
                let content: String
            }
        }
        
        struct APIError: Decodable {
            let message: String
            let code: String?
        }
    }
    
    func processText(
        _ text: String,
        action: AIAction,
        customInstruction: String? = nil,
        apiKey: String,
        model: String
    ) async throws -> String {
        guard !apiKey.isEmpty else {
            AppLogManager.shared.error("OpenRouter: API key is empty", category: "GuideAI")
            throw OpenRouterError.invalidAPIKey
        }
        
        AppLogManager.shared.info("OpenRouter: Starting request with model \(model) for action \(action.rawValue)", category: "GuideAI")
        
        let systemPrompt = buildSystemPrompt(for: action, customInstruction: customInstruction)
        let userPrompt = buildUserPrompt(guideText: text, action: action, customInstruction: customInstruction)
        
        let request = ChatCompletionRequest(
            model: model,
            messages: [
                ChatCompletionRequest.Message(role: "system", content: systemPrompt),
                ChatCompletionRequest.Message(role: "user", content: userPrompt)
            ],
            temperature: 0.3,
            maxTokens: 4096
        )
        
        guard let url = URL(string: baseURL) else {
            AppLogManager.shared.error("OpenRouter: Invalid URL", category: "GuideAI")
            throw OpenRouterError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("https://github.com/khcrysalis/Feather", forHTTPHeaderField: "HTTP-Referer")
        urlRequest.setValue("Feather Portal", forHTTPHeaderField: "X-Title")
        urlRequest.timeoutInterval = 60
        
        let encoder = JSONEncoder()
        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            AppLogManager.shared.error("OpenRouter: Failed to encode request - \(error.localizedDescription)", category: "GuideAI")
            throw OpenRouterError.invalidResponse
        }
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch {
            AppLogManager.shared.error("OpenRouter: Network error - \(error.localizedDescription)", category: "GuideAI")
            throw OpenRouterError.networkError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            AppLogManager.shared.error("OpenRouter: Invalid HTTP response", category: "GuideAI")
            throw OpenRouterError.invalidResponse
        }
        
        AppLogManager.shared.info("OpenRouter: Received response with status \(httpResponse.statusCode)", category: "GuideAI")
        
        // Log response body for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            AppLogManager.shared.debug("OpenRouter: Response body - \(responseString.prefix(500))", category: "GuideAI")
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            AppLogManager.shared.error("OpenRouter: Invalid API key (401)", category: "GuideAI")
            throw OpenRouterError.invalidAPIKey
        case 429:
            AppLogManager.shared.warning("OpenRouter: Rate limited (429)", category: "GuideAI")
            throw OpenRouterError.rateLimited
        case 402:
            AppLogManager.shared.error("OpenRouter: Insufficient credits (402)", category: "GuideAI")
            throw OpenRouterError.insufficientCredits
        case 404:
            AppLogManager.shared.error("OpenRouter: Model not found (404) - Model: \(model)", category: "GuideAI")
            throw OpenRouterError.apiError("Model '\(model)' not found. Please select a different model in Settings → Guides.")
        default:
            if let errorResponse = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
               let error = errorResponse.error {
                AppLogManager.shared.error("OpenRouter: API error - \(error.message)", category: "GuideAI")
                throw OpenRouterError.apiError(error.message)
            }
            AppLogManager.shared.error("OpenRouter: HTTP error \(httpResponse.statusCode)", category: "GuideAI")
            throw OpenRouterError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let completionResponse: ChatCompletionResponse
        
        do {
            completionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
        } catch {
            AppLogManager.shared.error("OpenRouter: Failed to decode response - \(error.localizedDescription)", category: "GuideAI")
            throw OpenRouterError.invalidResponse
        }
        
        if let error = completionResponse.error {
            AppLogManager.shared.error("OpenRouter: Response error - \(error.message)", category: "GuideAI")
            throw OpenRouterError.apiError(error.message)
        }
        
        guard let choices = completionResponse.choices,
              let firstChoice = choices.first else {
            AppLogManager.shared.error("OpenRouter: No content in response", category: "GuideAI")
            throw OpenRouterError.noContent
        }
        
        AppLogManager.shared.info("OpenRouter: Successfully received response", category: "GuideAI")
        return firstChoice.message.content
    }
    
    private func buildSystemPrompt(for action: AIAction, customInstruction: String?) -> String {
        let basePrompt = """
        You are a helpful assistant that processes guide content. Follow these rules strictly:
        1. Only use the provided guide text as your factual context.
        2. Follow the selected action precisely.
        3. Return clean, readable output with no meta commentary.
        4. Do not add information that is not present in the original guide.
        5. Do not include phrases like "Here is the..." or "I have..." in your response.
        6. Output only the processed content directly.
        7. Use markdown formatting for better readability.
        """
        
        switch action {
        case .simplify:
            return basePrompt + "\n\nYour task is to simplify the guide text. Make it easier to understand while preserving all important information. Use simpler words and shorter sentences."
        case .translate:
            let targetLanguage = customInstruction ?? "English"
            return basePrompt + "\n\nYour task is to translate the guide text to \(targetLanguage). Maintain the original structure, formatting, and meaning. Translate ALL content accurately to \(targetLanguage)."
        case .explain:
            return basePrompt + "\n\nYour task is to explain the guide content in detail. Break down complex concepts, provide context, and make sure the reader fully understands each part."
        case .summarize:
            return basePrompt + "\n\nYour task is to create a concise summary of the guide. Capture the essential information in a brief, easy-to-read format. Keep it short but comprehensive."
        case .keyPoints:
            return basePrompt + "\n\nYour task is to extract the key points from the guide. Present them as a clear, bulleted list. Focus on the most important information and actionable items."
        case .stepByStep:
            return basePrompt + "\n\nYour task is to convert the guide into clear step-by-step instructions. Number each step and make them easy to follow. Include any important warnings or tips."
        case .proofread:
            return basePrompt + "\n\nYour task is to proofread and improve the guide text. Fix any grammatical errors, improve clarity, and enhance readability while maintaining the original meaning."
        case .describeGuide:
            let instruction = customInstruction ?? "Describe the guide content"
            return basePrompt + "\n\nYour task is to follow this specific instruction exactly: \(instruction)\nDo not add unrelated content. Focus only on what the instruction asks for."
        }
    }
    
    private func buildUserPrompt(guideText: String, action: AIAction, customInstruction: String?) -> String {
        let actionDescription: String
        switch action {
        case .simplify:
            actionDescription = "Simplify the following guide text:"
        case .translate:
            let targetLanguage = customInstruction ?? "English"
            actionDescription = "Translate the following guide text to \(targetLanguage):"
        case .explain:
            actionDescription = "Explain the following guide text in detail:"
        case .summarize:
            actionDescription = "Summarize the following guide text:"
        case .keyPoints:
            actionDescription = "Extract the key points from the following guide text:"
        case .stepByStep:
            actionDescription = "Convert the following guide text into step-by-step instructions:"
        case .proofread:
            actionDescription = "Proofread and improve the following guide text:"
        case .describeGuide:
            let instruction = customInstruction ?? "Describe the guide"
            actionDescription = "Following the instruction '\(instruction)', process this guide text:"
        }
        
        return """
        \(actionDescription)
        
        ---
        GUIDE CONTENT:
        \(guideText)
        ---
        """
    }
}
