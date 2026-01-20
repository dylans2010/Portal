import SwiftUI
import NimbleViews

// MARK: - View
struct DefaultFrameworksView: View {
	@StateObject private var _manager = DefaultFrameworksManager.shared
	@State private var _isAddingPresenting = false
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Default Frameworks")) {
			NBSection(.localized("Frameworks"), systemName: "puzzlepiece.extension.fill") {
				if !_manager.frameworks.isEmpty {
					ForEach(_manager.frameworks, id: \.absoluteString) { framework in
						_frameworkRow(framework: framework)
					}
				} else {
					_emptyState()
				}
			} footer: {
				Text(.localized("Add any default frameworks you wish to add every time you sign an app. When signing an app, go to Tweaks, then click the \"Add Default Frameworks\" button so all your desired frameworks can get added."))
					.font(.footnote)
					.foregroundColor(.secondary)
			}
		}
		.toolbar {
			NBToolbarButton(
				systemImage: "plus",
				style: .icon,
				placement: .topBarTrailing
			) {
				_isAddingPresenting = true
			}
		}
		.sheet(isPresented: $_isAddingPresenting) {
			FileImporterRepresentableView(
				allowedContentTypes: [.dylib, .deb],
				allowsMultipleSelection: true,
				onDocumentsPicked: { urls in
					guard !urls.isEmpty else { return }
					
					for url in urls {
						_manager.addFramework(url) { result in
							switch result {
							case .success:
								HapticsManager.shared.success()
							case .failure(let error):
								HapticsManager.shared.error()
								UIAlertController.showAlertWithOk(
									title: .localized("Error"),
									message: error.localizedDescription
								)
							}
						}
					}
				}
			)
			.ignoresSafeArea()
		}
		.animation(.spring(response: 0.5, dampingFraction: 0.8), value: _manager.frameworks)
	}
}

// MARK: - Extension: View
extension DefaultFrameworksView {
	@ViewBuilder
	private func _frameworkRow(framework: URL) -> some View {
		HStack(spacing: 12) {
			// Icon
			ZStack {
				Circle()
					.fill(
						LinearGradient(
							colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 40, height: 40)
				
				Image(systemName: framework.pathExtension.lowercased() == "deb" ? "shippingbox.fill" : "puzzlepiece.extension.fill")
					.font(.system(size: 18))
					.foregroundStyle(Color.accentColor)
			}
			
			// Info
			VStack(alignment: .leading, spacing: 2) {
				Text(framework.lastPathComponent)
					.font(.body)
					.lineLimit(1)
				
				Text(framework.pathExtension.uppercased())
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer()
		}
		.padding(.vertical, 4)
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
			_frameworkActions(framework: framework)
		}
		.contextMenu {
			_frameworkActions(framework: framework)
		}
	}
	
	@ViewBuilder
	private func _frameworkActions(framework: URL) -> some View {
		Button(role: .destructive) {
			_manager.removeFramework(framework) {
				HapticsManager.shared.impact()
			}
		} label: {
			Label(.localized("Delete"), systemImage: "trash")
		}
	}
	
	@ViewBuilder
	private func _emptyState() -> some View {
		HStack {
			Spacer()
			VStack(spacing: 12) {
				Image(systemName: "puzzlepiece.extension")
					.font(.system(size: 40))
					.foregroundColor(.secondary.opacity(0.6))
				
				Text(.localized("No Default Frameworks"))
					.font(.subheadline)
					.foregroundColor(.secondary)
				
				Text(.localized("Tap + To Add Frameworks"))
					.font(.caption)
					.foregroundColor(Color(uiColor: .tertiaryLabel))
			}
			.padding(.vertical, 20)
			Spacer()
		}
	}
}
