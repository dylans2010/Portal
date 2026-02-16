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
    @Environment(\.colorScheme) var colorScheme

    var filteredLogs: [LogEntry] {
        if logManager.isVerboseLoggingEnabled {
            return logManager.logs.filter { $0.category == "Signing" }.sorted(by: { $0.timestamp < $1.timestamp })
        }
        return logManager.filteredLogs(searchText: searchText, level: selectedLevel, category: selectedCategory)
    }

    var body: some View {
        ZStack {
            // Modern Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 10) {
                    // Verbose Logging Toggle
                    HStack {
                        Label("Verbose Logging", systemImage: "terminal.fill")
                            .font(.system(size: 14, weight: .semibold))

                        Spacer()

                        Toggle("", isOn: $logManager.isVerboseLoggingEnabled)
                            .labelsHidden()
                            .tint(Color.accentColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(colorScheme == .dark ? 0.05 : 0.1), lineWidth: 1)
                    )

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
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
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
                .background(Color(UIColor.systemGroupedBackground))

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
        .toolbar(content: {
            ToolbarItemGroup(placement: .topBarTrailing) {
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
        })
        .fileExporter(
            isPresented: $showExporter,
            document: logDocument,
            contentType: exportType,
            defaultFilename: "Portal_Logs_\(Date().formatted(date: .numeric, time: .omitted))"
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
            logDocument = LogDocument(data: data, isJSON: false)
            exportType = .plainText
            showExporter = true
        }
    }

    private func saveAsJSON() {
        if let data = logManager.exportLogsAsJSON() {
            logDocument = LogDocument(data: data, isJSON: true)
            exportType = .json
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
            HStack(spacing: 6) {
                if let icon = icon {
                    Text(icon)
                        .font(.system(size: 14))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? .white.opacity(0.2) : .secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                ZStack {
                    if isSelected {
                        Color.accentColor
                    } else {
                        Color(UIColor.secondarySystemGroupedBackground)
                    }
                }
            )
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            .overlay(
                Capsule()
                    .stroke(.white.opacity(colorScheme == .dark ? 0.05 : 0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Entry Row
struct LogEntryRow: View {
    let entry: LogEntry
    @State private var isExpanded = false
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
            }
            .buttonStyle(.plain)

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
        .background(Color(UIColor.secondarySystemGroupedBackground).opacity(isExpanded ? 0.5 : 0))
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
    static var readableContentTypes: [UTType] { [.json, .plainText] }

    var data: Data
    var isJSON: Bool

    init(data: Data, isJSON: Bool) {
        self.data = data
        self.isJSON = isJSON
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
            self.isJSON = configuration.contentType == .json
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
