import SwiftUI

struct JSONFormatterView: View {
    @State private var jsonInput: String = ""
    @State private var jsonOutput: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(.localized("Input JSON"))
                        .font(.headline)
                    TextEditor(text: $jsonInput)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxHeight: .infinity)
                        .padding(4)
                        .background(Color.clear)
                        .cornerRadius(8)
                }

                HStack {
                    Button {
                        format(beautify: true)
                    } label: {
                        Text(.localized("Beautify"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        format(beautify: false)
                    } label: {
                        Text(.localized("Minify"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text(.localized("Output"))
                            .font(.headline)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = jsonOutput
                            HapticsManager.shared.success()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }

                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    ScrollView {
                        Text(jsonOutput)
                            .font(.system(.caption, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(4)
                    }
                    .frame(maxHeight: .infinity)
                    .background(Color.clear)
                    .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle(.localized("JSON Formatter"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func format(beautify: Bool) {
        errorMessage = nil
        guard let data = jsonInput.data(using: .utf8) else {
            errorMessage = "Invalid encoding"
            return
        }

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let options: JSONSerialization.WritingOptions = beautify ? [.prettyPrinted] : []
            let outputData = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
            jsonOutput = String(data: outputData, encoding: .utf8) ?? ""
            HapticsManager.shared.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticsManager.shared.error()
        }
    }
}
