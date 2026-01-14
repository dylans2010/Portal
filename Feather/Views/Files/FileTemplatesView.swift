// idk why i have this here but yeah

import SwiftUI
import NimbleViews

struct FileTemplatesView: View {
    let directoryURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTemplate: FileTemplate?
    @State private var fileName: String = ""
    @State private var errorMessage: String?
    
    enum FileTemplate: String, CaseIterable {
        case htmlBasic = "HTML Page"
        case htmlBootstrap = "HTML with Bootstrap"
        case cssBasic = "CSS Stylesheet"
        case jsBasic = "JavaScript"
        case pythonBasic = "Python Script"
        case swiftBasic = "Swift File"
        case jsonConfig = "JSON Configuration"
        case yamlConfig = "YAML Configuration"
        case markdownDoc = "Markdown Document"
        case gitignore = "Gitignore"
        case readme = "README"
        case license = "MIT License"
        
        var defaultFileName: String {
            switch self {
            case .htmlBasic, .htmlBootstrap: return "index.html"
            case .cssBasic: return "style.css"
            case .jsBasic: return "script.js"
            case .pythonBasic: return "script.py"
            case .swiftBasic: return "MyFile.swift"
            case .jsonConfig: return "config.json"
            case .yamlConfig: return "config.yaml"
            case .markdownDoc: return "document.md"
            case .gitignore: return ".gitignore"
            case .readme: return "README.md"
            case .license: return "LICENSE"
            }
        }
        
        var icon: String {
            switch self {
            case .htmlBasic, .htmlBootstrap: return "chevron.left.forwardslash.chevron.right"
            case .cssBasic: return "paintbrush.fill"
            case .jsBasic: return "curlybraces"
            case .pythonBasic: return "chevron.left.forwardslash.chevron.right"
            case .swiftBasic: return "swift"
            case .jsonConfig: return "curlybraces"
            case .yamlConfig: return "doc.text"
            case .markdownDoc: return "doc.plaintext"
            case .gitignore: return "eye.slash"
            case .readme: return "book"
            case .license: return "doc.text.fill"
            }
        }
        
        var content: String {
            switch self {
            case .htmlBasic:
                return """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>My Page</title>
                </head>
                <body>
                    <h1>Hello, World!</h1>
                    <p>This is a basic HTML page.</p>
                </body>
                </html>
                """
            case .htmlBootstrap:
                return """
                <!DOCTYPE html>
                <html lang="en">
                <head>
                    <meta charset="UTF-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Bootstrap Page</title>
                    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
                </head>
                <body>
                    <div class="container mt-5">
                        <h1 class="display-4">Hello, Bootstrap!</h1>
                        <p class="lead">This is a Bootstrap-enabled page.</p>
                    </div>
                    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
                </body>
                </html>
                """
            case .cssBasic:
                return """
                /* Basic CSS Stylesheet */
                
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    line-height: 1.6;
                    color: #333;
                }
                
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 20px;
                }
                """
            case .jsBasic:
                return """
                // JavaScript File
                
                'use strict';
                
                // Main function
                function main() {
                    console.log('Hello, JavaScript!');
                }
                
                // Run when DOM is ready
                document.addEventListener('DOMContentLoaded', main);
                """
            case .pythonBasic:
                return """
                #!/usr/bin/env python3
                # -*- coding: utf-8 -*-
                
                \"\"\"
                Python Script
                \"\"\"
                
                def main():
                    print("Hello, Python!")
                
                if __name__ == "__main__":
                    main()
                """
            case .swiftBasic:
                return """
                import Foundation
                
                // MARK: - MyFile
                
                struct MyStruct {
                    let name: String
                    
                    func greet() {
                        print("Hello, \\(name)!")
                    }
                }
                """
            case .jsonConfig:
                return """
                {
                  "name": "my-project",
                  "version": "1.0.0",
                  "description": "Project description",
                  "settings": {
                    "debug": false,
                    "timeout": 30
                  }
                }
                """
            case .yamlConfig:
                return """
                # YAML Configuration
                name: my-project
                version: 1.0.0
                description: Project description
                
                settings:
                  debug: false
                  timeout: 30
                """
            case .markdownDoc:
                return """
                # Document Title
                
                ## Introduction
                
                This is a markdown document.
                
                ## Features
                
                - Feature 1
                - Feature 2
                - Feature 3
                
                ## Usage
                
                ```bash
                # Example command
                echo "Hello, World!"
                ```
                
                ## License
                
                MIT License
                """
            case .gitignore:
                return """
                # macOS
                .DS_Store
                .AppleDouble
                .LSOverride
                
                # Xcode
                build/
                DerivedData/
                *.xcuserstate
                *.xcworkspace/xcuserdata/
                
                # Swift Package Manager
                .build/
                Packages/
                
                # Dependencies
                node_modules/
                vendor/
                
                # IDE
                .vscode/
                .idea/
                """
            case .readme:
                return """
                # Project Name
                
                Brief description of your project.
                
                ## Features
                
                - Feature 1
                - Feature 2
                
                ## Installation
                
                ```bash
                # Installation instructions
                ```
                
                ## Usage
                
                ```bash
                # Usage examples
                ```
                
                ## Contributing
                
                Contributions are welcome!
                
                ## License
                
                MIT License
                """
            case .license:
                return """
                MIT License
                
                Copyright (c) \(Calendar.current.component(.year, from: Date())) [Your Name]
                
                Permission is hereby granted, free of charge, to any person obtaining a copy
                of this software and associated documentation files (the "Software"), to deal
                in the Software without restriction, including without limitation the rights
                to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
                copies of the Software, and to permit persons to whom the Software is
                furnished to do so, subject to the following conditions:
                
                The above copyright notice and this permission notice shall be included in all
                copies or substantial portions of the Software.
                
                THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
                IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
                FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
                AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
                LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
                OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
                SOFTWARE.
                """
            }
        }
    }
    
    var body: some View {
        NBNavigationView(.localized("File Templates"), displayMode: .inline) {
            Form {
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
                    ForEach(FileTemplate.allCases, id: \.self) { template in
                        Button {
                            selectedTemplate = template
                            fileName = template.defaultFileName
                        } label: {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)
                                
                                Text(template.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if selectedTemplate == template {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text(.localized("Select Template"))
                }
                
                if selectedTemplate != nil {
                    Section {
                        TextField(.localized("File Name"), text: $fileName)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } header: {
                        Text(.localized("File Name"))
                    } footer: {
                        Text(.localized("Enter a name for the new file"))
                    }
                    
                    Section {
                        Button {
                            createFile()
                        } label: {
                            HStack {
                                Spacer()
                                Text(.localized("Create File"))
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        .disabled(fileName.isEmpty)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createFile() {
        guard let template = selectedTemplate, !fileName.isEmpty else { return }
        
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        // Check if file already exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            errorMessage = String(localized: "A file with this name already exists")
            HapticsManager.shared.error()
            return
        }
        
        do {
            try template.content.write(to: fileURL, atomically: true, encoding: .utf8)
            HapticsManager.shared.success()
            FileManagerService.shared.loadFiles()
            dismiss()
        } catch {
            errorMessage = String(localized: "Failed to create file") + ": \(error.localizedDescription)"
            HapticsManager.shared.error()
            AppLogManager.shared.error("Failed to create file from template: \(error.localizedDescription)", category: "Files")
        }
    }
}
