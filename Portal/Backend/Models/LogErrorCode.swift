import Foundation

struct LogErrorCodeInfo: Identifiable {
    let id = UUID()
    let code: String
    let description: String
    let suggestion: String
}

enum LogErrorCode: String, Codable, CaseIterable {
    // General
    case UNEXPECTED_ERROR = "UNEXPECTED_ERROR"
    case PERM_DENIED = "PERM_DENIED"
    case CRASH_LOG = "CRASH_LOG"
    case DEV_MODE_ENABLED = "DEV_MODE_ENABLED"

    // Signing
    case SIGN_FAILED = "SIGN_FAILED"
    case CERT_EXPIRED = "CERT_EXPIRED"
    case MISSING_CERT = "MISSING_CERT"
    case PROV_PROFILE_ERR = "PROV_PROFILE_ERR"
    case SIGN_ASSETS_ERR = "SIGN_ASSETS_ERR"
    case P12_NOT_FOUND = "P12_NOT_FOUND"
    case PROVISION_NOT_FOUND = "PROVISION_NOT_FOUND"
    case SIGN_SUCCESS = "SIGN_SUCCESS"
    case BATCH_SIGN_FAILED = "BATCH_SIGN_FAILED"
    case IMPORT_SUCCESS = "IMPORT_SUCCESS"
    case INSTALL_SUCCESS = "INSTALL_SUCCESS"

    // Network
    case CONNECTION_FAILED = "CONNECTION_FAILED"
    case TIMEOUT = "TIMEOUT"
    case INVALID_URL = "INVALID_URL"
    case API_ERR = "API_ERR"
    case API_UNAUTHORIZED = "API_UNAUTHORIZED"
    case API_INSUFFICIENT_CREDITS = "API_INSUFFICIENT_CREDITS"
    case MODEL_NOT_FOUND = "MODEL_NOT_FOUND"
    case DECODE_ERR = "DECODE_ERR"
    case DOWNLOAD_FAILED = "DOWNLOAD_FAILED"

    // Storage
    case DISK_FULL = "DISK_FULL"
    case DB_ERR = "DB_ERR"
    case FILE_NOT_FOUND = "FILE_NOT_FOUND"
    case DB_CORRUPT = "DB_CORRUPT"

    // IPA
    case INVALID_IPA = "INVALID_IPA"
    case EXTRACT_FAILED = "EXTRACT_FAILED"
    case MISSING_PLIST = "MISSING_PLIST"
    case ZIP_EXTRACT_ERR = "ZIP_EXTRACT_ERR"
    case APP_NOT_FOUND = "APP_NOT_FOUND"

    // AI & Services
    case APPLE_INTEL_ERR = "APPLE_INTEL_ERR"
    case DEVICE_NOT_SUPPORTED = "DEVICE_NOT_SUPPORTED"
    case HEARTBEAT_ERR = "HEARTBEAT_ERR"
    case GUIDE_AI_ERR = "GUIDE_AI_ERR"

    // Lifecycle
    case APP_LAUNCH = "APP_LAUNCH"
    case APP_ACTIVE = "APP_ACTIVE"
    case APP_BACKGROUND = "APP_BACKGROUND"

    // Backup & Restore
    case BACKUP_FAILED = "BACKUP_FAILED"
    case RESTORE_FAILED = "RESTORE_FAILED"
    case METADATA_ERR = "METADATA_ERR"

    // Files
    case FILE_OP_FAILED = "FILE_OP_FAILED"
    case FOLDER_CREATION_FAILED = "FOLDER_CREATION_FAILED"
    case PLAIN_TEXT_ERR = "PLAIN_TEXT_ERR"
    case JSON_ERR = "JSON_ERR"
    case PLIST_ERR = "PLIST_ERR"
    case HEX_ERR = "HEX_ERR"
    case CHECKSUM_ERR = "CHECKSUM_ERR"

    // Updates
    case UPDATE_CHECK_FAILED = "UPDATE_CHECK_FAILED"
    case UPDATE_INSTALL_FAILED = "UPDATE_INSTALL_FAILED"

    var info: LogErrorCodeInfo {
        switch self {
        case .UNEXPECTED_ERROR:
            return LogErrorCodeInfo(code: self.rawValue, description: "An unexpected error occurred in the application.", suggestion: "Try restarting the app or checking other logs for more context.")
        case .PERM_DENIED:
            return LogErrorCodeInfo(code: self.rawValue, description: "The app does not have permission to perform this action.", suggestion: "Check iOS Settings and ensure Portal has all necessary permissions.")
        case .CRASH_LOG:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application encountered a critical failure and crashed.", suggestion: "Please report this on GitHub with the provided crash logs.")
        case .DEV_MODE_ENABLED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Developer Mode has been unlocked.", suggestion: "Use these tools carefully as they can affect app stability.")

        case .SIGN_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "The code signing process failed.", suggestion: "Ensure your certificate and provisioning profile are valid and compatible.")
        case .CERT_EXPIRED:
            return LogErrorCodeInfo(code: self.rawValue, description: "The selected certificate has expired.", suggestion: "Use a new certificate or renew your current one via Apple Developer Portal.")
        case .MISSING_CERT:
            return LogErrorCodeInfo(code: self.rawValue, description: "No signing certificate was provided for the operation.", suggestion: "Import a P12 or use a Portal-connected developer account.")
        case .PROV_PROFILE_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "There is an issue with the provisioning profile.", suggestion: "Check if the profile matches the bundle identifier and certificate.")
        case .SIGN_ASSETS_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to list or access signing assets.", suggestion: "Check if the App Group container is accessible.")
        case .P12_NOT_FOUND:
            return LogErrorCodeInfo(code: self.rawValue, description: "The P12 certificate file could not be found.", suggestion: "Re-import your certificate or check if the file was deleted.")
        case .PROVISION_NOT_FOUND:
            return LogErrorCodeInfo(code: self.rawValue, description: "The provisioning profile file could not be found.", suggestion: "Re-import your profile or check if it was deleted.")
        case .SIGN_SUCCESS:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application was signed successfully.", suggestion: "You can now proceed with the installation.")
        case .BATCH_SIGN_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "One or more apps failed during batch signing.", suggestion: "Check individual app logs to identify which one failed.")
        case .IMPORT_SUCCESS:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application or file was imported successfully.", suggestion: "The imported content is now available in your library or file manager.")
        case .INSTALL_SUCCESS:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application was installed successfully.", suggestion: "You can now open the app from your home screen.")

        case .CONNECTION_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to connect to the server.", suggestion: "Check your internet connection or VPN settings.")
        case .TIMEOUT:
            return LogErrorCodeInfo(code: self.rawValue, description: "The network request timed out.", suggestion: "Try again later or check if the source server is down.")
        case .INVALID_URL:
            return LogErrorCodeInfo(code: self.rawValue, description: "The source URL is invalid or malformed.", suggestion: "Verify the URL and ensure it points to a valid file or source.")
        case .API_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "The remote API returned an error.", suggestion: "Check the detailed message for API-specific error details.")
        case .API_UNAUTHORIZED:
            return LogErrorCodeInfo(code: self.rawValue, description: "API request failed due to invalid credentials.", suggestion: "Check your API key in settings and ensure it's correct.")
        case .API_INSUFFICIENT_CREDITS:
            return LogErrorCodeInfo(code: self.rawValue, description: "Your API account has run out of credits.", suggestion: "Refill your credits on the provider's website.")
        case .MODEL_NOT_FOUND:
            return LogErrorCodeInfo(code: self.rawValue, description: "The requested AI model was not found.", suggestion: "Check if the model name is correct and available for your account.")
        case .DECODE_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to decode the response from the server.", suggestion: "This might be due to a change in the API or a corrupted response.")
        case .DOWNLOAD_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "The file download failed.", suggestion: "Ensure you have a stable connection and the link is still valid.")

        case .DISK_FULL:
            return LogErrorCodeInfo(code: self.rawValue, description: "The device is out of storage space.", suggestion: "Free up some space by deleting unused apps or files.")
        case .DB_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "A database error occurred.", suggestion: "Try restarting the app. If it persists, you may need to reset data.")
        case .DB_CORRUPT:
            return LogErrorCodeInfo(code: self.rawValue, description: "The local database appears to be corrupted.", suggestion: "Export your data if possible, then try resetting the app.")
        case .FILE_NOT_FOUND:
            return LogErrorCodeInfo(code: self.rawValue, description: "The requested file could not be found.", suggestion: "Ensure the file hasn't been moved or deleted manually.")

        case .INVALID_IPA:
            return LogErrorCodeInfo(code: self.rawValue, description: "The IPA file format is invalid or corrupted.", suggestion: "Try redownloading the IPA from a reliable source.")
        case .EXTRACT_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to extract the app bundle from the IPA.", suggestion: "Ensure you have enough storage and the IPA is not encrypted.")
        case .MISSING_PLIST:
            return LogErrorCodeInfo(code: self.rawValue, description: "The app bundle is missing its Info.plist file.", suggestion: "This IPA may be malformed. Try a different version of the app.")
        case .ZIP_EXTRACT_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to extract the ZIP archive.", suggestion: "The archive might be corrupted or password protected.")
        case .APP_NOT_FOUND:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application bundle could not be found in storage.", suggestion: "Try re-importing the IPA.")

        case .APPLE_INTEL_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Apple Intelligence processing failed.", suggestion: "Check if your device supports Apple Intelligence and has it enabled.")
        case .DEVICE_NOT_SUPPORTED:
            return LogErrorCodeInfo(code: self.rawValue, description: "This feature is not supported on your device.", suggestion: "Some features require specific hardware or iOS versions.")
        case .HEARTBEAT_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Communication with the device heartbeat service failed.", suggestion: "Ensure your device is correctly connected and trusted.")
        case .GUIDE_AI_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "An error occurred in the Guide AI service.", suggestion: "Check your internet connection or Guide AI settings.")

        case .APP_LAUNCH:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application has started.", suggestion: "No action needed.")
        case .APP_ACTIVE:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application moved to the foreground.", suggestion: "No action needed.")
        case .APP_BACKGROUND:
            return LogErrorCodeInfo(code: self.rawValue, description: "The application moved to the background.", suggestion: "No action needed.")

        case .BACKUP_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to create or export a backup.", suggestion: "Ensure you have enough storage space and the necessary permissions.")
        case .RESTORE_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to restore from a backup.", suggestion: "The backup file might be corrupted or incompatible with this version of Portal.")
        case .METADATA_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to process metadata for backups or apps.", suggestion: "This could be due to a database issue. Try refreshing the view.")

        case .FILE_OP_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "A file operation (rename, delete, duplicate) failed.", suggestion: "Check if the file is currently in use or if you have permission to modify it.")
        case .FOLDER_CREATION_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to create a new folder.", suggestion: "Ensure the folder name is valid and doesn't contain restricted characters.")
        case .PLAIN_TEXT_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to load or save a plain text file.", suggestion: "The file might be using an unsupported encoding.")
        case .JSON_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to process a JSON file.", suggestion: "Verify that the JSON structure is valid.")
        case .PLIST_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to process a Property List file.", suggestion: "Verify that the Plist structure is valid.")
        case .HEX_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "An error occurred in the Hex Editor.", suggestion: "The file might be too large or protected.")
        case .CHECKSUM_ERR:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to calculate the file checksum.", suggestion: "The file might have been modified or is inaccessible.")

        case .UPDATE_CHECK_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to check for application updates.", suggestion: "Check your internet connection and try again later.")
        case .UPDATE_INSTALL_FAILED:
            return LogErrorCodeInfo(code: self.rawValue, description: "Failed to install the application update.", suggestion: "Try downloading the update manually from the official source.")
        }
    }
}
