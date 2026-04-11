import SwiftUI
import NimbleViews

struct PairedDevicesView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager

    @State private var records: [PairRecord] = []
    @State private var selectedRecord: PairRecord?
    @State private var showClearConfirm = false

    // MARK: - Body

    var body: some View {
        ZStack {
            themeManager.appBackgroundColor.ignoresSafeArea()

            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(records) { record in
                        deviceRow(record)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    selectedRecord = selectedRecord?.id == record.id ? nil : record
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    withAnimation {
                                        PairHistoryStore.shared.delete(id: record.id)
                                        records = PairHistoryStore.shared.allRecords()
                                    }
                                } label: {
                                    Label(.localized("Remove"), systemImage: "trash")
                                }
                            }
                    }

                    Section {
                        Text(.localized("Paired device history is automatically removed after 7 days."))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle(.localized("Paired Devices"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !records.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label(.localized("Clear All"), systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            .localized("Remove All Paired Devices?"),
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button(.localized("Remove All"), role: .destructive) {
                withAnimation {
                    PairHistoryStore.shared.purgeAll()
                    records = []
                }
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
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "personalhotspot")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.accentColor.opacity(0.6))
            }

            VStack(spacing: 8) {
                Text(.localized("No Devices Found"))
                    .font(.title3.bold())

                Text(.localized("Devices you've paired with will appear here for 7 days after pairing."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - Device Row

    @ViewBuilder
    private func deviceRow(_ record: PairRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row header
            HStack(spacing: 12) {
                deviceIcon(for: record)

                VStack(alignment: .leading, spacing: 3) {
                    Text(record.deviceName.isEmpty
                         ? .localized("Unknown Device")
                         : record.deviceName)
                        .font(.headline)
                        .foregroundStyle(themeManager.primaryTextColor)

                    Text(record.formattedDate)
                        .font(.caption)
                        .foregroundStyle(themeManager.secondaryTextColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    roleBadge(for: record)

                    Image(systemName: selectedRecord?.id == record.id
                          ? "chevron.up"
                          : "chevron.down")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }
            .padding(.vertical, 10)

            // Expandable detail section
            if selectedRecord?.id == record.id {
                detailSection(for: record)
                    .transition(.asymmetric(
                        insertion: .push(from: .top).combined(with: .opacity),
                        removal: .push(from: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .listRowBackground(themeManager.cardBackgroundColor)
    }

    // MARK: - Device Icon

    private func deviceIcon(for record: PairRecord) -> some View {
        ZStack {
            Circle()
                .fill(record.wasHost
                      ? Color.blue.opacity(0.12)
                      : Color.green.opacity(0.12))
                .frame(width: 44, height: 44)
            Image(systemName: record.wasHost
                  ? "arrow.up.circle.fill"
                  : "arrow.down.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(record.wasHost ? .blue : .green)
        }
    }

    // MARK: - Role Badge

    private func roleBadge(for record: PairRecord) -> some View {
        Text(record.wasHost ? .localized("Sent") : .localized("Received"))
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(record.wasHost
                          ? Color.blue.opacity(0.12)
                          : Color.green.opacity(0.12))
            )
            .foregroundStyle(record.wasHost ? .blue : .green)
    }

    // MARK: - Detail Section

    private func detailSection(for record: PairRecord) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.vertical, 10)
                .opacity(0.3)

            // Section title
            Text(.localized("Full Mirror Data"))
                .font(.caption.weight(.semibold))
                .foregroundStyle(themeManager.accentColor)
                .textCase(.uppercase)
                .padding(.bottom, 12)

            // Stat grid (2 columns)
            let stats = statsForRecord(record)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(stats, id: \.label) { stat in
                    statCard(stat)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(.localized("This transfer included a complete mirror of this device's environment, including all configuration and application data."))
                    .font(.caption2)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .padding(.top, 12)
            }
        }
        .padding(.bottom, 12)
    }

    // MARK: - Stat Card

    private struct StatItem {
        let icon: String
        let color: Color
        let label: String
        let value: String
    }

    private func statCard(_ stat: StatItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: stat.icon)
                .font(.system(size: 15))
                .foregroundStyle(stat.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(stat.value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(themeManager.primaryTextColor)
                Text(stat.label)
                    .font(.caption2)
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(themeManager.cardBackgroundColor.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(themeManager.secondaryTextColor.opacity(0.1), lineWidth: 1)
        )
    }

    private func statsForRecord(_ record: PairRecord) -> [StatItem] {
        var items: [StatItem] = []

        if record.certificatesCount > 0 {
            items.append(StatItem(
                icon: "checkmark.seal.fill", color: .blue,
                label: .localized("Certificates"),
                value: "\(record.certificatesCount)"
            ))
        }
        if record.sourcesCount > 0 {
            items.append(StatItem(
                icon: "globe", color: .purple,
                label: .localized("Sources"),
                value: "\(record.sourcesCount)"
            ))
        }
        if record.signedAppsCount > 0 {
            items.append(StatItem(
                icon: "app.badge.fill", color: .green,
                label: .localized("Signed Apps"),
                value: "\(record.signedAppsCount)"
            ))
        }
        if record.importedAppsCount > 0 {
            items.append(StatItem(
                icon: "square.and.arrow.down.fill", color: .orange,
                label: .localized("Imported Apps"),
                value: "\(record.importedAppsCount)"
            ))
        }
        if record.frameworksCount > 0 {
            items.append(StatItem(
                icon: "puzzlepiece.extension.fill", color: .cyan,
                label: .localized("Frameworks"),
                value: "\(record.frameworksCount)"
            ))
        }
        if record.archivesCount > 0 {
            items.append(StatItem(
                icon: "archivebox.fill", color: .indigo,
                label: .localized("Archives"),
                value: "\(record.archivesCount)"
            ))
        }
        if record.settingsIncluded {
            items.append(StatItem(
                icon: "gearshape.2.fill", color: .gray,
                label: .localized("App Settings"),
                value: .localized("Yes")
            ))
        }

        if items.isEmpty {
            items.append(StatItem(
                icon: "questionmark.circle", color: .secondary,
                label: .localized("Details"),
                value: .localized("N/A")
            ))
        }
        return items
    }

}
