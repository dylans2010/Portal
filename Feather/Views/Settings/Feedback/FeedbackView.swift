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
                    .fill(Color(.systemBackground))
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
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Preview Dialog
struct FeedbackPreviewDialog: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String
    let category: FeedbackView.FeedbackCategory
    let includeDeviceInfo: Bool
    let includeLogs: Bool
    let includeCode: Bool
    let codeSnippet: String
    let onSubmit: () -> Void
    let onEdit: () -> Void
    
    @State private var appearAnimation: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(appearAnimation ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture { onEdit(); dismissDialog() }
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.15))
                            .frame(width: 72, height: 72)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [category.color, category.color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                            .shadow(color: category.color.opacity(0.3), radius: 12, x: 0, y: 6)
                        
                        Image(systemName: "eye.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.5)
                    
                    Text("Preview Your Feedback")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    
                    Text("Here is a preview of your Feedback Report, proceed?")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 28)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 10)
                
                // Preview Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Category Badge
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(category.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(category.color)
                        )
                        
                        // Title
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text(title)
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Divider()
                        
                        // Description with rendered markdown
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            MarkdownTextView(text: message)
                        }
                        
                        // Attachments Info
                        if includeDeviceInfo || includeLogs || includeCode {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Attachments")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                
                                HStack(spacing: 8) {
                                    if includeDeviceInfo {
                                        AttachmentBadge(icon: "iphone", text: "Device Info", color: .blue)
                                    }
                                    if includeLogs {
                                        AttachmentBadge(icon: "doc.text.fill", text: "Logs", color: .orange)
                                    }
                                    if includeCode {
                                        AttachmentBadge(icon: "curlybraces", text: "Code", color: .purple)
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: 300)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
                
                // Buttons
                HStack(spacing: 12) {
                    Button {
                        onEdit()
                        dismissDialog()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Edit")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(category.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(category.color.opacity(0.15))
                        )
                    }
                    
                    Button {
                        onSubmit()
                        dismissDialog()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Submit")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [category.color, category.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: category.color.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.2), radius: 40, x: 0, y: 20)
            )
            .padding(.horizontal, 16)
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

// MARK: - Attachment Badge
private struct AttachmentBadge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
    }
}

// MARK: - Markdown Text View
struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        Text(renderMarkdown(text))
            .font(.system(size: 15))
            .foregroundStyle(.primary)
    }
    
    private func renderMarkdown(_ input: String) -> AttributedString {
        var result = input
        
        // Convert markdown to plain text with basic formatting hints
        // Bold: **text** or __text__
        result = result.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "__(.+?)__", with: "$1", options: .regularExpression)
        
        // Italic: *text* or _text_
        result = result.replacingOccurrences(of: "\\*(.+?)\\*", with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: "_(.+?)_", with: "$1", options: .regularExpression)
        
        // Strikethrough: ~~text~~
        result = result.replacingOccurrences(of: "~~(.+?)~~", with: "$1", options: .regularExpression)
        
        // Code: `text`
        result = result.replacingOccurrences(of: "`(.+?)`", with: "$1", options: .regularExpression)
        
        // Links: [text](url)
        result = result.replacingOccurrences(of: "\\[(.+?)\\]\\(.+?\\)", with: "$1", options: .regularExpression)
        
        // Headers: ## text
        result = result.replacingOccurrences(of: "^#{1,6}\\s*", with: "", options: .regularExpression)
        
        // Quote: > text (multiline)
        if let regex = try? NSRegularExpression(pattern: "^>\\s*", options: [.anchorsMatchLines]) {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: "")
        }
        
        // List: - text (multiline)
        if let regex = try? NSRegularExpression(pattern: "^-\\s*", options: [.anchorsMatchLines]) {
            result = regex.stringByReplacingMatches(in: result, options: [], range: NSRange(result.startIndex..., in: result), withTemplate: "• ")
        }
        
        do {
            return try AttributedString(markdown: input, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
        } catch {
            return AttributedString(result)
        }
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
                                .fill(Color(.tertiarySystemGroupedBackground))
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
                                .fill(Color(.tertiarySystemGroupedBackground))
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
                                    .fill(Color(.tertiarySystemGroupedBackground))
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
                    .fill(Color(.systemBackground))
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
                    
                    Text("Due to API constraints, you cannot upload images directly. Please upload your images to a file hoster like Catbox and then share the link in your feedback description.")
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
                    .fill(Color(.systemBackground))
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
        .background(Color(.systemBackground))
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
    
    private let toolbarHeight: CGFloat = 52
    
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
            switch self {
            case .bold: return .blue
            case .italic: return .purple
            case .strikethrough: return .red
            case .code: return .orange
            case .quote: return .teal
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
        HStack(spacing: 8) {
            // Formatting buttons in a pill container
            HStack(spacing: 2) {
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
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
            Spacer()
            
            // Dismiss keyboard button
            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .frame(height: toolbarHeight)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
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
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isPressed ? .white : format.color)
                .frame(width: 34, height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isPressed ? format.color : Color.clear)
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

// MARK: - GitHub Feedback Service
actor GitHubFeedbackService {
    static let shared = GitHubFeedbackService()
    
    private let tokenEndpoint = "http://194.41.112.28:3000/token"
    private let githubAPIBase = "https://api.github.com"
    private let repoOwner = "dylans2010"
    private let repoName = "Portal"
    
    private var cachedToken: String?
    private var tokenExpiry: Date?
    
    struct GitHubIssueResponse: Codable {
        let id: Int
        let number: Int
        let html_url: String
        let title: String
        let state: String
    }
    
    struct GitHubIssueDetail: Codable, Identifiable {
        let id: Int
        let number: Int
        let html_url: String
        let title: String
        let body: String?
        let state: String
        let created_at: String
        let updated_at: String
        let labels: [GitHubLabel]
        let user: GitHubUser?
        let comments: Int
        
        var createdDate: Date? {
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: created_at)
        }
        
        var categoryFromLabels: FeedbackView.FeedbackCategory {
            for label in labels {
                switch label.name.lowercased() {
                case "bug": return .bug
                case "enhancement": return .suggestion
                case "feature-request": return .feature
                case "question": return .question
                case "crash": return .crash
                default: continue
                }
            }
            return .other
        }
    }
    
    struct GitHubLabel: Codable {
        let id: Int
        let name: String
        let color: String
    }
    
    struct GitHubUser: Codable {
        let login: String
        let avatar_url: String
    }
    
    struct TokenResponse: Codable {
        let token: String
        let expiresIn: Int?
    }
    
    func fetchToken() async throws -> String {
        if let token = cachedToken, let expiry = tokenExpiry, Date() < expiry {
            return token
        }
        
        guard let url = URL(string: tokenEndpoint) else {
            throw FeedbackError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw FeedbackError.tokenFetchFailed
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        cachedToken = tokenResponse.token
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn ?? 3600))
        
        return tokenResponse.token
    }
    
    func createIssue(title: String, body: String, labels: [String]) async throws -> GitHubIssueResponse {
        let token = try await fetchToken()
        
        guard let url = URL(string: "\(githubAPIBase)/repos/\(repoOwner)/\(repoName)/issues") else {
            throw FeedbackError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let issueBody: [String: Any] = [
            "title": title,
            "body": body,
            "labels": labels
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: issueBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = String(data: data, encoding: .utf8) {
                throw FeedbackError.githubAPIError(statusCode: httpResponse.statusCode, message: errorBody)
            }
            throw FeedbackError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(GitHubIssueResponse.self, from: data)
    }
    
    func fetchIssues(state: String = "all", labels: String = "app-feedback", perPage: Int = 30) async throws -> [GitHubIssueDetail] {
        let token = try await fetchToken()
        
        guard let url = URL(string: "\(githubAPIBase)/repos/\(repoOwner)/\(repoName)/issues?state=\(state)&labels=\(labels)&per_page=\(perPage)&sort=created&direction=desc") else {
            throw FeedbackError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorBody = String(data: data, encoding: .utf8) {
                throw FeedbackError.githubAPIError(statusCode: httpResponse.statusCode, message: errorBody)
            }
            throw FeedbackError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode([GitHubIssueDetail].self, from: data)
    }
}

// MARK: - Local Feedback Storage
class LocalFeedbackStorage {
    static let shared = LocalFeedbackStorage()
    private let userDefaultsKey = "Portal.SubmittedFeedback"
    
    struct SubmittedFeedback: Codable, Identifiable {
        let id: String
        let issueNumber: Int
        let issueURL: String
        let title: String
        let category: String
        let submittedAt: Date
        
        var categoryEnum: FeedbackView.FeedbackCategory {
            FeedbackView.FeedbackCategory.allCases.first { $0.rawValue == category } ?? .other
        }
    }
    
    func saveFeedback(_ feedback: SubmittedFeedback) {
        var feedbacks = getFeedbacks()
        feedbacks.insert(feedback, at: 0)
        if let data = try? JSONEncoder().encode(feedbacks) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func getFeedbacks() -> [SubmittedFeedback] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let feedbacks = try? JSONDecoder().decode([SubmittedFeedback].self, from: data) else {
            return []
        }
        return feedbacks
    }
    
    func deleteFeedback(id: String) {
        var feedbacks = getFeedbacks()
        feedbacks.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(feedbacks) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}

// MARK: - Modern Feedback View
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    
    @State private var feedbackTitle: String = ""
    @State private var feedbackMessage: String = ""
    @State private var codeSnippet: String = ""
    @State private var feedbackCategory: FeedbackCategory = .suggestion
    @State private var isSubmitting: Bool = false
    @State private var submissionStep: String = ""
    @State private var showSuccessSheet: Bool = false
    @State private var showErrorSheet: Bool = false
    @State private var errorMessage: String = ""
    @State private var appearAnimation: Bool = false
    @State private var includeLogs: Bool = false
    @State private var includeDeviceInfo: Bool = true
    @State private var includeScreenshots: Bool = false
    @State private var includeCode: Bool = false
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker: Bool = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showCodeEditor: Bool = false
    @State private var createdIssueURL: String = ""
    @State private var createdIssueNumber: Int = 0
    @State private var showLinkDialog: Bool = false
    @State private var showScreenshotError: Bool = false
    @State private var showCategoryInfo: Bool = false
    @State private var showPreview: Bool = false
    
    // New state for feedback sections
    @State private var selectedTab: FeedbackTab = .submit
    @State private var recentFeedbacks: [GitHubFeedbackService.GitHubIssueDetail] = []
    @State private var myFeedbacks: [LocalFeedbackStorage.SubmittedFeedback] = []
    @State private var isLoadingRecentFeedback: Bool = false
    @State private var recentFeedbackError: String? = nil
    @State private var selectedIssue: GitHubFeedbackService.GitHubIssueDetail? = nil
    
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case title, message
    }
    
    enum FeedbackTab: String, CaseIterable {
        case submit = "Submit"
        case recent = "Recent Feedback"
        case myFeedback = "My Feedback"
        
        var icon: String {
            switch self {
            case .submit: return "paperplane.fill"
            case .recent: return "bubble.left.and.bubble.right.fill"
            case .myFeedback: return "person.crop.circle.fill"
            }
        }
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
        
        var githubLabel: String {
            switch self {
            case .bug: return "bug"
            case .suggestion: return "enhancement"
            case .feature: return "feature-request"
            case .question: return "question"
            case .crash: return "crash"
            case .other: return "feedback"
            }
        }
    }
    
    private var isFormValid: Bool {
        !feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Tab Selector
                feedbackTabSelector
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Content based on selected tab
                switch selectedTab {
                case .submit:
                    mainScrollView
                case .recent:
                    recentFeedbackView
                case .myFeedback:
                    myFeedbackView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                animateAppearance()
                loadMyFeedbacks()
            }
            .sheet(isPresented: $showCodeEditor) {
                CodeEditorSheet(code: $codeSnippet)
            }
            .sheet(isPresented: $showSuccessSheet) {
                FeedbackSuccessSheet(issueNumber: createdIssueNumber, issueURL: createdIssueURL, onDismiss: { dismiss() })
            }
            .sheet(isPresented: $showErrorSheet) {
                FeedbackErrorSheet(errorMessage: errorMessage, onRetry: { submitFeedback() }, onDismiss: { showErrorSheet = false })
            }
            .sheet(item: $selectedIssue) { issue in
                FeedbackDetailSheet(issue: issue)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if focusedField == .message {
                        ModernFormattingToolbar(text: $feedbackMessage, showLinkDialog: $showLinkDialog)
                    }
                }
            }
            
            // Link Dialog Overlay
            if showLinkDialog {
                LinkInsertDialog(isPresented: $showLinkDialog, text: $feedbackMessage)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
            
            // Screenshot Error Dialog Overlay
            if showScreenshotError {
                ScreenshotErrorDialog(isPresented: $showScreenshotError)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
            
            // Category Info Dialog Overlay
            if showCategoryInfo {
                CategoryInfoDialog(isPresented: $showCategoryInfo)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(100)
            }
            
            // Preview Dialog Overlay
            if showPreview {
                FeedbackPreviewDialog(
                    isPresented: $showPreview,
                    title: feedbackTitle,
                    message: feedbackMessage,
                    category: feedbackCategory,
                    includeDeviceInfo: includeDeviceInfo,
                    includeLogs: includeLogs,
                    includeCode: includeCode,
                    codeSnippet: codeSnippet,
                    onSubmit: { submitFeedback() },
                    onEdit: { /* Just close the preview */ }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showLinkDialog)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showScreenshotError)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showCategoryInfo)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showPreview)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
    }
    
    // MARK: - Tab Selector
    private var feedbackTabSelector: some View {
        HStack(spacing: 8) {
            ForEach(FeedbackTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                    if tab == .recent && recentFeedbacks.isEmpty {
                        loadRecentFeedback()
                    }
                    HapticsManager.shared.softImpact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedTab == tab ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                    )
                    .foregroundStyle(selectedTab == tab ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Recent Feedback View
    private var recentFeedbackView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if isLoadingRecentFeedback {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 80, height: 80)
                            ProgressView()
                                .scaleEffect(1.3)
                                .tint(.accentColor)
                        }
                        Text("Loading Feedback...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
                } else if let error = recentFeedbackError {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.orange)
                        }
                        VStack(spacing: 6) {
                            Text("Unable to Load")
                                .font(.system(size: 18, weight: .semibold))
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        Button {
                            loadRecentFeedback()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Try Again")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else if recentFeedbacks.isEmpty {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        }
                        VStack(spacing: 6) {
                            Text("No Feedback Yet")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Be the first to share your thoughts!")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 80)
                } else {
                    ForEach(recentFeedbacks) { issue in
                        ModernRecentFeedbackCard(issue: issue) {
                            selectedIssue = issue
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .refreshable {
            await refreshRecentFeedback()
        }
    }
    
    // MARK: - My Feedback View
    private var myFeedbackView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if myFeedbacks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundStyle(.secondary)
                        Text("No Submissions Yet")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Your submitted feedback will appear here")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        Button {
                            withAnimation {
                                selectedTab = .submit
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                Text("Submit Feedback")
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                } else {
                    ForEach(myFeedbacks) { feedback in
                        MyFeedbackCard(feedback: feedback) {
                            if let url = URL(string: feedback.issueURL) {
                                openURL(url)
                            }
                        } onDelete: {
                            withAnimation {
                                LocalFeedbackStorage.shared.deleteFeedback(id: feedback.id)
                                loadMyFeedbacks()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private func loadRecentFeedback() {
        isLoadingRecentFeedback = true
        recentFeedbackError = nil
        
        Task {
            do {
                let issues = try await GitHubFeedbackService.shared.fetchIssues()
                await MainActor.run {
                    recentFeedbacks = issues
                    isLoadingRecentFeedback = false
                }
            } catch {
                await MainActor.run {
                    recentFeedbackError = error.localizedDescription
                    isLoadingRecentFeedback = false
                }
            }
        }
    }
    
    private func refreshRecentFeedback() async {
        do {
            let issues = try await GitHubFeedbackService.shared.fetchIssues()
            await MainActor.run {
                recentFeedbacks = issues
            }
        } catch {
            // Silently fail on refresh
        }
    }
    
    private func loadMyFeedbacks() {
        myFeedbacks = LocalFeedbackStorage.shared.getFeedbacks()
    }
    
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Simplified header
                cleanHeaderSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 15)
                
                // Combined form section
                cleanFormSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 15)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appearAnimation)
                
                // Compact attachments
                cleanAttachmentsSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 15)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                
                // Submit button
                cleanSubmitSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 15)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - Clean Header Section
    private var cleanHeaderSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(feedbackCategory.color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: feedbackCategory.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(feedbackCategory.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Submit Feedback")
                    .font(.system(size: 20, weight: .bold))
                Text("Creates a GitHub Issue")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: feedbackCategory)
    }
    
    // MARK: - Clean Form Section
    private var cleanFormSection: some View {
        VStack(spacing: 20) {
            // Category selector (horizontal scroll)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Category")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        showCategoryInfo = true
                        HapticsManager.shared.softImpact()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FeedbackCategory.allCases, id: \.self) { category in
                            CleanCategoryChip(
                                category: category,
                                isSelected: feedbackCategory == category
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    feedbackCategory = category
                                }
                                HapticsManager.shared.softImpact()
                            }
                        }
                    }
                }
            }
            
            // Title field
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                TextField("Brief summary", text: $feedbackTitle)
                    .font(.system(size: 16))
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .message }
                    .padding(14)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            
            // Description field
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Description")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(feedbackMessage.count)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
                
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $feedbackMessage)
                        .font(.system(size: 16))
                        .frame(minHeight: 120)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .focused($focusedField, equals: .message)
                    
                    if feedbackMessage.isEmpty {
                        Text("Describe your feedback...")
                            .font(.system(size: 16))
                            .foregroundStyle(.quaternary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Clean Attachments Section
    private var cleanAttachmentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Include")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 10) {
                CleanAttachmentToggle(
                    icon: "iphone",
                    title: "Device",
                    isOn: $includeDeviceInfo,
                    color: .blue
                )
                
                CleanAttachmentToggle(
                    icon: "doc.text",
                    title: "Logs",
                    isOn: $includeLogs,
                    color: .orange
                )
                
                CleanAttachmentToggle(
                    icon: "curlybraces",
                    title: "Code",
                    isOn: $includeCode,
                    color: .purple,
                    action: { showCodeEditor = true }
                )
            }
            
            // Code preview if included
            if includeCode && !codeSnippet.isEmpty {
                HStack {
                    Text(codeSnippet.prefix(50) + (codeSnippet.count > 50 ? "..." : ""))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button {
                        showCodeEditor = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.purple)
                    }
                }
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Clean Submit Section
    private var cleanSubmitSection: some View {
        VStack(spacing: 12) {
            Button {
                focusedField = nil
                showPreview = true
                HapticsManager.shared.softImpact()
            } label: {
                HStack(spacing: 10) {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(isSubmitting ? submissionStep : "Preview & Submit")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    isFormValid ? feedbackCategory.color : Color.gray.opacity(0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!isFormValid || isSubmitting)
            
            Text("Your feedback will be submitted as a GitHub Issue")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
    }
    
    private func animateAppearance() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            appearAnimation = true
        }
    }
    
    private func loadSelectedImages(from items: [PhotosPickerItem]) {
        Task {
            selectedImages = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImages.append(image)
                }
            }
            if !selectedImages.isEmpty {
                includeScreenshots = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 14) {
            headerIcon
            headerText
        }
        .padding(.vertical, 12)
    }
    
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [feedbackCategory.color.opacity(0.3), feedbackCategory.color.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
            
            Circle()
                .fill(
                    LinearGradient(
                        colors: [feedbackCategory.color, feedbackCategory.color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: feedbackCategory.color.opacity(0.4), radius: 12, x: 0, y: 6)
            
            Image(systemName: feedbackCategory.icon)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: feedbackCategory)
    }
    
    private var headerText: some View {
        VStack(spacing: 4) {
            Text("Report Feedback")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            
            Text("Your feedback creates a GitHub Issue directly")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Category Selector
    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(feedbackCategory.color.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "tag.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(feedbackCategory.color)
                }
                Text("Category")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Info Button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showCategoryInfo = true
                    }
                    HapticsManager.shared.softImpact()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                        Text("Guide")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(Color.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        ModernCategoryChip(
                            category: category,
                            isSelected: feedbackCategory == category
                        ) {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                feedbackCategory = category
                            }
                            HapticsManager.shared.softImpact()
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
        .padding(18)
        .background(modernSectionBackground)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            titleField
            Divider()
                .padding(.horizontal, 4)
            messageField
        }
        .padding(18)
        .background(modernSectionBackground)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }
                Text("Title")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Required")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.red.opacity(0.8)))
            }
            
            TextField("Brief summary of your feedback", text: $feedbackTitle)
                .font(.system(size: 16))
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .onSubmit { focusedField = .message }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(focusedField == .title ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .animation(.easeInOut(duration: 0.2), value: focusedField == .title)
        }
    }
    
    private var messageField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.purple)
                }
                Text("Description")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                Text("Required")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.red.opacity(0.8)))
                Spacer()
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $feedbackMessage)
                    .font(.system(size: 16))
                    .frame(minHeight: 160)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(focusedField == .message ? Color.purple : Color.clear, lineWidth: 2)
                    )
                    .focused($focusedField, equals: .message)
                    .animation(.easeInOut(duration: 0.2), value: focusedField == .message)
                
                if feedbackMessage.isEmpty {
                    Text("Describe your feedback in detail...")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }
            
            // Character count with visual indicator
            HStack(spacing: 12) {
                Spacer()
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(feedbackMessage.count > 0 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                    Text("\(feedbackMessage.count)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(feedbackMessage.count > 0 ? Color.primary : Color.gray)
                    Text("Characters")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemGroupedBackground))
                )
            }
        }
    }
    
    // MARK: - Attachments Section (Combined)
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 28, height: 28)
                    Image(systemName: "paperclip")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.indigo)
                }
                Text("Information")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                // Active count badge
                let activeCount = [includeLogs, includeDeviceInfo, includeCode].filter { $0 }.count
                if activeCount > 0 {
                    Text("\(activeCount) active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.indigo))
                }
            }
            
            // Toggle Options Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                modernAttachmentToggle(
                    icon: "doc.text.fill",
                    title: "App Logs",
                    subtitle: "\(AppLogManager.shared.logs.count) Entries",
                    color: .orange,
                    isOn: $includeLogs,
                    isDisabled: false
                )
                
                modernAttachmentToggle(
                    icon: "iphone",
                    title: "Device Info",
                    subtitle: UIDevice.current.modelName,
                    color: .blue,
                    isOn: $includeDeviceInfo,
                    isDisabled: false
                )
                
                modernAttachmentToggle(
                    icon: "photo.stack",
                    title: "Screenshots",
                    subtitle: "Unavailable",
                    color: .green,
                    isOn: .constant(false),
                    isDisabled: true,
                    action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showScreenshotError = true
                        }
                        HapticsManager.shared.error()
                    }
                )
                
                modernAttachmentToggle(
                    icon: "curlybraces",
                    title: "Code Snippet",
                    subtitle: codeSnippet.isEmpty ? "Add code" : "\(codeSnippet.components(separatedBy: "\n").count) lines",
                    color: .purple,
                    isOn: $includeCode,
                    isDisabled: false,
                    action: { showCodeEditor = true }
                )
            }
            
            // Code Preview
            if includeCode && !codeSnippet.isEmpty {
                codePreview
            }
        }
        .padding(18)
        .background(modernSectionBackground)
    }
    
    private func modernAttachmentToggle(icon: String, title: String, subtitle: String, color: Color, isOn: Binding<Bool>, isDisabled: Bool, action: (() -> Void)? = nil) -> some View {
        Button {
            if let action = action {
                action()
            } else if !isDisabled {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOn.wrappedValue.toggle()
                }
                HapticsManager.shared.softImpact()
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        attachmentIconBackground(isDisabled: isDisabled, isOn: isOn.wrappedValue, color: color)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(isDisabled ? Color.gray : (isOn.wrappedValue ? Color.white : color))
                    }
                    
                    Spacer()
                    
                    if isDisabled {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.gray.opacity(0.5))
                    } else {
                        Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(isOn.wrappedValue ? color : Color.gray.opacity(0.3))
                    }
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isDisabled ? Color.secondary : Color.primary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(isDisabled ? Color.gray : Color.secondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isDisabled ? Color(.tertiarySystemGroupedBackground).opacity(0.5) :
                        (isOn.wrappedValue ? color.opacity(0.08) : Color(.secondarySystemGroupedBackground))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isDisabled ? Color.gray.opacity(0.2) :
                        (isOn.wrappedValue ? color.opacity(0.4) : Color.clear),
                        lineWidth: isOn.wrappedValue ? 1.5 : 0
                    )
            )
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.7 : 1)
    }
    
    @ViewBuilder
    private func attachmentIconBackground(isDisabled: Bool, isOn: Bool, color: Color) -> some View {
        if isDisabled {
            Color.gray.opacity(0.2)
        } else if isOn {
            LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            LinearGradient(colors: [color.opacity(0.15), color.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private var screenshotsPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedImages.remove(at: index)
                                if index < selectedPhotoItems.count {
                                    selectedPhotoItems.remove(at: index)
                                }
                                if selectedImages.isEmpty {
                                    includeScreenshots = false
                                }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.black.opacity(0.6)))
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var modernSectionBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
            )
    }
    
    private var codePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(codeSnippet.prefix(200) + (codeSnippet.count > 200 ? "..." : ""))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(10)
            }
            .frame(maxHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            
            HStack(spacing: 12) {
                Button {
                    showCodeEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.system(size: 12, weight: .medium))
                }
                
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3)) {
                        codeSnippet = ""
                        includeCode = false
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.system(size: 12, weight: .medium))
                }
                
                Spacer()
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Submit Section
    private var submitSection: some View {
        VStack(spacing: 12) {
            if isSubmitting {
                submittingView
            } else {
                submitButton
            }
            
            Text("Your feedback will be submitted as a GitHub Issue.")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var submittingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: feedbackCategory.color))
                .scaleEffect(1.2)
            
            Text(submissionStep)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(feedbackCategory.color.opacity(0.1))
        )
    }
    
    private var submitButton: some View {
        Button {
            focusedField = nil
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showPreview = true
            }
            HapticsManager.shared.softImpact()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Preview & Submit")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isFormValid ? [feedbackCategory.color, feedbackCategory.color.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: isFormValid ? feedbackCategory.color.opacity(0.4) : Color.clear, radius: 12, x: 0, y: 6)
        }
        .disabled(!isFormValid)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
        .animation(.easeInOut(duration: 0.2), value: feedbackCategory)
    }
    
    // MARK: - Submit Feedback
    private func submitFeedback() {
        guard isFormValid else { return }
        
        focusedField = nil
        isSubmitting = true
        submissionStep = "Preparing Feedback..."
        HapticsManager.shared.softImpact()
        
        Task {
            do {
                submissionStep = "Fetching Authentication..."
                
                let issueBody = buildIssueBody()
                let labels = [feedbackCategory.githubLabel, "app-feedback"]
                let trimmedTitle = feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                
                submissionStep = "Creating GitHub Issue..."
                
                let response = try await GitHubFeedbackService.shared.createIssue(
                    title: "[\(feedbackCategory.rawValue)] \(trimmedTitle)",
                    body: issueBody,
                    labels: labels
                )
                
                await MainActor.run {
                    isSubmitting = false
                    createdIssueURL = response.html_url
                    createdIssueNumber = response.number
                    
                    // Save to local storage
                    let localFeedback = LocalFeedbackStorage.SubmittedFeedback(
                        id: UUID().uuidString,
                        issueNumber: response.number,
                        issueURL: response.html_url,
                        title: trimmedTitle,
                        category: feedbackCategory.rawValue,
                        submittedAt: Date()
                    )
                    LocalFeedbackStorage.shared.saveFeedback(localFeedback)
                    loadMyFeedbacks()
                    
                    HapticsManager.shared.success()
                    showSuccessSheet = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    HapticsManager.shared.error()
                    showErrorSheet = true
                }
            }
        }
    }
    
    private func buildIssueBody() -> String {
        var body = "## Description\n\(feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
        
        if includeCode && !codeSnippet.isEmpty {
            body += "\n## Code Snippet\n```\n\(codeSnippet)\n```\n\n"
        }
        
        if includeDeviceInfo {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            let device = UIDevice.current.modelName
            let iosVersion = UIDevice.current.systemVersion
            
            body += "\n## Device Information\n"
            body += "| Property | Value |\n"
            body += "|----------|-------|\n"
            body += "| App Version | \(version) (\(build)) |\n"
            body += "| Device | \(device) |\n"
            body += "| iOS Version | \(iosVersion) |\n\n"
        }
        
        if includeLogs {
            let logs = AppLogManager.shared.exportLogs()
            if !logs.isEmpty {
                body += "\n## App Logs\n"
                body += "<details>\n"
                body += "<summary>Click To Expand Logs</summary>\n\n"
                body += "```\n\(logs.prefix(10000))\n```\n\n"
                body += "</details>\n\n"
            }
        }
        
        if includeScreenshots && !selectedImages.isEmpty {
            body += "\n## Screenshots\n"
            body += "_\(selectedImages.count) screenshot(s) were attached but cannot be uploaded via Feedback API._\n\n"
        }
        
        body += "\n---\n_Submitted via Portal Feedback API_"
        
        return body
    }
}

// MARK: - Category Chip
struct FeedbackCategoryChip: View {
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color(.tertiarySystemGroupedBackground))
            )
            .foregroundStyle(isSelected ? Color.white : Color.primary)
        }
        .buttonStyle(.plain)
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
                        LinearGradient(colors: [Color(.secondarySystemGroupedBackground), Color(.secondarySystemGroupedBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
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
                    .fill(isSelected ? category.color : Color(.tertiarySystemGroupedBackground))
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
                    .fill(isOn ? color : Color(.tertiarySystemGroupedBackground))
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
            .background(Color(.systemGroupedBackground))
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
                        Text("Copied to clipboard")
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
                            .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
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
                            .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
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
                            .background(Circle().fill(localCode.isEmpty ? Color(.tertiarySystemGroupedBackground) : Color.red.opacity(0.1)))
                    }
                    .disabled(localCode.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(.systemBackground))
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
                .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
                
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
                .background(Color(.systemBackground))
            
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
                        .fill(Color(.tertiarySystemGroupedBackground))
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
            .background(Color(.systemBackground))
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

// MARK: - Success Sheet with Modern Animation
struct FeedbackSuccessSheet: View {
    let issueNumber: Int
    let issueURL: String
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showCheckmark = false
    @State private var showContent = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Success Icon
            ZStack {
                // Pulse rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(Color.green.opacity(0.2 - Double(i) * 0.05), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i) * 40, height: 120 + CGFloat(i) * 40)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(i) * 0.3),
                            value: pulseAnimation
                        )
                }
                
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showCheckmark ? 1 : 0.5)
                    .opacity(showCheckmark ? 1 : 0)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .green.opacity(0.4), radius: 16, x: 0, y: 8)
                    .scaleEffect(showCheckmark ? 1 : 0)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .rotationEffect(.degrees(showCheckmark ? 0 : -90))
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showCheckmark)
            
            Spacer().frame(height: 32)
            
            // Content
            VStack(spacing: 12) {
                Text("Feedback Submitted!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Text("Issue #\(issueNumber) has been created successfully.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Text("Thank you for helping us improve Portal!")
                    .font(.system(size: 14))
                    .foregroundStyle(.tertiary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: showContent)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    if let url = URL(string: issueURL) {
                        openURL(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                        Text("View On GitHub")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .green.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                
                Button {
                    dismiss()
                    onDismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: showContent)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCheckmark = true
                pulseAnimation = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showContent = true
            }
        }
    }
}

// MARK: - Error Sheet with Modern Animation
struct FeedbackErrorSheet: View {
    let errorMessage: String
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showIcon = false
    @State private var showContent = false
    @State private var shakeAnimation = false
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Animated Error Icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showIcon ? 1 : 0.5)
                    .opacity(showIcon ? 1 : 0)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .red.opacity(0.4), radius: 16, x: 0, y: 8)
                    .scaleEffect(showIcon ? 1 : 0)
                
                Image(systemName: "xmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(showIcon ? 1 : 0)
            }
            .offset(x: shakeAnimation ? -10 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showIcon)
            
            Spacer().frame(height: 32)
            
            // Content
            VStack(spacing: 12) {
                Text("Something Went Wrong")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: showContent)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                Button {
                    dismiss()
                    onRetry()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.red, .red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .red.opacity(0.3), radius: 12, x: 0, y: 6)
                }
                
                Button {
                    dismiss()
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 30)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5), value: showContent)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showIcon = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showContent = true
                // Shake animation
                withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                    shakeAnimation = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    shakeAnimation = false
                }
            }
        }
    }
}

// MARK: - Error Types
enum FeedbackError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case tokenFetchFailed
    case githubAPIError(statusCode: Int, message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server Error (Status: \(statusCode))"
        case .tokenFetchFailed:
            return "Failed to fetch authentication token (API Error)"
        case .githubAPIError(let statusCode, let message):
            return "GitHub API Error (\(statusCode)): \(message)"
        }
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

// MARK: - Modern Recent Feedback Card
struct ModernRecentFeedbackCard: View {
    let issue: GitHubFeedbackService.GitHubIssueDetail
    let onTap: () -> Void
    
    private var relativeDate: String {
        guard let date = issue.createdDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var cleanTitle: String {
        issue.title.replacingOccurrences(of: "\\[.*?\\]\\s*", with: "", options: .regularExpression)
    }
    
    private var cleanBody: String {
        guard let body = issue.body else { return "" }
        return body
            .replacingOccurrences(of: "## Description\n", with: "")
            .replacingOccurrences(of: "## Device Information\n[\\s\\S]*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // Category Icon
                ZStack {
                    Circle()
                        .fill(issue.categoryFromLabels.color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: issue.categoryFromLabels.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(issue.categoryFromLabels.color)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // Title and Status
                    HStack(alignment: .top) {
                        Text(cleanTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer(minLength: 8)
                        
                        // Status indicator
                        Image(systemName: issue.state == "open" ? "circle.fill" : "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(issue.state == "open" ? .green : .purple)
                    }
                    
                    // Body preview
                    if !cleanBody.isEmpty {
                        Text(String(cleanBody.prefix(100)) + (cleanBody.count > 100 ? "..." : ""))
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    // Meta info row
                    HStack(spacing: 12) {
                        // Issue number
                        HStack(spacing: 4) {
                            Image(systemName: "number")
                                .font(.system(size: 10, weight: .medium))
                            Text("\(issue.number)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.tertiary)
                        
                        // Time
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10, weight: .medium))
                            Text(relativeDate)
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.tertiary)
                        
                        // Comments
                        if issue.comments > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.system(size: 10, weight: .medium))
                                Text("\(issue.comments)")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.tertiary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.quaternary)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legacy Recent Feedback Card (kept for compatibility)
struct RecentFeedbackCard: View {
    let issue: GitHubFeedbackService.GitHubIssueDetail
    let onTap: () -> Void
    
    var body: some View {
        ModernRecentFeedbackCard(issue: issue, onTap: onTap)
    }
}

// MARK: - My Feedback Card
struct MyFeedbackCard: View {
    let feedback: LocalFeedbackStorage.SubmittedFeedback
    let onTap: () -> Void
    let onDelete: () -> Void
    
    private var relativeDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: feedback.submittedAt, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Category icon
            ZStack {
                Circle()
                    .fill(feedback.categoryEnum.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: feedback.categoryEnum.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(feedback.categoryEnum.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feedback.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text("#\(feedback.issueNumber)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.tertiary)
                    
                    Text(relativeDate)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                Button(action: onTap) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.accentColor)
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Feedback Detail Sheet
struct FeedbackDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    let issue: GitHubFeedbackService.GitHubIssueDetail
    
    private var relativeDate: String {
        guard let date = issue.createdDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var cleanTitle: String {
        issue.title.replacingOccurrences(of: "\\[.*?\\]\\s*", with: "", options: .regularExpression)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Modern Header
                    VStack(spacing: 16) {
                        // Status and meta row
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "number")
                                    .font(.system(size: 12, weight: .medium))
                                Text("\(issue.number)")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.secondary)
                            
                            Text("•")
                                .foregroundStyle(.quaternary)
                            
                            Text(relativeDate)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            // Status pill
                            HStack(spacing: 5) {
                                Image(systemName: issue.state == "open" ? "circle.fill" : "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                Text(issue.state.capitalized)
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(issue.state == "open" ? .green : .purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill((issue.state == "open" ? Color.green : Color.purple).opacity(0.12))
                            )
                        }
                        
                        // Title
                        Text(cleanTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Category badge
                        HStack(spacing: 8) {
                            Image(systemName: issue.categoryFromLabels.icon)
                                .font(.system(size: 12, weight: .semibold))
                            Text(issue.categoryFromLabels.rawValue)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(issue.categoryFromLabels.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(issue.categoryFromLabels.color.opacity(0.12))
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                    
                    Divider()
                        .padding(.horizontal, 20)
                    
                    // Labels
                    if !issue.labels.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                    .font(.system(size: 12))
                                Text("Labels")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.secondary)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(issue.labels, id: \.id) { label in
                                    Text(label.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(Color(hex: label.color).opacity(0.15))
                                        )
                                        .foregroundStyle(Color(hex: label.color))
                                }
                            }
                        }
                        .padding(20)
                        
                        Divider()
                            .padding(.horizontal, 20)
                    }
                    
                    // Body with Full Markdown Support
                    if let body = issue.body, !body.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 12))
                                Text("Description")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(.secondary)
                            
                            GitHubMarkdownView(markdown: body)
                        }
                        .padding(20)
                    }
                    
                    // Open in GitHub button
                    Button {
                        if let url = URL(string: issue.html_url) {
                            openURL(url)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("View on GitHub")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Feedback Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
    }
}

// MARK: - GitHub Markdown View (Full Support)
struct GitHubMarkdownView: View {
    let markdown: String
    @Environment(\.colorScheme) private var colorScheme
    @State private var contentHeight: CGFloat = 100
    
    var body: some View {
        GitHubMarkdownWebView(markdown: markdown, colorScheme: colorScheme, contentHeight: $contentHeight)
            .frame(height: contentHeight)
    }
}

// MARK: - GitHub Markdown WebView
struct GitHubMarkdownWebView: UIViewRepresentable {
    let markdown: String
    let colorScheme: ColorScheme
    @Binding var contentHeight: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func generateHTML() -> String {
        let isDark = colorScheme == .dark
        let textColor = isDark ? "#FFFFFF" : "#000000"
        let secondaryColor = isDark ? "#8E8E93" : "#6C6C70"
        let bgColor = isDark ? "#1C1C1E" : "#FFFFFF"
        let codeBgColor = isDark ? "#2C2C2E" : "#F2F2F7"
        let borderColor = isDark ? "#38383A" : "#E5E5EA"
        let linkColor = "#007AFF"
        
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { box-sizing: border-box; margin: 0; padding: 0; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
                    font-size: 15px;
                    line-height: 1.6;
                    color: \(textColor);
                    background-color: transparent;
                    padding: 0;
                    word-wrap: break-word;
                    -webkit-text-size-adjust: 100%;
                }
                h1, h2, h3, h4, h5, h6 {
                    font-weight: 600;
                    margin-top: 20px;
                    margin-bottom: 10px;
                    line-height: 1.3;
                }
                h1 { font-size: 24px; }
                h2 { font-size: 20px; }
                h3 { font-size: 18px; }
                h4 { font-size: 16px; }
                p { margin-bottom: 12px; }
                a { color: \(linkColor); text-decoration: none; }
                strong { font-weight: 600; }
                em { font-style: italic; }
                del { text-decoration: line-through; color: \(secondaryColor); }
                code {
                    font-family: 'SF Mono', Menlo, monospace;
                    font-size: 13px;
                    background-color: \(codeBgColor);
                    padding: 2px 6px;
                    border-radius: 4px;
                }
                pre {
                    background-color: \(codeBgColor);
                    padding: 12px;
                    border-radius: 8px;
                    overflow-x: auto;
                    margin: 12px 0;
                }
                pre code {
                    background: none;
                    padding: 0;
                    font-size: 13px;
                    line-height: 1.5;
                }
                blockquote {
                    border-left: 3px solid \(linkColor);
                    padding-left: 12px;
                    margin: 12px 0;
                    color: \(secondaryColor);
                }
                ul, ol {
                    padding-left: 24px;
                    margin: 12px 0;
                }
                li { margin-bottom: 6px; }
                li input[type="checkbox"] {
                    margin-right: 8px;
                    transform: scale(1.1);
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin: 12px 0;
                    font-size: 14px;
                }
                th, td {
                    border: 1px solid \(borderColor);
                    padding: 8px 12px;
                    text-align: left;
                }
                th {
                    background-color: \(codeBgColor);
                    font-weight: 600;
                }
                hr {
                    border: none;
                    border-top: 1px solid \(borderColor);
                    margin: 16px 0;
                }
                details {
                    background-color: \(codeBgColor);
                    border-radius: 8px;
                    padding: 12px;
                    margin: 12px 0;
                }
                summary {
                    font-weight: 600;
                    cursor: pointer;
                    padding: 4px 0;
                }
                details[open] summary {
                    margin-bottom: 8px;
                }
                img {
                    max-width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin: 8px 0;
                }
                .task-list-item {
                    list-style-type: none;
                    margin-left: -20px;
                }
            </style>
        </head>
        <body>
            \(convertMarkdownToHTML(markdown))
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    setTimeout(function() {
                        window.webkit.messageHandlers.heightHandler.postMessage(document.body.scrollHeight);
                    }, 100);
                });
            </script>
        </body>
        </html>
        """
    }
    
    private func convertMarkdownToHTML(_ markdown: String) -> String {
        var html = markdown
        
        // Escape HTML entities first (but preserve markdown syntax)
        html = html.replacingOccurrences(of: "&", with: "&amp;")
        html = html.replacingOccurrences(of: "<(?!details|summary|/details|/summary)", with: "&lt;", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?<!details|summary|/details|/summary)>", with: "&gt;", options: .regularExpression)
        
        // Headers
        html = html.replacingOccurrences(of: "(?m)^###### (.+)$", with: "<h6>$1</h6>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^##### (.+)$", with: "<h5>$1</h5>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^#### (.+)$", with: "<h4>$1</h4>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^### (.+)$", with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^## (.+)$", with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^# (.+)$", with: "<h1>$1</h1>", options: .regularExpression)
        
        // Code blocks (must be before inline code)
        html = html.replacingOccurrences(of: "```([\\s\\S]*?)```", with: "<pre><code>$1</code></pre>", options: .regularExpression)
        
        // Inline code
        html = html.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        
        // Bold and italic
        html = html.replacingOccurrences(of: "\\*\\*\\*(.+?)\\*\\*\\*", with: "<strong><em>$1</em></strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*\\*(.+?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*(.+?)\\*", with: "<em>$1</em>", options: .regularExpression)
        html = html.replacingOccurrences(of: "__(.+?)__", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "_(.+?)_", with: "<em>$1</em>", options: .regularExpression)
        
        // Strikethrough
        html = html.replacingOccurrences(of: "~~(.+?)~~", with: "<del>$1</del>", options: .regularExpression)
        
        // Links
        html = html.replacingOccurrences(of: "\\[([^\\]]+)\\]\\(([^)]+)\\)", with: "<a href=\"$2\">$1</a>", options: .regularExpression)
        
        // Images
        html = html.replacingOccurrences(of: "!\\[([^\\]]*?)\\]\\(([^)]+)\\)", with: "<img src=\"$2\" alt=\"$1\">", options: .regularExpression)
        
        // Blockquotes
        html = html.replacingOccurrences(of: "(?m)^> (.+)$", with: "<blockquote>$1</blockquote>", options: .regularExpression)
        
        // Horizontal rules
        html = html.replacingOccurrences(of: "(?m)^---+$", with: "<hr>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^\\*\\*\\*+$", with: "<hr>", options: .regularExpression)
        
        // Task lists
        html = html.replacingOccurrences(of: "(?m)^- \\[x\\] (.+)$", with: "<li class=\"task-list-item\"><input type=\"checkbox\" checked disabled> $1</li>", options: .regularExpression)
        html = html.replacingOccurrences(of: "(?m)^- \\[ \\] (.+)$", with: "<li class=\"task-list-item\"><input type=\"checkbox\" disabled> $1</li>", options: .regularExpression)
        
        // Unordered lists
        html = html.replacingOccurrences(of: "(?m)^[*-] (.+)$", with: "<li>$1</li>", options: .regularExpression)
        
        // Ordered lists
        html = html.replacingOccurrences(of: "(?m)^\\d+\\. (.+)$", with: "<li>$1</li>", options: .regularExpression)
        
        // Wrap consecutive list items
        html = html.replacingOccurrences(of: "(<li[^>]*>.*?</li>\\n?)+", with: "<ul>$0</ul>", options: .regularExpression)
        
        // Paragraphs (lines not already wrapped)
        let lines = html.components(separatedBy: "\n")
        var result: [String] = []
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                result.append("")
            } else if trimmed.hasPrefix("<") {
                result.append(line)
            } else {
                result.append("<p>\(line)</p>")
            }
        }
        html = result.joined(separator: "\n")
        
        return html
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: GitHubMarkdownWebView
        
        init(_ parent: GitHubMarkdownWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] result, error in
                if let height = result as? CGFloat {
                    DispatchQueue.main.async {
                        self?.parent.contentHeight = max(height + 20, 100)
                    }
                }
            }
        }
    }
}

import WebKit

// MARK: - Full Markdown View (Legacy - kept for compatibility)
struct FullMarkdownView: View {
    let text: String
    
    var body: some View {
        GitHubMarkdownView(markdown: text)
    }
}

// MARK: - Flow Layout for Labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Preview
struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FeedbackView()
        }
    }
}
