import SwiftUI
import SQLite3

struct SQLiteBrowserView: View {
    let fileURL: URL
    @State private var tables: [String] = []
    @State private var selectedTable: String?
    @State private var columns: [String] = []
    @State private var rows: [[String]] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let error = errorMessage {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section(header: Text(.localized("Tables"))) {
                    ForEach(tables, id: \.self) { table in
                        Button {
                            loadTable(table)
                        } label: {
                            HStack {
                                Text(table)
                                Spacer()
                                if selectedTable == table {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                if let table = selectedTable {
                    Section(header: Text(.localized("Data: \(table)"))) {
                        ScrollView(.horizontal) {
                            VStack(alignment: .leading, spacing: 0) {
                                // Header
                                HStack(spacing: 0) {
                                    ForEach(columns, id: \.self) { col in
                                        Text(col)
                                            .font(.caption.bold())
                                            .padding(8)
                                            .frame(width: 100, alignment: .leading)
                                            .background(Color.gray.opacity(0.2))
                                            .border(Color.gray.opacity(0.3), width: 0.5)
                                    }
                                }

                                // Rows
                                ForEach(0..<rows.count, id: \.self) { rowIndex in
                                    HStack(spacing: 0) {
                                        ForEach(0..<rows[rowIndex].count, id: \.self) { colIndex in
                                            Text(rows[rowIndex][colIndex])
                                                .font(.caption2)
                                                .padding(8)
                                                .frame(width: 100, height: 30, alignment: .leading)
                                                .border(Color.gray.opacity(0.3), width: 0.5)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(fileURL.lastPathComponent)
            .onAppear {
                loadTables()
            }
        }
    }

    private func loadTables() {
        var db: OpaquePointer?
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else {
            errorMessage = "Failed to open database"
            return
        }
        defer { sqlite3_close(db) }

        let query = "SELECT name FROM sqlite_master WHERE type='table';"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    tables.append(String(cString: cString))
                }
            }
        }
        sqlite3_finalize(statement)
    }

    private func loadTable(_ table: String) {
        selectedTable = table
        columns = []
        rows = []

        var db: OpaquePointer?
        guard sqlite3_open(fileURL.path, &db) == SQLITE_OK else { return }
        defer { sqlite3_close(db) }

        let query = "SELECT * FROM \(table) LIMIT 100;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let colCount = sqlite3_column_count(statement)
            for i in 0..<colCount {
                if let cName = sqlite3_column_name(statement, i) {
                    columns.append(String(cString: cName))
                }
            }

            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String] = []
                for i in 0..<colCount {
                    if let cText = sqlite3_column_text(statement, i) {
                        row.append(String(cString: cText))
                    } else {
                        row.append("NULL")
                    }
                }
                rows.append(row)
            }
        }
        sqlite3_finalize(statement)
    }
}
