import Foundation
import LocalAuthentication
import Security
import CryptoKit

// MARK: - Developer Authentication Manager
final class DeveloperAuthManager: ObservableObject {
    static let shared = DeveloperAuthManager()
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var authenticationError: String?
    @Published private(set) var lastAuthTime: Date?
    @Published var rememberMe: Bool {
        didSet {
            UserDefaults.standard.set(rememberMe, forKey: rememberMeKey)
            if !rememberMe {
                clearRememberedSession()
            }
        }
    }
    
    private let keychainService = "com.feather.developer"
    private let keychainAccount = "developerPasscode"
    private let tokenKey = "developerToken"
    private let rememberMeKey = "dev.rememberMe"
    private let rememberedSessionKey = "dev.rememberedSession"
    private let sessionTimeout: TimeInterval = 300 // 5 minutes
    private let rememberedSessionTimeout: TimeInterval = 604800 // 7 days
    
    // Valid developer tokens (in production, these would be fetched from a secure server)
    private let validDeveloperTokens: Set<String> = [
        "FEATHER-DEV-2024-ALPHA",
        "FEATHER-DEV-2024-BETA",
        "INTERNAL-DEV",
        "DEV-MODE-AUTH",
        "PORTAL-INTERNAL-DEV"
    ]
    
    private init() {
        self.rememberMe = UserDefaults.standard.bool(forKey: rememberMeKey)
        checkSessionValidity()
        attemptAutoAuthentication()
    }
    
    // MARK: - Auto Authentication (Remember Me)
    
    private func attemptAutoAuthentication() {
        guard rememberMe else { return }
        
        if let sessionData = UserDefaults.standard.data(forKey: rememberedSessionKey),
           let session = try? JSONDecoder().decode(RememberedSession.self, from: sessionData) {
            
            // Check if session is still valid
            if Date().timeIntervalSince(session.timestamp) < rememberedSessionTimeout {
                isAuthenticated = true
                lastAuthTime = Date()
                AppLogManager.shared.info("Auto authenticated via Remember Me", category: "Security")
            } else {
                clearRememberedSession()
                AppLogManager.shared.info("Remembered session expired", category: "Security")
            }
        }
    }
    
    func saveRememberedSession() {
        guard rememberMe else { return }
        
        let session = RememberedSession(timestamp: Date())
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: rememberedSessionKey)
            AppLogManager.shared.info("Session saved for Remember Me", category: "Security")
        }
    }
    
    private func clearRememberedSession() {
        UserDefaults.standard.removeObject(forKey: rememberedSessionKey)
    }
    
    private struct RememberedSession: Codable {
        let timestamp: Date
    }
    
    // MARK: - Session Management
    
    func checkSessionValidity() {
        // If Remember Me is enabled and we have a valid remembered session, stay authenticated
        if rememberMe {
            if let sessionData = UserDefaults.standard.data(forKey: rememberedSessionKey),
               let session = try? JSONDecoder().decode(RememberedSession.self, from: sessionData),
               Date().timeIntervalSince(session.timestamp) < rememberedSessionTimeout {
                return // Session is still valid
            }
        }
        
        guard let lastAuth = lastAuthTime else {
            isAuthenticated = false
            return
        }
        
        if Date().timeIntervalSince(lastAuth) > sessionTimeout {
            lockDeveloperMode()
        }
    }
    
    func lockDeveloperMode() {
        // Don't lock if Remember Me is enabled
        if rememberMe {
            if let sessionData = UserDefaults.standard.data(forKey: rememberedSessionKey),
               let session = try? JSONDecoder().decode(RememberedSession.self, from: sessionData),
               Date().timeIntervalSince(session.timestamp) < rememberedSessionTimeout {
                return // Keep authenticated
            }
        }
        
        isAuthenticated = false
        lastAuthTime = nil
        authenticationError = nil
        AppLogManager.shared.info("Developer mode locked", category: "Security")
    }
    
    // MARK: - Passcode Management
    
    var hasPasscodeSet: Bool {
        return getStoredPasscodeHash() != nil
    }
    
    func setPasscode(_ passcode: String) -> Bool {
        guard passcode.count >= 6 else {
            authenticationError = "Passcode must be at least 6 characters"
            return false
        }
        
        let hash = hashPasscode(passcode)
        let success = saveToKeychain(hash)
        
        if success {
            AppLogManager.shared.success("Developer passcode set", category: "Security")
        } else {
            authenticationError = "Failed to save passcode"
            AppLogManager.shared.error("Failed to set developer passcode", category: "Security")
        }
        
        return success
    }
    
    func verifyPasscode(_ passcode: String) -> Bool {
        guard let storedHash = getStoredPasscodeHash() else {
            authenticationError = "No Passcode Set"
            return false
        }
        
        let inputHash = hashPasscode(passcode)
        let isValid = storedHash == inputHash
        
        if isValid {
            isAuthenticated = true
            lastAuthTime = Date()
            authenticationError = nil
            saveRememberedSession()
            AppLogManager.shared.success("Developer passcode verified", category: "Security")
        } else {
            authenticationError = "Invalid Passcode"
            AppLogManager.shared.warning("Invalid developer passcode attempt", category: "Security")
        }
        
        return isValid
    }
    
    func removePasscode() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        let success = status == errSecSuccess || status == errSecItemNotFound
        
        if success {
            lockDeveloperMode()
            AppLogManager.shared.info("Developer passcode removed", category: "Security")
        }
        
        return success
    }
    
    // MARK: - Biometric Authentication
    
    var biometricType: LABiometryType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        return context.biometryType
    }
    
    var canUseBiometrics: Bool {
        return biometricType != .none
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error?.localizedDescription ?? "Biometrics not available")
            return
        }
        
        let reason = "Authenticate to access Developer Mode"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, authError in
            DispatchQueue.main.async {
                if success {
                    self?.isAuthenticated = true
                    self?.lastAuthTime = Date()
                    self?.authenticationError = nil
                    self?.saveRememberedSession()
                    AppLogManager.shared.success("Biometric authentication successful", category: "Security")
                    completion(true, nil)
                } else {
                    let errorMessage = authError?.localizedDescription ?? "Authentication Failed"
                    self?.authenticationError = errorMessage
                    AppLogManager.shared.warning("Biometric Authentication Failed: \(errorMessage)", category: "Security")
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // MARK: - Developer Token Validation
    
    func validateDeveloperToken(_ token: String) -> Bool {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let isValid = validDeveloperTokens.contains(normalizedToken)
        
        if isValid {
            isAuthenticated = true
            lastAuthTime = Date()
            authenticationError = nil
            saveDeveloperToken(normalizedToken)
            saveRememberedSession()
            AppLogManager.shared.success("Developer token validated", category: "Security")
        } else {
            authenticationError = "Invalid Developer Token"
            AppLogManager.shared.warning("Invalid developer token attempt", category: "Security")
        }
        
        return isValid
    }
    
    var hasSavedToken: Bool {
        return getSavedDeveloperToken() != nil
    }
    
    func authenticateWithSavedToken() -> Bool {
        guard let savedToken = getSavedDeveloperToken() else {
            return false
        }
        
        return validateDeveloperToken(savedToken)
    }
    
    // MARK: - Private Helpers
    
    private func hashPasscode(_ passcode: String) -> String {
        let data = Data(passcode.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func saveToKeychain(_ hash: String) -> Bool {
        let data = Data(hash.utf8)
        
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getStoredPasscodeHash() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let hash = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return hash
    }
    
    private func saveDeveloperToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    private func getSavedDeveloperToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func clearSavedToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        AppLogManager.shared.info("Developer Token Cleared", category: "Security")
    }
}
