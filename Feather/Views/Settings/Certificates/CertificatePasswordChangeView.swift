import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

struct CertificatePasswordChangeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var _p12URL: URL? = nil
    @State private var _currentPassword: String = ""
    @State private var _newPassword: String = ""
    @State private var _confirmPassword: String = ""

    @State private var _isImportingP12Presenting = false
    @State private var _isProcessing = false
    @State private var _errorMessage: String? = nil
    @State private var _successMessage: String? = nil

    private static let _p12Extensions: Set<String> = ["p12", "pfx"]

    private var _passwordsMatch: Bool {
        _newPassword.trimmingCharacters(in: .whitespacesAndNewlines) == _confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var processButtonDisabled: Bool {
        _p12URL == nil || !_passwordsMatch || _isProcessing
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

                        if let successMessage = _successMessage {
                            Text(successMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(.green)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        if let errorMessage = _errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
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
                let ext = selectedFileURL.pathExtension.lowercased()
                guard CertificatePasswordChangeView._p12Extensions.contains(ext) else {
                    self._errorMessage = "Please select a valid .p12 or .pfx certificate file."
                    return
                }
                self._errorMessage = nil
                self._successMessage = nil
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

        let ext = p12URL.pathExtension.lowercased()
        guard CertificatePasswordChangeView._p12Extensions.contains(ext) else {
            _errorMessage = "The selected file is not a valid PKCS#12 file. Please select a .p12 or .pfx file."
            return
        }

        let trimmedNew = _newPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = _confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedNew == trimmedConfirm else {
            _errorMessage = "New passwords do not match."
            return
        }

        _errorMessage = nil
        _successMessage = nil
        _isProcessing = true

        // Start accessing the security scoped resource for files from Document Picker
        let accessing = p12URL.startAccessingSecurityScopedResource()
        let currentPassword = _currentPassword
        let newPassword = _newPassword

        DispatchQueue.global(qos: .userInitiated).async {
            defer {
                if accessing {
                    p12URL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let p12Data = try Data(contentsOf: p12URL)
                let newData = try PasswordChanger.changePassword(
                    p12Data: p12Data,
                    oldPassword: currentPassword,
                    newPassword: newPassword
                )

                DispatchQueue.main.async {
                    _isProcessing = false
                    _handleSuccess(newData: newData, originalName: p12URL.lastPathComponent)
                }
            } catch let error as PasswordChangerError {
                DispatchQueue.main.async {
                    _isProcessing = false
                    _errorMessage = error.localizedDescription
                }
            } catch {
                DispatchQueue.main.async {
                    _isProcessing = false
                    _errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                }
            }
        }
    }

    private func _handleSuccess(newData: Data, originalName: String) {
        let tempDir = FileManager.default.temporaryDirectory
        let baseName = (originalName as NSString).deletingPathExtension
        let fileURL = tempDir.appendingPathComponent("\(baseName)_new.p12")

        do {
            try newData.write(to: fileURL)

            // Present UIActivityViewController directly to set completion handler for cleanup
            let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            controller.completionWithItemsHandler = { _, completed, _, _ in
                // Cleanup the temporary file after sharing is done
                try? FileManager.default.removeItem(at: fileURL)
                if completed {
                    DispatchQueue.main.async {
                        self._successMessage = "Password changed successfully. The updated certificate has been exported."
                    }
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
