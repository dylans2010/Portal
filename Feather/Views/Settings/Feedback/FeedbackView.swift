import SwiftUI
import UIKit
import PhotosUI

// MARK: - Modern Feedback View
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var feedbackTitle: String = ""
    @State private var feedbackMessage: String = ""
    @State private var feedbackCategory: FeedbackCategory = .suggestion
    @State private var isSubmitting: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var appearAnimation: Bool = false
    @State private var includeLogs: Bool = false
    @State private var selectedImages: [UIImage] = []
    @State private var showImagePicker: Bool = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showMarkdownPreview: Bool = false
    
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case title, message
    }
    
    enum FeedbackCategory: String, CaseIterable {
        case bug = "Bug Report"
        case suggestion = "Suggestion"
        case feature = "Feature Request"
        case question = "Question"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug.fill"
            case .suggestion: return "lightbulb.fill"
            case .feature: return "star.fill"
            case .question: return "questionmark.circle.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .bug: return .red
            case .suggestion: return .orange
            case .feature: return .purple
            case .question: return .blue
            case .other: return .gray
            }
        }
    }
    
    private var isFormValid: Bool {
        !feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection
                    .offset(y: appearAnimation ? 0 : 20)
                    .opacity(appearAnimation ? 1 : 0)
                
                categorySelector
                    .offset(y: appearAnimation ? 0 : 20)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appearAnimation)
                
                formSection
                    .offset(y: appearAnimation ? 0 : 20)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appearAnimation)
                
                attachmentsSection
                    .offset(y: appearAnimation ? 0 : 20)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appearAnimation)
                
                optionsSection
                    .offset(y: appearAnimation ? 0 : 20)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                
                submitButton
                    .offset(y: appearAnimation ? 0 : 20)
                    .opacity(appearAnimation ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.25), value: appearAnimation)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !feedbackMessage.isEmpty {
                    Button {
                        showMarkdownPreview.toggle()
                    } label: {
                        Image(systemName: showMarkdownPreview ? "eye.fill" : "eye")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedPhotoItems, maxSelectionCount: 3, matching: .images)
        .onChange(of: selectedPhotoItems) { newItems in
            Task {
                selectedImages = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
        .sheet(isPresented: $showMarkdownPreview) {
            MarkdownPreviewSheet(content: feedbackMessage)
        }
        .alert("Feedback Sent!", isPresented: $showSuccessAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Thank you for your feedback! We appreciate your input and will review it carefully.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 14) {
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
            
            VStack(spacing: 4) {
                Text("Share Your Feedback")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Help us improve by sharing your thoughts")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
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
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Form Section
    private var formSectionTitleLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "text.cursor")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Title")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    private var formSectionTitleInput: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.line")
                .font(.system(size: 16))
                .foregroundStyle(focusedField == .title ? Color.accentColor : Color.secondary)
            
            TextField("Brief summary of your feedback", text: $feedbackTitle)
                .font(.system(size: 15))
                .focused($focusedField, equals: .title)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(focusedField == .title ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
    
    private var formSectionTitleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            formSectionTitleLabel
            formSectionTitleInput
        }
    }
    
    private var formSectionMessageLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Message")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    private var formSectionMarkdownTools: some View {
        HStack(spacing: 8) {
            MarkdownToolButton(icon: "bold", action: { insertMarkdown("**", "**") })
            MarkdownToolButton(icon: "italic", action: { insertMarkdown("_", "_") })
            MarkdownToolButton(icon: "list.bullet", action: { insertMarkdown("\n- ", "") })
            MarkdownToolButton(icon: "chevron.left.forwardslash.chevron.right", action: { insertMarkdown("`", "`") })
        }
    }
    
    private var formSectionMessageHeader: some View {
        HStack {
            formSectionMessageLabel
            Spacer()
            formSectionMarkdownTools
        }
    }
    
    private var formSectionMessagePlaceholder: some View {
        Group {
            if feedbackMessage.isEmpty {
                Text("Describe your feedback in detail...\n\nSupports **Markdown** formatting")
                    .font(.system(size: 15))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var formSectionMessageEditor: some View {
        TextEditor(text: $feedbackMessage)
            .font(.system(size: 15, design: .monospaced))
            .frame(minHeight: 150)
            .padding(10)
            .scrollContentBackground(.hidden)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(focusedField == .message ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .overlay(alignment: .topLeading) {
                formSectionMessagePlaceholder
            }
            .focused($focusedField, equals: .message)
    }
    
    private var formSectionCharacterCount: some View {
        HStack {
            Spacer()
            Text("\(feedbackMessage.count) characters")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }
    
    private var formSectionMessageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            formSectionMessageHeader
            formSectionMessageEditor
            formSectionCharacterCount
        }
    }
    
    private var formSectionBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            formSectionTitleField
            formSectionMessageField
        }
        .padding(16)
        .background(formSectionBackground)
    }
    
    // MARK: - Attachments Section
    private var attachmentsSectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "paperclip")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Attachments")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text("\(selectedImages.count)/3")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }
    
    private var attachmentsEmptyButtonLabel: some View {
        HStack(spacing: 10) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 20))
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
    
    private var attachmentsEmptyState: some View {
        Button {
            showImagePicker = true
        } label: {
            attachmentsEmptyButtonLabel
        }
        .buttonStyle(.plain)
    }
    
    private func attachmentImageThumbnail(at index: Int) -> some View {
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
    
    private var attachmentsAddMoreButtonLabel: some View {
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
    
    private var attachmentsAddMoreButton: some View {
        Group {
            if selectedImages.count < 3 {
                Button {
                    showImagePicker = true
                } label: {
                    attachmentsAddMoreButtonLabel
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var attachmentsImageList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(selectedImages.indices, id: \.self) { index in
                    attachmentImageThumbnail(at: index)
                }
                attachmentsAddMoreButton
            }
            .padding(.horizontal, 2)
        }
    }
    
    private var attachmentsSectionContent: some View {
        Group {
            if selectedImages.isEmpty {
                attachmentsEmptyState
            } else {
                attachmentsImageList
            }
        }
    }
    
    private var attachmentsSectionBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
    }
    
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            attachmentsSectionHeader
            attachmentsSectionContent
        }
        .padding(14)
        .background(attachmentsSectionBackground)
    }
    
    // MARK: - Options Section
    private var optionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.orange)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include App Logs")
                        .font(.system(size: 15, weight: .medium))
                    Text("Attach diagnostic logs to help us debug")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $includeLogs)
                    .labelsHidden()
                    .tint(.orange)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemGroupedBackground))
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
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: includeLogs)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            submitFeedback()
        } label: {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(isSubmitting ? "Sending..." : "Submit Feedback")
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
        .disabled(!isFormValid || isSubmitting)
        .animation(.easeInOut(duration: 0.2), value: isFormValid)
        .animation(.easeInOut(duration: 0.2), value: feedbackCategory)
    }
    
    // MARK: - Helper Methods
    private func insertMarkdown(_ prefix: String, _ suffix: String) {
        feedbackMessage += prefix + suffix
        HapticsManager.shared.softImpact()
    }
    
    private func submitFeedback() {
        guard isFormValid else { return }
        
        focusedField = nil
        isSubmitting = true
        HapticsManager.shared.softImpact()
        
        let metadata = FeedbackMetadata(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            device: UIDevice.current.modelName,
            category: feedbackCategory.rawValue,
            hasImages: !selectedImages.isEmpty,
            hasLogs: includeLogs
        )
        
        var logsContent: String? = nil
        if includeLogs {
            logsContent = AppLogManager.shared.exportLogs()
        }
        
        let feedback = FeedbackPayload(
            title: feedbackTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            message: feedbackMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            metadata: metadata,
            logs: logsContent
        )
        
        Task {
            do {
                try await sendFeedback(feedback)
                await MainActor.run {
                    isSubmitting = false
                    HapticsManager.shared.success()
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
    
    private func sendFeedback(_ feedback: FeedbackPayload) async throws {
        guard let url = URL(string: "http://194.41.112.28:3000/feedback") else {
            throw FeedbackError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(feedback)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw FeedbackError.serverError(statusCode: httpResponse.statusCode)
        }
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

// MARK: - Models
struct FeedbackPayload: Codable {
    let title: String
    let message: String
    let metadata: FeedbackMetadata
    let logs: String?
}

struct FeedbackMetadata: Codable {
    let version: String
    let device: String
    let category: String
    let hasImages: Bool
    let hasLogs: Bool
}

enum FeedbackError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let statusCode):
            return "Server error (Status: \(statusCode))"
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
