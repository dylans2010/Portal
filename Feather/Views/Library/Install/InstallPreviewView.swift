import SwiftUI
import NimbleViews
import IDeviceSwift

// MARK: - View
struct InstallPreviewView: View {
	@Environment(\.dismiss) var dismiss

	@AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
	@AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
	@AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@State private var _isWebviewPresenting = false
	
	var app: AppInfoPresentable
	@StateObject var viewModel: InstallerStatusViewModel
	@StateObject var installer: ServerInstaller
	
	@State var isSharing: Bool
	@State var fromLibraryTab: Bool = true  // Track if installation was initiated from Library tab
	
	init(app: AppInfoPresentable, isSharing: Bool = false, fromLibraryTab: Bool = true) {
		self.app = app
		self.isSharing = isSharing
		self.fromLibraryTab = fromLibraryTab
		let viewModel = InstallerStatusViewModel(isIdevice: UserDefaults.standard.integer(forKey: "Feather.installationMethod") == 1)
		self._viewModel = StateObject(wrappedValue: viewModel)
		self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
	}

	// MARK: Body
	var body: some View {
		ZStack {
			InstallProgressView(app: app, viewModel: viewModel)
			_status()
			_button()
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
		.background(Color(UIColor.secondarySystemBackground))
		.cornerRadius(12)
		.padding()
		.sheet(isPresented: $_isWebviewPresenting) {
			SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
		}
		.onReceive(viewModel.$status) { newStatus in
			if _installationMethod == 0 {
				if case .ready = newStatus {
					if _serverMethod == 0 {
						UIApplication.shared.open(URL(string: installer.iTunesLink)!)
					} else if _serverMethod == 1 || _serverMethod == 2 {
						// Semi Local or Custom API - open webview for installation
						_isWebviewPresenting = true
					}
				}
				
				if case .sendingPayload = newStatus, (_serverMethod == 1 || _serverMethod == 2) {
					_isWebviewPresenting = false
				}
                
                if case .completed = newStatus {
                    BackgroundAudioManager.shared.stop()
                }
			}
		}
		.onAppear(perform: _install)
        .onAppear {
            BackgroundAudioManager.shared.start()
        }
        .onDisappear {
            BackgroundAudioManager.shared.stop()
        }
	}
	
	@ViewBuilder
	private func _status() -> some View {
		Label(viewModel.statusLabel, systemImage: viewModel.statusImage)
			.padding()
			.labelStyle(.titleAndIcon)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
			.animation(.smooth, value: viewModel.statusImage)
	}
	
	@ViewBuilder
	private func _button() -> some View {
		ZStack {
			if viewModel.isCompleted {
				if fromLibraryTab {
					// Show only Open button when installing from Library tab (original behavior)
					Button {
						UIApplication.openApp(with: app.identifier ?? "")
					} label: {
						NBButton("Open", systemImage: "", style: .text)
					}
					.padding()
					.compatTransition()
				} else {
					// Show Install and Modify buttons when installing from sources or elsewhere
					HStack(spacing: 12) {
						// Modify button - opens signing page
						Button {
							// Dismiss current sheet and navigate to signing
							dismiss()
							// Post notification to open signing view
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
								NotificationCenter.default.post(
									name: Notification.Name("Feather.openSigningView"),
									object: app
								)
							}
						} label: {
							HStack(spacing: 6) {
								Image(systemName: "pencil")
									.font(.system(size: 14, weight: .semibold))
								Text("Modify")
									.font(.system(size: 15, weight: .semibold))
							}
							.foregroundStyle(.white)
							.padding(.horizontal, 20)
							.padding(.vertical, 10)
							.background(
								LinearGradient(
									colors: [Color.accentColor, Color.accentColor.opacity(0.9)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.clipShape(Capsule())
							.shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
						}
						
						// Install button - triggers immediate installation
						Button {
							// Reset viewModel and re-trigger installation
							viewModel.status = .none
							viewModel.uploadProgress = 0
							viewModel.packageProgress = 0
							viewModel.installProgress = 0
							_install()
						} label: {
							HStack(spacing: 6) {
								Image(systemName: "arrow.down.circle.fill")
									.font(.system(size: 14, weight: .semibold))
								Text("Install")
									.font(.system(size: 15, weight: .semibold))
							}
							.foregroundStyle(.white)
							.padding(.horizontal, 20)
							.padding(.vertical, 10)
							.background(
								LinearGradient(
									colors: [Color.green, Color.green.opacity(0.9)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.clipShape(Capsule())
							.shadow(color: Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
						}
					}
					.padding()
					.compatTransition()
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
		.animation(.easeInOut(duration: 0.3), value: viewModel.isCompleted)
	}

	private func _install() {
		guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
			UIAlertController.showAlertWithOk(
				title: .localized("Install"),
				message: .localized("You cannot update '%@' with itself, please use an alternative tool to update it like a online signer or diffrent app.", arguments: Bundle.main.name)
			)
			return
		}
		
		Task.detached {
			do {
				let handler = await ArchiveHandler(app: app, viewModel: viewModel)
				try await handler.move()
				
				let packageUrl = try await handler.archive()
				
				if await !isSharing {
					if await _installationMethod == 0 {
						await MainActor.run {
							installer.packageUrl = packageUrl
							viewModel.status = .ready
						}
					} else if await _installationMethod == 1 {
						let handler = await InstallationProxy(viewModel: viewModel)
						try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
					}
				} else {
					let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
					
					if await !_useShareSheet {
						await MainActor.run {
							dismiss()
						}
					} else {
						if let package {
							await MainActor.run {
								dismiss()
								UIActivityViewController.show(activityItems: [package])
							}
						}
					}
				}
			} catch {
				await MainActor.run {
					UIAlertController.showAlertWithOk(
						title: .localized("Install"),
						message: String(describing: error),
						action: {
							HeartbeatManager.shared.start(true)
							dismiss()
						}
					)
				}
			}
		}
	}
}

// MARK: - Helper ViewModifier for iOS 16 compatibility
struct ContentTransitionModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.symbolEffect)
        } else {
            content
                .animation(.easeInOut(duration: 0.2), value: UUID())
        }
    }
}
