import SwiftUI

struct UUIDGeneratorView: View {
    @State private var count: Int = 1
    @State private var uuids: [String] = [UUID().uuidString]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(.localized("Count: \(count)"), value: $count, in: 1...100)
                    Button(.localized("Generate")) {
                        uuids = (0..<count).map { _ in UUID().uuidString }
                        HapticsManager.shared.impact()
                    }
                }

                Section(header: Text(.localized("Generated UUIDs"))) {
                    ForEach(uuids, id: \.self) { uuid in
                        HStack {
                            Text(uuid)
                                .font(.system(.caption, design: .monospaced))
                            Spacer()
                            Button {
                                UIPasteboard.general.string = uuid
                                HapticsManager.shared.success()
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                    }

                    if uuids.count > 1 {
                        Button(.localized("Copy All")) {
                            UIPasteboard.general.string = uuids.joined(separator: "\n")
                            HapticsManager.shared.success()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("UUID Generator"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
