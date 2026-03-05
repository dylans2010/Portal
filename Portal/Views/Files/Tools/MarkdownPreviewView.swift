import SwiftUI

struct MarkdownPreviewView: View {
    let fileURL: URL
    @State private var content: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if #available(iOS 15.0, *) {
                    Text(LocalizedStringKey(content))
                        .padding()
                } else {
                    Text(content)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(fileURL.lastPathComponent)
        .onAppear {
            content = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
        }
    }
}
