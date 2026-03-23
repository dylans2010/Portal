import SwiftUI

struct GoToPathView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var path: String = ""
    @Environment(\.dismiss) var dismiss
    let onGo: (URL) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(.localized("Enter Path")).themedText(.header)) {
                    TextField(.localized("/var/mobile/..."), text: $path)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section {
                    Button(.localized("Go")) {
                        let url = URL(fileURLWithPath: path)
                        onGo(url)
                        dismiss()
                    }
                    .disabled(path.isEmpty)
                }
            }
            .globalTheme()
            .navigationTitle(.localized("Go To Path"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) { dismiss() }
                }
            }
        }
    }
}
