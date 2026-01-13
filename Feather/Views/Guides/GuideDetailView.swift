import SwiftUI
import NimbleViews

// MARK: - Guide Detail View
struct GuideDetailView: View {
    let guide: Guide
    @State private var content: String = ""
    @State private var parsedContent: ParsedGuideContent?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#0077BE"
    @AppStorage("Feather.userTintColorType") private var colorType: String = "solid"
    @AppStorage("Feather.userTintGradientStart") private var gradientStartHex: String = "#0077BE"
    @AppStorage("Feather.userTintGradientEnd") private var gradientEndHex: String = "#848ef9"
    
    // AI State
    @State private var showingAIActionSheet = false
    @State private var showingDescribeGuideInput = false
    @State private var describeGuideInstruction: String = ""
    @State private var isProcessingAI = false
    @State private var aiOutputContent: String?
    @State private var aiParsedContent: ParsedGuideContent?
    @State private var aiError: String?
    @State private var showingAIOutput = false
    @State private var aiEngineUsed: AIEngine?
    @State private var didFallback = false
    @ObservedObject private var aiSettingsManager = GuideAISettingsManager.shared
    
    var accentColor: Color {
        if colorType == "gradient" {
            return Color(hex: gradientStartHex)
        } else {
            return Color(hex: selectedColorHex)
        }
    }
    
    private var isAIEnabled: Bool {
        aiSettingsManager.getPreference(for: guide.id).aiEnabled
    }
    
    private var isAIAvailable: Bool {
        // AI is available if either Apple Intelligence is supported OR OpenRouter API key is configured
        let appleIntelligenceAvailable = AppleIntelligenceService.shared.isAvailable
        let openRouterConfigured = aiSettingsManager.hasAPIKey
        return appleIntelligenceAvailable || openRouterConfigured
    }
    
    private var shouldShowAIButton: Bool {
        // Always show the AI button if AI is enabled for this guide
        // The button will indicate availability status when tapped
        return isAIEnabled
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading Guide...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.red)
                        
                        Text("Failed to load guide")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Retry") {
                            Task {
                                await loadContent()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else if showingAIOutput, let aiParsed = aiParsedContent {
                    // AI Output View
                    VStack(alignment: .leading, spacing: 16) {
                        // AI Output Header
                        aiOutputHeader
                        
                        ForEach(aiParsed.elements) { element in
                            renderElement(element)
                        }
                    }
                    .padding()
                } else if let parsed = parsedContent {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(parsed.elements) { element in
                            renderElement(element)
                        }
                    }
                    .padding()
                }
            }
            
            // AI Processing Overlay
            if isProcessingAI {
                aiProcessingOverlay
            }
        }
        .navigationTitle(guide.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if shouldShowAIButton {
                    aiButton
                }
            }
        }
        .task {
            await loadContent()
        }
        .confirmationDialog("AI Actions", isPresented: $showingAIActionSheet, titleVisibility: .visible) {
            ForEach(AIAction.allCases) { action in
                Button(action.displayName) {
                    if action == .describeGuide {
                        showingDescribeGuideInput = true
                    } else {
                        Task {
                            await processAIAction(action)
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Describe Guide", isPresented: $showingDescribeGuideInput) {
            TextField("Enter your instruction...", text: $describeGuideInstruction)
            Button("Cancel", role: .cancel) {
                describeGuideInstruction = ""
            }
            Button("Process") {
                Task {
                    await processAIAction(.describeGuide, customInstruction: describeGuideInstruction)
                    describeGuideInstruction = ""
                }
            }
        } message: {
            Text("Enter a custom instruction describing what you want done with the guide.")
        }
        .alert("AI Error", isPresented: Binding(
            get: { aiError != nil },
            set: { if !$0 { aiError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = aiError {
                Text(error)
            }
        }
    }
    
    @ViewBuilder
    private var aiButton: some View {
        Button {
            if isAIAvailable {
                showingAIActionSheet = true
            } else {
                aiError = GuideAIService.shared.getAvailabilityStatus(for: guide.id)
            }
        } label: {
            Image(systemName: "sparkles")
                .foregroundStyle(isAIAvailable ? accentColor : .secondary)
        }
        .disabled(isProcessingAI)
    }
    
    @ViewBuilder
    private var aiOutputHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.purple)
                Text("AI Generated Content")
                    .font(.headline)
                    .foregroundStyle(.purple)
                Spacer()
                Button {
                    withAnimation {
                        showingAIOutput = false
                        aiParsedContent = nil
                        aiOutputContent = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            
            if let engine = aiEngineUsed {
                HStack(spacing: 4) {
                    Text("Powered by")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(engine.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    if didFallback {
                        Text("(fallback)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var aiProcessingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Processing with AI...")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Text("This may take a moment")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    private func processAIAction(_ action: AIAction, customInstruction: String? = nil) async {
        guard !content.isEmpty else {
            aiError = "Guide content is not loaded"
            return
        }
        
        isProcessingAI = true
        aiError = nil
        
        do {
            let result = try await GuideAIService.shared.processGuide(
                guideId: guide.id,
                guideText: content,
                action: action,
                customInstruction: customInstruction
            )
            
            aiOutputContent = result.content
            aiParsedContent = GuideParser.parse(markdown: result.content)
            aiEngineUsed = result.engineUsed
            didFallback = result.didFallback
            
            withAnimation {
                showingAIOutput = true
            }
            
            HapticsManager.shared.success()
        } catch {
            aiError = error.localizedDescription
            HapticsManager.shared.error()
        }
        
        isProcessingAI = false
    }
    
    private func loadContent() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedContent = try await GitHubGuidesService.shared.fetchGuideContent(guide: guide)
            content = fetchedContent
            parsedContent = GuideParser.parse(markdown: fetchedContent)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    @ViewBuilder
    private func renderElement(_ element: GuideElement) -> some View {
        switch element {
        case .heading(let level, let text, let isAccent):
            renderHeading(level: level, text: text, isAccent: isAccent)
            
        case .paragraph(let content):
            renderParagraph(content: content)
            
        case .codeBlock(let language, let code):
            renderCodeBlock(language: language, code: code)
            
        case .image(let url, let altText):
            renderImage(url: url, altText: altText)
            
        case .link(let url, let text):
            renderLink(url: url, text: text)
            
        case .listItem(let level, let content):
            renderListItem(level: level, content: content)
            
        case .blockquote(let content):
            renderBlockquote(content: content)
        }
    }
    
    private func renderHeading(level: Int, text: String, isAccent: Bool) -> some View {
        return Text(text)
            .font(headingFont(for: level))
            .fontWeight(.bold)
            .foregroundStyle(isAccent ? accentColor : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, level == 1 ? 8 : 4)
    }
    
    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1: return .title
        case 2: return .title2
        case 3: return .title3
        case 4: return .headline
        default: return .subheadline
        }
    }
    
    private func renderParagraph(content: [InlineContent]) -> some View {
        renderInlineContent(content)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func renderInlineContent(_ content: [InlineContent]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ForEach(content) { segment in
                switch segment {
                case .text(let text):
                    Text(parseInlineMarkdown(text))
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                case .link(let url, let text):
                    if let validURL = URL(string: url) {
                        Link(destination: validURL) {
                            Text(text)
                                .font(.body)
                                .foregroundStyle(.blue)
                                .underline()
                        }
                    } else {
                        Text(text)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    
                case .accentText(let text):
                    Text(parseInlineMarkdown(text))
                        .font(.body)
                        .foregroundStyle(accentColor)
                    
                case .accentLink(let url, let text):
                    if let validURL = URL(string: url) {
                        Link(destination: validURL) {
                            Text(text)
                                .font(.body)
                                .foregroundStyle(accentColor)
                                .underline()
                        }
                    } else {
                        Text(text)
                            .font(.body)
                            .foregroundStyle(accentColor)
                    }
                }
            }
        }
    }
    
    private func renderCodeBlock(language: String?, code: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let lang = language, !lang.isEmpty {
                Text(lang.uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.primary)
                    .padding(12)
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    private func renderImage(url: String, altText: String?) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
            case .failure:
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    if let alt = altText {
                        Text(alt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 150)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private func renderLink(url: String, text: String) -> some View {
        if let validURL = URL(string: url) {
            return AnyView(
                Link(destination: validURL) {
                    HStack {
                        Text(text)
                            .foregroundStyle(.blue)
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        } else {
            return AnyView(
                Text(text)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }
    
    private func renderListItem(level: Int, content: [InlineContent]) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundStyle(.secondary)
                .frame(width: 16)
            renderInlineContent(content)
        }
        .padding(.leading, CGFloat(level) * 20)
    }
    
    private func renderBlockquote(content: [InlineContent]) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(Color.blue.opacity(0.5))
                .frame(width: 4)
            
            renderInlineContent(content)
                .italic()
        }
        .padding(.vertical, 8)
    }
    
    // Static regex patterns for better performance
    private static let codeRegex = try? NSRegularExpression(pattern: "`([^`]+)`", options: [])
    private static let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*|__(.+?)__", options: [])
    private static let italicRegex = try? NSRegularExpression(pattern: "(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)|(?<!_)_(?!_)(.+?)(?<!_)_(?!_)", options: [])
    
    // Simple inline markdown parser for bold, italic, and inline code
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        var resultText = text
        var ranges: [(range: Range<String.Index>, type: FormatType)] = []
        
        enum FormatType {
            case code
            case bold
            case italic
        }
        
        // Process code first (highest priority)
        if let regex = Self.codeRegex {
            let matches = regex.matches(in: resultText, options: [], range: NSRange(resultText.startIndex..., in: resultText))
            // Process in reverse to maintain indices
            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: resultText),
                   match.numberOfRanges >= 2,
                   let contentRange = Range(match.range(at: 1), in: resultText) {
                    let content = String(resultText[contentRange])
                    resultText.replaceSubrange(matchRange, with: content)
                    
                    // Calculate new range after replacement
                    let newStart = matchRange.lowerBound
                    let newEnd = resultText.index(newStart, offsetBy: content.count)
                    ranges.append((range: newStart..<newEnd, type: .code))
                }
            }
        }
        
        // Process bold (before italic to handle ** vs *)
        if let regex = Self.boldRegex {
            let matches = regex.matches(in: resultText, options: [], range: NSRange(resultText.startIndex..., in: resultText))
            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: resultText) {
                    // Try group 1 (for **text**) or group 2 (for __text__)
                    var content = ""
                    var contentRange: Range<String.Index>?
                    
                    if match.numberOfRanges >= 2, let range1 = Range(match.range(at: 1), in: resultText), !resultText[range1].isEmpty {
                        contentRange = range1
                        content = String(resultText[range1])
                    } else if match.numberOfRanges >= 3, let range2 = Range(match.range(at: 2), in: resultText), !resultText[range2].isEmpty {
                        contentRange = range2
                        content = String(resultText[range2])
                    }
                    
                    if let _ = contentRange {
                        resultText.replaceSubrange(matchRange, with: content)
                        
                        let newStart = matchRange.lowerBound
                        let newEnd = resultText.index(newStart, offsetBy: content.count)
                        ranges.append((range: newStart..<newEnd, type: .bold))
                    }
                }
            }
        }
        
        // Process italic last
        if let regex = Self.italicRegex {
            let matches = regex.matches(in: resultText, options: [], range: NSRange(resultText.startIndex..., in: resultText))
            for match in matches.reversed() {
                if let matchRange = Range(match.range, in: resultText) {
                    var content = ""
                    var contentRange: Range<String.Index>?
                    
                    if match.numberOfRanges >= 2, let range1 = Range(match.range(at: 1), in: resultText), !resultText[range1].isEmpty {
                        contentRange = range1
                        content = String(resultText[range1])
                    } else if match.numberOfRanges >= 3, let range2 = Range(match.range(at: 2), in: resultText), !resultText[range2].isEmpty {
                        contentRange = range2
                        content = String(resultText[range2])
                    }
                    
                    if let _ = contentRange {
                        resultText.replaceSubrange(matchRange, with: content)
                        
                        let newStart = matchRange.lowerBound
                        let newEnd = resultText.index(newStart, offsetBy: content.count)
                        ranges.append((range: newStart..<newEnd, type: .italic))
                    }
                }
            }
        }
        
        // Create attributed string
        var result = AttributedString(resultText)
        
        // Apply formatting
        for (range, type) in ranges {
            if let attrRange = Range(range, in: result) {
                switch type {
                case .code:
                    result[attrRange].font = .system(.body, design: .monospaced)
                    result[attrRange].backgroundColor = Color.secondary.opacity(0.2)
                case .bold:
                    result[attrRange].font = .body.bold()
                case .italic:
                    result[attrRange].font = .body.italic()
                }
            }
        }
        
        return result
    }
}
