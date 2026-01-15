import Foundation
import Combine
import SwiftUI
import IDeviceSwift

// MARK: - Modern Installer Status Extension
extension InstallerStatusViewModel {
    
    // MARK: - Status Icon
    var statusImage: String {
        switch status {
        case .none:
            return "archivebox.fill"
        case .ready:
            return "app.gift.fill"
        case .sendingManifest:
            return "doc.text.fill"
        case .sendingPayload:
            return "arrow.up.doc.fill"
        case .installing:
            return "arrow.down.app.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .broken:
            return "xmark.circle.fill"
        }
    }
    
    // MARK: - Status Label
    var statusLabel: String {
        switch status {
        case .none:
            return .localized("Packaging")
        case .ready:
            return .localized("Ready to Install")
        case .sendingManifest:
            return .localized("Sending Manifest")
        case .sendingPayload:
            return .localized("Uploading App")
        case .installing:
            return .localized("Installing")
        case .completed:
            return .localized("Completed")
        case .broken:
            return .localized("Failed")
        }
    }
    
    // MARK: - Status Color
    var statusColor: Color {
        switch status {
        case .none:
            return .gray
        case .ready:
            return .blue
        case .sendingManifest, .sendingPayload:
            return .orange
        case .installing:
            return .purple
        case .completed:
            return .green
        case .broken:
            return .red
        }
    }
    
    // MARK: - Status Description
    var statusDescription: String {
        switch status {
        case .none:
            return .localized("Preparing your app for installation...")
        case .ready:
            return .localized("App is ready to be installed on your device")
        case .sendingManifest:
            return .localized("Sending installation manifest to device...")
        case .sendingPayload:
            return .localized("Uploading app data to your device...")
        case .installing:
            return .localized("Installing app on your device...")
        case .completed:
            return .localized("App has been successfully installed!")
        case .broken:
            return .localized("Installation failed. Please try again.")
        }
    }
    
    // MARK: - Progress Percentage
    var progressPercentage: Int {
        Int(overallProgress * 100)
    }
    
    // MARK: - Formatted Progress
    var formattedProgress: String {
        "\(progressPercentage)%"
    }
    
    // MARK: - Is In Progress
    var isInProgress: Bool {
        switch status {
        case .none, .ready, .sendingManifest, .sendingPayload, .installing:
            return true
        case .completed, .broken:
            return false
        }
    }
    
    // MARK: - Is Error State
    var isError: Bool {
        if case .broken = status {
            return true
        }
        return false
    }
    
    // MARK: - Is Success State
    var isSuccess: Bool {
        if case .completed = status {
            return true
        }
        return false
    }
    
    // MARK: - Step Number
    var currentStep: Int {
        switch status {
        case .none: return 1
        case .ready: return 2
        case .sendingManifest: return 3
        case .sendingPayload: return 4
        case .installing: return 5
        case .completed, .broken: return 6
        }
    }
    
    // MARK: - Total Steps
    var totalSteps: Int {
        isIDevice ? 6 : 3
    }
    
    // MARK: - Step Progress Text
    var stepProgressText: String {
        .localized("Step \(currentStep) of \(totalSteps)")
    }
    
    // MARK: - Individual Progress Values
    var uploadProgressPercentage: Int {
        Int(uploadProgress * 100)
    }
    
    var packageProgressPercentage: Int {
        Int(packageProgress * 100)
    }
    
    var installProgressPercentage: Int {
        Int(installProgress * 100)
    }
}
