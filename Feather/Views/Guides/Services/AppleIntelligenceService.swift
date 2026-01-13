import Foundation
import UIKit
import SwiftUI

final class AppleIntelligenceService {
    static let shared = AppleIntelligenceService()
    
    private init() {}
    
    enum AppleIntelligenceError: Error, LocalizedError {
        case notAvailable
        case processingFailed(String)
        case unsupportedAction
        case cancelled
        case noResult
        
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
            }
        }
    }
    
    var isAvailable: Bool {
        if #available(iOS 18.2, *) {
            return checkWritingToolsAvailability()
        }
        return false
    }
    
    private func checkWritingToolsAvailability() -> Bool {
        // Check if device supports Apple Intelligence
        // This checks for iOS 18.2+ and compatible hardware (A17 Pro or M-series)
        guard #available(iOS 18.2, *) else { return false }
        
        // Check device model for Apple Intelligence support
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Apple Intelligence requires iPhone 15 Pro/Pro Max (A17 Pro) or later
        // or iPad/Mac with M1 or later
        let supportedPrefixes = [
            "iPhone16,", // iPhone 15 Pro, Pro Max
            "iPhone17,", // iPhone 16 series
            "iPad14,",   // iPad Pro M2
            "iPad16,",   // iPad Pro M4
            "arm64"      // Simulator on Apple Silicon Mac
        ]
        
        return supportedPrefixes.contains { identifier.hasPrefix($0) }
    }
    
    func processText(
        _ text: String,
        action: AIAction,
        customInstruction: String? = nil
    ) async throws -> String {
        guard isAvailable else {
            throw AppleIntelligenceError.notAvailable
        }
        
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
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            continuation.resume(throwing: AppleIntelligenceError.processingFailed("Unable to present interface"))
            return
        }
        
        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        let writingToolsVC = WritingToolsViewController(
            text: text,
            action: action,
            customInstruction: customInstruction
        ) { result in
            switch result {
            case .success(let processedText):
                continuation.resume(returning: processedText)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
        
        let navController = UINavigationController(rootViewController: writingToolsVC)
        navController.modalPresentationStyle = .pageSheet
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
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
    }
    
    private func getInstructionText() -> String {
        switch action {
        case .simplify:
            return "Use Writing Tools to simplify this text. Select the text and choose 'Proofread' or 'Rewrite' options."
        case .translate:
            return "Use Writing Tools to translate this text. Select the text and use the translation features."
        case .explain:
            return "Use Writing Tools to explain or expand on this text. Select the text and choose 'Rewrite' options."
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
        dismiss(animated: true) {
            self.completion(.failure(AppleIntelligenceService.AppleIntelligenceError.cancelled))
        }
    }
    
    @objc private func doneTapped() {
        guard !hasCompleted else { return }
        hasCompleted = true
        let processedText = textView.text ?? ""
        dismiss(animated: true) {
            if processedText.isEmpty {
                self.completion(.failure(AppleIntelligenceService.AppleIntelligenceError.noResult))
            } else {
                self.completion(.success(processedText))
            }
        }
    }
}
