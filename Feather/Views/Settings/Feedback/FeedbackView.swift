import SwiftUI
import UIKit
import PhotosUI

// MARK: - Category Info Dialog
struct CategoryInfoDialog: View {
    @Binding var isPresented: Bool
    @State private var appearAnimation: Bool = false
    
    private let categories: [(FeedbackView.FeedbackCategory, String)] = [
        (.bug, "Report issues where something isn't working as expected. Include steps to reproduce the bug, what you expected to happen, and what actually happened."),
        (.suggestion, "Share ideas for improving existing features. Tell us what could be better and how you'd like to see it improved."),
        (.feature, "Request entirely new features or capabilities. Describe what you'd like to see added and why it would be useful."),
        (.question, "Ask questions about how to use the app or clarify functionality. We're here to help!"),
        (.crash, "Report app crashes or freezes. Include what you were doing when the crash occurred and any error messages you saw."),
        (.other, "For feedback that doesn't fit other categories. General comments, praise, or anything else you'd like to share.")
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
                        
                        Text("Choose the right category for your feedback")
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
                    
                    Text("Here is a preview of your feedback report, proceed?")
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
        
        // Quote: > text
        result = result.replacingOccurrences(of: "^>\\s*", with: "", options: [.regularExpression, .anchorsMatchLines])
        
        // List: - text
        result = result.replacingOccurrences(of: "^-\\s*", with: "• ", options: [.regularExpression, .anchorsMatchLines])
        
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
                    
                    Text("Add a hyperlink to your feedback")
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
                            
                            TextField("Display text", text: $linkTitle)
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
                            
                            TextField("https://example.com", text: $linkURL)
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
                    
                    Text("Due to API constraints, you cannot upload images directly. Please upload your images to a file hoster like CatBox and then share the link in your feedback description.")
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
                        Text("Use catbox.moe or imgur.com to host your images")
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
            mainScrollView
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Feedback")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear { animateAppearance() }
                .sheet(isPresented: $showCodeEditor) {
                    CodeEditorSheet(code: $codeSnippet)
                }
                .sheet(isPresented: $showSuccessSheet) {
                    FeedbackSuccessSheet(issueNumber: createdIssueNumber, issueURL: createdIssueURL, onDismiss: { dismiss() })
                }
                .sheet(isPresented: $showErrorSheet) {
                    FeedbackErrorSheet(errorMessage: errorMessage, onRetry: { submitFeedback() }, onDismiss: { showErrorSheet = false })
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
    }
    
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                
                categorySelector
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appearAnimation)
                
                formSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                
                attachmentsSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
                
                submitSection
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
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
            Text("Share Your Feedback")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            
            Text("Your feedback creates a GitHub issue directly")
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
                    Text("Describe your feedback in detail. You can use markdown formatting...")
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
                    Text("characters")
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
                Text("Attachments & Info")
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
                    subtitle: "\(AppLogManager.shared.logs.count) entries",
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
            
            Text("Your feedback will be submitted as a GitHub issue")
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
        submissionStep = "Preparing feedback..."
        HapticsManager.shared.softImpact()
        
        Task {
            do {
                submissionStep = "Fetching authentication..."
                
                let issueBody = buildIssueBody()
                let labels = [feedbackCategory.githubLabel, "app-feedback"]
                
                submissionStep = "Creating GitHub issue..."
                
                let response = try await GitHubFeedbackService.shared.createIssue(
                    title: "[\(feedbackCategory.rawValue)] \(feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines))",
                    body: issueBody,
                    labels: labels
                )
                
                await MainActor.run {
                    isSubmitting = false
                    createdIssueURL = response.html_url
                    createdIssueNumber = response.number
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
                body += "<summary>Click to expand logs</summary>\n\n"
                body += "```\n\(logs.prefix(10000))\n```\n\n"
                body += "</details>\n\n"
            }
        }
        
        if includeScreenshots && !selectedImages.isEmpty {
            body += "\n## Screenshots\n"
            body += "_\(selectedImages.count) screenshot(s) were attached but cannot be uploaded via API._\n\n"
        }
        
        body += "\n---\n_Submitted via Portal app feedback system_"
        
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
                    StatPill(icon: "character", value: "\(characterCount)", label: "chars", color: .purple)
                    StatPill(icon: "textformat.abc", value: "\(wordCount)", label: "words", color: .orange)
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
                
                Text("Issue #\(issueNumber) has been created")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                
                Text("Thank you for helping us improve!")
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
                        Text("View on GitHub")
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
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error (Status: \(statusCode))"
        case .tokenFetchFailed:
            return "Failed to fetch authentication token"
        case .githubAPIError(let statusCode, let message):
            return "GitHub API error (\(statusCode)): \(message)"
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

// MARK: - Preview
struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FeedbackView()
        }
    }
}
