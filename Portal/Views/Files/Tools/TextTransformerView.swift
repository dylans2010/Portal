import SwiftUI

struct TextTransformerView: View {
    @State private var inputText: String = ""
    @State private var outputText: String = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $inputText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxHeight: .infinity)
                    .border(Color.secondary.opacity(0.2))
                    .cornerRadius(8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button("UPPERCASE") { outputText = inputText.uppercased() }
                        Button("lowercase") { outputText = inputText.lowercased() }
                        Button("Title Case") { outputText = inputText.capitalized }
                        Button("Base64 Enc") { outputText = inputText.data(using: .utf8)?.base64EncodedString() ?? "" }
                        Button("Base64 Dec") {
                            if let data = Data(base64Encoded: inputText) {
                                outputText = String(data: data, encoding: .utf8) ?? "Invalid UTF8"
                            } else {
                                outputText = "Invalid Base64"
                            }
                        }
                        Button("URL Enc") { outputText = inputText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "" }
                        Button("URL Dec") { outputText = inputText.removingPercentEncoding ?? "" }
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading) {
                    HStack {
                        Text(.localized("Output"))
                            .font(.headline)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = outputText
                            HapticsManager.shared.success()
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }

                    TextEditor(text: .constant(outputText))
                        .font(.system(.body, design: .monospaced))
                        .frame(maxHeight: .infinity)
                        .border(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle(.localized("Text Transformer"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
