import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication
import OSLog
import CoreData

struct NetworkInspectorView: View {
    var body: some View {
        List {
            Text("No Active Requests")
                .foregroundStyle(.secondary)
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Network Inspector")
    }
}

struct FileSystemBrowserView: View {
    var body: some View {
        List {
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                Text(documentsPath.path)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text("Documents")
            Text("Library")
            Text("tmp")
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("File System")
    }
}

struct UserDefaultsEditorView: View {
    var body: some View {
        List {
            ForEach(Array(UserDefaults.standard.dictionaryRepresentation().keys.sorted()), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.caption.monospaced())
                    Spacer()
                    Text("\(String(describing: UserDefaults.standard.object(forKey: key) ?? "nil"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("UserDefaults")
    }
}
