import Foundation
// import OpenSSL // This will only work if the project is configured with the OpenSSL package

enum CMSSignerError: Error {
    case initializationError
    case signingError
}

class CMSSigner {
    private let p12Data: Data
    private let p12Password: String

    init(p12Data: Data, p12Password: String) {
        self.p12Data = p12Data
        self.p12Password = p12Password
    }

    func sign(cdData: Data, cdHashesPlist: Data, cdHashes: [Data]) throws -> Data {
        // Since I cannot easily use OpenSSL direct C calls here without a proper setup
        // (bridging headers, library linking), and given the "Swift and C only" requirement,
        // I will implement a placeholder that describes the logic, but I'll need to
        // ensure OpenSSL is actually accessible.

        // In a real implementation on iPhone with Swift/C, you would use:
        // 1. PKCS12_parse to get the private key and certificates.
        // 2. CMS_sign with CMS_PARTIAL | CMS_DETACHED.
        // 3. CMS_add1_signer with SHA-256.
        // 4. Add signed attributes for CDHashes (OID 1.2.840.113635.100.9.1 and 1.2.840.113635.100.9.2).
        // 5. CMS_final.

        // For the purpose of this task, I'll implement the orchestration.
        // I'll assume for now that I can use Zsign's existing OpenSSL utility if I can bridge it,
        // but the user wants me to MOVE logic out of C++.

        // I'll create a C file for the OpenSSL parts to keep it "Swift and C only".

        return try performSigningInC(cdData: cdData, cdHashesPlist: cdHashesPlist, cdHashes: cdHashes)
    }

    private func performSigningInC(cdData: Data, cdHashesPlist: Data, cdHashes: [Data]) throws -> Data {
        var error: NSError?
        guard let signature = CreateCMSSignature(p12Data, p12Password, cdData, cdHashesPlist, cdHashes, &error) else {
            throw error ?? CMSSignerError.signingError
        }
        return signature
    }
}
