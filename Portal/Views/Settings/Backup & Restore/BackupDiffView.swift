import SwiftUI

struct BackupDiffView: View {
    @Environment(\.dismiss) private var dismiss
    let snapshotID: String
    let backupMetadata: [String: Any]

    @State private var diffItems: [BackupAdvancedManager.DiffItem] = []
    @State private var isLoading = true
    @State private var selectedCategory: String?

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Comparing Snapshots...")
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        HStack(spacing: 20) {
                            statView(title: "Added", count: diffItems.filter { $0.status == .added }.count, color: .green)
                            statView(title: "Removed", count: diffItems.filter { $0.status == .removed }.count, color: .red)
                            statView(title: "Modified", count: diffItems.filter { $0.status == .modified }.count, color: .orange)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } header: {
                        Text("Change Summary")
                    }

                    let categories = Array(Set(diffItems.map { $0.category })).sorted()
                    ForEach(categories, id: \.self) { category in
                        Section {
                            DisclosureGroup {
                                let items = diffItems.filter { $0.category == category }
                                ForEach(items) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .font(.subheadline)
                                            Text(item.category)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(item.status.rawValue)
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(item.status.color.opacity(0.1))
                                            .foregroundStyle(item.status.color)
                                            .clipShape(Capsule())
                                    }
                                    .padding(.vertical, 2)
                                }
                            } label: {
                                HStack {
                                    Text(category)
                                        .font(.headline)
                                    Spacer()
                                    Text("\(diffItems.filter { $0.category == category }.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Differences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                loadDiff()
            }
        }
    }

    private func statView(title: String, count: Int, color: Color) -> some View {
        VStack {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func loadDiff() {
        Task {
            // Simulate comparison delay
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Actually load current state metadata
            let currentMetadata = BackupAdvancedManager.shared.getCurrentStateMetadata()

            diffItems = BackupAdvancedManager.shared.compareBackups(currentMetadata: currentMetadata, backupMetadata: backupMetadata)
            isLoading = false
        }
    }
}
