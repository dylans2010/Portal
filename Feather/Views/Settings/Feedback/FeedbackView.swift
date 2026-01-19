import SwiftUI
import UIKit
import PhotosUI

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
        mainScrollView
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { animateAppearance() }
            .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItems, maxSelectionCount: 3, matching: .images)
            .onChange(of: selectedPhotoItems) { newItems in
                loadSelectedImages(from: newItems)
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
                        FeedbackCategoryChip(
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
                    Text("Describe your feedback in detail...")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                Spacer()
                Text("\(feedbackMessage.count) characters")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }
    
    // MARK: - Attachments Section (Combined)
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "paperclip")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("Attachments & Info")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            
            // Toggle Options Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                attachmentToggle(
                    icon: "doc.text.fill",
                    title: "App Logs",
                    subtitle: "\(AppLogManager.shared.logs.count) entries",
                    color: .orange,
                    isOn: $includeLogs
                )
                
                attachmentToggle(
                    icon: "iphone",
                    title: "Device Info",
                    subtitle: UIDevice.current.modelName,
                    color: .blue,
                    isOn: $includeDeviceInfo
                )
                
                attachmentToggle(
                    icon: "photo.stack",
                    title: "Screenshots",
                    subtitle: selectedImages.isEmpty ? "Add images" : "\(selectedImages.count) selected",
                    color: .green,
                    isOn: $includeScreenshots,
                    action: { showImagePicker = true }
                )
                
                attachmentToggle(
                    icon: "curlybraces",
                    title: "Code Snippet",
                    subtitle: codeSnippet.isEmpty ? "Add code" : "\(codeSnippet.components(separatedBy: "\n").count) lines",
                    color: .purple,
                    isOn: $includeCode,
                    action: { showCodeEditor = true }
                )
            }
            
            // Screenshots Preview
            if includeScreenshots && !selectedImages.isEmpty {
                screenshotsPreview
            }
            
            // Code Preview
            if includeCode && !codeSnippet.isEmpty {
                codePreview
            }
        }
        .padding(14)
        .background(sectionBackground)
    }
    
    private func attachmentToggle(icon: String, title: String, subtitle: String, color: Color, isOn: Binding<Bool>, action: (() -> Void)? = nil) -> some View {
        Button {
            if let action = action {
                action()
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isOn.wrappedValue.toggle()
                }
            }
            HapticsManager.shared.softImpact()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isOn.wrappedValue ? color : color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(isOn.wrappedValue ? .white : color)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(isOn.wrappedValue ? color : .tertiary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isOn.wrappedValue ? color.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(isOn.wrappedValue ? color.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var screenshotsPreview: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
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
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                                .background(Circle().fill(Color.black.opacity(0.5)))
                        }
                        .offset(x: 4, y: -4)
                    }
                }
                
                if selectedImages.count < 3 {
                    Button {
                        showImagePicker = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundStyle(.green)
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundStyle(Color.green.opacity(0.4))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
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
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
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
