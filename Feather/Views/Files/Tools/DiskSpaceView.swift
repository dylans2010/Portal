import SwiftUI
import Foundation

struct DiskSpaceView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @State private var totalSpace: Int64 = 0
    @State private var freeSpace: Int64 = 0
    @State private var usedSpace: Int64 = 0

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text(.localized("Storage Info")).themedText(.header)) {
                    StorageRow(label: .localized("Total"), value: totalSpace, color: .gray)
                    StorageRow(label: .localized("Free"), value: freeSpace, color: .green)
                    StorageRow(label: .localized("Used"), value: usedSpace, color: .blue)
                }

                Section {
                    let usedPercent = totalSpace > 0 ? Double(usedSpace) / Double(totalSpace) : 0
                    VStack {
                        ProgressView(value: usedPercent)
                            .tint(themeManager.accentColor)
                        Text("\(Int(usedPercent * 100))% used")
                            .font(.caption)
                            .themedText(.secondary)
                    }
                }
            }
            .globalTheme()
            .navigationTitle(.localized("Disk Space"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                load()
            }
        }
    }

    private func load() {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory())
        do {
            let resourceValues = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            totalSpace = Int64(resourceValues.volumeTotalCapacity ?? 0)
            freeSpace = Int64(resourceValues.volumeAvailableCapacity ?? 0)
            usedSpace = totalSpace - freeSpace
        } catch {
            print("Error: \(error)")
        }
    }
}

struct StorageRow: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let label: String
    let value: Int64
    let color: Color

    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .themedText(.primary)
            Spacer()
            Text(ByteCountFormatter.string(fromByteCount: value, countStyle: .file))
                .font(.system(.body, design: .monospaced))
                .themedText(.secondary)
        }
    }
}
