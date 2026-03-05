import SwiftUI

struct RestoreSimulationView: View {
    @Environment(\.dismiss) private var dismiss
    let snapshotID: String
    let backupMetadata: [String: Any]

    @State private var result: BackupAdvancedManager.SimulationResult?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Running Dry-Run Restore...")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 40)
                } else if let result = result {
                    Section {
                        Label {
                            Text("Simulation runs purely in memory and does not alter your live data.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "info.circle.fill").foregroundStyle(.blue)
                        }
                    }

                    if !result.conflicts.isEmpty {
                        Section {
                            ForEach(result.conflicts, id: \.self) { conflict in
                                Label(conflict, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                            }
                        } header: {
                            Text("Conflicts Detected").foregroundStyle(.red)
                        }
                    }

                    Section {
                        ForEach(result.overwritten, id: \.self) { item in
                            Label(item, systemImage: "arrow.triangle.2.circlepath").foregroundStyle(.orange)
                        }
                    } header: {
                        Text("Items To Be Overwritten")
                    }

                    Section {
                        ForEach(result.removed, id: \.self) { item in
                            Label(item, systemImage: "trash.fill").foregroundStyle(.red)
                        }
                    } header: {
                        Text("Items To Be Removed")
                    }

                    Section {
                        ForEach(result.unchanged, id: \.self) { item in
                            Label(item, systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    } header: {
                        Text("Items Unchanged")
                    }
                }
            }
            .navigationTitle("Restore Simulation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                loadSimulation()
            }
        }
    }

    private func loadSimulation() {
        Task {
            // Simulate processing delay
            try? await Task.sleep(nanoseconds: 800_000_000)
            result = BackupAdvancedManager.shared.simulateRestore(backupMetadata: backupMetadata)
            isLoading = false
        }
    }
}
