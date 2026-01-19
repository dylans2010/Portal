import SwiftUI
import UIKit

// MARK: - Formatting Options
enum FormattingOption: String, CaseIterable, Identifiable {
    case bold, italic, underline, strikethrough
    case alignLeft, alignCenter, alignRight
    case bulletList, numberedList
    case header1, header2, header3
    case code, quote, link
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .alignLeft: return "text.alignleft"
        case .alignCenter: return "text.aligncenter"
        case .alignRight: return "text.alignright"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .header1: return "textformat.size.larger"
        case .header2: return "textformat.size"
        case .header3: return "textformat.size.smaller"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .quote: return "text.quote"
        case .link: return "link"
        }
    }
    
    var label: String {
        switch self {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strike"
        case .alignLeft: return "Left"
        case .alignCenter: return "Center"
        case .alignRight: return "Right"
        case .bulletList: return "Bullets"
        case .numberedList: return "Numbers"
        case .header1: return "H1"
        case .header2: return "H2"
        case .header3: return "H3"
        case .code: return "Code"
        case .quote: return "Quote"
        case .link: return "Link"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .bold: return [Color(red: 1.0, green: 0.4, blue: 0.4), Color(red: 0.95, green: 0.25, blue: 0.35)]
        case .italic: return [Color(red: 0.4, green: 0.8, blue: 1.0), Color(red: 0.3, green: 0.6, blue: 0.95)]
        case .underline: return [Color(red: 0.5, green: 0.9, blue: 0.5), Color(red: 0.3, green: 0.75, blue: 0.4)]
        case .strikethrough: return [Color(red: 1.0, green: 0.75, blue: 0.4), Color(red: 0.95, green: 0.55, blue: 0.3)]
        case .alignLeft, .alignCenter, .alignRight: return [Color(red: 0.6, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.35, blue: 0.9)]
        case .bulletList, .numberedList: return [Color(red: 0.4, green: 0.9, blue: 0.8), Color(red: 0.3, green: 0.75, blue: 0.7)]
        case .header1, .header2, .header3: return [Color(red: 1.0, green: 0.5, blue: 0.8), Color(red: 0.9, green: 0.35, blue: 0.65)]
        case .code: return [Color(red: 0.6, green: 0.4, blue: 1.0), Color(red: 0.8, green: 0.3, blue: 0.95)]
        case .quote: return [Color(red: 0.5, green: 0.7, blue: 0.9), Color(red: 0.4, green: 0.55, blue: 0.85)]
        case .link: return [Color(red: 0.4, green: 1.0, blue: 0.7), Color(red: 0.3, green: 0.85, blue: 0.55)]
        }
    }
    
    static var textStyles: [FormattingOption] { [.bold, .italic, .underline, .strikethrough] }
    static var alignments: [FormattingOption] { [.alignLeft, .alignCenter, .alignRight] }
    static var lists: [FormattingOption] { [.bulletList, .numberedList] }
    static var headers: [FormattingOption] { [.header1, .header2, .header3] }
    static var blocks: [FormattingOption] { [.code, .quote, .link] }
}

// MARK: - Formatted Text Manager
class FormattedTextManager: ObservableObject {
    @Published var attributedText: NSMutableAttributedString
    @Published var activeFormats: Set<FormattingOption> = []
    @Published var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    weak var textView: UITextView? {
        didSet {
            if let textView = textView {
                attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            }
        }
    }
    
    init() {
        attributedText = NSMutableAttributedString()
    }
    
    var plainText: String {
        attributedText.string
    }
    
    var characterCount: Int {
        attributedText.length
    }
    
    func applyFormat(_ option: FormattingOption) {
        guard let textView = textView else { return }
        let range = textView.selectedRange
        guard range.length > 0 else { return }
        
        let mutableAttr = NSMutableAttributedString(attributedString: textView.attributedText)
        
        switch option {
        case .bold:
            applyFontTrait(.traitBold, to: mutableAttr, in: range)
        case .italic:
            applyFontTrait(.traitItalic, to: mutableAttr, in: range)
        case .underline:
            toggleAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, in: mutableAttr, range: range)
        case .strikethrough:
            toggleAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, in: mutableAttr, range: range)
        case .alignLeft:
            applyAlignment(.left, to: mutableAttr, in: range)
        case .alignCenter:
            applyAlignment(.center, to: mutableAttr, in: range)
        case .alignRight:
            applyAlignment(.right, to: mutableAttr, in: range)
        case .header1:
            applyHeaderStyle(size: 28, weight: .bold, to: mutableAttr, in: range)
        case .header2:
            applyHeaderStyle(size: 22, weight: .semibold, to: mutableAttr, in: range)
        case .header3:
            applyHeaderStyle(size: 18, weight: .medium, to: mutableAttr, in: range)
        case .code:
            applyCodeStyle(to: mutableAttr, in: range)
        case .quote:
            applyQuoteStyle(to: mutableAttr, in: range)
        case .bulletList, .numberedList:
            // Lists are handled differently - insert prefix
            break
        case .link:
            // Link requires URL input - handled separately
            break
        }
        
        textView.attributedText = mutableAttr
        textView.selectedRange = range
        attributedText = mutableAttr
        updateActiveFormats()
    }
    
    func applyLink(url: String) {
        guard let textView = textView, let linkURL = URL(string: url) else { return }
        let range = textView.selectedRange
        guard range.length > 0 else { return }
        
        let mutableAttr = NSMutableAttributedString(attributedString: textView.attributedText)
        mutableAttr.addAttribute(.link, value: linkURL, range: range)
        mutableAttr.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: range)
        mutableAttr.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        
        textView.attributedText = mutableAttr
        textView.selectedRange = range
        attributedText = mutableAttr
    }
    
    private func applyFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, to attrString: NSMutableAttributedString, in range: NSRange) {
        attrString.enumerateAttribute(.font, in: range, options: []) { value, subRange, _ in
            guard let currentFont = value as? UIFont else {
                let defaultFont = UIFont.systemFont(ofSize: 15)
                if let descriptor = defaultFont.fontDescriptor.withSymbolicTraits(trait) {
                    attrString.addAttribute(.font, value: UIFont(descriptor: descriptor, size: 15), range: subRange)
                }
                return
            }
            
            var newTraits = currentFont.fontDescriptor.symbolicTraits
            if newTraits.contains(trait) {
                newTraits.remove(trait)
            } else {
                newTraits.insert(trait)
            }
            
            if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(newTraits) {
                attrString.addAttribute(.font, value: UIFont(descriptor: descriptor, size: currentFont.pointSize), range: subRange)
            }
        }
    }
    
    private func toggleAttribute(_ key: NSAttributedString.Key, value: Any, in attrString: NSMutableAttributedString, range: NSRange) {
        var hasAttribute = false
        attrString.enumerateAttribute(key, in: range, options: []) { existingValue, _, stop in
            if existingValue != nil {
                hasAttribute = true
                stop.pointee = true
            }
        }
        
        if hasAttribute {
            attrString.removeAttribute(key, range: range)
        } else {
            attrString.addAttribute(key, value: value, range: range)
        }
    }
    
    private func applyAlignment(_ alignment: NSTextAlignment, to attrString: NSMutableAttributedString, in range: NSRange) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }
    
    private func applyHeaderStyle(size: CGFloat, weight: UIFont.Weight, to attrString: NSMutableAttributedString, in range: NSRange) {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        attrString.addAttribute(.font, value: font, range: range)
    }
    
    private func applyCodeStyle(to attrString: NSMutableAttributedString, in range: NSRange) {
        let codeFont = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        attrString.addAttribute(.font, value: codeFont, range: range)
        attrString.addAttribute(.backgroundColor, value: UIColor.systemPurple.withAlphaComponent(0.15), range: range)
        attrString.addAttribute(.foregroundColor, value: UIColor.systemPurple, range: range)
    }
    
    private func applyQuoteStyle(to attrString: NSMutableAttributedString, in range: NSRange) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 16
        paragraphStyle.headIndent = 16
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
        attrString.addAttribute(.foregroundColor, value: UIColor.secondaryLabel, range: range)
        
        let font = UIFont.italicSystemFont(ofSize: 15)
        attrString.addAttribute(.font, value: font, range: range)
    }
    
    func updateActiveFormats() {
        guard let textView = textView else { return }
        let range = textView.selectedRange
        guard range.length > 0 else {
            activeFormats.removeAll()
            return
        }
        
        var formats: Set<FormattingOption> = []
        let attrString = textView.attributedText ?? NSAttributedString()
        
        attrString.enumerateAttributes(in: range, options: []) { attrs, _, _ in
            if let font = attrs[.font] as? UIFont {
                let traits = font.fontDescriptor.symbolicTraits
                if traits.contains(.traitBold) { formats.insert(.bold) }
                if traits.contains(.traitItalic) { formats.insert(.italic) }
            }
            if attrs[.underlineStyle] != nil { formats.insert(.underline) }
            if attrs[.strikethroughStyle] != nil { formats.insert(.strikethrough) }
        }
        
        activeFormats = formats
    }
}

// MARK: - Liquid Glass Button Style
struct LiquidGlassButtonStyle: ButtonStyle {
    let isActive: Bool
    let gradient: [Color]
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let option: FormattingOption
    let isActive: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Liquid Glass background
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isActive ?
                        LinearGradient(colors: option.gradient, startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: isActive ? [Color.white.opacity(0.6), Color.white.opacity(0.2)] : [Color.white.opacity(0.3), Color.white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: isActive ? option.gradient[0].opacity(0.4) : Color.black.opacity(0.1), radius: isActive ? 8 : 4, x: 0, y: isActive ? 4 : 2)
                
                Image(systemName: option.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isActive ? .white : .primary)
            }
            .frame(width: 40, height: 36)
        }
        .buttonStyle(LiquidGlassButtonStyle(isActive: isActive, gradient: option.gradient))
    }
}

// MARK: - Format Section
struct FormatSection: View {
    let title: String
    let options: [FormattingOption]
    let activeFormats: Set<FormattingOption>
    let onSelect: (FormattingOption) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            
            HStack(spacing: 6) {
                ForEach(options) { option in
                    FormatButton(
                        option: option,
                        isActive: activeFormats.contains(option)
                    ) {
                        onSelect(option)
                    }
                }
            }
        }
    }
}

// MARK: - Feedback Format Controller View
struct FeedbackFormatController: View {
    @ObservedObject var manager: FormattedTextManager
    @Environment(\.dismiss) private var dismiss
    @State private var showLinkInput = false
    @State private var linkURL = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle bar
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 12)
            
            // Header
            HStack {
                Text("Format")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
            // Formatting options
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Text Styles
                    FormatSection(
                        title: "Style",
                        options: FormattingOption.textStyles,
                        activeFormats: manager.activeFormats,
                        onSelect: { option in
                            manager.applyFormat(option)
                            HapticsManager.shared.softImpact()
                        }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Alignment
                    FormatSection(
                        title: "Alignment",
                        options: FormattingOption.alignments,
                        activeFormats: manager.activeFormats,
                        onSelect: { option in
                            manager.applyFormat(option)
                            HapticsManager.shared.softImpact()
                        }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Headers
                    FormatSection(
                        title: "Headers",
                        options: FormattingOption.headers,
                        activeFormats: manager.activeFormats,
                        onSelect: { option in
                            manager.applyFormat(option)
                            HapticsManager.shared.softImpact()
                        }
                    )
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Blocks
                    HStack(spacing: 16) {
                        FormatSection(
                            title: "Blocks",
                            options: [.code, .quote],
                            activeFormats: manager.activeFormats,
                            onSelect: { option in
                                manager.applyFormat(option)
                                HapticsManager.shared.softImpact()
                            }
                        )
                        
                        Spacer()
                        
                        // Link button
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Link")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                            
                            FormatButton(
                                option: .link,
                                isActive: false
                            ) {
                                showLinkInput = true
                                HapticsManager.shared.softImpact()
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(
            ZStack {
                // Liquid Glass background
                Rectangle()
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.clear,
                        Color.black.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .ignoresSafeArea()
        )
        .alert("Add Link", isPresented: $showLinkInput) {
            TextField("https://", text: $linkURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            
            Button("Cancel", role: .cancel) {
                linkURL = ""
            }
            
            Button("Add") {
                if !linkURL.isEmpty {
                    manager.applyLink(url: linkURL)
                    linkURL = ""
                }
            }
        } message: {
            Text("Enter the URL for the selected text")
        }
    }
}

// MARK: - Format Controller Presenter
struct FormatControllerPresenter {
    @MainActor
    static func present(manager: FormattedTextManager) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        let formatView = FeedbackFormatController(manager: manager)
        let hostingController = UIHostingController(rootView: formatView)
        
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [.custom { _ in 320 }, .medium()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 24
        }
        
        hostingController.view.backgroundColor = .clear
        topVC.present(hostingController, animated: true)
    }
}

// MARK: - Formatted Description Editor
struct FormattedDescriptionEditor: UIViewRepresentable {
    @ObservedObject var manager: FormattedTextManager
    var placeholder: String
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        
        context.coordinator.setupPlaceholder(for: textView, placeholder: placeholder)
        manager.textView = textView
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.updatePlaceholder(for: textView, isEmpty: manager.attributedText.length == 0)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FormattedDescriptionEditor
        weak var placeholderLabel: UILabel?
        
        init(_ parent: FormattedDescriptionEditor) {
            self.parent = parent
        }
        
        func setupPlaceholder(for textView: UITextView, placeholder: String) {
            let label = UILabel()
            label.text = placeholder
            label.font = UIFont.systemFont(ofSize: 15)
            label.textColor = .tertiaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false
            textView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: textView.topAnchor, constant: 14),
                label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 15)
            ])
            
            placeholderLabel = label
        }
        
        func updatePlaceholder(for textView: UITextView, isEmpty: Bool) {
            placeholderLabel?.isHidden = !isEmpty
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.manager.attributedText = NSMutableAttributedString(attributedString: textView.attributedText)
            placeholderLabel?.isHidden = textView.text.count > 0
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.manager.selectedRange = textView.selectedRange
            parent.manager.updateActiveFormats()
        }
    }
}

// MARK: - Preview
struct FeedbackFormatController_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackFormatController(manager: FormattedTextManager())
            .preferredColorScheme(.dark)
    }
}
