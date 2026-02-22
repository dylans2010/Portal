import SwiftUI
import NimbleViews
import AltSourceKit
import Darwin
import ZIPFoundation
import UserNotifications
import LocalAuthentication
import OSLog
import CoreData

struct CoreDataInspectorView: View {
    var body: some View {
        List {
            Section(header: Text("Entities")) {
                NavigationLink("Certificates") {
                    EntityDetailView(entityName: "Certificate")
                }
                NavigationLink("Sources") {
                    EntityDetailView(entityName: "AltSource")
                }
                NavigationLink("Signed Apps") {
                    EntityDetailView(entityName: "Signed")
                }
                NavigationLink("Imported Apps") {
                    EntityDetailView(entityName: "Imported")
                }
            }

            Section(header: Text("Statistics")) {
                HStack {
                    Text("Total Certificates")
                    Spacer()
                    Text("\(Storage.shared.getCertificates().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Sources")
                    Spacer()
                    Text("\(Storage.shared.getSources().count)")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Total Signed Apps")
                    Spacer()
                    Text("\(Storage.shared.getSignedApps().count)")
                        .foregroundStyle(.secondary)
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("CoreData Inspector")
    }
}

struct EntityDetailView: View {
    let entityName: String

    var body: some View {
        List {
            Text("Entity: \(entityName)")
                .font(.caption)
                .foregroundStyle(.secondary)
            // Add more detailed entity inspection here
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(entityName)
    }
}

// MARK: - Test Notifications View
