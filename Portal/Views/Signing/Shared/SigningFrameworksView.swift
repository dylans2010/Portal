import SwiftUI
import NimbleViews

// MARK: - View
struct SigningFrameworksView: View {
	@State private var _frameworks: [String] = []
	@State private var _plugins: [String] = []
	
	private let _frameworksPath: String = .localized("Frameworks")
	private let _pluginsPath: String = .localized("PlugIns")
	
	var app: AppInfoPresentable
	@Binding var options: Options?
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Frameworks & Plugins")) {
			Group {
				if !_frameworks.isEmpty {
					Section {
						ForEach(_frameworks, id: \.self) { framework in
							SigningToggleCellView(
								title: "\(self._frameworksPath)/\(framework)",
								options: $options,
								arrayKeyPath: \.removeFiles
							)
							.padding(.vertical, 2)
						}
					} header: {
						HStack {
							Image(systemName: "cube.box.fill")
								.foregroundStyle(
									LinearGradient(
										colors: [Color.blue, Color.blue.opacity(0.7), Color.cyan],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
							Text(_frameworksPath)
								.font(.subheadline)
								.fontWeight(.semibold)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.primary, Color.blue.opacity(0.6)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
						}
						.textCase(.none)
					}
				}
				
				if !_plugins.isEmpty {
					Section {
						ForEach(_plugins, id: \.self) { plugin in
							SigningToggleCellView(
								title: "\(self._pluginsPath)/\(plugin)",
								options: $options,
								arrayKeyPath: \.removeFiles
							)
							.padding(.vertical, 2)
						}
					} header: {
						HStack {
							Image(systemName: "puzzlepiece.extension.fill")
								.foregroundStyle(
									LinearGradient(
										colors: [Color.purple, Color.pink, Color.purple.opacity(0.7)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
							Text(_pluginsPath)
								.font(.subheadline)
								.fontWeight(.semibold)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.primary, Color.purple.opacity(0.6)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
						}
						.textCase(.none)
					}
				}
				
				if
					_frameworks.isEmpty,
					_plugins.isEmpty
				{
					HStack {
						Spacer()
						VStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [
												Color.blue.opacity(0.2),
												Color.cyan.opacity(0.15),
												Color.blue.opacity(0.1)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 60, height: 60)
									.shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 4)
								
								Image(systemName: "cube.transparent")
									.font(.system(size: 30))
									.foregroundStyle(
										LinearGradient(
											colors: [Color.blue, Color.cyan, Color.blue.opacity(0.7)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							Text(.localized("No Frameworks or Plugins Found"))
								.font(.subheadline)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.secondary, Color.secondary.opacity(0.7)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
						}
						.padding(.vertical, 30)
						Spacer()
					}
				}
			}
			.disabled(options == nil)
		}
		.onAppear(perform: _listFrameworksAndPlugins)
	}
}

// MARK: - Extension: View
extension SigningFrameworksView {
	private func _listFrameworksAndPlugins() {
		guard let path = Storage.shared.getAppDirectory(for: app) else { return }
		
		_frameworks = _listFiles(at: path.appendingPathComponent(_frameworksPath))
		_plugins = _listFiles(at: path.appendingPathComponent(_pluginsPath))
	}
	
	private func _listFiles(at path: URL) -> [String] {
		(try? FileManager.default.contentsOfDirectory(atPath: path.path)) ?? []
	}
}
