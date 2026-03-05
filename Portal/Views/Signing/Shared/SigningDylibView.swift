import SwiftUI
import NimbleViews
import ZsignSwift

// MARK: - View
struct SigningDylibView: View {
	@State private var _dylibs: [String] = []
	@State private var _hiddenDylibCount: Int = 0
	
	var app: AppInfoPresentable
	@Binding var options: Options?
	
	var body: some View {
		NBList(.localized("Dylibs"), type: .list) {
			Section {
				ForEach(_dylibs, id: \.self) { dylib in
					SigningToggleCellView(
						title: dylib,
						options: $options,
						arrayKeyPath: \.disInjectionFiles
					)
					.padding(.vertical, 2)
				}
			} header: {
				HStack {
					Image(systemName: "puzzlepiece.fill")
						.foregroundStyle(
							LinearGradient(
								colors: [Color.orange, Color.red, Color.orange.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("Dynamic Libraries"))
						.font(.subheadline)
						.fontWeight(.semibold)
						.foregroundStyle(
							LinearGradient(
								colors: [Color.primary, Color.orange.opacity(0.6)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
				}
				.textCase(.none)
			}
			.disabled(options == nil)
			
			NBSection(.localized("Hidden")) {
				HStack {
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [
										Color.gray.opacity(0.3),
										Color.gray.opacity(0.2),
										Color.gray.opacity(0.1)
									],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 28, height: 28)
							.shadow(color: Color.gray.opacity(0.3), radius: 4, x: 0, y: 2)
						
						Image(systemName: "eye.slash.fill")
							.font(.caption)
							.foregroundStyle(
								LinearGradient(
									colors: [Color.gray, Color.gray.opacity(0.7), Color.gray.opacity(0.5)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
					}
					
					Text(verbatim: .localized("%lld required system dylibs not shown to user.", arguments: _hiddenDylibCount))
						.font(.footnote)
						.foregroundStyle(
							LinearGradient(
								colors: [Color.secondary, Color.secondary.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
				}
			}
		}
		.onAppear(perform: _loadDylibs)
	}
}

// MARK: - Extension: View
extension SigningDylibView {
	private func _loadDylibs() {
		guard let path = Storage.shared.getAppDirectory(for: app) else { return }
		
		let bundle = Bundle(url: path)
		let execPath = path.appendingPathComponent(bundle?.exec ?? "").relativePath
		
		let allDylibs = Zsign.listDylibs(appExecutable: execPath).map { $0 as String }
		
		_dylibs = allDylibs.filter { $0.hasPrefix("@rpath") || $0.hasPrefix("@executable_path") }
		_hiddenDylibCount = allDylibs.count - _dylibs.count
	}
}
