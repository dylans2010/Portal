import SwiftUI
import NimbleViews

struct HexEditorView: View {
    @Environment(\.dismiss) var dismiss
    let fileURL: URL
    
    @State private var hexContent: String = ""
    @State private var isLoading: Bool = true
    
    var body: some View {
        NBNavigationView(.localized("Hex Editor"), displayMode: .inline) {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if isLoading {
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "0.square.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color.purple, Color.purple.opacity(0.7)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                            .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text(.localized("Loading file..."))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 40)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                // File info header with modern styling
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [Color.purple.opacity(0.15), Color.purple.opacity(0.08)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 48, height: 48)
                                        
                                        Image(systemName: "0.square.fill")
                                            .font(.title3)
                                            .foregroundStyle(
                                                LinearGradient(
                                                    colors: [Color.purple, Color.purple.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                    }
                                    .shadow(color: Color.purple.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(fileURL.lastPathComponent)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text("\(hexContent.split(separator: "\n").count) lines")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                                )
                                .padding()
                                
                                // Hex content
                                Text(hexContent)
                                    .font(.system(.caption, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadHexContent()
        }
    }
    
    private func loadHexContent() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let hex = formatHexDump(data: data)
                
                DispatchQueue.main.async {
                    self.hexContent = hex
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.hexContent = "Error loading file: \(error.localizedDescription)"
                    self.isLoading = false
                }
                AppLogManager.shared.error("Failed to load file for hex editor: \(error.localizedDescription)", category: "Files")
            }
        }
    }
    
    private func formatHexDump(data: Data) -> String {
        var result = ""
        let bytesPerLine = 16
        
        for offset in stride(from: 0, to: data.count, by: bytesPerLine) {
            // Offset
            result += String(format: "%08X  ", offset)
            
            // Hex bytes
            for i in 0..<bytesPerLine {
                let index = offset + i
                if index < data.count {
                    result += String(format: "%02X ", data[index])
                } else {
                    result += "   "
                }
                
                if i == 7 {
                    result += " "
                }
            }
            
            result += " |"
            
            // ASCII representation
            for i in 0..<bytesPerLine {
                let index = offset + i
                if index < data.count {
                    let byte = data[index]
                    if byte >= 32 && byte <= 126 {
                        result += String(format: "%c", byte)
                    } else {
                        result += "."
                    }
                } else {
                    result += " "
                }
            }
            
            result += "|\n"
        }
        
        return result
    }
}
