import SwiftUI
import UIKit

// MARK: - Format Option
enum FormatOption: String, CaseIterable, Identifiable, Hashable {
    case bold, italic, underline, strikethrough, code, link, header, quote, list
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .link: return "link"
        case .header: return "textformat.size"
        case .quote: return "text.quote"
        case .list: return "list.bullet"
        }
    }
    
    var color: Color {
        switch self {
        case .bold: return .red
        case .italic: return .blue
        case .underline: return .green
        case .strikethrough: return .orange
        case .code: return .purple
        case .link: return .teal
        case .header: return .pink
        case .quote: return .indigo
        case .list: return .mint
        }
    }
    
    var markdownPrefix: String {
        switch self {
        case .bold: return "**"
        case .italic: return "_"
        case .underline: return "__"
        case .strikethrough: return "~~"
        case .code: return "`"
        case .link: return "["
        case .header: return "# "
        case .quote: return "> "
        case .list: return "• "
        }
    }
    
    var markdownSuffix: String {
        switch self {
        case .bold: return "**"
        case .italic: return "_"
        case .underline: return "__"
        case .strikethrough: return "~~"
        case .code: return "`"
        case .link: return "](url)"
        case .header, .quote, .list: return ""
        }
    }
}

// MARK: - Markdown Text Manager
class MarkdownTextManager: ObservableObject {
    @Published var rawText: String = ""
    @Published var attributedText: NSAttributedString = NSAttributedString()
    @Published var activeFormats: Set<FormatOption> = []
    
    weak var textView: UITextView? {
        didSet { setupTextView() }
    }
    
    var plainText: String { rawText }
    var characterCount: Int { rawText.count }
    
    private func setupTextView() {
        guard let textView = textView else { return }
        textView.attributedText = attributedText
    }
    
    func insertFormat(_ option: FormatOption) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange
        let currentText = rawText
        
        if selectedRange.length > 0 {
            // Wrap selected text
            let start = currentText.index(currentText.startIndex, offsetBy: selectedRange.location)
            let end = currentText.index(start, offsetBy: selectedRange.length)
            let selectedText = String(currentText[start..<end])
            
            let wrappedText = option.markdownPrefix + selectedText + option.markdownSuffix
            
            let mutableText = NSMutableString(string: currentText)
            mutableText.replaceCharacters(in: selectedRange, with: wrappedText)
            rawText = mutableText as String
            
            // Update cursor position
            let newPosition = selectedRange.location + wrappedText.count
            updateTextView()
            textView.selectedRange = NSRange(location: newPosition, length: 0)
        } else {
            // Insert at cursor
            let insertText = option.markdownPrefix + option.markdownSuffix
            let location = selectedRange.location
            
            let mutableText = NSMutableString(string: currentText)
            mutableText.insert(insertText, at: location)
            rawText = mutableText as String
            
            // Position cursor between prefix and suffix
            let cursorPosition = location + option.markdownPrefix.count
            updateTextView()
            textView.selectedRange = NSRange(location: cursorPosition, length: 0)
        }
        
        HapticsManager.shared.softImpact()
    }
    
    func updateFromTextView() {
        guard let textView = textView else { return }
        rawText = textView.text ?? ""
        parseAndRender()
    }
    
    func updateTextView() {
        parseAndRender()
        guard let textView = textView else { return }
        let selectedRange = textView.selectedRange
        textView.attributedText = attributedText
        textView.selectedRange = selectedRange
    }
    
    private func parseAndRender() {
        attributedText = parseMarkdown(rawText)
    }
    
    private func parseMarkdown(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let defaultFont = UIFont.systemFont(ofSize: 16)
        let defaultAttrs: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: UIColor.label
        ]
        
        var currentIndex = text.startIndex
        let endIndex = text.endIndex
        
        while currentIndex < endIndex {
            // Check for bold **text**
            if let match = matchPattern(in: text, from: currentIndex, prefix: "**", suffix: "**") {
                let boldFont = UIFont.boldSystemFont(ofSize: 16)
                let attrs: [NSAttributedString.Key: Any] = [.font: boldFont, .foregroundColor: UIColor.label]
                result.append(NSAttributedString(string: match.content, attributes: attrs))
                currentIndex = match.endIndex
                continue
            }
            
            // Check for italic _text_
            if let match = matchPattern(in: text, from: currentIndex, prefix: "_", suffix: "_") {
                let italicFont = UIFont.italicSystemFont(ofSize: 16)
                let attrs: [NSAttributedString.Key: Any] = [.font: italicFont, .foregroundColor: UIColor.label]
                result.append(NSAttributedString(string: match.content, attributes: attrs))
                currentIndex = match.endIndex
                continue
            }
            
            // Check for underline __text__
            if let match = matchPattern(in: text, from: currentIndex, prefix: "__", suffix: "__") {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: defaultFont,
                    .foregroundColor: UIColor.label,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ]
                result.append(NSAttributedString(string: match.content, attributes: attrs))
                currentIndex = match.endIndex
                continue
            }
            
            // Check for strikethrough ~~text~~
            if let match = matchPattern(in: text, from: currentIndex, prefix: "~~", suffix: "~~") {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: defaultFont,
                    .foregroundColor: UIColor.label,
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue
                ]
                result.append(NSAttributedString(string: match.content, attributes: attrs))
                currentIndex = match.endIndex
                continue
            }
            
            // Check for code `text`
            if let match = matchPattern(in: text, from: currentIndex, prefix: "`", suffix: "`") {
                let codeFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: codeFont,
                    .foregroundColor: UIColor.systemPurple,
                    .backgroundColor: UIColor.systemPurple.withAlphaComponent(0.1)
                ]
                result.append(NSAttributedString(string: match.content, attributes: attrs))
                currentIndex = match.endIndex
                continue
            }
            
            // Check for header # text (at line start)
            if currentIndex == text.startIndex || text[text.index(before: currentIndex)] == "\n" {
                if text[currentIndex...].hasPrefix("# ") {
                    if let lineEnd = text[currentIndex...].firstIndex(of: "\n") ?? (currentIndex < endIndex ? endIndex : nil) {
                        let headerStart = text.index(currentIndex, offsetBy: 2)
                        if headerStart < lineEnd {
                            let headerText = String(text[headerStart..<lineEnd])
                            let headerFont = UIFont.boldSystemFont(ofSize: 22)
                            let attrs: [NSAttributedString.Key: Any] = [.font: headerFont, .foregroundColor: UIColor.label]
                            result.append(NSAttributedString(string: headerText, attributes: attrs))
                            if lineEnd < endIndex {
                                result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
                                currentIndex = text.index(after: lineEnd)
                            } else {
                                currentIndex = endIndex
                            }
                            continue
                        }
                    }
                }
                
                // Check for quote > text
                if text[currentIndex...].hasPrefix("> ") {
                    if let lineEnd = text[currentIndex...].firstIndex(of: "\n") ?? (currentIndex < endIndex ? endIndex : nil) {
                        let quoteStart = text.index(currentIndex, offsetBy: 2)
                        if quoteStart < lineEnd {
                            let quoteText = String(text[quoteStart..<lineEnd])
                            let quoteFont = UIFont.italicSystemFont(ofSize: 16)
                            let attrs: [NSAttributedString.Key: Any] = [
                                .font: quoteFont,
                                .foregroundColor: UIColor.secondaryLabel
                            ]
                            result.append(NSAttributedString(string: "│ " + quoteText, attributes: attrs))
                            if lineEnd < endIndex {
                                result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
                                currentIndex = text.index(after: lineEnd)
                            } else {
                                currentIndex = endIndex
                            }
                            continue
                        }
                    }
                }
                
                // Check for list • text
                if text[currentIndex...].hasPrefix("• ") {
                    if let lineEnd = text[currentIndex...].firstIndex(of: "\n") ?? (currentIndex < endIndex ? endIndex : nil) {
                        let listStart = text.index(currentIndex, offsetBy: 2)
                        if listStart <= lineEnd {
                            let listText = String(text[listStart..<lineEnd])
                            let attrs: [NSAttributedString.Key: Any] = [.font: defaultFont, .foregroundColor: UIColor.label]
                            result.append(NSAttributedString(string: "  • " + listText, attributes: attrs))
                            if lineEnd < endIndex {
                                result.append(NSAttributedString(string: "\n", attributes: defaultAttrs))
                                currentIndex = text.index(after: lineEnd)
                            } else {
                                currentIndex = endIndex
                            }
                            continue
                        }
                    }
                }
            }
            
            // Regular character
            let char = String(text[currentIndex])
            result.append(NSAttributedString(string: char, attributes: defaultAttrs))
            currentIndex = text.index(after: currentIndex)
        }
        
        return result
    }
    
    private struct PatternMatch {
        let content: String
        let endIndex: String.Index
    }
    
    private func matchPattern(in text: String, from start: String.Index, prefix: String, suffix: String) -> PatternMatch? {
        let remaining = text[start...]
        guard remaining.hasPrefix(prefix) else { return nil }
        
        let contentStart = text.index(start, offsetBy: prefix.count)
        guard contentStart < text.endIndex else { return nil }
        
        // Find the suffix
        if let suffixRange = text[contentStart...].range(of: suffix) {
            let content = String(text[contentStart..<suffixRange.lowerBound])
            guard !content.isEmpty else { return nil }
            return PatternMatch(content: content, endIndex: suffixRange.upperBound)
        }
        
        return nil
    }
}

// MARK: - Format Toolbar Button
struct FormatToolbarButton: View {
    let option: FormatOption
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: option.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(option.color)
                    .frame(width: 44, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(option.color.opacity(0.12))
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Keyboard Format Toolbar
struct KeyboardFormatToolbar: View {
    @ObservedObject var manager: MarkdownTextManager
    let onDismissKeyboard: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FormatOption.allCases) { option in
                        FormatToolbarButton(option: option) {
                            manager.insertFormat(option)
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Divider()
                .frame(height: 30)
                .padding(.horizontal, 8)
            
            Button(action: onDismissKeyboard) {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 36)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 52)
        .background(.bar)
    }
}

// MARK: - UIKit Toolbar View
class FormatToolbarUIView: UIView {
    var manager: MarkdownTextManager?
    private var hostingController: UIHostingController<KeyboardFormatToolbar>?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with manager: MarkdownTextManager, dismissAction: @escaping () -> Void) {
        self.manager = manager
        
        let toolbar = KeyboardFormatToolbar(manager: manager, onDismissKeyboard: dismissAction)
        let hosting = UIHostingController(rootView: toolbar)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        hostingController = hosting
    }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 52)
    }
}

// MARK: - Markdown Description Editor
struct MarkdownDescriptionEditor: UIViewRepresentable {
    @ObservedObject var manager: MarkdownTextManager
    let placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 16)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.allowsEditingTextAttributes = false
        textView.autocorrectionType = .default
        textView.autocapitalizationType = .sentences
        
        // Setup toolbar
        let toolbar = FormatToolbarUIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 52))
        toolbar.configure(with: manager) {
            textView.resignFirstResponder()
        }
        textView.inputAccessoryView = toolbar
        
        // Setup placeholder
        context.coordinator.setupPlaceholder(textView, placeholder)
        
        manager.textView = textView
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.placeholder?.isHidden = !manager.rawText.isEmpty
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MarkdownDescriptionEditor
        weak var placeholder: UILabel?
        
        init(_ parent: MarkdownDescriptionEditor) {
            self.parent = parent
        }
        
        func setupPlaceholder(_ textView: UITextView, _ text: String) {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 16)
            label.textColor = .tertiaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            textView.addSubview(label)
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: textView.topAnchor, constant: 12),
                label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 13)
            ])
            placeholder = label
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.manager.rawText = textView.text ?? ""
            parent.manager.updateTextView()
            placeholder?.isHidden = !textView.text.isEmpty
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            placeholder?.isHidden = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            placeholder?.isHidden = !textView.text.isEmpty
        }
    }
}

// MARK: - Legacy Support (Sheet version for fallback)
struct FeedbackFormatController: View {
    @ObservedObject var manager: MarkdownTextManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            HStack {
                Label("Format", systemImage: "textformat")
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FormatOption.allCases) { option in
                        FormatToolbarButton(option: option) {
                            manager.insertFormat(option)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Backward Compatibility Aliases
typealias FormattedTextManager = MarkdownTextManager
typealias FormattedDescriptionEditor = MarkdownDescriptionEditor
