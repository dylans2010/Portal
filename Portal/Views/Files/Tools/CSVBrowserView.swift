import SwiftUI

struct CSVBrowserView: View {
    let fileURL: URL
    @State private var rows: [[String]] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error = errorMessage {
                    Text(error).foregroundStyle(.red)
                } else {
                    ScrollView([.horizontal, .vertical]) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<rows.count, id: \.self) { rowIndex in
                                HStack(spacing: 0) {
                                    ForEach(0..<rows[rowIndex].count, id: \.self) { colIndex in
                                        Text(rows[rowIndex][colIndex])
                                            .padding(8)
                                            .frame(width: 120, height: 40, alignment: .leading)
                                            .border(Color.gray.opacity(0.3), width: 0.5)
                                            .background(rowIndex == 0 ? Color.gray.opacity(0.2) : Color.clear)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(fileURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadCSV()
            }
        }
    }

    private func loadCSV() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let parsedRows = content.components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
                    .map { $0.components(separatedBy: ",") }

                DispatchQueue.main.async {
                    self.rows = parsedRows
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}
