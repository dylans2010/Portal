import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

// MARK: - App Logs View
struct AppLogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogEntry.LogLevel?
    @State private var selectedCategory: String?
    @State private var showFilters = false
    @State private var showExporter = false
    @State private var logDocument: LogDocument?
    @State private var exportType: UTType = .plainText
    @State private var autoScroll = true
    @State private var showInfo = false
    @Environment(\.colorScheme) var colorScheme

    var filteredLogs: [LogEntry] {
        logManager.filteredLogs(searchText: searchText, level: selectedLevel, category: selectedCategory).reversed()
    }

    var body: some View {
        ZStack {
            // Modern Background
            Color.clear
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 14, weight: .medium))

                        TextField("Search Logs", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15, weight: .medium))

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(colorScheme == .dark ? 0.05 : 0.1), lineWidth: 1)
                    )

                    // Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterPill(
                                title: "All",
                                isSelected: selectedLevel == nil,
                                count: logManager.logs.count
                            ) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedLevel = nil
                                }
                            }

                            ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                                let count = logManager.logs.filter { $0.level == level }.count
                                if count > 0 {
                                    FilterPill(
                                        title: level.rawValue,
                                        icon: level.icon,
                                        isSelected: selectedLevel == level,
                                        count: count
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedLevel = selectedLevel == level ? nil : level
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .padding()
                .background(Color.clear)

                Divider()

                // Logs List
                if filteredLogs.isEmpty {
                    VStack(spacing: 20) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)

                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 8) {
                            Text(logManager.logs.isEmpty ? "No Logs Yet" : "No Matching Logs")
                                .font(.headline)

                            if !logManager.logs.isEmpty {
                                Text("There is currently no logs, try adjusting your search or filters.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                        }
                        Spacer()
                    }
                    .transition(AnyTransition.opacity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredLogs) { log in
                                    LogEntryRow(entry: log)
                                        .id(log.id)

                                    Divider()
                                        .padding(.leading, 16)
                                }

                                // Privacy Disclaimer
                                VStack(spacing: 8) {
                                    Image(systemName: "hand.raised.shield.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.secondary)

                                    Text("These logs always remain on device and never shared with anyone. You can choose to share them when reporting feedback, on the Include section, click the Logs button to send these logs on the GitHub Issue. ")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .padding(.vertical, 30)
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .onChange(of: filteredLogs.count) { _ in
                            if autoScroll, let lastLog = filteredLogs.last {
                                withAnimation(.spring()) {
                                    proxy.scrollTo(lastLog.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("App Logs")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: searchText) { newValue in
            if newValue == "dev=True" {
                Task {
                    await GestureManager.shared.performAction(for: .tripleTap, in: .settings)
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            ScreenshotPreventingView {
                LogInfoView()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gestureAuthenticateDeveloper)) { _ in
            UserDefaults.standard.set(true, forKey: "Feather.devModeUnlocked")
            HapticsManager.shared.success()
            ToastManager.shared.show("🛠️ Developer Mode Phase 1 Complete!", type: .success)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Info button
                Button(action: { showInfo = true }) {
                    Image(systemName: "info.circle")
                }

                // Auto-scroll toggle
                Button(action: { autoScroll.toggle() }) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .foregroundStyle(autoScroll ? Color.accentColor : .secondary)
                }

                // Share menu
                Menu {
                    Button(action: copyToClipboard) {
                        Label("Copy To Clipboard", systemImage: "doc.on.clipboard")
                    }

                    Menu {
                        Button(action: saveAsText) {
                            Label("Plain Text (.txt)", systemImage: "doc.text")
                        }
                        Button(action: saveAsJSON) {
                            Label("JSON Data (.json)", systemImage: "braces")
                        }
                        Button(action: saveAsCSV) {
                            Label("CSV Spreadsheet (.csv)", systemImage: "tablecells")
                        }
                    } label: {
                        Label("Export Logs", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        logManager.clearLogs()
                        HapticsManager.shared.success()
                    }) {
                        Label("Clear Logs", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: logDocument,
            contentType: exportType,
            defaultFilename: "Portal_Logs_\(Date().formatted(.iso8601.year().month().day().timeSeparator(.omitted)))"
        ) { result in
            switch result {
            case .success(let url):
                logManager.success("Logs saved to \(url.lastPathComponent)", category: "AppLogs")
            case .failure(let error):
                logManager.error("Failed to save logs: \(error.localizedDescription)", category: "AppLogs")
            }
        }
    }

    private func saveAsText() {
        let text = logManager.exportLogs()
        if let data = text.data(using: .utf8) {
            logDocument = LogDocument(data: data, contentType: .plainText)
            exportType = .plainText
            showExporter = true
        }
    }

    private func saveAsJSON() {
        if let data = logManager.exportLogsAsJSON() {
            logDocument = LogDocument(data: data, contentType: .json)
            exportType = .json
            showExporter = true
        }
    }

    private func saveAsCSV() {
        let csv = logManager.exportLogsAsCSV()
        if let data = csv.data(using: .utf8) {
            logDocument = LogDocument(data: data, contentType: .commaSeparatedText)
            exportType = .commaSeparatedText
            showExporter = true
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = logManager.exportLogs()
        HapticsManager.shared.success()
        logManager.success("Logs Copied To Clipboard", category: "Developer")
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    var icon: String?
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))

                Text("\(count)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isSelected ? .white.opacity(0.25) : .primary.opacity(0.05))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : .primary.opacity(0.8))
            .clipShape(Capsule())
            .shadow(color: isSelected ? Color.accentColor.opacity(0.4) : .black.opacity(0.05), radius: 8, x: 0, y: 4)
            .overlay(
                Capsule()
                    .stroke(.white.opacity(colorScheme == .dark ? 0.1 : 0.3), lineWidth: 1)
            )
            .contentShape(Capsule())
        }

        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Log Entry Row
struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
    @State private var showErrorCodeDetail = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticsManager.shared.softImpact()
            } label: {
                HStack(alignment: .top, spacing: 12) {
                    // Level Icon
                    Image(systemName: "list.bullet.indent")
                        .font(.system(size: 14))
                        .foregroundStyle(levelColor(entry.level))
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.level.icon)
                                .font(.system(size: 11))

                            Text(entry.formattedTimestamp)
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)

                            if let code = entry.errorCode {
                                Text(code.rawValue)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.red.opacity(0.1))
                                    .foregroundStyle(.red)
                                    .cornerRadius(4)
                            }

                            Spacer()

                            Label(entry.category.uppercased(), systemImage: "tag.fill")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(levelColor(entry.level).opacity(0.1))
                                .foregroundStyle(levelColor(entry.level))
                                .clipShape(Capsule())
                        }

                        Text(entry.message)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)
                            .lineLimit(isExpanded ? nil : 3)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.top, 4)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .contextMenu {
                Button {
                    UIPasteboard.general.string = entry.message
                    HapticsManager.shared.success()
                } label: {
                    Label("Copy Message", systemImage: "doc.on.doc")
                }

                Button {
                    UIPasteboard.general.string = entry.detailedMessage
                    HapticsManager.shared.success()
                } label: {
                    Label("Copy Detailed Log", systemImage: "doc.text.below.ecg")
                }

                if entry.errorCode != nil {
                    Divider()

                    Button {
                        showErrorCodeDetail = true
                    } label: {
                        Label("Error Log", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $showErrorCodeDetail) {
                ScreenshotPreventingView {
                    if let code = entry.errorCode {
                        ErrorCodeDetailView(code: code)
                    }
                }
            }


            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        DetailRow(label: "Level", value: entry.level.rawValue)
                        DetailRow(label: "File", value: entry.file)
                        DetailRow(label: "Function", value: entry.function)
                        DetailRow(label: "Line", value: "\(entry.line)")
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 12)
                    .padding(.top, 4)
                }
                .transition(.opacity)
            }
        }
        .background(Color.clear.opacity(isExpanded ? 0.5 : 0))
    }

    private func levelColor(_ level: LogEntry.LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 4) {
            Text("\(label):")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)

            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .textSelection(.enabled)

            Spacer()
        }
    }
}

// MARK: - Activity View Controller
// MARK: - Log Document
struct LogDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText, .commaSeparatedText] }

    var data: Data
    var contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
            self.contentType = configuration.contentType
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Error Code Detail View
struct ErrorCodeDetailView: View {
    let code: LogErrorCode
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.red.opacity(0.1))
                                .frame(width: 80, height: 80)

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.red)
                        }

                        Text(code.rawValue)
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 20) {
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Label("DESCRIPTION", systemImage: "text.alignleft")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.secondary)

                            Text(code.info.description)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(12)

                        // Suggestion
                        VStack(alignment: .leading, spacing: 8) {
                            Label("SUGGESTION", systemImage: "lightbulb.fill")
                                .font(.system(size: 12, weight: .black))
                                .foregroundStyle(.orange)

                            Text(code.info.suggestion)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Got it")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(12)
                    }
                    .padding()
                }
            .navigationTitle("Error Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Log Info View
struct LogInfoView: View {
    @Environment(\.dismiss) var dismiss
    @State private var expandedCodes: Set<LogErrorCode> = []

    var body: some View {
        NavigationStack {
            List {
                understandingLogsSection
                logLevelsSection
                errorLogCodesSection
            }
            .navigationTitle("Log Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
    }

    @ViewBuilder
    private var understandingLogsSection: some View {
        Section("Understanding Logs") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Logs are essential for debugging issues within Portal. They capture events, errors, and warnings that occur during operations like signing and installation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Sharing these logs when reporting a bug helps developers identify and fix the issue much faster.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var logLevelsSection: some View {
        Section("Log Levels") {
            ForEach(LogEntry.LogLevel.allCases, id: \.self) { level in
                HStack(spacing: 12) {
                    Text(level.icon)
                    VStack(alignment: .leading) {
                        Text(level.rawValue)
                            .font(.headline)
                        Text(description(for: level))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var errorLogCodesSection: some View {
        Section("Error Log Codes") {
            ForEach(LogErrorCode.allCases, id: \.self) { code in
                LogErrorCodeRow(
                    code: code,
                    isExpanded: expandedCodes.contains(code)
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        if expandedCodes.contains(code) {
                            expandedCodes.remove(code)
                        } else {
                            expandedCodes.insert(code)
                        }
                    }
                    HapticsManager.shared.softImpact()
                }
            }
        }
    }

    private func description(for level: LogEntry.LogLevel) -> String {
        switch level {
        case .debug: return "Detailed technical information for developers."
        case .info: return "General informational messages about normal operations."
        case .success: return "Confirmation of successful completion of a task."
        case .warning: return "Indications of potential issues that aren't yet fatal."
        case .error: return "Standard error messages when an operation fails."
        case .critical: return "Serious failures that might require immediate attention."
        }
    }
}

// MARK: - Log Error Code Row
struct LogErrorCodeRow: View {
    let code: LogErrorCode
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        let info = code.info
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(info.code)
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(.red)
                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }

            Text(info.description)
                .font(.subheadline)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SUGGESTION")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.secondary)
                    Text(info.suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Click to see suggestion")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                    .padding(.vertical, 4)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}
