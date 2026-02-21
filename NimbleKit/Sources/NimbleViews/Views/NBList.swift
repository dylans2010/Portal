import SwiftUI

public struct NBList<Content>: View where Content: View {
	public enum NBListType {
		case list
		case form
	}
	
	private var _title: String
	private var _mode: NavigationBarItem.TitleDisplayMode
	private var _type: NBListType
	private var _content: Content
	
	public init(
		_ title: String,
		displayMode: NavigationBarItem.TitleDisplayMode = .automatic,
		type: NBListType = .form,
		@ViewBuilder content: () -> Content
	) {
		self._title = title
		self._mode = displayMode
		self._type = type
		self._content = content()
	}
	
	public var body: some View {
		Group {
			switch _type {
			case .form:
				Form {
					_content
				}
				.hideScrollContentBackground()
			case .list:
				List {
					_content
				}
				.hideScrollContentBackground()
			}
		}
		.navigationTitle(_title)
		.navigationBarTitleDisplayMode(_mode)
	}
}

extension View {
	@ViewBuilder
	fileprivate func hideScrollContentBackground() -> some View {
		if #available(iOS 16.0, *) {
			self.scrollContentBackground(.hidden)
		} else {
			self
		}
	}
}
