// This is LostView aka the old AppIconsPageView but now it will be used when users access unknown pages or accessing private views.

import SwiftUI
import NimbleViews

// MARK: - View
struct LostView: View {
    @Environment(\.dismiss) var dismiss
    var onGoBack: (() -> Void)? = nil

	// MARK: Body
	var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("Are You Lost?")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Why are you here? It's rare for you to be here, how did you even get here in the first place.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section {
                Button(action: {
                    if let onGoBack = onGoBack {
                        onGoBack()
                    } else {
                        dismiss()
                    }
                }) {
                    Text("Go Back")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.accentColor)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
        .scrollContentBackground(.hidden)
        .navigationTitle(.localized("I'm Lost"))
	}
}
