import SwiftUI

struct FontBrowserView: View {
    let fileURL: URL
    @State private var fontName: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                if let name = fontName {
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("The quick brown fox jumps over the lazy dog")
                                .font(.custom(name, size: 24))

                            Text("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                                .font(.custom(name, size: 20))

                            Text("abcdefghijklmnopqrstuvwxyz")
                                .font(.custom(name, size: 20))

                            Text("0123456789!@#$%^&*()")
                                .font(.custom(name, size: 20))
                        }
                        .padding()
                    }
                } else if let error = errorMessage {
                    Text(error).foregroundStyle(.red)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(fileURL.lastPathComponent)
            .onAppear {
                loadFont()
            }
        }
    }

    private func loadFont() {
        guard let data = try? Data(contentsOf: fileURL) else {
            errorMessage = "Failed to read file"
            return
        }

        guard let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider) else {
            errorMessage = "Invalid font file"
            return
        }

        var error: Unmanaged<CFError>?
        if CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            if let name = cgFont.postScriptName as String? {
                fontName = name
            } else {
                errorMessage = "Could not get font name"
            }
        } else {
            errorMessage = error?.takeRetainedValue().localizedDescription ?? "Registration failed"
        }
    }
}
