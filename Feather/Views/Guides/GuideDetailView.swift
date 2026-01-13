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
    @State private var showingTranslateSheet = false
    @State private var describeGuideInstruction: String = ""
    @State private var selectedLanguage: String = ""
    @State private var isProcessingAI = false
    @State private var aiOutputContent: String?
    @State private var aiParsedContent: ParsedGuideContent?
    @State private var aiError: String?
    @State private var showingAIOutput = false
    @State private var aiEngineUsed: AIEngine?
    @State private var didFallback = false
    @State private var currentAIAction: AIAction?
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
        .sheet(isPresented: $showingAIActionSheet) {
            AIActionsSheet(
                isPresented: $showingAIActionSheet,
                isAIAvailable: isAIAvailable,
                onActionSelected: { action in
                    if action == .describeGuide {
                        showingAIActionSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingDescribeGuideInput = true
                        }
                    } else if action == .translate {
                        showingAIActionSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingTranslateSheet = true
                        }
                    } else {
                        showingAIActionSheet = false
                        currentAIAction = action
                        Task {
                            await processAIAction(action)
                        }
                    }
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingDescribeGuideInput) {
            CustomPromptSheet(
                isPresented: $showingDescribeGuideInput,
                instruction: $describeGuideInstruction,
                onSubmit: {
                    showingDescribeGuideInput = false
                    currentAIAction = .describeGuide
                    Task {
                        await processAIAction(.describeGuide, customInstruction: describeGuideInstruction)
                        describeGuideInstruction = ""
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTranslateSheet) {
            TranslateSheet(
                isPresented: $showingTranslateSheet,
                selectedLanguage: $selectedLanguage,
                onSubmit: { language in
                    showingTranslateSheet = false
                    currentAIAction = .translate
                    Task {
                        await processAIAction(.translate, customInstruction: "Translate to \(language)")
                        selectedLanguage = ""
                    }
                }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: Binding(
            get: { aiError != nil },
            set: { if !$0 { aiError = nil } }
        )) {
            AIErrorSheet(
                error: aiError ?? "",
                isAIAvailable: isAIAvailable,
                onDismiss: { aiError = nil }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
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
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Animated gradient icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Generated")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let engine = aiEngineUsed {
                        HStack(spacing: 4) {
                            Image(systemName: engine == .appleIntelligence ? "apple.logo" : "cloud.fill")
                                .font(.caption2)
                            Text(engine.displayName)
                                .font(.caption)
                            if didFallback {
                                Text("• Fallback")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showingAIOutput = false
                        aiParsedContent = nil
                        aiOutputContent = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.purple.opacity(0.15), Color.pink.opacity(0.1), Color.blue.opacity(0.05)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.purple.opacity(0.3), .pink.opacity(0.2), .blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private var aiProcessingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated sparkles
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.purple.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    // Spinning ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.purple, .pink, .blue, .purple],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isProcessingAI ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isProcessingAI)
                    
                    // Center icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isProcessingAI ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isProcessingAI)
                }
                
                VStack(spacing: 8) {
                    Text(getProcessingTitle())
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text("This may take a moment...")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(40)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
            .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
    
    private func getProcessingTitle() -> String {
        guard let action = currentAIAction else { return "Processing..." }
        switch action {
        case .simplify: return "Simplifying..."
        case .translate: return "Translating..."
        case .explain: return "Explaining..."
        case .summarize: return "Summarizing..."
        case .keyPoints: return "Extracting Key Points..."
        case .stepByStep: return "Creating Steps..."
        case .proofread: return "Proofreading..."
        case .describeGuide: return "Processing..."
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

// MARK: - AI Actions Sheet
struct AIActionsSheet: View {
    @Binding var isPresented: Bool
    let isAIAvailable: Bool
    let onActionSelected: (AIAction) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with animated gradient
                    VStack(spacing: 12) {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.purple.opacity(0.4), .pink.opacity(0.2), .clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .pink, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("AI Actions")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Transform your guide with AI")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Actions Grid
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(AIAction.allCases) { action in
                            AIActionButton(action: action) {
                                HapticsManager.shared.softImpact()
                                onActionSelected(action)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    if !isAIAvailable {
                        VStack(spacing: 12) {
                            HStack(spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("AI Not Configured")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Add your API key in Settings → Guides")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.orange.opacity(0.15), .yellow.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

struct AIActionButton: View {
    let action: AIAction
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 14) {
                ZStack {
                    // Background glow
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: action.gradientColors.map { $0.opacity(0.3) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)
                        .blur(radius: 8)
                    
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: action.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: action.systemImage)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
                
                VStack(spacing: 4) {
                    Text(action.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(action.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Custom Prompt Sheet
struct CustomPromptSheet: View {
    @Binding var isPresented: Bool
    @Binding var instruction: String
    let onSubmit: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        Image(systemName: "text.bubble")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    
                    Text("Custom Prompt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Enter your own instructions for the AI")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)
                
                // Text Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your instruction")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $instruction)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .focused($isFocused)
                }
                .padding(.horizontal)
                
                // Submit Button
                Button {
                    onSubmit()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Process with AI")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: instruction.isEmpty ? [.gray, .secondary] : [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(12)
                }
                .disabled(instruction.isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        instruction = ""
                        isPresented = false
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

// MARK: - AI Error Sheet
struct AIErrorSheet: View {
    let error: String
    let isAIAvailable: Bool
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    
                    Text("AI Unavailable")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding(.top, 32)
                
                // Error Message
                VStack(spacing: 16) {
                    Text(error)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    if !isAIAvailable {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "1.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Go to Settings → Guides")
                                    .font(.subheadline)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "2.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Add your OpenRouter API key")
                                    .font(.subheadline)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "3.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Select an AI model")
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Dismiss Button
                Button {
                    onDismiss()
                } label: {
                    Text("Got it")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Translate Sheet
struct TranslateSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedLanguage: String
    let onSubmit: (String) -> Void
    
    @State private var showCustomLanguage = false
    @State private var customLanguage = ""
    @FocusState private var isCustomFocused: Bool
    
    static let languages: [(name: String, flag: String, code: String)] = [
        ("Spanish", "🇪🇸", "es"),
        ("French", "🇫🇷", "fr"),
        ("German", "🇩🇪", "de"),
        ("Italian", "🇮🇹", "it"),
        ("Portuguese", "🇵🇹", "pt"),
        ("Chinese (Simplified)", "🇨🇳", "zh"),
        ("Japanese", "🇯🇵", "ja"),
        ("Korean", "🇰🇷", "ko"),
        ("Arabic", "🇸🇦", "ar"),
        ("Russian", "🇷🇺", "ru"),
        ("Hindi", "🇮🇳", "hi"),
        ("Dutch", "🇳🇱", "nl")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [.green.opacity(0.4), .mint.opacity(0.2), .clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 60
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "globe")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Translate")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Select your target language")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Language Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Self.languages, id: \.code) { language in
                            LanguageButton(
                                name: language.name,
                                flag: language.flag,
                                isSelected: selectedLanguage == language.name
                            ) {
                                selectedLanguage = language.name
                                HapticsManager.shared.softImpact()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Custom Language Option
                    VStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                showCustomLanguage.toggle()
                                if showCustomLanguage {
                                    selectedLanguage = ""
                                    isCustomFocused = true
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Language Not Listed")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: showCustomLanguage ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        
                        if showCustomLanguage {
                            HStack {
                                TextField("Enter language name...", text: $customLanguage)
                                    .textFieldStyle(.plain)
                                    .focused($isCustomFocused)
                                    .onChange(of: customLanguage) { newValue in
                                        if !newValue.isEmpty {
                                            selectedLanguage = newValue
                                        }
                                    }
                                
                                if !customLanguage.isEmpty {
                                    Button {
                                        customLanguage = ""
                                        selectedLanguage = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Translate Button
                    Button {
                        if !selectedLanguage.isEmpty {
                            onSubmit(selectedLanguage)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Translate to \(selectedLanguage.isEmpty ? "..." : selectedLanguage)")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: selectedLanguage.isEmpty ? [.gray, .secondary] : [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .disabled(selectedLanguage.isEmpty)
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        selectedLanguage = ""
                        customLanguage = ""
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct LanguageButton: View {
    let name: String
    let flag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Text(flag)
                    .font(.title2)
                
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding()
            .background(isSelected ? Color.green.opacity(0.15) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
