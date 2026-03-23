import SwiftUI
import OSLog
import AltSourceKit

struct SourcesAddBulkView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    let sourceURLs: [String]

    @State private var phase: Phase = .processing
    @State private var progress: Double = 0.0
    @State private var processedCount: Int = 0
    @State private var addedCount: Int = 0
    @State private var skippedCount: Int = 0
    @State private var failedCount: Int = 0
    @State private var sourceResults: [SourceResult] = []
    @State private var portalCode: String = ""
    @State private var errorMessage: String?
    @State private var showCopiedFeedback = false

    struct SourceResult: Identifiable {
        let id = UUID()
        let url: String
        let name: String?
        let status: Status

        enum Status {
            case added
            case skipped
            case failed(String)
        }
    }

    enum Phase {
        case processing
        case success
        case error
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    headerSection
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    progressSection
                }

                if phase == .success {
                    successSection
                    sourcesDetailSection
                }

                if phase == .error {
                    errorSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(.localized("Bulk Import"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) { dismiss() }
                }
            }
            .interactiveDismissDisabled(phase == .processing)
            .task {
                await processBulkSources()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: headerIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(headerGradient)
                    .pulseEffect(phase == .processing)
            }
            .padding(.top, 20)

            Text(headerTitle)
                .font(.system(.title2, design: .rounded).bold())

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .animation(.spring(), value: phase)
    }

    private var headerIcon: String {
        switch phase {
        case .processing: return "arrow.triangle.2.circlepath"
        case .success: return "checkmark.seal.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    private var headerGradient: AnyShapeStyle {
        switch phase {
        case .processing: return AnyShapeStyle(Color.accentColor.gradient)
        case .success: return AnyShapeStyle(Color.green.gradient)
        case .error: return AnyShapeStyle(Color.red.gradient)
        }
    }

    private var headerTitle: String {
        switch phase {
        case .processing: return .localized("Processing Sources")
        case .success: return .localized("Import Complete")
        case .error: return .localized("Import Failed")
        }
    }

    private var headerSubtitle: String {
        switch phase {
        case .processing: return .localized("Adding \(sourceURLs.count) sources to Portal...")
        case .success:
            if addedCount > 0 && skippedCount > 0 {
                return .localized("\(addedCount) added, \(skippedCount) already existed.")
            } else if addedCount > 0 {
                return .localized("\(addedCount) sources added to your library.")
            } else {
                return .localized("All sources were already in your library.")
            }
        case .error: return errorMessage ?? .localized("An error occurred during import.")
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(.localized("Progress"))
                    .font(.subheadline.bold())
                Spacer()
                Text("\(processedCount)/\(sourceURLs.count)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(height: 12)

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.gradient)
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 12)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 12)

            if phase == .processing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(.localized("Fetching and adding sources..."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var successSection: some View {
        Group {
            Section {
                Label(.localized("\(addedCount) Sources Added"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

                if skippedCount > 0 {
                    Label(.localized("\(skippedCount) Already Existed"), systemImage: "arrow.uturn.right.circle.fill")
                        .foregroundStyle(.orange)
                }

                if failedCount > 0 {
                    Label(.localized("\(failedCount) Failed"), systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                }
            } header: {
                SettingsSectionHeader(title: .localized("Results"), icon: "list.clipboard.fill")
            }

            if !portalCode.isEmpty {
                Section {
                    Text(portalCode)
                        .font(.system(.caption2, design: .monospaced))
                        .textSelection(.enabled)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemFill).opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.vertical, 8)
                } header: {
                    HStack {
                        Label(.localized("Transfer Code"), systemImage: "key.fill")
                        Spacer()
                        Button {
                            UIPasteboard.general.string = portalCode
                            HapticsManager.shared.success()
                            withAnimation { showCopiedFeedback = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopiedFeedback = false }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                Text(showCopiedFeedback ? .localized("Copied") : .localized("Copy"))
                            }
                            .font(.caption.bold())
                        }
                        .bounceEffect(showCopiedFeedback)
                    }
                }
            }
        }
    }

    private var sourcesDetailSection: some View {
        Section {
            ForEach(sourceResults) { result in
                HStack(spacing: 12) {
                    Image(systemName: statusIcon(for: result.status))
                        .foregroundStyle(statusColor(for: result.status))
                        .font(.body)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.name ?? result.url)
                            .font(.subheadline)
                            .lineLimit(1)

                        if result.name != nil {
                            Text(result.url)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                        }

                        if case .failed(let reason) = result.status {
                            Text(reason)
                                .font(.caption2)
                                .foregroundStyle(.red.opacity(0.8))
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    Text(statusLabel(for: result.status))
                        .font(.caption2.bold())
                        .foregroundStyle(statusColor(for: result.status))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(statusColor(for: result.status).opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.vertical, 4)
            }
        } header: {
            SettingsSectionHeader(title: .localized("Source Details"), icon: "list.bullet.rectangle.fill")
        }
    }

    private func statusIcon(for status: SourceResult.Status) -> String {
        switch status {
        case .added: return "checkmark.circle.fill"
        case .skipped: return "arrow.uturn.right.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }

    private func statusColor(for status: SourceResult.Status) -> Color {
        switch status {
        case .added: return .green
        case .skipped: return .orange
        case .failed: return .red
        }
    }

    private func statusLabel(for status: SourceResult.Status) -> String {
        switch status {
        case .added: return .localized("Added")
        case .skipped: return .localized("Exists")
        case .failed: return .localized("Failed")
        }
    }

    private var errorSection: some View {
        Section {
            Label(errorMessage ?? .localized("Unknown Error"), systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Button {
                withAnimation(.spring()) {
                    phase = .processing
                    progress = 0.0
                    processedCount = 0
                    addedCount = 0
                    skippedCount = 0
                    failedCount = 0
                    portalCode = ""
                    errorMessage = nil
                    sourceResults = []
                }
                Task {
                    await processBulkSources()
                }
            } label: {
                Label(.localized("Retry"), systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        } header: {
            SettingsSectionHeader(title: .localized("Error"), icon: "exclamationmark.octagon.fill")
        }
    }

    @MainActor
    private func processBulkSources() async {
        guard !sourceURLs.isEmpty else {
            errorMessage = .localized("No source URLs provided.")
            withAnimation(.spring()) { phase = .error }
            HapticsManager.shared.error()
            return
        }

        Logger.misc.info("[Bulk Import] Starting bulk import of \(sourceURLs.count) sources")

        var validURLs: [String] = []
        let total = Double(sourceURLs.count)

        for urlString in sourceURLs {
            let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmed.isEmpty, let sourceURL = URL(string: trimmed) else {
                failedCount += 1
                sourceResults.append(SourceResult(url: trimmed, name: nil, status: .failed(.localized("Invalid URL"))))
                processedCount += 1
                withAnimation { progress = Double(processedCount) / total }
                continue
            }

            if Storage.shared.sourceExists(trimmed) {
                skippedCount += 1
                let existingName = Storage.shared.getSources()
                    .first(where: { $0.sourceURL?.absoluteString == trimmed || $0.identifier == trimmed })?
                    .name
                sourceResults.append(SourceResult(url: trimmed, name: existingName, status: .skipped))
                validURLs.append(trimmed)
            } else {
                do {
                    let (data, _) = try await URLSession.shared.data(from: sourceURL)
                    let repository = try JSONDecoder().decode(ASRepository.self, from: data)

                    Storage.shared.addSource(sourceURL, repository: repository, id: trimmed) { _ in }
                    addedCount += 1
                    sourceResults.append(SourceResult(url: trimmed, name: repository.name, status: .added))
                    validURLs.append(trimmed)
                } catch {
                    Logger.misc.error("[Bulk Import] Failed to fetch/validate source: \(trimmed) - \(error.localizedDescription)")
                    failedCount += 1
                    let reason: String
                    if (error as? URLError)?.code == .notConnectedToInternet {
                        reason = .localized("No internet connection")
                    } else if (error as? URLError)?.code == .timedOut {
                        reason = .localized("Request timed out")
                    } else if error is DecodingError {
                        reason = .localized("Not a valid source repository")
                    } else {
                        reason = .localized("Could not reach server")
                    }
                    sourceResults.append(SourceResult(url: trimmed, name: nil, status: .failed(reason)))
                }
            }

            processedCount += 1
            withAnimation { progress = Double(processedCount) / total }

            try? await Task.sleep(nanoseconds: 80_000_000)
        }

        guard !validURLs.isEmpty else {
            errorMessage = .localized("No valid source URLs could be added.")
            withAnimation(.spring()) { phase = .error }
            HapticsManager.shared.error()
            return
        }

        let code = PortalSourceExport.encode(urls: validURLs)
        guard !code.isEmpty else {
            errorMessage = .localized("Failed to generate Portal Transfer code.")
            withAnimation(.spring()) { phase = .error }
            HapticsManager.shared.error()
            return
        }

        portalCode = code
        Logger.misc.info("[Bulk Import] Generated Portal code for \(validURLs.count) sources")

        withAnimation(.spring()) { phase = .success }
        HapticsManager.shared.success()
    }
}
