import SwiftUI
import UIKit

// MARK: - Formatting Option
enum FormatOption: String, CaseIterable, Identifiable, Hashable {
    case bold, italic, underline, strikethrough, code, link
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .link: return "link"
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
        }
    }
}

// MARK: - Formatted Text Manager
class FormattedTextManager: ObservableObject {
    @Published var attributedText = NSMutableAttributedString()
    @Published var activeFormats: Set<FormatOption> = []
    weak var textView: UITextView?
    
    var plainText: String { attributedText.string }
    var characterCount: Int { attributedText.length }
    
    func applyFormat(_ option: FormatOption) {
        guard let textView = textView else { return }
        let range = textView.selectedRange
        guard range.length > 0, range.location + range.length <= textView.attributedText.length else { return }
        
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        
        switch option {
        case .bold: toggleTrait(.traitBold, in: mutable, range: range)
        case .italic: toggleTrait(.traitItalic, in: mutable, range: range)
        case .underline: toggleStyle(.underlineStyle, in: mutable, range: range)
        case .strikethrough: toggleStyle(.strikethroughStyle, in: mutable, range: range)
        case .code: applyCode(to: mutable, range: range)
        case .link: break
        }
        
        textView.attributedText = mutable
        textView.selectedRange = range
        attributedText = mutable
        updateActiveFormats()
        HapticsManager.shared.softImpact()
    }
    
    func applyLink(_ url: String) {
        guard let textView = textView, let link = URL(string: url) else { return }
        let range = textView.selectedRange
        guard range.length > 0 else { return }
        
        let mutable = NSMutableAttributedString(attributedString: textView.attributedText)
        mutable.addAttributes([.link: link, .foregroundColor: UIColor.systemBlue, .underlineStyle: NSUnderlineStyle.single.rawValue], range: range)
        textView.attributedText = mutable
        textView.selectedRange = range
        attributedText = mutable
    }
    
    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits, in str: NSMutableAttributedString, range: NSRange) {
        str.enumerateAttribute(.font, in: range, options: []) { val, r, _ in
            let font = (val as? UIFont) ?? UIFont.systemFont(ofSize: 15)
            var traits = font.fontDescriptor.symbolicTraits
            if traits.contains(trait) { traits.remove(trait) } else { traits.insert(trait) }
            if let desc = font.fontDescriptor.withSymbolicTraits(traits) {
                str.addAttribute(.font, value: UIFont(descriptor: desc, size: font.pointSize), range: r)
            }
        }
    }
    
    private func toggleStyle(_ key: NSAttributedString.Key, in str: NSMutableAttributedString, range: NSRange) {
        var has = false
        str.enumerateAttribute(key, in: range, options: []) { v, _, stop in if v != nil { has = true; stop.pointee = true } }
        if has { str.removeAttribute(key, range: range) }
        else { str.addAttribute(key, value: NSUnderlineStyle.single.rawValue, range: range) }
    }
    
    private func applyCode(to str: NSMutableAttributedString, range: NSRange) {
        str.addAttributes([
            .font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .backgroundColor: UIColor.systemPurple.withAlphaComponent(0.15),
            .foregroundColor: UIColor.systemPurple
        ], range: range)
    }
    
    func updateActiveFormats() {
        guard let textView = textView else { activeFormats.removeAll(); return }
        let range = textView.selectedRange
        guard range.length > 0, range.location + range.length <= textView.attributedText.length else { activeFormats.removeAll(); return }
        
        var formats: Set<FormatOption> = []
        textView.attributedText.enumerateAttributes(in: range, options: []) { attrs, _, _ in
            if let font = attrs[.font] as? UIFont {
                if font.fontDescriptor.symbolicTraits.contains(.traitBold) { formats.insert(.bold) }
                if font.fontDescriptor.symbolicTraits.contains(.traitItalic) { formats.insert(.italic) }
            }
            if attrs[.underlineStyle] != nil { formats.insert(.underline) }
            if attrs[.strikethroughStyle] != nil { formats.insert(.strikethrough) }
        }
        activeFormats = formats
    }
}

// MARK: - Compact Format Button
struct CompactFormatButton: View {
    let option: FormatOption
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: option.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? .white : .primary)
                .frame(width: 36, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isActive ? option.color : Color(.tertiarySystemFill))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feedback Format Controller
struct FeedbackFormatController: View {
    @ObservedObject var manager: FormattedTextManager
    @Environment(\.dismiss) private var dismiss
    @State private var linkURL = ""
    @State private var showLink = false
    
    private let options: [FormatOption] = [.bold, .italic, .underline, .strikethrough, .code, .link]
    
    var body: some View {
        VStack(spacing: 12) {
            // Drag handle
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            // Title row
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
            
            // Format buttons
            HStack(spacing: 8) {
                ForEach(options) { opt in
                    CompactFormatButton(option: opt, isActive: manager.activeFormats.contains(opt)) {
                        if opt == .link { showLink = true }
                        else { manager.applyFormat(opt) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .alert("Add Link", isPresented: $showLink) {
            TextField("https://", text: $linkURL)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
            Button("Cancel", role: .cancel) { linkURL = "" }
            Button("Add") { manager.applyLink(linkURL); linkURL = "" }
        }
    }
}

// MARK: - Formatted Description Editor
struct FormattedDescriptionEditor: UIViewRepresentable {
    @ObservedObject var manager: FormattedTextManager
    let placeholder: String
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = .systemFont(ofSize: 15)
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        tv.allowsEditingTextAttributes = true
        context.coordinator.addPlaceholder(tv, placeholder)
        manager.textView = tv
        return tv
    }
    
    func updateUIView(_ tv: UITextView, context: Context) {
        context.coordinator.placeholder?.isHidden = tv.text.count > 0
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: FormattedDescriptionEditor
        weak var placeholder: UILabel?
        
        init(_ parent: FormattedDescriptionEditor) { self.parent = parent }
        
        func addPlaceholder(_ tv: UITextView, _ text: String) {
            let lbl = UILabel()
            lbl.text = text
            lbl.font = .systemFont(ofSize: 15)
            lbl.textColor = .tertiaryLabel
            lbl.translatesAutoresizingMaskIntoConstraints = false
            tv.addSubview(lbl)
            NSLayoutConstraint.activate([
                lbl.topAnchor.constraint(equalTo: tv.topAnchor, constant: 12),
                lbl.leadingAnchor.constraint(equalTo: tv.leadingAnchor, constant: 13)
            ])
            placeholder = lbl
        }
        
        func textViewDidChange(_ tv: UITextView) {
            parent.manager.attributedText = NSMutableAttributedString(attributedString: tv.attributedText)
            placeholder?.isHidden = tv.text.count > 0
        }
        
        func textViewDidChangeSelection(_ tv: UITextView) {
            parent.manager.updateActiveFormats()
        }
    }
}
