import SwiftUI
import NimbleViews

// MARK: - View
struct SigningPropertiesView: View {
	@Environment(\.dismiss) var dismiss
	
	@State private var text: String = ""
	
	var saveButtonDisabled: Bool {
		text == initialValue
	}
	
	var title: String
	var initialValue: String 
	@Binding var bindingValue: String?
	
	// MARK: Body
	var body: some View {
		NBList(title) {
			VStack(spacing: 0) {
				TextField(initialValue, text: $text)
					.textInputAutocapitalization(.none)
					.padding()
					.background(
						LinearGradient(
							colors: [
								Color(UIColor.secondarySystemGroupedBackground),
								Color(UIColor.secondarySystemGroupedBackground).opacity(0.95),
								Color.accentColor.opacity(0.02)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: 12, style: .continuous)
							.stroke(
								LinearGradient(
									colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 1
							)
					)
			}
		}
		.toolbar {
			NBToolbarButton(
				.localized("Save"),
				style: .text,
				placement: .topBarTrailing,
				isDisabled: saveButtonDisabled
			) {
				if !saveButtonDisabled {
					bindingValue = text
					dismiss()
				}
			}
		}
		.onAppear {
			text = initialValue
		}
	}
}
