import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

struct CertificatePasswordChangeView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var _p12URL: URL? = nil
    @State private var _currentPassword: String = ""
    @State private var _newPassword: String = ""
    @State private var _confirmPassword: String = ""

    @State private var _isImportingP12Presenting = false
    @State private var _isProcessing = false
    @State private var _errorMessage: String? = nil
    @State private var _successData: Data? = nil
    @State private var _validationResult: P12ValidationResult? = nil

    private var _passwordsMatch: Bool {
        _newPassword.trimmingCharacters(in: .whitespacesAndNewlines) == _confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var processButtonDisabled: Bool {
        _p12URL == nil || _newPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !_passwordsMatch || _isProcessing || _successData != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        fileImportSection

                        Divider()
                            .padding(.vertical, 8)

                        passwordFieldsSection

                        if let errorMessage = _errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        if _successData != nil {
                            successSection
                        }

                        Spacer(minLength: 30)
                    }
                    .padding(20)
                }

                processButton
                    .padding(20)
            }
            .background(Color.clear)
            .navigationTitle("Change P12 Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $_isImportingP12Presenting) {
                p12ImportSheet
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color.accentColor)
                .padding(.bottom, 8)

            Text("Update Certificate Password")
                .font(.headline)

            Text("Change your certificates password using this tool. The processing happens entirely on device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 10)
    }

    private var fileImportSection: some View {
        Button {
            _isImportingP12Presenting = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: _p12URL != nil ? "checkmark.circle.fill" : "key.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(_p12URL != nil ? .green : .orange)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("P12 Certificate")
                        .font(.system(size: 16, weight: .semibold))

                    Text(_p12URL?.lastPathComponent ?? "Select .p12 File")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var passwordFieldsSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Password")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    SecureField("Enter Current Password", text: $_currentPassword)
                        .font(.system(size: 15))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("New Password")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Color.accentColor)
                    SecureField("Enter New Password", text: $_newPassword)
                        .font(.system(size: 15))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm New Password")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)

                HStack(spacing: 12) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(Color.accentColor)
                    SecureField("Confirm New Password", text: $_confirmPassword)
                        .font(.system(size: 15))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )

                if !_confirmPassword.isEmpty && !_passwordsMatch {
                    Text("Passwords do not match")
                        .font(.system(size: 12))
                        .foregroundStyle(.red)
                        .padding(.leading, 4)
                }
            }
        }
    }

    private var successSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Password Changed Successfully")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Export the updated .p12 file to save it.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )

            if let result = _validationResult {
                VStack(alignment: .leading, spacing: 10) {
                    _certificateInfoRow(
                        icon: "person.text.rectangle.fill",
                        title: "Signing Identity",
                        value: result.signingIdentity
                    )

                    if let teamID = result.teamID {
                        _certificateInfoRow(
                            icon: "person.2.fill",
                            title: "Team ID",
                            value: teamID
                        )
                    }

                    if let expiration = result.expirationDate {
                        _certificateInfoRow(
                            icon: "calendar.badge.clock",
                            title: "Expiration",
                            value: _formatDate(expiration)
                        )
                    }

                    HStack(spacing: 8) {
                        Image(systemName: result.isVerified ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                            .foregroundStyle(result.isVerified ? .green : .orange)
                            .font(.system(size: 14))
                        Text(result.isVerified ? "Certificate Verified" : "Certificate Untrusted")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(result.isVerified ? .green : .orange)
                    }
                    .padding(.top, 2)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                )
            }

            Button {
                if let data = _successData, let name = _p12URL?.lastPathComponent {
                    _handleSuccess(newData: data, originalName: name)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Export Updated Certificate")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.green)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var processButton: some View {
        Button {
            _processPasswordChange()
        } label: {
            HStack(spacing: 8) {
                if _isProcessing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Change Password")
                        .font(.system(size: 16, weight: .bold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        processButtonDisabled
                        ? AnyShapeStyle(Color.gray.opacity(0.5))
                        : AnyShapeStyle(Color.accentColor)
                    )
            )
            .shadow(color: processButtonDisabled ? .clear : Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(processButtonDisabled)
    }

    private var p12ImportSheet: some View {
        FileImporterRepresentableView(
            allowedContentTypes: [.p12],
            onDocumentsPicked: { urls in
                guard let selectedFileURL = urls.first else { return }
                self._p12URL = selectedFileURL
            }
        )
        .ignoresSafeArea()
    }

    private func _processPasswordChange() {
        guard let p12URL = _p12URL else {
            _errorMessage = "Please select a .p12 certificate file."
            return
        }

        // Validate that the selected file has a PKCS#12 extension
        let ext = p12URL.pathExtension.lowercased()
        guard ext == "p12" || ext == "pfx" else {
            _errorMessage = "Please select a valid PKCS#12 file (.p12 or .pfx)."
            return
        }

        let trimmedNew = _newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = _confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedNew == trimmedConfirm else {
            _errorMessage = "New passwords do not match."
            return
        }

        _errorMessage = nil
        _successData = nil
        _validationResult = nil
        _isProcessing = true

        // Start accessing the security scoped resource for files from Document Picker
        let accessing = p12URL.startAccessingSecurityScopedResource()
        let currentPassword = _currentPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let newPassword = trimmedNew

        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                if accessing {
                    p12URL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                // Always read the certificate as raw binary data
                let p12Data = try Data(contentsOf: p12URL)

                // Attempt validation; if it fails due to unsupported encryption,
                // still try the password change via the fallback strategies inside
                // PasswordChanger.changePassword.
                var validation: P12ValidationResult? = nil

                do {
                    validation = try PasswordChanger.validateP12(
                        p12Data: p12Data,
                        password: currentPassword
                    )
                } catch let error as PasswordChangerError {
                    // Auth failed means wrong password — fail immediately
                    if case .authFailed = error {
                        DispatchQueue.main.async {
                            _isProcessing = false
                            _errorMessage = _userFacingMessage(for: error)
                        }
                        return
                    }
                    // For unsupported encryption or decode errors, continue to
                    // changePassword which has its own fallback strategies.
                }

                // Attempt the password change (may use fallback strategies internally)
                let newData: Data
                do {
                    newData = try PasswordChanger.changePassword(
                        p12Data: p12Data,
                        oldPassword: currentPassword,
                        newPassword: newPassword
                    )
                } catch let error as PasswordChangerError {
                    DispatchQueue.main.async {
                        _isProcessing = false
                        _errorMessage = _userFacingMessage(for: error)
                    }
                    return
                }

                DispatchQueue.main.async {
                    _isProcessing = false
                    _validationResult = validation
                    _successData = newData
                }
            } catch {
                DispatchQueue.main.async {
                    _isProcessing = false
                    _errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                }
            }
        }
    }

    private func _userFacingMessage(for error: PasswordChangerError) -> String {
        switch error {
        case .authFailed:
            return "The password for this certificate is incorrect. Please check your current password and try again."
        case .unsupportedEncryption:
            return "This certificate uses an encryption format that could not be processed. Try re-exporting the certificate from Keychain Access or your certificate management tool."
        case .decodeFailed:
            return "The selected file could not be read as a valid PKCS#12 certificate."
        case .importFailed(let status):
            return "Certificate import failed (error \(status)). The file may use an incompatible format."
        case .exportFailed(let status):
            return "Failed to save the updated certificate (error \(status))."
        case .noItemsFound:
            return "No signing identity was found in the certificate file."
        case .invalidData:
            return "The selected file does not contain valid certificate data."
        case .invalidParam:
            return "A parameter error occurred while processing the certificate."
        case .notSupported:
            return "This operation is not supported on this device."
        }
    }

    private func _certificateInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .font(.system(size: 14))
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(2)
            }
        }
    }

    private static let _dateDisplayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func _formatDate(_ date: Date) -> String {
        Self._dateDisplayFormatter.string(from: date)
    }

    private func _handleSuccess(newData: Data, originalName: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = originalName.replacingOccurrences(of: ".p12", with: "_new.p12")
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try newData.write(to: fileURL)

            // Present UIActivityViewController directly to set completion handler for cleanup
            let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            controller.completionWithItemsHandler = { _, _, _, _ in
                // Cleanup the temporary file and dismiss after the share sheet is done
                try? FileManager.default.removeItem(at: fileURL)
                DispatchQueue.main.async {
                    dismiss()
                }
            }

            if let topVC = UIApplication.topViewController() {
                if let popover = controller.popoverPresentationController {
                    popover.sourceView = topVC.view
                    popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                topVC.present(controller, animated: true)
            }
        } catch {
            _errorMessage = "Failed to save the new certificate: \(error.localizedDescription)"
        }
    }
}
