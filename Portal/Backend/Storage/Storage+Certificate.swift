import CoreData
import ZsignSwift
import WidgetKit

// MARK: - Class extension: certificate
extension Storage {
        func addCertificate(
                uuid: String,
                password: String? = nil,
                nickname: String? = nil,
                ppq: Bool = false,
                expiration: Date,
                isDefault: Bool = false,
                completion: @escaping (Error?) -> Void
        ) {
                
                let new = CertificatePair(context: context)
                new.uuid = uuid
                new.date = Date()
                new.password = password
                new.ppQCheck = ppq
                new.expiration = expiration
                new.nickname = nickname
                new.isDefault = isDefault
                Storage.shared.revokagedCertificate(for: new)
                saveContext()
                HapticsManager.shared.impact()
                
                // Update widget data with the new certificate if it's the default or first one
                if isDefault || getAllCertificates().count == 1 {
                        updateWidgetData(certName: nickname ?? "Certificate", expiryDate: expiration)
                }
                
                completion(nil)
        }
        
        func deleteCertificate(for cert: CertificatePair) {
                if let url = getUuidDirectory(for: cert) {
                        try? FileManager.default.removeItem(at: url)
                }
                context.delete(cert)
                saveContext()
                
                // Update widget with next available certificate or clear data
                let remainingCerts = getAllCertificates()
                if let nextCert = remainingCerts.first {
                        updateWidgetData(certName: nextCert.nickname ?? "Certificate", expiryDate: nextCert.expiration)
                } else {
                        updateWidgetData(certName: "No Certificate", expiryDate: nil)
                }
        }
        
        func getCertificates() -> [CertificatePair] {
                let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
                return (try? context.fetch(fetchRequest)) ?? []
        }

        func getCertificate(for index: Int) -> CertificatePair? {
                let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]

                guard
                        let results = try? context.fetch(fetchRequest),
                        index >= 0 && index < results.count
                else {
                        return nil
                }
                
                return results[index]
        }
        
        func revokagedCertificate(for cert: CertificatePair) {
                guard !cert.revoked else { return }
                
                Zsign.checkRevokage(
                        provisionPath: Storage.shared.getFile(.provision, from: cert)?.path ?? "",
                        p12Path: Storage.shared.getFile(.certificate, from: cert)?.path ?? "",
                        p12Password: cert.password ?? ""
                ) { (status, _, _) in
                        if status == 1 {
                                DispatchQueue.main.async {
                                        cert.revoked = true
                                        self.saveContext()
                                }
                        }
                }
        }
        
        enum FileRequest: String {
                case certificate = "p12"
                case provision = "mobileprovision"
        }
        
        func getFile(_ type: FileRequest, from cert: CertificatePair) -> URL? {
                guard let url = getUuidDirectory(for: cert) else {
                        return nil
                }
                
                return FileManager.default.getPath(in: url, for: type.rawValue)
        }
        
        func getProvisionFileDecoded(for cert: CertificatePair) -> Certificate? {
                guard let url = getFile(.provision, from: cert) else {
                        return nil
                }
                
                let read = CertificateReader(url)
                return read.decoded
        }
        
        func getUuidDirectory(for cert: CertificatePair) -> URL? {
                guard let uuid = cert.uuid else {
                        return nil
                }
                
                return FileManager.default.certificates(uuid)
        }
        
        func getAllCertificates() -> [CertificatePair] {
                let fetchRequest: NSFetchRequest<CertificatePair> = CertificatePair.fetchRequest()
                fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)]
                return (try? context.fetch(fetchRequest)) ?? []
        }

        func updateWidgetData(certName: String, expiryDate: Date?) {
                let userDefaults = UserDefaults(suiteName: Storage.appGroupID) ?? .standard
                userDefaults.set(certName, forKey: "widget.selectedCertName")
                if let expiryDate = expiryDate {
                        userDefaults.set(expiryDate.timeIntervalSince1970, forKey: "widget.selectedCertExpiry")
                } else {
                        userDefaults.removeObject(forKey: "widget.selectedCertExpiry")
                }

                // Save recent apps for the widget
                let signedApps = getSignedApps().prefix(4)
                let widgetApps = signedApps.map { app -> [String: String?] in
                        ["name": app.name ?? "Unknown", "icon": app.icon]
                }

                if let encoded = try? JSONSerialization.data(withJSONObject: widgetApps) {
                        userDefaults.set(encoded, forKey: "widget.recentApps")
                }

                userDefaults.synchronize()

                WidgetCenter.shared.reloadAllTimelines()
        }
}
