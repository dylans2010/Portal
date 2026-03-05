import SwiftUI
import CryptoKit

struct HashVerifierView: View {
    let fileURL: URL
    @State private var expectedHash: String = ""
    @State private var actualHash: String = ""
    @State private var algorithm: HashAlgorithm = .sha256
    @State private var isCalculating = false
    @State private var resultMessage: String?
    @State private var isMatch: Bool?

    enum HashAlgorithm: String, CaseIterable {
        case md5 = "MD5"
        case sha1 = "SHA-1"
        case sha256 = "SHA-256"
        case sha512 = "SHA-512"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(.localized("Expected Hash"))) {
                    TextField(.localized("Paste expected hash here"), text: $expectedHash)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text(.localized("Algorithm"))) {
                    Picker(.localized("Algorithm"), selection: $algorithm) {
                        ForEach(HashAlgorithm.allCases, id: \.self) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        verify()
                    } label: {
                        if isCalculating {
                            ProgressView()
                        } else {
                            Text(.localized("Verify"))
                        }
                    }
                    .disabled(isCalculating || expectedHash.isEmpty)
                }

                if let message = resultMessage {
                    Section {
                        HStack {
                            Image(systemName: isMatch == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isMatch == true ? .green : .red)
                            Text(message)
                        }

                        VStack(alignment: .leading) {
                            Text(.localized("Actual Hash:"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(actualHash)
                                .font(.system(.caption2, design: .monospaced))
                                .textSelection(.enabled)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(.localized("Hash Verifier"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func verify() {
        isCalculating = true
        resultMessage = nil
        isMatch = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                let hash: String

                switch algorithm {
                case .md5:
                    hash = Insecure.MD5.hash(data: data).map { String(format: "%02x", $0) }.joined()
                case .sha1:
                    hash = Insecure.SHA1.hash(data: data).map { String(format: "%02x", $0) }.joined()
                case .sha256:
                    hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
                case .sha512:
                    hash = SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()
                }

                DispatchQueue.main.async {
                    actualHash = hash
                    isMatch = hash.lowercased() == expectedHash.trimmingCharacters(in: .whitespaces).lowercased()
                    resultMessage = isMatch == true ? .localized("Hashes Match!") : .localized("Hashes Do NOT Match")
                    isCalculating = false
                    if isMatch == true {
                        HapticsManager.shared.success()
                    } else {
                        HapticsManager.shared.error()
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    resultMessage = error.localizedDescription
                    isCalculating = false
                }
            }
        }
    }
}
