
import SwiftUI

struct ExpandableText: View {
	let text: String
	let lineLimit: Int

	@State private var expanded: Bool = false
	@State private var truncated: Bool = false

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(text)
				.lineLimit(expanded ? nil : lineLimit)
				.background(
					Text(text)
						.lineLimit(lineLimit)
						.background(GeometryReader { proxy in
							Color.clear
								.onAppear {
									let totalHeight = proxy.size.height
									let lineHeight = UIFont.preferredFont(forTextStyle: .body).lineHeight
									truncated = totalHeight > lineHeight * CGFloat(lineLimit)
								}
						})
						.hidden()
				)
                .onTapGesture {pGesture in
                    withAnimation {
                        expanded.toggle()
                    }
                }

			if truncated {
				Button(action: {
					withAnimation {
						expanded.toggle()
					}
				}) {
					Text(expanded ? .localized("View Less") : .localized("See All"))
						.font(.caption)
						.foregroundColor(.accentColor)
				}
			}
		}
	}
}

