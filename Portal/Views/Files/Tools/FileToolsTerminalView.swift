import SwiftUI
import UIKit
import NimbleViews

// MARK: - Advanced File Tools Terminal View
struct FileToolsTerminalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("terminal_theme") private var terminalTheme: TerminalTheme = .classic
    @StateObject private var viewModel: TerminalViewModel
    @FocusState private var isInputFocused: Bool

    init(currentDirectory: URL) {
        _viewModel = StateObject(wrappedValue: TerminalViewModel(currentDirectory: currentDirectory))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Terminal Output Area
                outputArea

                // Input Area
                inputArea
            }
            .navigationTitle(.localized("Terminal"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    terminalMenu
                }
            }
            .onAppear {
                isInputFocused = true
            }
        }
    }

    private var outputArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    // Welcome message
                    Text("Portal Terminal v2.0")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)

                    ForEach(viewModel.history) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Text("\(viewModel.currentPathName) $")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(terminalTheme.promptColor)

                                Text(item.command)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(terminalTheme.textColor)
                            }

                            if !item.output.isEmpty {
                                Text(item.output)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(item.isError ? .red : terminalTheme.secondaryTextColor)
                                    .padding(.leading, 12)
                                    .textSelection(.enabled)
                            }
                        }
                        .id(item.id)
                    }
                }
                .padding()
            }
            .background(terminalTheme.backgroundColor)
            .onChange(of: viewModel.history.count) { _ in
                if let last = viewModel.history.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                Text(">")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(terminalTheme.promptColor)

                TextField(.localized("Enter Command"), text: $viewModel.currentInput)
                    .foregroundStyle(terminalTheme.textColor)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .focused($isInputFocused)
                    .onSubmit {
                        viewModel.execute()
                    }

                if !viewModel.currentInput.isEmpty {
                    Button {
                        viewModel.execute()
                    } label: {
                        Image(systemName: "return")
                            .foregroundStyle(terminalTheme.promptColor)
                    }
                }
            }
            .padding()
            .background(terminalTheme.backgroundColor)

            // Command History / Suggestions bar
            if !viewModel.commandHistory.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.commandHistory.reversed().prefix(10), id: \.self) { cmd in
                            Button {
                                viewModel.currentInput = cmd
                            } label: {
                                Text(cmd)
                                    .font(.system(size: 12, design: .monospaced))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(Color.primary.opacity(0.1)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.clear)
            }
        }
    }

    private var terminalMenu: some View {
        Menu {
            Section("File Operations") {
                Button("ls - List Files") { viewModel.currentInput = "ls" }
                Button("pwd - Print Directory") { viewModel.currentInput = "pwd" }
                Button("mkdir - Create Folder") { viewModel.currentInput = "mkdir " }
                Button("touch - Create File") { viewModel.currentInput = "touch " }
            }

            Section("Manipulation") {
                Button("cp - Copy") { viewModel.currentInput = "cp " }
                Button("mv - Move/Rename") { viewModel.currentInput = "mv " }
                Button("rm - Remove") { viewModel.currentInput = "rm " }
                Button("cat - Read File") { viewModel.currentInput = "cat " }
            }

            Section("System Info") {
                Button("neofetch - System Info") { viewModel.currentInput = "neofetch" }
                Button("df - Disk Usage") { viewModel.currentInput = "df" }
                Button("uptime - System Uptime") { viewModel.currentInput = "uptime" }
                Button("uname - OS Name") { viewModel.currentInput = "uname" }
            }

            Section("Utilities") {
                Button("whoami - Current User") { viewModel.currentInput = "whoami" }
                Button("date - Current Date") { viewModel.currentInput = "date" }
                Button("history - Cmd History") { viewModel.currentInput = "history" }
                Button("echo - Print Text") { viewModel.currentInput = "echo " }
            }

            Section("Terminal") {
                Button("clear - Clear Output") { viewModel.executeCommand("clear") }
                Button("help - Show Help") { viewModel.executeCommand("help") }
            }
        } label: {
            Image(systemName: "terminal.fill")
        }
    }
}

// MARK: - Terminal View Model
class TerminalViewModel: ObservableObject {
    @Published var currentInput = ""
    @Published var history: [TerminalEntry] = []
    @Published var commandHistory: [String] = []
    @Published var currentDirectory: URL

    struct TerminalEntry: Identifiable {
        let id = UUID()
        let command: String
        let output: String
        let isError: Bool
    }

    var currentPathName: String {
        currentDirectory.lastPathComponent
    }

    init(currentDirectory: URL) {
        self.currentDirectory = currentDirectory
    }

    func execute() {
        let cmd = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }

        executeCommand(cmd)
        currentInput = ""
    }

    func executeCommand(_ command: String) {
        if command == "clear" {
            history.removeAll()
            return
        }

        if !commandHistory.contains(command) {
            commandHistory.append(command)
        }

        let (output, isError) = executeCommandInternal(command)
        history.append(TerminalEntry(command: command, output: output, isError: isError))
    }

    private func executeCommandInternal(_ command: String) -> (output: String, isError: Bool) {
        let parts = command.split(separator: " ").map(String.init)
        let baseCmd = parts.first?.lowercased() ?? ""
        let args = parts.dropFirst()

        var output = ""
        var isError = false

        switch baseCmd {
        case "ls":
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: currentDirectory, includingPropertiesForKeys: [.isDirectoryKey])
                output = contents.map { url in
                    let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
                    return isDir ? "\(url.lastPathComponent)/" : url.lastPathComponent
                }.sorted().joined(separator: "\n")
            } catch {
                output = error.localizedDescription
                isError = true
            }

        case "pwd":
            output = currentDirectory.path

        case "cd":
            if let path = args.first {
                if path == ".." {
                    currentDirectory = currentDirectory.deletingLastPathComponent()
                    output = "Moved to: \(currentDirectory.lastPathComponent)"
                } else {
                    let newDir = currentDirectory.appendingPathComponent(path)
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: newDir.path, isDirectory: &isDir), isDir.boolValue {
                        currentDirectory = newDir
                        output = "Moved to: \(path)"
                    } else {
                        output = "cd: \(path): No such directory"
                        isError = true
                    }
                }
            }

        case "cat":
            if let path = args.first {
                let fileURL = currentDirectory.appendingPathComponent(path)
                if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                    output = content
                } else {
                    output = "cat: \(path): No such file or unable to read"
                    isError = true
                }
            }

        case "mkdir":
            if let path = args.first {
                let dirURL = currentDirectory.appendingPathComponent(path)
                do {
                    try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: true)
                    output = "Created directory: \(path)"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            }

        case "rm":
            if let path = args.first {
                let fileURL = currentDirectory.appendingPathComponent(path)
                do {
                    try FileManager.default.removeItem(at: fileURL)
                    output = "Removed: \(path)"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            }

        case "touch":
            if let path = args.first {
                let fileURL = currentDirectory.appendingPathComponent(path)
                if FileManager.default.createFile(atPath: fileURL.path, contents: nil) {
                    output = "Created file: \(path)"
                } else {
                    output = "touch: \(path): Failed to create"
                    isError = true
                }
            }

        case "cp":
            if args.count >= 2 {
                let src = currentDirectory.appendingPathComponent(args[0])
                let dst = currentDirectory.appendingPathComponent(args[1])
                do {
                    try FileManager.default.copyItem(at: src, to: dst)
                    output = "Copied \(args[0]) to \(args[1])"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            } else {
                output = "Usage: cp <source> <destination>"
                isError = true
            }

        case "mv":
            if args.count >= 2 {
                let src = currentDirectory.appendingPathComponent(args[0])
                let dst = currentDirectory.appendingPathComponent(args[1])
                do {
                    try FileManager.default.moveItem(at: src, to: dst)
                    output = "Moved/Renamed \(args[0]) to \(args[1])"
                } catch {
                    output = error.localizedDescription
                    isError = true
                }
            } else {
                output = "Usage: mv <source> <destination>"
                isError = true
            }

        case "whoami":
            output = "mobile"

        case "date":
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE MMM d HH:mm:ss zzz yyyy"
            output = formatter.string(from: Date())

        case "echo":
            output = args.joined(separator: " ")

        case "uname":
            output = "Darwin"

        case "history":
            output = commandHistory.enumerated().map { "\($0 + 1)  \($1)" }.joined(separator: "\n")

        case "df":
            if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
               let size = attributes[.systemSize] as? Int64,
               let free = attributes[.systemFreeSize] as? Int64 {
                let sizeGB = Double(size) / (1024 * 1024 * 1024)
                let freeGB = Double(free) / (1024 * 1024 * 1024)
                let usedGB = sizeGB - freeGB
                output = String(format: "Filesystem    Size    Used   Avail  Capacity\n/dev/disk0s1  %.1fGB  %.1fGB  %.1fGB   %d%%", sizeGB, usedGB, freeGB, Int((usedGB/sizeGB) * 100))
            } else {
                output = "df: failed to get disk usage"
                isError = true
            }

        case "uptime":
            let uptime = ProcessInfo.processInfo.systemUptime
            let days = Int(uptime / 86400)
            let hours = Int((uptime.truncatingRemainder(dividingBy: 86400)) / 3600)
            let minutes = Int((uptime.truncatingRemainder(dividingBy: 3600)) / 60)
            output = "up \(days) days, \(hours):\(String(format: "%02d", minutes))"

        case "neofetch":
            let device = UIDevice.current
            output = """
               .---.         OS: \(device.systemName) \(device.systemVersion)
              /     \\        Host: \(device.model)
              | () () |       Kernel: Darwin
              \\  ^  /        Uptime: \(executeCommandInternal("uptime").output)
               |||||         Packages: Swift, SwiftUI
               |||||         Shell: FeatherTerminal
            """

        case "help":
            output = """
            Available commands:
            ls, pwd, cd, cat, mkdir, rm, touch, cp, mv,
            whoami, date, echo, uname, history, df, uptime,
            neofetch, clear, help
            """

        default:
            output = "sh: command not found: \(baseCmd)"
            isError = true
        }

        return (output, isError)
    }
}
