import Foundation

final class OpenRouterService {
    static let shared = OpenRouterService()
    
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    private init() {}
    
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
            throw OpenRouterError.invalidAPIKey
        }
        
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
            throw OpenRouterError.invalidResponse
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("Feather Portal iOS", forHTTPHeaderField: "HTTP-Referer")
        urlRequest.setValue("Feather Portal", forHTTPHeaderField: "X-Title")
        
        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw OpenRouterError.invalidAPIKey
        case 429:
            throw OpenRouterError.rateLimited
        case 402:
            throw OpenRouterError.insufficientCredits
        default:
            if let errorResponse = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
               let error = errorResponse.error {
                throw OpenRouterError.apiError(error.message)
            }
            throw OpenRouterError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        let decoder = JSONDecoder()
        let completionResponse = try decoder.decode(ChatCompletionResponse.self, from: data)
        
        if let error = completionResponse.error {
            throw OpenRouterError.apiError(error.message)
        }
        
        guard let choices = completionResponse.choices,
              let firstChoice = choices.first else {
            throw OpenRouterError.noContent
        }
        
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
        """
        
        switch action {
        case .simplify:
            return basePrompt + "\n\nYour task is to simplify the guide text. Make it easier to understand while preserving all important information. Use simpler words and shorter sentences."
        case .translate:
            return basePrompt + "\n\nYour task is to translate the guide text. Detect the source language and translate to English if not English, or to the user's preferred language if specified. Maintain the original structure and meaning."
        case .explain:
            return basePrompt + "\n\nYour task is to explain the guide content in detail. Break down complex concepts, provide context, and make sure the reader fully understands each part."
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
            actionDescription = "Translate the following guide text:"
        case .explain:
            actionDescription = "Explain the following guide text in detail:"
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
