// This is LostView aka the old AppIconsPageView but now it will be used when users access unknown pages or accessing private views.

import SwiftUI
import NimbleViews

// MARK: - View
struct AppIconsPageView: View {
	@Binding var currentIcon: String?
	
	// MARK: Body
	var body: some View {
		NBNavigationView(.localized("I'm Lost")) {
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
			}
            .hideScrollContentBackground()
		}
	}
}
