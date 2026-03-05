import SwiftUI
import UIKit
import PhotosUI

// MARK: - Category Info Dialog
struct CategoryInfoDialog: View {
    @Binding var isPresented: Bool
    @State private var appearAnimation: Bool = false
    
    private let categories: [(FeedbackView.FeedbackCategory, String)] = [
        (.bug, "Report issues where something isn't working as expected."),
        (.suggestion, "Share ideas for improving existing features."),
        (.feature, "Request entirely new features or capabilities."),
        (.question, "Ask questions about how to use the app or clarify functionality."),
        (.crash, "Report app crashes, freezes or any errors."),
        (.other, "For feedback that doesn't fit other categories.")
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(appearAnimation ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { dismissDialog() }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.5)
                    .opacity(appearAnimation ? 1 : 0)
                    
                    VStack(spacing: 6) {
                        Text("Category Guide")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        
                        Text("Choose the right category for your feedback so I can assist you better.")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 10)
                }
                .padding(.top, 28)
                .padding(.bottom, 20)
                
                // Categories List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(categories.enumerated()), id: \.offset) { index, item in
                            CategoryInfoCard(category: item.0, description: item.1)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.05), value: appearAnimation)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 380)
                
                // Close Button
                Button {
                    dismissDialog()
                } label: {
                    Text("Got It")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.blue, .blue.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 20)
            .scaleEffect(appearAnimation ? 1 : 0.9)
            .opacity(appearAnimation ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }
    
    private func dismissDialog() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            appearAnimation = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Category Info Card
private struct CategoryInfoCard: View {
    let category: FeedbackView.FeedbackCategory
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// MARK: - Link Dialog
struct LinkInsertDialog: View {
    @Binding var isPresented: Bool
    @Binding var text: String
    @State private var linkTitle: String = ""
    @State private var linkURL: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, url
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismissDialog() }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Insert Link")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    Text("Add a hyperlink to your feedback report.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Input Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "textformat")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.blue)
                            Text("Link Title")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "character.cursor.ibeam")
                                .font(.system(size: 16))
                                .foregroundStyle(focusedField == .title ? Color.blue : Color.secondary)
                            
                            TextField("Display Text", text: $linkTitle)
                                .font(.system(size: 15))
                                .focused($focusedField, equals: .title)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .url }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(focusedField == .title ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.blue)
                            Text("URL")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.secondary)
                        }
                        
                        HStack(spacing: 12) {
                            Image(systemName: "link")
                                .font(.system(size: 16))
                                .foregroundStyle(focusedField == .url ? Color.blue : Color.secondary)
                            
                            TextField("Enter URL Here", text: $linkURL)
                                .font(.system(size: 15))
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .url)
                                .submitLabel(.done)
                                .onSubmit { insertLink() }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(UIColor.secondarySystemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(focusedField == .url ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                // Buttons
                HStack(spacing: 12) {
                    Button {
                        dismissDialog()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.clear)
                            )
                    }
                    
                    Button {
                        insertLink()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Insert")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: isValidInput ? [.blue, .blue.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: isValidInput ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                    }
                    .disabled(!isValidInput)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
        .onAppear { focusedField = .title }
    }
    
    private var isValidInput: Bool {
        !linkTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !linkURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func insertLink() {
        guard isValidInput else { return }
        let markdown = "[\(linkTitle.trimmingCharacters(in: .whitespacesAndNewlines))](\(linkURL.trimmingCharacters(in: .whitespacesAndNewlines)))"
        text += markdown
        HapticsManager.shared.softImpact()
        dismissDialog()
    }
    
    private func dismissDialog() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - Screenshot Error Dialog
struct ScreenshotErrorDialog: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { dismissDialog() }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.orange, Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: .orange.opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Image Upload Unavailable")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    
                    Text("Due to GitHub constraints, you cannot upload images directly via this form. Please upload your images to a hoster like Catbox or Imgur and then share the link in your description.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Suggestion Box
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.yellow)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tip")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("Use catbox.moe or imgur.com to host your images.")
                            .font(.system(size: 13))
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                // Button
                Button {
                    dismissDialog()
                } label: {
                    Text("Got It")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 30, x: 0, y: 10)
            )
            .padding(.horizontal, 24)
        }
    }
    
    private func dismissDialog() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isPresented = false
        }
    }
}

// MARK: - Formatting Toolbar
struct FormattingToolbar: View {
    @Binding var text: String
    @Binding var showLinkDialog: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private let toolbarHeight: CGFloat = 48
    
    enum FormatType {
        case bold, italic, strikethrough, code, quote, link, list, heading
        
        var icon: String {
            switch self {
            case .bold: return "bold"
            case .italic: return "italic"
            case .strikethrough: return "strikethrough"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .quote: return "text.quote"
            case .link: return "link"
            case .list: return "list.bullet"
            case .heading: return "number"
            }
        }
        
        var label: String {
            switch self {
            case .bold: return "Bold"
            case .italic: return "Italic"
            case .strikethrough: return "Strikethrough"
            case .code: return "Code"
            case .quote: return "Quote"
            case .link: return "Link"
            case .list: return "List"
            case .heading: return "Heading"
            }
        }
        
        var color: Color {
            switch self {
            case .bold: return .primary
            case .italic: return .primary
            case .strikethrough: return .primary
            case .code: return .orange
            case .quote: return .purple
            case .link: return .blue
            case .list: return .green
            case .heading: return .indigo
            }
        }
        
        var prefix: String {
            switch self {
            case .bold: return "**"
            case .italic: return "_"
            case .strikethrough: return "~~"
            case .code: return "`"
            case .quote: return "> "
            case .link: return "["
            case .list: return "- "
            case .heading: return "## "
            }
        }
        
        var suffix: String {
            switch self {
            case .bold: return "**"
            case .italic: return "_"
            case .strikethrough: return "~~"
            case .code: return "`"
            case .quote: return ""
            case .link: return "](url)"
            case .list: return ""
            case .heading: return ""
            }
        }
        
        var isLineFormat: Bool {
            switch self {
            case .quote, .list, .heading: return true
            default: return false
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach([FormatType.bold, .italic, .strikethrough, .code, .quote, .link, .list, .heading], id: \.icon) { format in
                        FormattingButton(format: format) {
                            if format == .link {
                                showLinkDialog = true
                            } else {
                                applyFormatting(format)
                            }
                            HapticsManager.shared.softImpact()
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 8)
            
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .frame(height: toolbarHeight)
        .background(Color.clear)
    }
    
    private func applyFormatting(_ format: FormatType) {
        if format.isLineFormat {
            if text.isEmpty {
                text = format.prefix
            } else if text.hasSuffix("\n") {
                text += format.prefix
            } else {
                text += "\n" + format.prefix
            }
        } else {
            let placeholder = "text"
            text += format.prefix + placeholder + format.suffix
        }
    }
}

// MARK: - Formatting Button
private struct FormattingButton: View {
    let format: FormattingToolbar.FormatType
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: format.icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(isPressed ? format.color : Color.primary.opacity(0.7))
                .frame(width: 40, height: 40)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(format.label)
    }
}

// MARK: - Modern Formatting Toolbar
struct ModernFormattingToolbar: View {
    @Binding var text: String
    @Binding var showLinkDialog: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    private let toolbarHeight: CGFloat = 50
    
    enum FormatType: CaseIterable {
        case bold, italic, strikethrough, code, quote, link, list, heading
        
        var icon: String {
            switch self {
            case .bold: return "bold"
            case .italic: return "italic"
            case .strikethrough: return "strikethrough"
            case .code: return "chevron.left.forwardslash.chevron.right"
            case .quote: return "text.quote"
            case .link: return "link"
            case .list: return "list.bullet"
            case .heading: return "number"
            }
        }
        
        var label: String {
            switch self {
            case .bold: return "Bold"
            case .italic: return "Italic"
            case .strikethrough: return "Strikethrough"
            case .code: return "Code"
            case .quote: return "Quote"
            case .link: return "Link"
            case .list: return "List"
            case .heading: return "Heading"
            }
        }
        
        var color: Color {
            return .primary
        }
        
        var prefix: String {
            switch self {
            case .bold: return "**"
            case .italic: return "_"
            case .strikethrough: return "~~"
            case .code: return "`"
            case .quote: return "> "
            case .link: return "["
            case .list: return "- "
            case .heading: return "## "
            }
        }
        
        var suffix: String {
            switch self {
            case .bold: return "**"
            case .italic: return "_"
            case .strikethrough: return "~~"
            case .code: return "`"
            case .quote: return ""
            case .link: return "](url)"
            case .list: return ""
            case .heading: return ""
            }
        }
        
        var isLineFormat: Bool {
            switch self {
            case .quote, .list, .heading: return true
            default: return false
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(FormatType.allCases, id: \.icon) { format in
                        ModernFormatButton(format: format) {
                            if format == .link {
                                showLinkDialog = true
                            } else {
                                applyFormatting(format)
                            }
                            HapticsManager.shared.softImpact()
                        }
                    }
                }
                .padding(.horizontal, 12)
            }
            
            Divider()
                .frame(height: 24)
                .padding(.horizontal, 8)
            
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .frame(height: toolbarHeight)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: -2)
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
        )
    }
    
    private func applyFormatting(_ format: FormatType) {
        if format.isLineFormat {
            if text.isEmpty {
                text = format.prefix
            } else if text.hasSuffix("\n") {
                text += format.prefix
            } else {
                text += "\n" + format.prefix
            }
        } else {
            let placeholder = "text"
            text += format.prefix + placeholder + format.suffix
        }
    }
}

// MARK: - Modern Format Button
private struct ModernFormatButton: View {
    let format: ModernFormattingToolbar.FormatType
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: format.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(isPressed ? Color.accentColor : .primary.opacity(0.8))
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isPressed ? Color.accentColor.opacity(0.1) : Color.clear)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel(format.label)
    }
}

// MARK: - Modern Feedback View
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
    @Environment(\.openURL) private var openURL
    
    // Constants
    private let repoOwner = "dylans2010"
    private let repoName = "Portal"

    @State private var githubAccount: String = ""
    @State private var feedbackTitle: String = ""
    @State private var feedbackMessage: String = ""
    @State private var codeSnippet: String = ""
    @State private var feedbackCategory: FeedbackCategory = .suggestion
    @State private var isSubmitting: Bool = false
    @State private var appearAnimation: Bool = false
    @State private var includeLogs: Bool = false
    @State private var includeDeviceInfo: Bool = true
    @State private var includeCode: Bool = false
    @State private var showCodeEditor: Bool = false
    @State private var showLinkDialog: Bool = false
    @State private var showScreenshotError: Bool = false
    @State private var showCategoryInfo: Bool = false
    
    // Validation state
    @State private var showTitleError = false
    @State private var showMessageError = false
    @State private var showConfirmation = false
    
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case title, message
    }
    
    enum FeedbackCategory: String, CaseIterable {
        case bug = "Bug Report"
        case suggestion = "Suggestion"
        case feature = "Feature Request"
        case question = "Question"
        case crash = "Crash Report"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug.fill"
            case .suggestion: return "lightbulb.fill"
            case .feature: return "star.fill"
            case .question: return "questionmark.circle.fill"
            case .crash: return "exclamationmark.triangle.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .bug: return .red
            case .suggestion: return .orange
            case .feature: return .purple
            case .question: return .blue
            case .crash: return .pink
            case .other: return .gray
            }
        }
    }
    
    private var isFormValid: Bool {
        !feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var descriptionPlaceholder: String {
        switch feedbackCategory {
        case .bug: return "Describe The Bug"
        case .suggestion: return "Describe Your Suggestion"
        case .feature: return "Describe The Feature"
        case .question: return "Ask Your Question"
        case .crash: return "Describe The Crash"
        case .other: return "Describe Your Feedback"
        }
    }

    private var descriptionSubtext: String {
        switch feedbackCategory {
        case .bug: return "Please include what happened, what you expected, and steps to reproduce."
        case .suggestion: return "Please explain how this would improve Portal."
        case .feature: return "Please describe the new functionality you'd like to see."
        case .question: return "Please be as specific as possible with your question."
        case .crash: return "Please include what you were doing when the crash occurred."
        case .other: return "Any other feedback or comments you have."
        }
    }

    private var descriptionHeader: String {
        switch feedbackCategory {
        case .bug: return "Bug Details"
        case .suggestion: return "Suggestion Details"
        case .feature: return "Feature Details"
        case .question: return "Question Details"
        case .crash: return "Crash Details"
        case .other: return "Description"
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                mainScrollView
            }
            .background(Color.clear)
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                animateAppearance()
            }
            .sheet(isPresented: $showCodeEditor) {
                CodeEditorSheet(code: $codeSnippet)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField == .message {
                        ModernFormattingToolbar(text: $feedbackMessage, showLinkDialog: $showLinkDialog)
                    }
                }
            }
            .alert("Submit Feedback", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Submit") {
                    performSubmission()
                }
            } message: {
                Text("You are about to be redirected to GitHub to submit your feedback. Do you want to continue?")
            }
            
            // Link Dialog Overlay
            if showLinkDialog {
                LinkInsertDialog(isPresented: $showLinkDialog, text: $feedbackMessage)
                    .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
            
            // Screenshot Error Dialog Overlay
            if showScreenshotError {
                ScreenshotErrorDialog(isPresented: $showScreenshotError)
                    .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
            
            // Category Info Dialog Overlay
            if showCategoryInfo {
                CategoryInfoDialog(isPresented: $showCategoryInfo)
                    .transition(AnyTransition.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
            
            if isSubmitting {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                        Text("Preparing...")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }
                .transition(.opacity)
                .zIndex(200)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showLinkDialog)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showScreenshotError)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showCategoryInfo)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSubmitting)
    }
    
    private var mainScrollView: some View {
        Form {
            if showHeaderViews {
                Section {
                    FeedbackHeaderView()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Picker("Category", selection: $feedbackCategory) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                HStack {
                    Text("Category")
                    Spacer()
                    Button {
                        showCategoryInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Choose the right category for your feedback so I can assist you better.")
            }

            Section {
                TextField("GitHub Username", text: $githubAccount)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Submitted By")
            } footer: {
                Text("Enter your GitHub username so we can credit you or follow up if needed.")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Title", text: $feedbackTitle)
                        .focused($focusedField, equals: .title)

                    if showTitleError && feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Title is required")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Title")
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    TextEditor(text: $feedbackMessage)
                        .frame(minHeight: 150)
                        .focused($focusedField, equals: .message)

                    if showMessageError && feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Description is required")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text(descriptionHeader)
            } footer: {
                Text(descriptionSubtext)
            }

            Section {
                Toggle("Device Info", isOn: $includeDeviceInfo)
                Toggle("App Logs", isOn: $includeLogs)
                Toggle("Code Snippet", isOn: $includeCode)
                
                if includeCode {
                    Button(codeSnippet.isEmpty ? "Add Code" : "Edit Code") {
                        showCodeEditor = true
                    }
                }
            } header: {
                Text("Include")
            }

            Section {
                Button {
                    submitFeedback()
                } label: {
                    HStack {
                        Spacer()
                        Text("Submit Feedback")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private func animateAppearance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            appearAnimation = true
        }
    }
    
    // MARK: - Submit Feedback
    private func submitFeedback() {
        focusedField = nil

        withAnimation {
            showTitleError = feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            showMessageError = feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard !showTitleError && !showMessageError else {
            HapticsManager.shared.error()
            return
        }

        showConfirmation = true
    }

    private func performSubmission() {
        isSubmitting = true
        HapticsManager.shared.softImpact()
        
        Task {
            // Short loading delay for smoother UX
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            let url = buildGitHubURL()

            await MainActor.run {
                if let url = url {
                    UIApplication.shared.open(url)
                    
                    // Clear form after submission
                    feedbackTitle = ""
                    feedbackMessage = ""
                    codeSnippet = ""
                    githubAccount = ""
                    showTitleError = false
                    showMessageError = false
                }
                isSubmitting = false
            }
        }
    }
    
    private func buildGitHubURL() -> URL? {
        let title = "[\(feedbackCategory.rawValue)] \(feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines))"
        let body = buildMarkdownBody()

        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .githubQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .githubQueryAllowed) ?? ""

        let urlString = "https://github.com/\(repoOwner)/\(repoName)/issues/new?title=\(encodedTitle)&body=\(encodedBody)"
        return URL(string: urlString)
    }

    private func buildMarkdownBody() -> String {
        var body = "## Category\n\(feedbackCategory.rawValue)\n\n"
        body += "## Submitted By\n\(githubAccount.isEmpty ? "Anonymous" : githubAccount)\n\n"
        body += "## Title\n\(feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
        body += "## Suggestion Details\n\(feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
        
        if includeCode && !codeSnippet.isEmpty {
            body += "## Code Snippet\n```\n\(codeSnippet)\n```\n\n"
        }
        
        if includeDeviceInfo {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            let device = UIDevice.current.modelName
            let iosVersion = UIDevice.current.systemVersion
            
            body += "## Device Info\n"
            body += "- **App Version:** \(version) (\(build))\n"
            body += "- **iOS Version:** \(iosVersion)\n"
            body += "- **Device Model:** \(device)\n"
            body += "- **Timestamp:** \(timestamp)\n\n"
        }
        
        if includeLogs {
            let logs = AppLogManager.shared.exportLogs()
            if !logs.isEmpty {
                body += "## App Logs\n"
                body += "<details>\n"
                body += "<summary>View Logs</summary>\n\n"
                body += "```\n\(logs.prefix(8000))\n```\n\n"
                body += "</details>\n"
            }
        }
        
        body += "\n---\n_Submitted via Portal Feedback Form_"
        
        return body
    }
    
    private var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

// MARK: - Modern Category Chip
struct ModernCategoryChip: View {
    let category: FeedbackView.FeedbackCategory
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.2) : category.color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white : category.color)
                }
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(colors: [category.color, category.color.opacity(0.85)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                        LinearGradient(colors: [Color.clear, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .shadow(color: isSelected ? category.color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Clean Category Chip
struct CleanCategoryChip: View {
    let category: FeedbackView.FeedbackCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color.clear)
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Clean Attachment Toggle
struct CleanAttachmentToggle: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button {
            if let action = action {
                action()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isOn.toggle()
            }
            HapticsManager.shared.softImpact()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isOn ? .white : color)
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isOn ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOn ? color : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Code Editor Sheet
struct CodeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var code: String
    @State private var localCode: String = ""
    @State private var showCopiedToast: Bool = false
    
    private var lineCount: Int {
        localCode.isEmpty ? 0 : localCode.components(separatedBy: "\n").count
    }
    
    private var characterCount: Int {
        localCode.count
    }
    
    private var wordCount: Int {
        localCode.split { $0.isWhitespace || $0.isNewline }.count
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                codeEditorHeader
                codeEditorContent
                codeEditorFooter
            }
            .background(Color.clear)
            .navigationTitle("Code Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        code = localCode
                        HapticsManager.shared.softImpact()
                        dismiss()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                            .foregroundStyle(localCode.isEmpty ? Color.secondary : Color.accentColor)
                    }
                    .disabled(localCode.isEmpty)
                }
            }
        }
        .onAppear {
            localCode = code
        }
        .overlay {
            if showCopiedToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Copied To Clipboard")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    .padding(.bottom, 100)
                }
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showCopiedToast)
    }
    
    private var codeEditorHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Stats Pills
                HStack(spacing: 8) {
                    StatPill(icon: "text.line.first.and.arrowtriangle.forward", value: "\(lineCount)", label: "lines", color: .blue)
                    StatPill(icon: "character", value: "\(characterCount)", label: "Chars", color: .purple)
                    StatPill(icon: "textformat.abc", value: "\(wordCount)", label: "Words", color: .orange)
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 4) {
                    Button {
                        UIPasteboard.general.string = localCode
                        showCopiedToast = true
                        HapticsManager.shared.softImpact()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopiedToast = false
                        }
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.clear))
                    }
                    .disabled(localCode.isEmpty)
                    .opacity(localCode.isEmpty ? 0.5 : 1)
                    
                    Button {
                        if let clipboardContent = UIPasteboard.general.string {
                            localCode += clipboardContent
                            HapticsManager.shared.softImpact()
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color.clear))
                    }
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            localCode = ""
                        }
                        HapticsManager.shared.softImpact()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(localCode.isEmpty ? Color.secondary : Color.red)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(localCode.isEmpty ? Color.clear : Color.red.opacity(0.1)))
                    }
                    .disabled(localCode.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color.clear)
    }
    
    private var codeEditorContent: some View {
        ZStack(alignment: .topLeading) {
            // Line numbers
            HStack(spacing: 0) {
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(1...max(1, lineCount), id: \.self) { lineNumber in
                        Text("\(lineNumber)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(height: 20)
                    }
                    Spacer()
                }
                .frame(width: 40)
                .padding(.top, 12)
                .padding(.leading, 8)
                .background(Color.clear.opacity(0.5))
                
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 1)
                
                Spacer()
            }
            
            // Code editor
            TextEditor(text: $localCode)
                .font(.system(size: 14, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(.leading, 52)
                .padding(.top, 4)
                .background(Color.clear)
            
            // Placeholder
            if localCode.isEmpty {
                Text("// Paste or type your code here...\n// Supports any programming language")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 56)
                    .padding(.top, 12)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var codeEditorFooter: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                // Language indicator (placeholder)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Plain Text")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.clear)
                )
                
                Spacer()
                
                // Size indicator
                if characterCount > 0 {
                    let sizeKB = Double(characterCount) / 1024.0
                    Text(sizeKB < 1 ? "\(characterCount) B" : String(format: "%.1f KB", sizeKB))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.clear)
        }
    }
}

// MARK: - Stat Pill Component
private struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - UIDevice Extension
extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

// MARK: - CharacterSet Extension
extension CharacterSet {
    static let githubQueryAllowed: CharacterSet = {
        var cs = CharacterSet.urlQueryAllowed
        cs.remove(charactersIn: "&+=")
        return cs
    }()
}

// MARK: - Preview
struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FeedbackView()
        }
    }
}
