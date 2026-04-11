import SwiftUI
import NimbleViews

// MARK: - Pair Record
/// A single entry in the pairing history.
/// Records are automatically discarded after 7 days.
struct PairRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    let deviceName: String
    let deviceModel: String?
    let osVersion: String?
    let sourcesCount: Int
    let certificatesCount: Int
    let signedAppsCount: Int
    let importedAppsCount: Int
    let frameworksCount: Int
    let archivesCount: Int
    let settingsIncluded: Bool
    /// `true` if this device sent the data (was the host).
    let wasHost: Bool

    var isExpired: Bool {
        Date().timeIntervalSince(date) > 7 * 24 * 60 * 60
    }

    var formattedDate: String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    var totalItemCount: Int {
        sourcesCount + certificatesCount + signedAppsCount + importedAppsCount
    }
}

// MARK: - Pair History Store
/// Persists pairing history records in `UserDefaults`.
/// Expired records (> 7 days) are pruned on every read and write.
final class PairHistoryStore {
    static let shared = PairHistoryStore()
    private let key = "Feather.pairHistory"

    private init() {}

    func allRecords() -> [PairRecord] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let records = try? JSONDecoder().decode([PairRecord].self, from: data)
        else { return [] }
        return records.filter { !$0.isExpired }
    }

    func append(_ record: PairRecord) {
        var records = allRecords()
        records.insert(record, at: 0)
        save(records)
    }

    func delete(id: UUID) {
        var records = allRecords()
        records.removeAll { $0.id == id }
        save(records)
    }

    func purgeAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func save(_ records: [PairRecord]) {
        let fresh = records.filter { !$0.isExpired }
        if let data = try? JSONEncoder().encode(fresh) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

// MARK: - Pair History View
/// Shows every device that has been paired in the last 7 days.
/// Records are grouped by calendar day and auto-deleted after 7 days.
struct PairHistoryView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    @State private var records: [PairRecord] = []
    @State private var showClearConfirm = false

    private var groupedRecords: [(String, [PairRecord])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        var groups: [(String, [PairRecord])] = []
        var seen: [String: Int] = [:]
        for record in records {
            let key = formatter.string(from: record.date)
            if let idx = seen[key] {
                groups[idx].1.append(record)
            } else {
                seen[key] = groups.count
                groups.append((key, [record]))
            }
        }
        return groups
    }

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedRecords, id: \.0) { section in
                        Section {
                            ForEach(section.1) { record in
                                recordRow(record)
                            }
                        } header: {
                            Text(section.0)
                        }
                    }

                    Section {
                        Text(.localized("History is automatically deleted after 7 days."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(.localized("Pair History"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !records.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label(.localized("Clear History"), systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            .localized("Clear All Pair History?"),
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button(.localized("Clear All"), role: .destructive) {
                PairHistoryStore.shared.purgeAll()
                records = []
            }
            Button(.localized("Cancel"), role: .cancel) {}
        } message: {
            Text(.localized("This action cannot be undone."))
        }
        .onAppear {
            records = PairHistoryStore.shared.allRecords()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text(.localized("No Pair History"))
                .font(.title3.bold())
            Text(.localized("Devices you pair with will appear here for 7 days."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    // MARK: - Record Row

    private func recordRow(_ record: PairRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: record.wasHost ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                    .foregroundStyle(record.wasHost ? .blue : .green)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(record.deviceName.isEmpty ? .localized("Unknown Device") : record.deviceName)
                        .font(.headline)
                    Text(record.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(record.wasHost ? .localized("Sent") : .localized("Received"))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(record.wasHost ? Color.blue.opacity(0.15) : Color.green.opacity(0.15))
                    )
                    .foregroundStyle(record.wasHost ? .blue : .green)
            }

            // What was transferred
            let chips = transferChips(for: record)
            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(chips, id: \.label) { chip in
                            HStack(spacing: 4) {
                                Image(systemName: chip.icon)
                                    .font(.caption2)
                                Text(chip.label)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(chip.color.opacity(0.12)))
                            .foregroundStyle(chip.color)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                PairHistoryStore.shared.delete(id: record.id)
                records = PairHistoryStore.shared.allRecords()
            } label: {
                Label(.localized("Delete"), systemImage: "trash")
            }
        }
    }

    // MARK: - Transfer Chips

    struct Chip {
        let icon: String
        let label: String
        let color: Color
    }

    private func transferChips(for record: PairRecord) -> [Chip] {
        var chips: [Chip] = []
        if record.certificatesCount > 0 {
            chips.append(Chip(icon: "checkmark.seal.fill",
                              label: "\(record.certificatesCount) " + .localized("Certs"),
                              color: .blue))
        }
        if record.sourcesCount > 0 {
            chips.append(Chip(icon: "globe",
                              label: "\(record.sourcesCount) " + .localized("Sources"),
                              color: .purple))
        }
        if record.signedAppsCount > 0 {
            chips.append(Chip(icon: "app.badge.fill",
                              label: "\(record.signedAppsCount) " + .localized("Apps"),
                              color: .green))
        }
        if record.importedAppsCount > 0 {
            chips.append(Chip(icon: "square.and.arrow.down.fill",
                              label: "\(record.importedAppsCount) " + .localized("IPA"),
                              color: .orange))
        }
        if record.frameworksCount > 0 {
            chips.append(Chip(icon: "puzzlepiece.extension.fill",
                              label: "\(record.frameworksCount) " + .localized("FW"),
                              color: .cyan))
        }
        if record.settingsIncluded {
            chips.append(Chip(icon: "gearshape.fill",
                              label: .localized("Settings"),
                              color: .gray))
        }
        return chips
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        PairHistoryView()
    }
}
#endif
