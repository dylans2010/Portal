import UIKit
import OSLog

class CertificateReader: NSObject {
	let file: URL?
	var decoded: Certificate?
	
	init(_ file: URL?) {
		self.file = file
		super.init()
		self.decoded = self._readAndDecode()
	}

    init(data: Data) {
        self.file = nil
        super.init()
        self.decoded = self._decode(data: data)
    }
	
	private func _readAndDecode() -> Certificate? {
		guard let file = file else { return nil }
		
		do {
			let fileData = try Data(contentsOf: file)
			return _decode(data: fileData)
		} catch {
			Logger.misc.error("Error reading certificate file: \(error.localizedDescription)")
			return nil
		}
	}

    private func _decode(data: Data) -> Certificate? {
        do {
            guard let xmlRange = data.range(of: Data("<?xml".utf8)) else {
                Logger.misc.error("XML start not found")
                return nil
            }

            let xmlData = data.subdata(in: xmlRange.lowerBound..<data.endIndex)

            let decoder = PropertyListDecoder()
            var decodedData = try decoder.decode(Certificate.self, from: xmlData)

            // Check for PPQ in the entire file content
            if decodedData.PPQCheck == nil {
                let fileString = String(data: data, encoding: .utf8) ?? ""
                decodedData.PPQCheck = fileString.uppercased().contains("PPQ")
            }

            return decodedData
        } catch {
            Logger.misc.error("Error extracting certificate: \(error.localizedDescription)")
            return nil
        }
    }
}
