import Foundation
import OSLog
import Combine
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Log Entry
struct LogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    let errorCode: LogErrorCode?
    let file: String
    let function: String
    let line: Int
    
    enum LogLevel: String, Codable, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case success = "SUCCESS"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var icon: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .success: return "✅"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
        
        var displayColor: String {
            switch self {
            case .debug: return "gray"
            case .info: return "blue"
            case .success: return "green"
            case .warning: return "orange"
            case .error: return "red"
            case .critical: return "purple"
            }
        }
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
    
    var formattedMessage: String {
        let codeStr = errorCode != nil ? " [\(errorCode!.rawValue)]" : ""
        return "[\(formattedTimestamp)] \(level.icon) [\(level.rawValue)]\(codeStr) [\(category)] \(message)"
    }
    
    var detailedMessage: String {
        let codeStr = errorCode != nil ? "Error Code: \(errorCode!.rawValue)\n" : ""
        return """
        [\(formattedTimestamp)] \(level.icon) [\(level.rawValue)]
        Category: \(category)
        \(codeStr)Message: \(message)
        Location: \(file):\(line) In \(function)
        """
    }
}

// MARK: - App Log Manager
final class AppLogManager: ObservableObject {
    static let shared = AppLogManager()
    
    @Published private(set) var logs: [LogEntry] = []
    private let maxLogs = 10000
    private let persistenceKey = "Feather.AppLogs"
    
    private init() {
        loadPersistedLogs()
        setupLogInterception()
    }
    
    // MARK: - Logging Methods
    
    func log(
        _ message: String,
        level: LogEntry.LogLevel = .info,
        category: String = "General",
        errorCode: LogErrorCode? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            id: UUID(),
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            errorCode: errorCode,
            file: URL(fileURLWithPath: file).lastPathComponent,
            function: function,
            line: line
        )
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.append(entry)
            
            // Keep only the most recent logs
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }
            
            // Persist logs periodically (every 100 logs)
            if self.logs.count % 100 == 0 {
                self.persistLogs()
            }
        }
        
        // Also log to OSLog
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Feather", category: category)
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info, .success:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
    }
    
    // Convenience methods
    func debug(_ message: String, category: String = "General", errorCode: LogErrorCode? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, errorCode: errorCode, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", errorCode: LogErrorCode? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, errorCode: errorCode, file: file, function: function, line: line)
    }
    
    func success(_ message: String, category: String = "General", errorCode: LogErrorCode? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .success, category: category, errorCode: errorCode, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", errorCode: LogErrorCode? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, errorCode: errorCode, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "General", errorCode: LogErrorCode? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, errorCode: errorCode, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: String = "General", errorCode: LogErrorCode? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, errorCode: errorCode, file: file, function: function, line: line)
    }
    
    // MARK: - Filtering
    
    func filteredLogs(searchText: String = "", level: LogEntry.LogLevel? = nil, category: String? = nil) -> [LogEntry] {
        var filtered = logs
        
        if !searchText.isEmpty {
            filtered = filtered.filter { log in
                log.message.localizedCaseInsensitiveContains(searchText) ||
                log.category.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let level = level {
            filtered = filtered.filter { $0.level == level }
        }
        
        if let category = category, !category.isEmpty {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered
    }
    
    func categories() -> [String] {
        return Array(Set(logs.map { $0.category })).sorted()
    }
    
    // MARK: - Export
    
    func exportLogs() -> String {
        return logs.map { $0.detailedMessage }.joined(separator: "\n\n")
    }
    
    func exportLogsAsJSON() -> Data? {
        return try? JSONEncoder().encode(logs)
    }

    func exportLogsAsCSV() -> String {
        var csvString = "Timestamp,Level,ErrorCode,Category,Message,File,Function,Line\n"
        for log in logs {
            let timestamp = log.formattedTimestamp
            let level = log.level.rawValue
            let errorCode = log.errorCode?.rawValue ?? ""
            let category = log.category.replacingOccurrences(of: "\"", with: "\"\"")
            let message = log.message.replacingOccurrences(of: "\"", with: "\"\"")
            let file = log.file
            let function = log.function
            let line = log.line
            csvString += "\"\(timestamp)\",\"\(level)\",\"\(errorCode)\",\"\(category)\",\"\(message)\",\"\(file)\",\"\(function)\",\(line)\n"
        }
        return csvString
    }
    
    // MARK: - Clear
    
    func clearLogs() {
        logs.removeAll()
        // Remove from UserDefaults to permanently delete
        UserDefaults.standard.removeObject(forKey: persistenceKey)
        UserDefaults.standard.synchronize()
        AppLogManager.shared.info("Logs Cleared Successfully", category: "AppLogs")
    }
    
    // MARK: - Persistence
    
    private func persistLogs() {
        if let data = try? JSONEncoder().encode(logs.suffix(1000)) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }
    
    private func loadPersistedLogs() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let persistedLogs = try? JSONDecoder().decode([LogEntry].self, from: data) {
            logs = persistedLogs
        }
    }
    
    // MARK: - Log Interception
    
    private func setupLogInterception() {
        #if canImport(UIKit)
        // Log app lifecycle events
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.info("Portal Became Active", category: "Lifecycle")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.info("App will resign active", category: "Lifecycle")
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.info("Portal is now on the background", category: "Lifecycle")
            self?.persistLogs()
        }
        #endif
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
