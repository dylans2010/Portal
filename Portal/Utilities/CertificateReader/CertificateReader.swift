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
	
	private func _readAndDecode() -> Certificate? {
		guard let file = file else { return nil }
		
		do {
			let fileData = try Data(contentsOf: file)
			
			guard let xmlRange = fileData.range(of: Data("<?xml".utf8)) else {
				Logger.misc.error("XML start not found")
				return nil
			}
			
			let xmlData = fileData.subdata(in: xmlRange.lowerBound..<fileData.endIndex)
			
			let decoder = PropertyListDecoder()
			var data = try decoder.decode(Certificate.self, from: xmlData)
			
			// Check for PPQ in the entire file content
			if data.PPQCheck == nil {
				let fileString = String(data: fileData, encoding: .utf8) ?? ""
				data.PPQCheck = fileString.uppercased().contains("PPQ")
			}
			
			return data
		} catch {
			Logger.misc.error("Error extracting certificate: \(error.localizedDescription)")
			return nil
		}
	}
}
