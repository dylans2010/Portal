import Foundation
import UIKit
import SwiftUI

final class AppleIntelligenceService {
    static let shared = AppleIntelligenceService()
    
    private init() {
        AppLogManager.shared.info("AppleIntelligenceService initialized", category: "AppleIntelligence")
    }
    
    enum AppleIntelligenceError: Error, LocalizedError {
        case notAvailable
        case processingFailed(String)
        case unsupportedAction
        case cancelled
        case noResult
        case deviceNotSupported(String)
        case writingToolsUnavailable
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Apple Intelligence is not available on this device"
            case .processingFailed(let message):
                return "Processing failed: \(message)"
            case .unsupportedAction:
                return "This action is not supported by Apple Intelligence"
            case .cancelled:
                return "Operation was cancelled"
            case .noResult:
                return "No result from Apple Intelligence"
            case .deviceNotSupported(let device):
                return "Device '\(device)' does not support Apple Intelligence. Requires iPhone 15 Pro or later, or iPad/Mac with M1 chip or later."
            case .writingToolsUnavailable:
                return "Writing Tools are not available. Please ensure Apple Intelligence is enabled in Settings."
            }
        }
    }
    
    var isAvailable: Bool {
        let available = checkWritingToolsAvailability()
        AppLogManager.shared.debug("Apple Intelligence availability check: \(available)", category: "AppleIntelligence")
        return available
    }
    
    var deviceIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    private func checkWritingToolsAvailability() -> Bool {
        // Check if device supports Apple Intelligence
        // This checks for iOS 18.2+ and compatible hardware (A17 Pro or M-series)
        guard #available(iOS 18.2, *) else {
            AppLogManager.shared.warning("iOS version < 18.2, Apple Intelligence not available", category: "AppleIntelligence")
            return false
        }
        
        let identifier = deviceIdentifier
        AppLogManager.shared.info("Device identifier: \(identifier)", category: "AppleIntelligence")
        
        // Apple Intelligence requires iPhone 15 Pro/Pro Max (A17 Pro) or later
        // or iPad/Mac with M1 or later
        let supportedPrefixes = [
            "iPhone16,", // iPhone 15 Pro, Pro Max
            "iPhone17,", // iPhone 16 series
            "iPhone18,", // Future iPhones
            "iPad14,",   // iPad Pro M2
            "iPad16,",   // iPad Pro M4
            "arm64"      // Simulator on Apple Silicon Mac
        ]
        
        let isSupported = supportedPrefixes.contains { identifier.hasPrefix($0) }
        
        if !isSupported {
            AppLogManager.shared.error("Device '\(identifier)' not in supported list for Apple Intelligence", category: "AppleIntelligence")
        } else {
            AppLogManager.shared.success("Device '\(identifier)' supports Apple Intelligence", category: "AppleIntelligence")
        }
        
        return isSupported
    }
    
    func processText(
        _ text: String,
        action: AIAction,
        customInstruction: String? = nil
    ) async throws -> String {
        AppLogManager.shared.info("Starting Apple Intelligence processing for action: \(action.rawValue)", category: "AppleIntelligence")
        
        if let instruction = customInstruction {
            AppLogManager.shared.debug("Custom instruction provided: \(instruction)", category: "AppleIntelligence")
        }
        
        guard isAvailable else {
            let error = AppleIntelligenceError.deviceNotSupported(deviceIdentifier)
            AppLogManager.shared.error("Apple Intelligence not available: \(error.localizedDescription)", category: "AppleIntelligence")
            throw error
        }
        
        AppLogManager.shared.info("Presenting Writing Tools interface...", category: "AppleIntelligence")
        
        // Apple Intelligence Writing Tools requires user interaction through the system UI
        // We'll present a modal with a text view that has Writing Tools enabled
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                presentWritingToolsInterface(
                    text: text,
                    action: action,
                    customInstruction: customInstruction,
                    continuation: continuation
                )
            }
        }
    }
    
    @MainActor
    private func presentWritingToolsInterface(
        text: String,
        action: AIAction,
        customInstruction: String?,
        continuation: CheckedContinuation<String, Error>
    ) {
        AppLogManager.shared.debug("Attempting to present Writing Tools interface", category: "AppleIntelligence")
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            let error = AppleIntelligenceError.processingFailed("Unable to present interface - no root view controller")
            AppLogManager.shared.error("Failed to get root view controller", category: "AppleIntelligence")
            continuation.resume(throwing: error)
            return
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        AppLogManager.shared.debug("Found top controller: \(type(of: topController))", category: "AppleIntelligence")
        
        let writingToolsVC = WritingToolsViewController(
            text: text,
            action: action,
            customInstruction: customInstruction
        ) { result in
            switch result {
            case .success(let processedText):
                AppLogManager.shared.success("Apple Intelligence processing completed successfully", category: "AppleIntelligence")
                AppLogManager.shared.debug("Output length: \(processedText.count) characters", category: "AppleIntelligence")
                continuation.resume(returning: processedText)
            case .failure(let error):
                AppLogManager.shared.error("Apple Intelligence processing failed: \(error.localizedDescription)", category: "AppleIntelligence")
                continuation.resume(throwing: error)
            }
        }
        
        let navController = UINavigationController(rootViewController: writingToolsVC)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        AppLogManager.shared.info("Presenting Writing Tools view controller", category: "AppleIntelligence")
        topController.present(navController, animated: true)
    }
}

// MARK: - Writing Tools View Controller
class WritingToolsViewController: UIViewController {
    private let originalText: String
    private let action: AIAction
    private let customInstruction: String?
    private let completion: (Result<String, Error>) -> Void
    
    private var textView: UITextView!
    private var hasCompleted = false
    
    init(
        text: String,
        action: AIAction,
        customInstruction: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        self.originalText = text
        self.action = action
        self.customInstruction = customInstruction
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        AppLogManager.shared.debug("WritingToolsViewController initialized for action: \(action.rawValue)", category: "AppleIntelligence")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AppLogManager.shared.debug("WritingToolsViewController viewDidLoad", category: "AppleIntelligence")
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppLogManager.shared.info("Writing Tools interface presented to user", category: "AppleIntelligence")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        title = "Apple Intelligence"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        
        // Instructions label
        let instructionLabel = UILabel()
        instructionLabel.text = getInstructionText()
        instructionLabel.font = .preferredFont(forTextStyle: .subheadline)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.numberOfLines = 0
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        // Text view with Writing Tools support
        textView = UITextView()
        textView.text = originalText
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isEditable = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        
        // Enable Writing Tools on iOS 18.2+
        if #available(iOS 18.2, *) {
            textView.writingToolsBehavior = .complete
            AppLogManager.shared.success("Writing Tools behavior set to .complete", category: "AppleIntelligence")
        } else {
            AppLogManager.shared.warning("iOS < 18.2, Writing Tools behavior not available", category: "AppleIntelligence")
        }
        
        view.addSubview(textView)
        
        // Tip label
        let tipLabel = UILabel()
        tipLabel.text = "Tip: Select text and use the Writing Tools menu, or tap the ✨ button in the keyboard toolbar."
        tipLabel.font = .preferredFont(forTextStyle: .caption1)
        tipLabel.textColor = .tertiaryLabel
        tipLabel.numberOfLines = 0
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tipLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            textView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: tipLabel.topAnchor, constant: -12),
            
            tipLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tipLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tipLabel.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -12)
        ])
        
        // Select all text to make it easy to apply Writing Tools
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: 0, length: textView.text.count)
        AppLogManager.shared.debug("Text selected, ready for Writing Tools", category: "AppleIntelligence")
    }
    
    private func getInstructionText() -> String {
        switch action {
        case .simplify:
            return "Use Writing Tools to simplify this text. Select the text and choose 'Proofread' or 'Rewrite' options."
        case .translate:
            if let language = customInstruction {
                return "Translate this text to \(language). Select the text and use Writing Tools translation features, or manually translate and tap Done."
            }
            return "Use Writing Tools to translate this text. Select the text and use the translation features."
        case .explain:
            return "Use Writing Tools to explain or expand on this text. Select the text and choose 'Rewrite' options."
        case .summarize:
            return "Use Writing Tools to summarize this text. Select the text and choose 'Summary' or 'Rewrite' options."
        case .keyPoints:
            return "Use Writing Tools to extract key points from this text. Select the text and choose 'Key Points' or 'Rewrite' options."
        case .stepByStep:
            return "Use Writing Tools to convert this text into step-by-step instructions. Select the text and choose 'Rewrite' options."
        case .proofread:
            return "Use Writing Tools to proofread this text. Select the text and choose 'Proofread' to fix grammar and improve clarity."
        case .describeGuide:
            if let instruction = customInstruction {
                return "Custom instruction: \(instruction)\n\nUse Writing Tools to process the text according to this instruction."
            }
            return "Use Writing Tools to process this text as needed."
        }
    }
    
    @objc private func cancelTapped() {
        guard !hasCompleted else { return }
        hasCompleted = true
        AppLogManager.shared.warning("User cancelled Apple Intelligence operation", category: "AppleIntelligence")
        dismiss(animated: true) {
            self.completion(.failure(AppleIntelligenceService.AppleIntelligenceError.cancelled))
        }
    }
    
    @objc private func doneTapped() {
        guard !hasCompleted else { return }
        hasCompleted = true
        let processedText = textView.text ?? ""
        
        AppLogManager.shared.info("User tapped Done, processing result...", category: "AppleIntelligence")
        AppLogManager.shared.debug("Original text length: \(originalText.count), Processed text length: \(processedText.count)", category: "AppleIntelligence")
        
        // Check if text was actually modified
        if processedText == originalText {
            AppLogManager.shared.warning("Text was not modified by user", category: "AppleIntelligence")
        }
        
        dismiss(animated: true) {
            if processedText.isEmpty {
                AppLogManager.shared.error("No result from Writing Tools - empty text", category: "AppleIntelligence")
                self.completion(.failure(AppleIntelligenceService.AppleIntelligenceError.noResult))
            } else {
                self.completion(.success(processedText))
            }
        }
    }
}
