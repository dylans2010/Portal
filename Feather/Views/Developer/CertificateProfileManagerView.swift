import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct CertificateProfileManagerView: View {
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .easeInOut(duration: 0.35)
    ) private var certificates: FetchedResults<CertificatePair>

    @State private var selectedCertificate: CertificatePair?
    @State private var showAddCertificate = false
    @State private var showImportProfile = false
    @State private var searchText = ""
    @State private var filterExpired = false

    var filteredCertificates: [CertificatePair] {
        var result = Array(certificates)

        if !searchText.isEmpty {
            result = result.filter { cert in
                (cert.nickname?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        if filterExpired {
            let now = Date()
            result = result.filter { cert in
                guard let expiration = cert.expiration else { return true }
                return expiration > now
            }
        }

        return result
    }

    var body: some View {
        List {
            // Statistics Section
            Section {
                HStack {
                    StatCard(title: "Total", value: "\(certificates.count)", icon: "doc.badge.plus", color: .blue)
                    StatCard(title: "Valid", value: "\(validCertificatesCount)", icon: "checkmark.shield", color: .green)
                    StatCard(title: "Expired", value: "\(expiredCertificatesCount)", icon: "exclamationmark.triangle", color: .red)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            // Filter Section
            Section {
                Toggle("Hide Expired Certificates", isOn: $filterExpired)
            }

            // Certificates List
            Section {
                if filteredCertificates.isEmpty {
                    if #available(iOS 17, *) {
                        ContentUnavailableView {
                            Label("No Certificates", systemImage: "person.badge.key")
                        } description: {
                            Text("Add a signing certificate to get started.")
                        } actions: {
                            Button("Add Certificate") {
                                showAddCertificate = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.key")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No Certificates")
                                .font(.headline)
                            Text("Add a signing certificate to get started")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Add Certificate") {
                                showAddCertificate = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                } else {
                    ForEach(filteredCertificates, id: \.uuid) { cert in
                        CertificateManagerRow(certificate: cert, onSelect: {
                            selectedCertificate = cert
                        })
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Storage.shared.deleteCertificate(for: cert)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Certificates (\(filteredCertificates.count))")
                    Spacer()
                }
            }

            // Actions Section
            Section {
                Button {
                    showAddCertificate = true
                } label: {
                    Label("Add Certificate", systemImage: "plus.circle.fill")
                }

                Button {
                    showImportProfile = true
                } label: {
                    Label("Import Provisioning Profile", systemImage: "square.and.arrow.down")
                }

                Button {
                    refreshAllCertificates()
                } label: {
                    Label("Refresh All Certificates", systemImage: "arrow.clockwise")
                }
            } header: {
                Text("Actions")
            }
        }
            .scrollContentBackground(.hidden)
        .searchable(text: $searchText, prompt: "Search Certificates")
        .navigationTitle("Certificate Manager")
        .sheet(isPresented: $showAddCertificate) {
            CertificatesAddView()
        }
        .sheet(item: $selectedCertificate) { cert in
            CertificatesInfoView(cert: cert)
        }
    }

    private var validCertificatesCount: Int {
        let now = Date()
        return certificates.filter { cert in
            guard let expiration = cert.expiration else { return true }
            return expiration > now
        }.count
    }

    private var expiredCertificatesCount: Int {
        let now = Date()
        return certificates.filter { cert in
            guard let expiration = cert.expiration else { return false }
            return expiration <= now
        }.count
    }

    private func refreshAllCertificates() {
        for cert in certificates {
            Storage.shared.revokagedCertificate(for: cert)
        }
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Refreshing certificate status", type: .success)
        AppLogManager.shared.info("Refreshing all certificate statuses", category: "CertManager")
    }
}
