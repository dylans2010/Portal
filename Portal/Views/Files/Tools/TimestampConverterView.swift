import SwiftUI

struct TimestampConverterView: View {
    @State private var timestamp: String = "\(Int(Date().timeIntervalSince1970))"
    @State private var date: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(.localized("Unix Timestamp to Date"))) {
                    TextField(.localized("Timestamp"), text: $timestamp)
                        .keyboardType(.numberPad)
                        .onChange(of: timestamp) { newValue in
                            if let ts = Double(newValue) {
                                date = Date(timeIntervalSince1970: ts)
                            }
                        }

                    Text(date.formatted())
                        .foregroundStyle(.secondary)
                }

                Section(header: Text(.localized("Date to Unix Timestamp"))) {
                    DatePicker(.localized("Select Date"), selection: $date)
                        .onChange(of: date) { newValue in
                            timestamp = "\(Int(newValue.timeIntervalSince1970))"
                        }

                    Text("\(Int(date.timeIntervalSince1970))")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                Section {
                    Button(.localized("Now")) {
                        date = Date()
                        timestamp = "\(Int(date.timeIntervalSince1970))"
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("Timestamp Converter"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
