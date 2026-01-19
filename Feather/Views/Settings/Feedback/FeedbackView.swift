import SwiftUI
import UIKit
import PhotosUI

// MARK: - GitHub Feedback Service
actor GitHubFeedbackService {
    static let shared = GitHubFeedbackService()
    
    private let tokenEndpoint = "http://194.41.112.28:3000/github-token"
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

// MARK: - Appearance Modifier
struct AppearanceModifier: ViewModifier {
    let appearAnimation: Bool
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: appearAnimation ? 0 : 20)
            .opacity(appearAnimation ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: appearAnimation)
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
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var appearAnimation: Bool = false
    @State private var includeLogs: Bool = false
    @State private var includeDeviceInfo: Bool = true
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker: Bool = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showMarkdownPreview: Bool = false
    @State private var showCodeEditor: Bool = false
    @State private var createdIssueURL: String = ""
    @State private var createdIssueNumber: Int = 0
    
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case title, message, code
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
        mainScrollView
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear { animateAppearance() }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItems, maxSelectionCount: 3, matching: .images)
            .onChange(of: selectedPhotoItems) { newItems in
                loadSelectedImages(from: newItems)
            }
            .sheet(isPresented: $showMarkdownPreview) {
                MarkdownPreviewSheet(content: feedbackMessage)
            }
            .sheet(isPresented: $showCodeEditor) {
                CodeEditorSheet(code: $codeSnippet)
            }
            .sheet(isPresented: $showSuccessSheet) {
                SuccessSheet(issueNumber: createdIssueNumber, issueURL: createdIssueURL, onDismiss: { dismiss() })
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
                Button("Retry") { submitFeedback() }
            } message: {
                Text(errorMessage)
            }
    }
    
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                    .modifier(AppearanceModifier(appearAnimation: appearAnimation, delay: 0))
                
                categorySelector
                    .modifier(AppearanceModifier(appearAnimation: appearAnimation, delay: 0.05))
                
                formSection
                    .modifier(AppearanceModifier(appearAnimation: appearAnimation, delay: 0.1))
                
                codeSection
                    .modifier(AppearanceModifier(appearAnimation: appearAnimation, delay: 0.15))
                
                attachmentsSection
                    .modifier(AppearanceModifier(appearAnimation: appearAnimation, delay: 0.2))
                
                optionsSection
                    .modifier(AppearanceModifier(appearAnimation: appearAnimation, delay: 0.25))
                
                submitSection
                    .modifier(AppearanceModifier(appearAnimation: appearAnimation, delay: 0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !feedbackMessage.isEmpty {
                Button {
                    showMarkdownPreview.toggle()
                } label: {
                    Image(systemName: "eye")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.accentColor)
                }
            }
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
        }
    }
    
    // MARK: - Section Background
    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
    
    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.tertiarySystemGroupedBackground))
    }
    
    private func inputOverlay(focused: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(focused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Category")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(FeedbackCategory.allCases, id: \.self) { category in
                        CategoryChip(
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
                .padding(.horizontal, 2)
            }
        }
        .padding(14)
        .background(sectionBackground)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            titleField
            messageField
        }
        .padding(16)
        .background(sectionBackground)
    }
    
    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "text.cursor")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Title")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("*")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.red)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 16))
                    .foregroundStyle(focusedField == .title ? Color.accentColor : Color.secondary)
                
                TextField("Brief summary of your feedback", text: $feedbackTitle)
                    .font(.system(size: 15))
                    .focused($focusedField, equals: .title)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .message }
            }
            .padding(14)
            .background(inputBackground)
            .overlay(inputOverlay(focused: focusedField == .title))
        }
    }
    
    private var messageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("Description")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Text("*")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.red)
                }
                Spacer()
                markdownTools
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $feedbackMessage)
                    .font(.system(size: 15))
                    .frame(minHeight: 150)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(inputBackground)
                    .overlay(inputOverlay(focused: focusedField == .message))
                    .focused($focusedField, equals: .message)
                
                if feedbackMessage.isEmpty {
                    Text("Describe your feedback in detail...\n\nSupports **Markdown** formatting")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                if feedbackMessage.count > 5000 {
                    Label("Message is quite long", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
                Spacer()
                Text("\(feedbackMessage.count) characters")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    private var markdownTools: some View {
        HStack(spacing: 8) {
            MarkdownToolButton(icon: "bold", tooltip: "Bold") { insertMarkdown("**", "**") }
            MarkdownToolButton(icon: "italic", tooltip: "Italic") { insertMarkdown("_", "_") }
            MarkdownToolButton(icon: "list.bullet", tooltip: "List") { insertMarkdown("\n- ", "") }
            MarkdownToolButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code") { insertMarkdown("`", "`") }
        }
    }
    
    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        feedbackMessage += prefix + suffix
        HapticsManager.shared.softImpact()
    }
    
    // MARK: - Code Section
    private var codeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "curlybraces")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Code Snippet")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !codeSnippet.isEmpty {
                    Text("\(codeSnippet.components(separatedBy: "\n").count) lines")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            
            if codeSnippet.isEmpty {
                codeEmptyState
            } else {
                codePreview
            }
        }
        .padding(14)
        .background(sectionBackground)
    }
    
    private var codeEmptyState: some View {
        Button {
            showCodeEditor = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.square.on.square")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add Code Snippet")
                        .font(.system(size: 14, weight: .medium))
                    Text("Include relevant code for context")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(inputBackground)
        }
        .buttonStyle(.plain)
    }
    
    private var codePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                Text(codeSnippet.prefix(500) + (codeSnippet.count > 500 ? "..." : ""))
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(12)
            }
            .frame(maxHeight: 120)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            
            HStack(spacing: 12) {
                Button {
                    showCodeEditor = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.system(size: 13, weight: .medium))
                }
                
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3)) {
                        codeSnippet = ""
                    }
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.system(size: 13, weight: .medium))
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Attachments Section
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "photo.stack")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Screenshots")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(selectedImages.count)/3")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            
            if selectedImages.isEmpty {
                attachmentsEmptyState
            } else {
                attachmentsImageList
            }
        }
        .padding(14)
        .background(sectionBackground)
    }
    
    private var attachmentsEmptyState: some View {
        Button {
            showImagePicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add Screenshots")
                        .font(.system(size: 14, weight: .medium))
                    Text("Up to 3 images")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(Color.accentColor.opacity(0.3))
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var attachmentsImageList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    attachmentThumbnail(at: index)
                }
                
                if selectedImages.count < 3 {
                    addMoreButton
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private func attachmentThumbnail(at index: Int) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: selectedImages[index])
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Button {
                withAnimation(.spring(response: 0.3)) {
                    selectedImages.remove(at: index)
                    if index < selectedPhotoItems.count {
                        selectedPhotoItems.remove(at: index)
                    }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .background(Circle().fill(Color.black.opacity(0.5)))
            }
            .offset(x: 6, y: -6)
        }
    }
    
    private var addMoreButton: some View {
        Button {
            showImagePicker = true
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                Text("Add")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(Color.accentColor)
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                            .foregroundStyle(Color.accentColor.opacity(0.4))
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(spacing: 12) {
            optionRow(
                icon: "doc.text.fill",
                iconColor: .orange,
                title: "Include App Logs",
                subtitle: "Attach diagnostic logs to help us debug",
                isOn: $includeLogs
            )
            
            if includeLogs {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                    Text("\(AppLogManager.shared.logs.count) log entries will be attached")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            optionRow(
                icon: "iphone",
                iconColor: .blue,
                title: "Include Device Info",
                subtitle: "Add device model and iOS version",
                isOn: $includeDeviceInfo
            )
        }
        .padding(14)
        .background(sectionBackground)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: includeLogs)
    }
    
    private func optionRow(icon: String, iconColor: Color, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(iconColor)
        }
        .padding(14)
        .background(inputBackground)
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
            submitFeedback()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Submit Feedback")
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
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func buildIssueBody() -> String {
        var body = """
        ## Description
        \(feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        
        """
        
        if !codeSnippet.isEmpty {
            body += """
            
            ## Code Snippet
            ```
            \(codeSnippet)
            ```
            
            """
        }
        
        if includeDeviceInfo {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
            let device = UIDevice.current.modelName
            let iosVersion = UIDevice.current.systemVersion
            
            body += """
            
            ## Device Information
            | Property | Value |
            |----------|-------|
            | App Version | \(version) (\(build)) |
            | Device | \(device) |
            | iOS Version | \(iosVersion) |
            
            """
        }
        
        if includeLogs {
            let logs = AppLogManager.shared.exportLogs()
            if !logs.isEmpty {
                body += """
                
                ## App Logs
                <details>
                <summary>Click to expand logs</summary>
                
                ```
                \(logs.prefix(10000))
                ```
                
                </details>
                
                """
            }
        }
        
        if !selectedImages.isEmpty {
            body += """
            
            ## Screenshots
            _\(selectedImages.count) screenshot(s) were attached but cannot be uploaded via API._
            
            """
        }
        
        body += """
        
        ---
        _Submitted via Portal app feedback system_
        """
        
        return body
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
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
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Markdown Tool Button
struct MarkdownToolButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color(.tertiarySystemGroupedBackground)))
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

// MARK: - Markdown Preview Sheet
struct MarkdownPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let content: String
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let attributed = try? AttributedString(markdown: content, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                        Text(attributed)
                            .font(.system(size: 15))
                            .padding()
                    } else {
                        Text(content)
                            .font(.system(size: 15))
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Code Editor Sheet
struct CodeEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var code: String
    @State private var localCode: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                codeEditorHeader
                codeEditorContent
            }
            .navigationTitle("Code Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        code = localCode
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            localCode = code
        }
    }
    
    private var codeEditorHeader: some View {
        HStack(spacing: 12) {
            Label("\(localCode.components(separatedBy: "\n").count) lines", systemImage: "text.alignleft")
            Spacer()
            Button {
                localCode = ""
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .disabled(localCode.isEmpty)
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGroupedBackground))
    }
    
    private var codeEditorContent: some View {
        TextEditor(text: $localCode)
            .font(.system(size: 14, design: .monospaced))
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .overlay(alignment: .topLeading) {
                if localCode.isEmpty {
                    Text("Paste or type your code here...")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
            }
    }
}

// MARK: - Success Sheet
struct SuccessSheet: View {
    let issueNumber: Int
    let issueURL: String
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            successIcon
            
            VStack(spacing: 8) {
                Text("Feedback Submitted!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                
                Text("Issue #\(issueNumber) has been created")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
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
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                showCheckmark = true
            }
        }
    }
    
    private var successIcon: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.15))
                .frame(width: 120, height: 120)
            
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
            
            Image(systemName: "checkmark")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)
                .scaleEffect(showCheckmark ? 1 : 0)
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
