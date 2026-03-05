import SwiftUI

struct FRAppIconView: View {
	private var _app: AppInfoPresentable
	private var _size: CGFloat
	@AppStorage("Feather.shouldTintIcons") private var _shouldTintIcons: Bool = false
	@AppStorage("Feather.userTintColor") private var _userTintColor: String = "#0077BE"
	@AppStorage("Feather.userTintColorType") private var _colorType: String = "solid"
	@AppStorage("Feather.userTintGradientStart") private var _gradientStartHex: String = "#0077BE"
	@AppStorage("Feather.userInterfaceStyle") private var _userInterfaceStyle: Int = 0

	@State private var _tintedIcon: UIImage?
	@State private var _originalIcon: UIImage?
	
	init(app: AppInfoPresentable, size: CGFloat = 87) {
		self._app = app
		self._size = size
	}
	
	var body: some View {
		Group {
			if _shouldTintIcons {
				if let tintedIcon = _tintedIcon {
					Image(uiImage: tintedIcon)
						.appIconStyle(size: _size)
				} else {
					originalIconView
				}
			} else {
				originalIconView
			}
		}
		.task(id: _app.uuid) {
			await loadIcons()
		}
		.onChange(of: _shouldTintIcons) { newValue in
			if newValue {
				loadTintedIcon()
			}
		}
		.onChange(of: _userTintColor) { _ in loadTintedIcon() }
		.onChange(of: _colorType) { _ in loadTintedIcon() }
		.onChange(of: _gradientStartHex) { _ in loadTintedIcon() }
		.onChange(of: _userInterfaceStyle) { _ in loadTintedIcon() }
	}

	@ViewBuilder
	private var originalIconView: some View {
		if let uiImage = _originalIcon {
			Image(uiImage: uiImage)
				.appIconStyle(size: _size)
		} else {
			Image("App_Unknown")
				.appIconStyle(size: _size)
		}
	}

	private func loadIcons() async {
		guard let bundleURL = await Storage.shared.getAppDirectory(for: _app) else { return }

		let iconFilePath = bundleURL.appendingPathComponent(_app.icon ?? "")
		if let uiImage = UIImage(contentsOfFile: iconFilePath.path) {
			await MainActor.run {
				self._originalIcon = uiImage
			}
		}

		if _shouldTintIcons {
			loadTintedIcon(with: bundleURL)
		}
	}

	private func loadTintedIcon(with bundleURL: URL? = nil) {
		guard _shouldTintIcons else { return }

		Task.detached(priority: .userInitiated) {
			let url: URL?
			if let bundleURL = bundleURL {
				url = bundleURL
			} else {
				url = await Storage.shared.getAppDirectory(for: _app)
			}

			if let url = url, let tinted = iconTest(url) {
				await MainActor.run {
					self._tintedIcon = tinted
				}
			}
		}
	}
}
