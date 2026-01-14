import SwiftUI
import NimbleViews

struct SearchReplaceView: View {
    let fileURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var fileContent: String = ""
    @State private var searchText: String = ""
    @State private var replaceText: String = ""
    @State private var isCaseSensitive: Bool = false
    @State private var useRegex: Bool = false
    @State private var matchCount: Int = 0
    @State private var hasChanges: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NBNavigationView(.localized("Search & Replace"), displayMode: .inline) {
            Form {
                Section {
                    TextField(.localized("Search For..."), text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: searchText) { _ in
                            updateMatchCount()
                        }
                    
                    TextField(.localized("Replace With..."), text: $replaceText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text(.localized("Search & Replace"))
                }
                
                Section {
                    Toggle(.localized("Case Sensitive"), isOn: $isCaseSensitive)
                        .onChange(of: isCaseSensitive) { _ in
                            updateMatchCount()
                        }
                    
                    Toggle(.localized("Use Regular Expression"), isOn: $useRegex)
                        .onChange(of: useRegex) { _ in
                            updateMatchCount()
                        }
                } header: {
                    Text(.localized("Options"))
                }
                
                if matchCount > 0 {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text("\(matchCount) match\(matchCount == 1 ? "" : "es") found")
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    Button {
                        performReplace()
                    } label: {
                        HStack {
                            Spacer()
                            Text(.localized("Replace All"))
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(searchText.isEmpty || matchCount == 0)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
                
                if hasChanges {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(.localized("Save")) {
                            saveChanges()
                        }
                    }
                }
            }
        }
        .onAppear {
            loadFile()
        }
    }
    
    private func loadFile() {
        do {
            let data = try Data(contentsOf: fileURL)
            fileContent = String(data: data, encoding: .utf8) ?? ""
            updateMatchCount()
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }
    
    private func updateMatchCount() {
        guard !searchText.isEmpty else {
            matchCount = 0
            return
        }
        
        if useRegex {
            do {
                let options: NSRegularExpression.Options = isCaseSensitive ? [] : [.caseInsensitive]
                let regex = try NSRegularExpression(pattern: searchText, options: options)
                matchCount = regex.numberOfMatches(in: fileContent, range: NSRange(fileContent.startIndex..., in: fileContent))
                errorMessage = nil
            } catch {
                matchCount = 0
                errorMessage = "Invalid Regular Expression"
            }
        } else {
            let options: String.CompareOptions = isCaseSensitive ? [] : [.caseInsensitive]
            var count = 0
            var searchRange = fileContent.startIndex..<fileContent.endIndex
            
            while let range = fileContent.range(of: searchText, options: options, range: searchRange) {
                count += 1
                searchRange = range.upperBound..<fileContent.endIndex
            }
            
            matchCount = count
            errorMessage = nil
        }
    }
    
    private func performReplace() {
        guard !searchText.isEmpty, matchCount > 0 else { return }
        
        if useRegex {
            do {
                let options: NSRegularExpression.Options = isCaseSensitive ? [] : [.caseInsensitive]
                let regex = try NSRegularExpression(pattern: searchText, options: options)
                let range = NSRange(fileContent.startIndex..., in: fileContent)
                fileContent = regex.stringByReplacingMatches(in: fileContent, range: range, withTemplate: replaceText)
                hasChanges = true
                updateMatchCount()
                HapticsManager.shared.success()
            } catch {
                errorMessage = "Replace Failed: \(error.localizedDescription)"
                HapticsManager.shared.error()
            }
        } else {
            let options: String.CompareOptions = isCaseSensitive ? [] : [.caseInsensitive]
            fileContent = fileContent.replacingOccurrences(of: searchText, with: replaceText, options: options)
            hasChanges = true
            updateMatchCount()
            HapticsManager.shared.success()
        }
    }
    
    private func saveChanges() {
        do {
            guard let data = fileContent.data(using: .utf8) else {
                throw NSError(domain: "SearchReplace", code: -1, userInfo: [NSLocalizedDescriptionKey: String(localized: "Failed to encode content")])
            }
            
            try data.write(to: fileURL, options: .atomic)
            HapticsManager.shared.success()
            hasChanges = false
            dismiss()
        } catch {
            errorMessage = "Save Failed: \(error.localizedDescription)"
            HapticsManager.shared.error()
        }
    }
}
