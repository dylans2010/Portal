import SwiftUI
import NimbleViews

// MARK: - FileCompareView
struct FileCompareView: View {
    let file1: FileItem
    let file2: FileItem
    @Environment(\.dismiss) var dismiss
    
    @State private var content1: String = ""
    @State private var content2: String = ""
    @State private var differences: [DiffLine] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var showSideBySide: Bool = false
    
    struct DiffLine: Identifiable {
        let id = UUID()
        let lineNumber: Int
        let type: DiffType
        let content1: String?
        let content2: String?
        
        enum DiffType {
            case same
            case added
            case removed
            case changed
        }
    }
    
    var body: some View {
        NBNavigationView(.localized("Compare Files"), displayMode: .inline) {
            VStack(spacing: 0) {
                // File headers with modern icons
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [file1.iconColor.opacity(0.15), file1.iconColor.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: file1.icon)
                                .font(.caption)
                                .foregroundStyle(file1.iconColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(file1.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            if let size = file1.size {
                                Text(size)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(file2.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            if let size = file2.size {
                                Text(size)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [file2.iconColor.opacity(0.15), file2.iconColor.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: file2.icon)
                                .font(.caption)
                                .foregroundStyle(file2.iconColor)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()
                } else {
                    if showSideBySide {
                        sideBySideView
                    } else {
                        unifiedView
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Close")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSideBySide.toggle()
                    } label: {
                        Image(systemName: showSideBySide ? "rectangle.split.1x2" : "rectangle.split.2x1")
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            loadAndCompare()
        }
    }
    
    private var unifiedView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(differences) { diff in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(diff.lineNumber)")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, alignment: .trailing)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            if let content1 = diff.content1 {
                                Text(content1)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(diff.type == .removed || diff.type == .changed ? .red : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(diff.type == .removed || diff.type == .changed ? Color.red.opacity(0.1) : Color.clear)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if let content2 = diff.content2, diff.type != .same {
                                Text(content2)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(diff.type == .added || diff.type == .changed ? .green : .primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(diff.type == .added || diff.type == .changed ? Color.green.opacity(0.1) : Color.clear)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var sideBySideView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(differences) { diff in
                    HStack(alignment: .top, spacing: 0) {
                        // Left side (file 1)
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(diff.lineNumber)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)
                            
                            Text(diff.content1 ?? "")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(diff.type == .removed || diff.type == .changed ? .red : .primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(diff.type == .removed || diff.type == .changed ? Color.red.opacity(0.1) : Color.clear)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        // Right side (file 2)
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(diff.lineNumber)")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)
                            
                            Text(diff.content2 ?? "")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(diff.type == .added || diff.type == .changed ? .green : .primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(diff.type == .added || diff.type == .changed ? Color.green.opacity(0.1) : Color.clear)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private func loadAndCompare() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data1 = try Data(contentsOf: file1.url)
                let data2 = try Data(contentsOf: file2.url)
                
                guard let text1 = String(data: data1, encoding: .utf8),
                      let text2 = String(data: data2, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Unable to decode files as text. Only text files can be compared."
                        self.isLoading = false
                    }
                    return
                }
                
                self.content1 = text1
                self.content2 = text2
                
                let lines1 = text1.components(separatedBy: .newlines)
                let lines2 = text2.components(separatedBy: .newlines)
                
                let diffs = computeDiff(lines1: lines1, lines2: lines2)
                
                DispatchQueue.main.async {
                    self.differences = diffs
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                AppLogManager.shared.error("Failed to compare files: \(error.localizedDescription)", category: "Files")
            }
        }
    }
    
    private func computeDiff(lines1: [String], lines2: [String]) -> [DiffLine] {
        var diffs: [DiffLine] = []
        let maxLines = max(lines1.count, lines2.count)
        
        for i in 0..<maxLines {
            let line1 = i < lines1.count ? lines1[i] : nil
            let line2 = i < lines2.count ? lines2[i] : nil
            
            let type: DiffLine.DiffType
            if line1 == line2 {
                type = .same
            } else if line1 == nil {
                type = .added
            } else if line2 == nil {
                type = .removed
            } else {
                type = .changed
            }
            
            diffs.append(DiffLine(
                lineNumber: i + 1,
                type: type,
                content1: line1,
                content2: line2
            ))
        }
        
        return diffs
    }
}
