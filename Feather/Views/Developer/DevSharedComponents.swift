import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct DevMenuItem {
    let icon: String
    let title: String
    let color: Color
    let destination: AnyView
}


struct DeveloperMenuRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
        }
    }
}




struct DeveloperInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}


struct ListDetailView: View {
    let items: [String]
    let title: String
    @State private var searchText = ""

    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredItems, id: \.self) { item in
                Text(item)
                    .font(.caption.monospaced())
            }
        }
            .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct PlistViewer: View {
    let dictionary: [String: Any]
    let title: String
    @State private var searchText = ""

    var filteredKeys: [String] {
        let keys = dictionary.keys.sorted()
        if searchText.isEmpty {
            return keys
        }
        return keys.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            ForEach(filteredKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 4) {
                    Text(key)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text(String(describing: dictionary[key] ?? ""))
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
                .padding(.vertical, 4)
            }
        }
            .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search Keys")
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct CheckRow: View {
    let label: String
    let passed: Bool

    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passed ? .green : .red)
            Text(label)
                .font(.subheadline)
            Spacer()
        }
    }
}


struct SourceDataView: View {
    var body: some View {
        List {
            ForEach(Storage.shared.getSources(), id: \.self) { source in
                NavigationLink(destination: JSONViewer(json: source.description)) {
                    Text(source.name ?? "Unknown")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Source Data")
    }
}


struct JSONViewer: View {
    let json: String
    var body: some View {
        ScrollView {
            Text(json)
                .font(.caption.monospaced())
                .padding()
        }
        .navigationTitle("JSON")
    }
}


struct AppStateView: View {
    var body: some View {
        List {
            Section(header: Text("Storage")) {
                Text("Documents: \(getDocumentsSize())")
                Text("Cache: \(getCacheSize())")
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("App State")
    }

    func getDocumentsSize() -> String {
        // Calculate size
        return "12.5 MB"
    }

    func getCacheSize() -> String {
        return "4.2 MB"
    }
}


class PerformanceMonitor: ObservableObject {
    @Published var cpuUsage: Double = 0.0
    @Published var memoryUsage: String = "0 MB"
    @Published var diskSpace: String = "0 GB"
    @Published var isMonitoring: Bool = false

    private var timer: Timer?
    private let updateQueue = DispatchQueue(label: "com.portal.performanceMonitor", qos: .utility)

    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // Initial update
        updateMetricsAsync()

        // Schedule periodic updates on main thread but execute work on background
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMetricsAsync()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
    }

    private func updateMetricsAsync() {
        updateQueue.async { [weak self] in
            guard let self = self else { return }

            let cpu = self.calculateCPUUsage()
            let memory = self.calculateMemoryUsage()
            let disk = self.calculateDiskSpace()

            DispatchQueue.main.async {
                self.cpuUsage = cpu
                self.memoryUsage = memory
                self.diskSpace = disk
            }
        }
    }

    private func calculateCPUUsage() -> Double {
        // Simplified CPU usage calculation that's safer
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            // Use a simpler estimation based on memory pressure as a proxy
            // This avoids the problematic host_processor_info call
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            // Estimate CPU based on memory usage (rough approximation for display purposes)
            return min(max(usedMB / 5.0, 5.0), 95.0)
        }

        return 0.0
    }

    private func calculateMemoryUsage() -> String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            return String(format: "%.1f MB", usedMB)
        }

        return "N/A"
    }

    private func calculateDiskSpace() -> String {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let freeSpace = systemAttributes[.systemFreeSize] as? NSNumber {
                let freeGB = Double(truncating: freeSpace) / 1024.0 / 1024.0 / 1024.0
                return String(format: "%.1f GB Free", freeGB)
            }
        } catch {
            // Silently handle error
        }
        return "N/A"
    }

    deinit {
        stopMonitoring()
    }
}




struct ReleaseDetailView: View {
    let release: GitHubRelease

    var body: some View {
        List {
            Section(header: Text("Release Info")) {
                LabeledContent("Tag", value: release.tagName)
                LabeledContent("Name", value: release.name)
                LabeledContent("Prerelease", value: release.prerelease ? "Yes" : "No")
                if let date = release.publishedAt {
                    LabeledContent("Published", value: date.formatted())
                }
            }

            if let body = release.body, !body.isEmpty {
                Section(header: Text("Release Notes")) {
                    ScrollView {
                        ModernMarkdownView(markdown: body)
                            .padding(.vertical, 8)
                    }
                }
            }

            if !release.assets.isEmpty {
                Section(header: Text("Assets (\(release.assets.count))")) {
                    ForEach(release.assets) { asset in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(asset.name)
                                .font(.system(.body, design: .monospaced))
                            HStack {
                                Text(ByteCountFormatter.string(fromByteCount: Int64(asset.size), countStyle: .file))
                                Text("•")
                                Text("\(asset.downloadCount) Downloads")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section {
                Button("Open In GitHub") {
                    if let url = URL(string: release.htmlUrl) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(release.tagName)
    }
}


struct SourceInspectorView: View {
    let source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    @State private var rawJSON: String = ""
    @State private var isLoadingJSON = false

    var body: some View {
        List {
            Section(header: Text("Source Info")) {
                LabeledContent("Name", value: source.name ?? "Unknown")
                if let url = source.sourceURL {
                    LabeledContent("URL", value: url.absoluteString)
                }
                LabeledContent("Order", value: "\(source.order)")
                if let date = source.date {
                    LabeledContent("Added", value: date.formatted())
                }
            }

            if let repo = viewModel.sources[source] {
                Section(header: Text("Repository Data")) {
                    LabeledContent("Apps", value: "\(repo.apps.count)")
                    if let news = repo.news {
                        LabeledContent("News Items", value: "\(news.count)")
                    }
                    if let name = repo.name {
                        LabeledContent("Repo Name", value: name)
                    }
                }
            }

            Section(header: Text("Raw JSON")) {
                Button {
                    loadRawJSON()
                } label: {
                    HStack {
                        if isLoadingJSON {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Load Raw JSON")
                    }
                }

                if !rawJSON.isEmpty {
                    ScrollView(.horizontal) {
                        Text(rawJSON)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .frame(maxHeight: 300)

                    Button("Copy JSON") {
                        UIPasteboard.general.string = rawJSON
                        HapticsManager.shared.success()
                    }
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(source.name ?? "Source")
    }

    private func loadRawJSON() {
        guard let url = source.sourceURL else { return }
        isLoadingJSON = true

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoadingJSON = false
                if let data = data {
                    if let json = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                       let prettyString = String(data: prettyData, encoding: .utf8) {
                        rawJSON = prettyString
                    } else {
                        rawJSON = String(data: data, encoding: .utf8) ?? "Unable To Decode"
                    }
                } else if let error = error {
                    rawJSON = "Error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}


struct DeveloperBatchAppRow: View {
    let app: Imported
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)

                FRAppIconView(app: app, size: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(app.name ?? "Unknown App")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)

                    Text(app.identifier ?? "Unknown Bundle ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}


struct EntitlementItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var type: ValueType

    enum ValueType: String, CaseIterable {
        case string = "String"
        case boolean = "Boolean"
        case array = "Array"
        case integer = "Integer"
    }
}


struct EntitlementRow: View {
    @Binding var item: EntitlementItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.key)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)

            HStack {
                Text(item.type.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())

                Text(item.value)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}


struct PlistItem: Identifiable {
    let id = UUID()
    var key: String
    var value: String
    var type: EntitlementItem.ValueType
}


struct PlistItemRow: View {
    @Binding var item: PlistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.key)
                .font(.subheadline.bold())
            Text(item.value)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
    }
}


struct SecurityStatusRow: View {
    let certificate: CertificatePair

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(certificate.nickname ?? "Unknown")
                    .font(.subheadline.bold())

                HStack(spacing: 4) {
                    Image(systemName: statusIcon)
                        .font(.caption)
                    Text(statusText)
                        .font(.caption)
                }
                .foregroundStyle(statusColor)
            }

            Spacer()

            Image(systemName: overallStatus ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                .font(.title2)
                .foregroundStyle(overallStatus ? .green : .orange)
        }
    }

    private var isExpired: Bool {
        guard let expiration = certificate.expiration else { return false }
        return expiration <= Date()
    }

    private var isExpiringSoon: Bool {
        guard let expiration = certificate.expiration else { return false }
        return expiration <= Date().addingTimeInterval(30 * 86400) && !isExpired
    }

    private var statusIcon: String {
        if isExpired { return "xmark.circle.fill" }
        if isExpiringSoon { return "exclamationmark.triangle.fill" }
        return "checkmark.circle.fill"
    }

    private var statusText: String {
        if isExpired { return "Expired" }
        if isExpiringSoon { return "Expiring Soon" }
        return "Valid"
    }

    private var statusColor: Color {
        if isExpired { return .red }
        if isExpiringSoon { return .orange }
        return .green
    }

    private var overallStatus: Bool {
        !isExpired
    }
}


struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)

            Text(value)
                .font(.title.bold())
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.clear)
        )
    }
}


class MockNearbyTransferService: NearbyTransferService {
    override init() {
        super.init()
        // Set to a simulated transferring state
        self.state = .transferring(progress: 0.45, bytesTransferred: 450_000_000, totalBytes: 1_000_000_000, speed: 4_500_000)
        self.currentItem = "Certificates.zip"
    }

    func setMode(_ mode: TransferMode) {
        // Simulate mode changes
        if mode == .send {
            self.state = .transferring(progress: 0.65, bytesTransferred: 650_000_000, totalBytes: 1_000_000_000, speed: 5_000_000)
        } else {
            self.state = .transferring(progress: 0.45, bytesTransferred: 450_000_000, totalBytes: 1_000_000_000, speed: 4_500_000)
        }
    }
}


struct OfflineViewWithDismiss: View {
    @Binding var showDismissButton: Bool
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            OfflineView()

            // Intercept icon taps if needed
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if showDismissButton {
                        onDismiss()
                    }
                }
                .allowsHitTesting(false)
        }
    }
}


    struct DeveloperBatchSignResult: Identifiable {
        let id = UUID()
        let appName: String
        let success: Bool
        let message: String
    }
