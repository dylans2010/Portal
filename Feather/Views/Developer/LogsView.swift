import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

// MARK: - Log Document
struct LogDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json, .plainText] }
    var content: Data
    var isJSON: Bool

    init(content: Data, isJSON: Bool) {
        self.content = content
        self.isJSON = isJSON
    }

    init(configuration: ReadConfiguration) throws {
        content = try configuration.file.regularFileContents ?? Data()
        isJSON = configuration.contentType == .json
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: content)
    }
}

// MARK: - App Logs View
struct AppLogsView: View {
    @StateObject private var logManager = AppLogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogEntry.LogLevel?
    @State private var selectedCategory: String?
    @State private var showFilters = false
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var autoScroll = true
    @State private var showingExporter = false
    @State private var exportDocument: LogDocument?
    @Environment(\.colorScheme) var colorScheme

    var filteredLogs: [LogEntry] {
        logManager.filteredLogs(searchText: searchText, level: selectedLevel, category: selectedCategory)
    }

    var body: some View {
        ZStack {
            // Modern Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 16, weight: .medium))

                        TextField("Search Logs", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16, weight: .medium))

                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(colorScheme == .dark ? 0.1 : 0.3), lineWidth: 1)
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
                    VStack(spacing: 24) {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 110, height: 110)

                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

                        VStack(spacing: 12) {
                            Text(logManager.logs.isEmpty ? "No Logs Yet" : "No Matching Logs")
                                .font(.system(.title3, design: .rounded, weight: .bold))

                            if !logManager.logs.isEmpty {
                                Text("We couldn't find any logs matching your search. Try adjusting your filters.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 50)
                            }
                        }
                        Spacer()
                    }
                    .transition(AnyTransition.opacity.combined(with: .scale(0.9)))
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(filteredLogs) { log in
                                    LogEntryRow(entry: log)
                                        .id(log.id)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 16)
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
                    Button(action: shareAsText) {
                        Label("Share As Text", systemImage: "doc.text")
                    }

                    Button(action: shareAsJSON) {
                        Label("Share As JSON", systemImage: "doc.badge.gearshape")
                    }

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
        .sheet(isPresented: $showShareSheet) {
            ActivityViewController(activityItems: [shareText])
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: exportDocument?.isJSON == true ? .json : .plainText,
            defaultFilename: "PortalLogs"
        ) { result in
            switch result {
            case .success(let url):
                logManager.success("Logs exported to \(url.lastPathComponent)", category: "AppLogs")
            case .failure(let error):
                logManager.error("Export failed: \(error.localizedDescription)", category: "AppLogs")
            }
        }
    }

    private func shareAsText() {
        let text = logManager.exportLogs()
        if let data = text.data(using: .utf8) {
            exportDocument = LogDocument(content: data, isJSON: false)
            showingExporter = true
        }
    }

    private func shareAsJSON() {
        if let jsonData = logManager.exportLogsAsJSON() {
            exportDocument = LogDocument(content: jsonData, isJSON: true)
            showingExporter = true
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
                HStack(alignment: .top, spacing: 14) {
                    // Level Indicator Line
                    RoundedRectangle(cornerRadius: 3)
                        .fill(levelColor(entry.level))
                        .frame(width: 5)
                        .padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            HStack(spacing: 6) {
                                Text(entry.level.icon)
                                    .font(.system(size: 12))
                                Text(entry.level.rawValue)
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(levelColor(entry.level))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(levelColor(entry.level).opacity(0.12))
                            .clipShape(Capsule())

                            Text(entry.formattedTimestamp)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(entry.category)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(.secondary.opacity(0.8))
                        }

                        Text(entry.message)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary.opacity(0.9))
                            .lineLimit(isExpanded ? nil : 2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: isExpanded)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .padding(.top, 8)
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal, 12)

                    VStack(alignment: .leading, spacing: 6) {
                        DetailRow(label: "Level", value: entry.level.rawValue)
                        DetailRow(label: "File", value: entry.file)
                        DetailRow(label: "Function", value: entry.function)
                        DetailRow(label: "Line", value: "\(entry.line)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .padding(.top, 4)
                }
                .transition(AnyTransition.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(colorScheme == .dark ? 0.05 : 0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
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
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
