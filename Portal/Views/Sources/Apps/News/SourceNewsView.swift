import SwiftUI
import AltSourceKit
import NimbleViews

// MARK: - View
struct SourceNewsView: View {
	@State var isLoading = true
	@State var hasLoadedInitialData = false
	
	@State private var _selectedNewsPresenting: ASRepository.News?
	
	@Namespace private var _namespace
	
	var news: [ASRepository.News]?
	
	// MARK: Body
	var body: some View {
		VStack {
			if
				let news,
				!news.isEmpty
			{
				ScrollView(.horizontal, showsIndicators: false) {
					LazyHStack(spacing: 16) {
						ForEach(news.reversed().enumerated().map { ($0, $1) }, id: \.1.id) { index, new in
							Button {
								_selectedNewsPresenting = new
							} label: {
								SourceNewsCardView(new: new)
									.compatMatchedTransitionSource(id: new.id, ns: _namespace)
									.scaleEffect(isLoading ? 0.8 : 1.0)
									.opacity(isLoading ? 0 : 1)
									.offset(y: isLoading ? 20 : 0)
									.animation(
										.spring(response: 0.6, dampingFraction: 0.8)
											.delay(Double(index) * 0.1),
										value: isLoading
									)
							}
						}
					}
					.padding(.horizontal, 16)
				}
				.frame(height: 170)
				.transition(AnyTransition.opacity)
			}
		}
		.frame(height: (news?.isEmpty == false) ? 180 : 0)
		.onAppear {
			if !hasLoadedInitialData && news?.isEmpty == false {
				_load()
				hasLoadedInitialData = true
			}
		}
		.fullScreenCover(item: $_selectedNewsPresenting) { new in
			SourceNewsCardInfoView(new: new)
				.compatNavigationTransition(id: new.id, ns: _namespace)
		}
	}
	
	private func _load() {
		withAnimation(.easeIn(duration: 0.3)) {
			isLoading = false
		}
	}
}
