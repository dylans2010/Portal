import SwiftUI

// MARK: - View
struct CertificatesInfoEntitlementCellView: View {
	let key: String
	let value: Any
	@State private var _isExpanded = false
	
	// MARK: Body
	var body: some View {
		if let dict = value as? [String: Any] {
			_makeDisclosureGroup(items: dict.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 })
		} else if let array = value as? [Any] {
			_makeDisclosureGroup(items: array.enumerated().map { ("\($0)", $1) })
		} else {
			HStack(alignment: .top, spacing: 12) {
				VStack(alignment: .leading, spacing: 4) {
					Text(key)
						.font(.body)
						.fontWeight(.medium)
						.foregroundStyle(.primary)
					
					Text(_typeDescription(value))
						.font(.caption)
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				Text(_formatted(value))
					.font(.body)
					.fontWeight(.semibold)
					.foregroundStyle(_valueColor(value))
					.padding(.horizontal, 12)
					.padding(.vertical, 6)
					.background(
						Capsule()
							.fill(_valueColor(value).opacity(0.15))
					)
					.copyableText(_formatted(value))
			}
			.padding(.vertical, 2)
		}
	}
	
	private func _makeDisclosureGroup(items: [(String, Any)]) -> some View {
		DisclosureGroup(isExpanded: $_isExpanded) {
			ForEach(items, id: \.0) { item in
				CertificatesInfoEntitlementCellView(key: item.0, value: item.1)
					.padding(.leading, 8)
			}
		} label: {
			HStack {
				Image(systemName: "folder.fill")
					.font(.caption)
					.foregroundStyle(Color.accentColor)
				Text(key)
					.fontWeight(.medium)
			}
		}
		.accentColor(.accentColor)
	}
	
	private func _formatted(_ value: Any) -> String {
		switch value {
		case let bool as Bool: return bool ? "✓" : "✗"
		case let number as NSNumber: return number.stringValue
		case let string as String: return string
		default: return String(describing: value)
		}
	}
	
	private func _typeDescription(_ value: Any) -> String {
		switch value {
		case is Bool: return "Boolean"
		case is NSNumber: return "Number"
		case is String: return "String"
		default: return "Value"
		}
	}
	
	private func _valueColor(_ value: Any) -> Color {
		switch value {
		case let bool as Bool: return bool ? .green : .red
		case is NSNumber: return .blue
		case is String: return .purple
		default: return .secondary
		}
	}
}
