import SwiftUI
import NimbleViews

// MARK: - CertificateQuickAddView
struct CertificateQuickAddView: View {
    let p12URL: URL
    let mobileprovisionURL: URL
    @Environment(\.dismiss) var dismiss
    
    @State private var password: String = ""
    @State private var certificateName: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NBNavigationView(.localized("Add Certificate"), displayMode: .inline) {
            Form {
                Section {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Certificate File"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(p12URL.lastPathComponent)
                                .font(.body)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "doc.badge.gearshape.fill")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("Provisioning File"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(mobileprovisionURL.lastPathComponent)
                                .font(.body)
                        }
                    }
                } header: {
                    Text(.localized("Files"))
                }
                
                Section {
                    SecureField(.localized("Enter Password"), text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .disabled(isProcessing)
                } header: {
                    Text(.localized("Password"))
                } footer: {
                    Text(.localized("Enter the password for the .p12 certificate. Leave blank if there is no password."))
                }
                
                Section {
                    TextField(.localized("Nickname (Optional)"), text: $certificateName)
                        .textInputAutocapitalization(.words)
                        .disabled(isProcessing)
                } header: {
                    Text(.localized("Certificate Name"))
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    } header: {
                        Text(.localized("Error"))
                    }
                }
                
                if isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                            Text(.localized("Adding Certificate..."))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Add")) {
                        addCertificate()
                    }
                    .disabled(isProcessing)
                }
            }
        }
    }
    
    private func addCertificate() {
        errorMessage = nil
        
        // Validate password first
        guard FR.checkPasswordForCertificate(for: p12URL, with: password, using: mobileprovisionURL) else {
            errorMessage = .localized("Invalid password. Please check the password and try again.")
            HapticsManager.shared.error()
            return
        }
        
        isProcessing = true
        HapticsManager.shared.impact()
        
        FR.handleCertificateFiles(
            p12URL: p12URL,
            provisionURL: mobileprovisionURL,
            p12Password: password,
            certificateName: certificateName,
            isDefault: false
        ) { error in
            isProcessing = false
            
            if let error = error {
                errorMessage = error.localizedDescription
                HapticsManager.shared.error()
                AppLogManager.shared.error("Failed to add certificate: \(error.localizedDescription)", category: "Files")
            } else {
                HapticsManager.shared.success()
                AppLogManager.shared.info("Certificate added successfully from Files tab", category: "Files")
                dismiss()
            }
        }
    }
}
