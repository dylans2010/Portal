import Foundation
import UIKit
import CoreData

/// Manager for handling automatic signing and installation of downloaded apps
class AutoSignManager {
    static let shared = AutoSignManager()
    
    private init() {}
    
    /// Check if auto-sign is enabled
    var isAutoSignEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "Feather.autoSignAfterDownload")
    }
    
    /// Automatically sign and install an app
    /// - Parameters:
    ///   - app: The app to sign (URL or AppInfoPresentable)
    ///   - completion: Completion handler with success/failure
    func autoSignAndInstall(_ appURL: URL, completion: @escaping (Bool, Error?) -> Void) {
        // Get the default certificate
        guard let defaultCert = getDefaultCertificate() else {
            completion(false, AutoSignError.noCertificate)
            return
        }
        
        // Create a temporary app object from URL
        // For now, we'll trigger the standard signing flow
        // In a production implementation, this would:
        // 1. Extract app info from IPA
        // 2. Sign with default certificate
        // 3. Install in background
        // 4. Update Live Activity
        // 5. Remove from Library
        
        // Post notification to trigger signing with default options
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("Feather.autoSignAndInstall"),
                object: appURL,
                userInfo: ["certificateIndex": self.getDefaultCertificateIndex()]
            )
        }
        
        completion(true, nil)
    }
    
    /// Get the default certificate for signing
    private func getDefaultCertificate() -> CertificatePair? {
        // Get default certificate from UserDefaults
        let defaultIndex = UserDefaults.standard.integer(forKey: "feather.selectedCert")
        
        // Fetch certificates from Core Data
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = CertificatePair.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
        
        do {
            let certificates = try context.fetch(fetchRequest)
            guard certificates.indices.contains(defaultIndex) else {
                return certificates.first // Return first certificate if default index is invalid
            }
            return certificates[defaultIndex]
        } catch {
            print("❌ Failed to fetch certificates: \(error)")
            return nil
        }
    }
    
    /// Get the index of the default certificate
    private func getDefaultCertificateIndex() -> Int {
        return UserDefaults.standard.integer(forKey: "feather.selectedCert")
    }
    
    /// Show a compact toaster notification
    func showLiveActivityToast() {
        DispatchQueue.main.async {
            // Show a compact banner notification
            NotificationCenter.default.post(
                name: Notification.Name("Feather.showLiveActivityToast"),
                object: nil,
                userInfo: ["message": "Check Lock Screen For A Live Activity!"]
            )
        }
    }
    
    /// Remove an app from the Library after successful installation
    /// - Parameter appName: The name of the app to remove
    func removeFromLibrary(appName: String) {
        let context = PersistenceController.shared.container.viewContext
        
        // Try to find and remove the signed app
        let signedFetch = Signed.fetchRequest()
        signedFetch.predicate = NSPredicate(format: "name == %@", appName)
        
        do {
            let signedApps = try context.fetch(signedFetch)
            for app in signedApps {
                context.delete(app)
            }
            
            // Try to save
            try context.save()
            print("✅ Removed \(appName) from Library")
        } catch {
            print("❌ Failed to remove \(appName) from Library: \(error)")
        }
    }
}

// MARK: - Auto Sign Errors
enum AutoSignError: LocalizedError {
    case noCertificate
    case signingFailed(String)
    case installationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noCertificate:
            return "No certificate available for signing. Please import a certificate in Settings."
        case .signingFailed(let message):
            return "Signing failed: \(message)"
        case .installationFailed(let message):
            return "Installation failed: \(message)"
        }
    }
}
