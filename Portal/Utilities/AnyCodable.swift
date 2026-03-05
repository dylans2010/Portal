import Foundation

struct AnyCodable: Codable, Equatable {
	let value: Any
	
	init(_ value: Any) {
		self.value = value
	}
	
	static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
		// Handle NSNull
		if lhs.value is NSNull && rhs.value is NSNull {
			return true
		}
		
		// Handle Bool
		if let lhsBool = lhs.value as? Bool, let rhsBool = rhs.value as? Bool {
			return lhsBool == rhsBool
		}
		
		// Handle Int
		if let lhsInt = lhs.value as? Int, let rhsInt = rhs.value as? Int {
			return lhsInt == rhsInt
		}
		
		// Handle UInt
		if let lhsUInt = lhs.value as? UInt, let rhsUInt = rhs.value as? UInt {
			return lhsUInt == rhsUInt
		}
		
		// Handle Double
		if let lhsDouble = lhs.value as? Double, let rhsDouble = rhs.value as? Double {
			return lhsDouble == rhsDouble
		}
		
		// Handle String
		if let lhsString = lhs.value as? String, let rhsString = rhs.value as? String {
			return lhsString == rhsString
		}
		
		// Handle Array
		if let lhsArray = lhs.value as? [Any], let rhsArray = rhs.value as? [Any] {
			guard lhsArray.count == rhsArray.count else { return false }
			for (lhsElement, rhsElement) in zip(lhsArray, rhsArray) {
				if AnyCodable(lhsElement) != AnyCodable(rhsElement) {
					return false
				}
			}
			return true
		}
		
		// Handle Dictionary
		if let lhsDict = lhs.value as? [String: Any], let rhsDict = rhs.value as? [String: Any] {
			guard lhsDict.count == rhsDict.count else { return false }
			for (key, lhsValue) in lhsDict {
				guard let rhsValue = rhsDict[key] else { return false }
				if AnyCodable(lhsValue) != AnyCodable(rhsValue) {
					return false
				}
			}
			return true
		}
		
		// If types don't match or aren't supported, they're not equal
		return false
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		
		if container.decodeNil() {
			self.value = NSNull()
		} else if let bool = try? container.decode(Bool.self) {
			self.value = bool
		} else if let int = try? container.decode(Int.self) {
			self.value = int
		} else if let uint = try? container.decode(UInt.self) {
			self.value = uint
		} else if let double = try? container.decode(Double.self) {
			self.value = double
		} else if let string = try? container.decode(String.self) {
			self.value = string
		} else if let array = try? container.decode([AnyCodable].self) {
			self.value = array.map { $0.value }
		} else if let dictionary = try? container.decode([String: AnyCodable].self) {
			self.value = dictionary.mapValues { $0.value }
		} else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable cannot decode value")
		}
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		
		switch self.value {
		case is NSNull:
			try container.encodeNil()
		case let bool as Bool:
			try container.encode(bool)
		case let int as Int:
			try container.encode(int)
		case let uint as UInt:
			try container.encode(uint)
		case let double as Double:
			try container.encode(double)
		case let string as String:
			try container.encode(string)
		case let array as [Any]:
			try container.encode(array.map { AnyCodable($0) })
		case let dictionary as [String: Any]:
			try container.encode(dictionary.mapValues { AnyCodable($0) })
		default:
			throw EncodingError.invalidValue(self.value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable cannot encode value"))
		}
	}
}
