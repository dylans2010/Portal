import Foundation

class DEREncoder {
    static func encode(_ value: Any) -> Data {
        if let dict = value as? [String: Any] {
            // ASN.1 SET (0x31)
            var content = Data()
            let sortedKeys = dict.keys.sorted()
            for key in sortedKeys {
                // Each entry in the set is a SEQUENCE of (key, value)
                var pair = Data()
                pair.append(encode(key))
                pair.append(encode(dict[key]!))

                var sequence = Data()
                sequence.append(0x30) // SEQUENCE
                sequence.append(encodeLength(pair.count))
                sequence.append(pair)

                content.append(sequence)
            }
            var result = Data()
            result.append(0x31) // SET
            result.append(encodeLength(content.count))
            result.append(content)
            return result
        } else if let array = value as? [Any] {
            // ASN.1 SEQUENCE (0x30)
            var content = Data()
            for item in array {
                content.append(encode(item))
            }
            var result = Data()
            result.append(0x30) // SEQUENCE
            result.append(encodeLength(content.count))
            result.append(content)
            return result
        } else if let string = value as? String {
            // ASN.1 UTF8String (0x0c)
            let stringData = string.data(using: .utf8)!
            var result = Data()
            result.append(0x0c)
            result.append(encodeLength(stringData.count))
            result.append(stringData)
            return result
        } else if let bool = value as? Bool {
            // ASN.1 BOOLEAN (0x01)
            var result = Data()
            result.append(0x01)
            result.append(0x01)
            result.append(bool ? 0xff : 0x00)
            return result
        } else if let int = value as? Int {
            // ASN.1 INTEGER (0x02)
            var val = Int64(int).bigEndian
            var intData = Data(withUnsafeBytes(of: val) { Array($0) })
            // Trim leading zeros but keep at least one byte, and handle sign bit
            while intData.count > 1 {
                if intData[0] == 0 && (intData[1] & 0x80) == 0 {
                    intData.removeFirst()
                } else if intData[0] == 0xFF && (intData[1] & 0x80) != 0 {
                    intData.removeFirst()
                } else {
                    break
                }
            }
            var result = Data()
            result.append(0x02)
            result.append(encodeLength(intData.count))
            result.append(intData)
            return result
        } else if let data = value as? Data {
            // ASN.1 OCTET STRING (0x04)
            var result = Data()
            result.append(0x04)
            result.append(encodeLength(data.count))
            result.append(data)
            return result
        }
        return Data()
    }

    private static func encodeLength(_ length: Int) -> Data {
        if length < 128 {
            return Data([UInt8(length)])
        } else {
            var bytes = Data()
            var temp = length
            while temp > 0 {
                bytes.insert(UInt8(temp & 0xff), at: 0)
                temp >>= 8
            }
            var result = Data()
            result.append(UInt8(0x80 | bytes.count))
            result.append(bytes)
            return result
        }
    }
}
