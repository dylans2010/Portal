import Foundation
import SwiftUI

/// TranslationService provides centralized localization management for the Feather app.
/// It replaces hardcoded strings with localized versions based on the user's selected language.
class TranslationService {
    /// Shared singleton instance
    static let shared = TranslationService()
    
    private init() {}
    
    /// Get a localized string by key
    /// - Parameter key: The localization key from Localizable.xcstrings
    /// - Returns: The localized string for the current language
    func localized(_ key: String) -> String {
        return NSLocalizedString(key, comment: "")
    }
    
    /// Get a localized string with formatting arguments
    /// - Parameters:
    ///   - key: The localization key from Localizable.xcstrings
    ///   - arguments: Variable arguments to format the string
    /// - Returns: The formatted localized string
    func localized(_ key: String, arguments: CVarArg...) -> String {
        return String(format: NSLocalizedString(key, comment: ""), arguments: arguments)
    }
    
    /// Get the current app language code
    /// - Returns: The language code (e.g., "en", "es", "de")
    func getCurrentLanguage() -> String {
        if let languages = UserDefaults.standard.array(forKey: "AppleLanguages") as? [String],
           let currentLanguage = languages.first {
            return currentLanguage
        }
        return Locale.current.languageCode ?? "en"
    }
    
    /// Set the app language
    /// - Parameter languageCode: The language code to set (e.g., "en", "es", "de")
    func setLanguage(_ languageCode: String) {
        UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
    }
    
    /// Get all available languages
    /// - Returns: Array of AppLanguage enum cases
    func getAvailableLanguages() -> [AppLanguage] {
        return AppLanguage.allCases
    }
}

/// Enum representing all supported app languages
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case german = "de"
    case czech = "cs"
    case french = "fr"
    case indonesian = "id"
    case italian = "it"
    case polish = "pl"
    case russian = "ru"
    case turkish = "tr"
    case vietnamese = "vi"
    case simplifiedChinese = "zh-Hans"
    
    /// Language code (ISO 639-1)
    var code: String {
        rawValue
    }
    
    /// Display name in English
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .german: return "German"
        case .czech: return "Czech"
        case .french: return "French"
        case .indonesian: return "Indonesian"
        case .italian: return "Italian"
        case .polish: return "Polish"
        case .russian: return "Russian"
        case .turkish: return "Turkish"
        case .vietnamese: return "Vietnamese"
        case .simplifiedChinese: return "Simplified Chinese"
        }
    }
    
    /// Native name (language name in its own language)
    var nativeName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .czech: return "Čeština"
        case .french: return "Français"
        case .indonesian: return "Bahasa Indonesia"
        case .italian: return "Italiano"
        case .polish: return "Polski"
        case .russian: return "Русский"
        case .turkish: return "Türkçe"
        case .vietnamese: return "Tiếng Việt"
        case .simplifiedChinese: return "简体中文"
        }
    }
}
