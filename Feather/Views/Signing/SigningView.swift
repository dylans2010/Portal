import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - View
struct SigningView: View {
	@Environment(\.dismiss) var dismiss
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@StateObject private var _optionsManager = OptionsManager.shared
	
	@State private var _temporaryOptions: Options = OptionsManager.shared.options
	@State private var _temporaryCertificate: Int
	@State private var _isAltPickerPresenting = false
	@State private var _isFilePickerPresenting = false
	@State private var _isImagePickerPresenting = false
	@State private var _isSigning = false
	@State private var _selectedPhoto: PhotosPickerItem? = nil
	@State var appIcon: UIImage?
	
	@State private var _isNameDialogPresenting = false
	@State private var _isIdentifierDialogPresenting = false
	@State private var _isVersionDialogPresenting = false
    @State private var _isSigningProcessPresented = false
	@State private var _isAddingCertificatePresenting = false
	
	// MARK: Fetch
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .easeInOut(duration: 0.35)
	) private var certificates: FetchedResults<CertificatePair>
	
	private func _selectedCert() -> CertificatePair? {
		guard certificates.indices.contains(_temporaryCertificate) else { return nil }
		return certificates[_temporaryCertificate]
	}
	
	var app: AppInfoPresentable
	
	init(app: AppInfoPresentable) {
		self.app = app
		let storedCert = UserDefaults.standard.integer(forKey: "feather.selectedCert")
		__temporaryCertificate = State(initialValue: storedCert)
	}
		
	// MARK: Body
    var body: some View {
		NBNavigationView(app.name ?? .localized("Unknown"), displayMode: .inline) {
			ScrollView {
				VStack(spacing: 20) {
					_customizationOptions(for: app)
					_cert()
					_customizationProperties(for: app)
					
					// Bottom padding for button
					Spacer()
						.frame(height: 100)
				}
				.padding(.horizontal)
				.padding(.top, 12)
			}
			.background(
				LinearGradient(
					colors: [
						Color(UIColor.systemGroupedBackground),
						Color(UIColor.systemGroupedBackground).opacity(0.95),
						Color.accentColor.opacity(0.02),
						Color(UIColor.systemGroupedBackground)
					],
					startPoint: .top,
					endPoint: .bottom
				)
			)
			.overlay(alignment: .bottom) {
				VStack(spacing: 0) {
					// Gradient fade effect
					LinearGradient(
						colors: [
							Color(UIColor.systemGroupedBackground).opacity(0),
							Color(UIColor.systemGroupedBackground).opacity(0.8),
							Color(UIColor.systemGroupedBackground).opacity(0.95),
							Color(UIColor.systemGroupedBackground)
						],
						startPoint: .top,
						endPoint: .bottom
					)
					.frame(height: 40)
					
					// Modern floating button with gradient
					Button {
						_start()
					} label: {
						HStack(spacing: 12) {
							Image(systemName: "signature")
								.font(.system(size: 18, weight: .semibold))
							Text(.localized("Start Signing"))
								.font(.system(size: 17, weight: .semibold))
						}
						.foregroundStyle(.white)
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(
							ZStack {
								// Shadow layer
								Capsule()
									.fill(Color.accentColor.opacity(0.3))
									.blur(radius: 6)
									.offset(y: 3)
								
								// Main gradient with multiple colors
								Capsule()
									.fill(
										LinearGradient(
											colors: [
												Color.accentColor,
												Color.accentColor.opacity(0.9),
												Color.accentColor.opacity(0.85)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
						)
						.clipShape(Capsule())
						.shadow(color: Color.accentColor.opacity(0.5), radius: 15, x: 0, y: 8)
					}
					.padding(.horizontal, 20)
					.padding(.vertical, 12)
					.background(
						LinearGradient(
							colors: [
								Color(UIColor.systemGroupedBackground),
								Color(UIColor.systemGroupedBackground).opacity(0.98)
							],
							startPoint: .top,
							endPoint: .bottom
						)
					)
				}
				.ignoresSafeArea(edges: .bottom)
			}

			.toolbar {
				NBToolbarButton(role: .dismiss)
				NBToolbarButton(
					.localized("Reset"),
					style: .text,
					placement: .topBarTrailing
				) {
					_temporaryOptions = OptionsManager.shared.options
					appIcon = nil
				}
			}
			.sheet(isPresented: $_isAltPickerPresenting) { SigningAlternativeIconView(app: app, appIcon: $appIcon, isModifing: .constant(true)) }
			.sheet(isPresented: $_isFilePickerPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.image],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self.appIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
					}
				)
				.ignoresSafeArea()
			}
			.photosPicker(isPresented: $_isImagePickerPresenting, selection: $_selectedPhoto)
			.onChange(of: _selectedPhoto) { newValue in
				guard let newValue else { return }
				
				Task {
					if let data = try? await newValue.loadTransferable(type: Data.self),
					   let image = UIImage(data: data)?.resizeToSquare() {
						appIcon = image
					}
				}
			}
			.disabled(_isSigning)
			.animation(animationForPlatform(), value: _isSigning)
            .fullScreenCover(isPresented: $_isSigningProcessPresented) {
                if #available(iOS 17.0, *) {
                    SigningProcessView(
                        appName: _temporaryOptions.appName ?? app.name ?? "App",
                        appIcon: appIcon
                    )
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Signing \( _temporaryOptions.appName ?? app.name ?? "App")...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                }
            }
			.sheet(isPresented: $_isAddingCertificatePresenting) {
				CertificatesAddView()
					.presentationDetents([.medium])
			}
		}
		.alert(.localized("Name"), isPresented: $_isNameDialogPresenting) {
			TextField(_temporaryOptions.appName ?? (app.name ?? ""), text: Binding(
				get: { _temporaryOptions.appName ?? app.name ?? "" },
				set: { _temporaryOptions.appName = $0 }
			))
			.textInputAutocapitalization(.none)
			Button(.localized("Cancel"), role: .cancel) { }
			Button(.localized("Save")) { }
		}
		.alert(.localized("Identifier"), isPresented: $_isIdentifierDialogPresenting) {
			TextField(_temporaryOptions.appIdentifier ?? (app.identifier ?? ""), text: Binding(
				get: { _temporaryOptions.appIdentifier ?? app.identifier ?? "" },
				set: { _temporaryOptions.appIdentifier = $0 }
			))
			.textInputAutocapitalization(.none)
			Button(.localized("Cancel"), role: .cancel) { }
			Button(.localized("Save")) { }
		}
		.alert(.localized("Version"), isPresented: $_isVersionDialogPresenting) {
			TextField(_temporaryOptions.appVersion ?? (app.version ?? ""), text: Binding(
				get: { _temporaryOptions.appVersion ?? app.version ?? "" },
				set: { _temporaryOptions.appVersion = $0 }
			))
			.textInputAutocapitalization(.none)
			Button(.localized("Cancel"), role: .cancel) { }
			Button(.localized("Save")) { }
		}
		.onAppear {
			// ppq protection (previously broken lmao)
			if
				_optionsManager.options.ppqProtection,
				let identifier = app.identifier,
				let cert = _selectedCert(),
				cert.ppQCheck
			{
				_temporaryOptions.appIdentifier = "\(identifier).\(_optionsManager.options.ppqString)"
			}
			
			if
				let currentBundleId = app.identifier,
				let newBundleId = _temporaryOptions.identifiers[currentBundleId]
			{
				_temporaryOptions.appIdentifier = newBundleId
			}
			
			if
				let currentName = app.name,
				let newName = _temporaryOptions.displayNames[currentName]
			{
				_temporaryOptions.appName = newName
			}
		}
    }
}

// MARK: - Extension: View
extension SigningView {
	@ViewBuilder
	private func _customizationOptions(for app: AppInfoPresentable) -> some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(.localized("Customization"))
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 4)
			
			VStack(spacing: 0) {
				// Enhanced icon selection with gradient background
				HStack(spacing: 16) {
					Menu {
						Button(.localized("Select Alternative Icon"), systemImage: "app.dashed") { _isAltPickerPresenting = true }
						Button(.localized("Choose From Files"), systemImage: "folder") { _isFilePickerPresenting = true }
						Button(.localized("Choose From Photos"), systemImage: "photo") { _isImagePickerPresenting = true }
					} label: {
						ZStack {
							if let icon = appIcon {
								Image(uiImage: icon)
									.appIconStyle()
									.shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
							} else {
								FRAppIconView(app: app, size: 64)
									.shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
							}
						}
					}
					
					VStack(alignment: .leading, spacing: 4) {
						Text(app.name ?? .localized("Unknown"))
							.font(.title3)
							.fontWeight(.bold)
							.foregroundStyle(
								LinearGradient(
									colors: [Color.primary, Color.primary.opacity(0.8)],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
						
						Text(.localized("Tap icon to change"))
							.font(.caption)
							.foregroundStyle(.secondary)
					}
					
					Spacer()
				}
				.padding()
				.background(
					LinearGradient(
						colors: [
							Color(UIColor.secondarySystemGroupedBackground),
							Color(UIColor.secondarySystemGroupedBackground).opacity(0.95),
							Color.accentColor.opacity(0.02)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
				.overlay(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.stroke(
							LinearGradient(
								colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							),
							lineWidth: 1
						)
				)
				
				Divider()
					.padding(.vertical, 8)
				
				VStack(spacing: 0) {
					_infoCell(.localized("Name"), desc: _temporaryOptions.appName ?? app.name, icon: "pencil") {
						_isNameDialogPresenting = true
					}
					
					Divider()
						.padding(.leading, 52)
					
					_infoCell(.localized("Identifier"), desc: _temporaryOptions.appIdentifier ?? app.identifier, icon: "barcode") {
						_isIdentifierDialogPresenting = true
					}
					
					Divider()
						.padding(.leading, 52)
					
					_infoCell(.localized("Version"), desc: _temporaryOptions.appVersion ?? app.version, icon: "tag") {
						_isVersionDialogPresenting = true
					}
				}
				.background(Color(UIColor.secondarySystemGroupedBackground))
				.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
			}
		}
	}
	
	@ViewBuilder
	private func _cert() -> some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(.localized("Signing"))
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 4)
			
			VStack(spacing: 0) {
				if let cert = _selectedCert() {
					NavigationLink {
						CertificatesView(selectedCert: $_temporaryCertificate)
					} label: {
						CertificatesCellView(cert: cert)
							.padding()
					}
					.background(
						LinearGradient(
							colors: [
								Color(UIColor.secondarySystemGroupedBackground),
								Color(UIColor.secondarySystemGroupedBackground).opacity(0.95),
								Color.accentColor.opacity(0.02)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: 14, style: .continuous)
							.stroke(
								LinearGradient(
									colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 1
							)
					)
				} else {
					VStack(spacing: 16) {
						HStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.15)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 44, height: 44)
								
								Image(systemName: "exclamationmark.triangle.fill")
									.font(.title3)
									.foregroundStyle(
										LinearGradient(
											colors: [Color.orange, Color.orange.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							VStack(alignment: .leading, spacing: 4) {
								Text(.localized("No Certificate"))
									.font(.headline)
									.foregroundColor(.primary)
								Text(.localized("Add a certificate to continue"))
									.font(.caption)
									.foregroundColor(.secondary)
							}
							Spacer()
						}
						
						Button {
							_isAddingCertificatePresenting = true
						} label: {
							HStack(spacing: 10) {
								Image(systemName: "plus.circle.fill")
									.font(.body)
								Text(.localized("Add Certificate"))
									.font(.body.weight(.semibold))
							}
							.foregroundStyle(.white)
							.frame(maxWidth: .infinity)
							.padding(.vertical, 14)
							.background(
								LinearGradient(
									colors: [Color.accentColor, Color.accentColor.opacity(0.9), Color.accentColor.opacity(0.8)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
							.shadow(color: Color.accentColor.opacity(0.4), radius: 10, x: 0, y: 5)
						}
					}
					.padding()
					.background(
						LinearGradient(
							colors: [
								Color(UIColor.secondarySystemGroupedBackground),
								Color(UIColor.secondarySystemGroupedBackground).opacity(0.95),
								Color.orange.opacity(0.03)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: 14, style: .continuous)
							.stroke(
								LinearGradient(
									colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 1.5
							)
					)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _customizationProperties(for app: AppInfoPresentable) -> some View {
		VStack(alignment: .leading, spacing: 16) {
			Text(.localized("Advanced"))
				.font(.headline)
				.foregroundStyle(.primary)
				.padding(.horizontal, 4)
			
			VStack(spacing: 0) {
				DisclosureGroup(
                content: {
					VStack(spacing: 0) {
						NavigationLink {
							SigningDylibView(
								app: app,
								options: $_temporaryOptions.optional()
							)
						} label: {
							HStack {
								Label(.localized("Existing Dylibs"), systemImage: "puzzlepiece")
								Spacer()
								Image(systemName: "chevron.right")
									.font(.caption)
									.foregroundStyle(.tertiary)
							}
							.padding()
						}
						
						Divider()
							.padding(.leading, 52)
						
						NavigationLink {
							SigningFrameworksView(
								app: app,
								options: $_temporaryOptions.optional()
							)
						} label: {
							HStack {
								Label(.localized("Frameworks & Plugins"), systemImage: "cube.box")
								Spacer()
								Image(systemName: "chevron.right")
									.font(.caption)
									.foregroundStyle(.tertiary)
							}
							.padding()
						}
						
						#if NIGHTLY || DEBUG
						Divider()
							.padding(.leading, 52)
						
						NavigationLink {
							SigningEntitlementsView(
								bindingValue: $_temporaryOptions.appEntitlementsFile
							)
						} label: {
							HStack {
								Label(.localized("Entitlements") + " (BETA)", systemImage: "lock.shield")
								Spacer()
								Image(systemName: "chevron.right")
									.font(.caption)
									.foregroundStyle(.tertiary)
							}
							.padding()
						}
						#endif
						
						Divider()
							.padding(.leading, 52)
						
						NavigationLink {
							SigningTweaksView(
								options: $_temporaryOptions
							)
						} label: {
							HStack {
								Label(.localized("Tweaks"), systemImage: "wrench.and.screwdriver")
								Spacer()
								Image(systemName: "chevron.right")
									.font(.caption)
									.foregroundStyle(.tertiary)
							}
							.padding()
						}
					}
                },
                label: {
					HStack {
						Label(.localized("Modify"), systemImage: "hammer")
						Spacer()
					}
					.padding()
                }
            )
			.tint(.primary)
			
			Divider()
			
			NavigationLink {
				Form { SigningOptionsView(
					options: $_temporaryOptions,
					temporaryOptions: _optionsManager.options
				)}
				.navigationTitle(.localized("Properties"))
			} label: {
				HStack {
					Label(.localized("Properties"), systemImage: "slider.horizontal.3")
					Spacer()
					Image(systemName: "chevron.right")
						.font(.caption)
						.foregroundStyle(.tertiary)
				}
				.padding()
            }
			}
			.background(Color(UIColor.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
		}
	}
	
	@ViewBuilder
	private func _infoCell(_ title: String, desc: String?, icon: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			HStack(spacing: 12) {
				Image(systemName: icon)
					.font(.body)
					.foregroundStyle(.secondary)
					.frame(width: 28)
				
				Text(title)
					.font(.body)
					.foregroundStyle(.primary)
				
				Spacer()
				
				Text(desc ?? .localized("Unknown"))
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.lineLimit(1)
				
				Image(systemName: "chevron.right")
					.font(.caption)
					.foregroundStyle(.tertiary)
			}
			.padding()
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Extension: View (import)
extension SigningView {
	private func _start() {
		// CRITICAL: Check for .dylib files before signing
		if DylibDetector.shared.hasDylibs() {
			UIAlertController.showAlertWithOk(
				title: .localized("Dynamic Libraries Detected"),
				message: .localized("Sorry but you may not add any .dylib or .deb files to this app. Please resign the app without any additional frameworks to proceed.")
			)
			return
		}

		guard
			let cert = _selectedCert()
		else {
			UIAlertController.showAlertWithOk(
				title: .localized("No Certificate"),
				message: .localized("Please go to Settings and import a certificate"),
				isCancel: true
			)
			return
		}

		HapticsManager.shared.impact()
		_isSigning = true
        _isSigningProcessPresented = true
		
        if _serverMethod == 2 {
            // Custom API - uses remote signing with custom endpoint
            FR.remoteSignPackageFile(
                app,
                using: _temporaryOptions,
                certificate: cert
            ) { result in
				DispatchQueue.main.async {
					_isSigning = false
					_isSigningProcessPresented = false
					
					switch result {
					case .success(let installLink):
						// Send notification if enabled
						if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
							NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
						}
						
						let install = UIAlertAction(title: .localized("Install"), style: .default) { _ in
							if let url = URL(string: installLink) {
								UIApplication.shared.open(url)
							}
						}
						let copy = UIAlertAction(title: .localized("Copy Link"), style: .default) { _ in
							UIPasteboard.general.string = installLink
						}
						let cancel = UIAlertAction(title: .localized("Cancel"), style: .cancel)
						
						UIAlertController.showAlert(
							title: .localized("Signing Successful"),
							message: .localized("Your app is ready to install."),
							actions: [install, copy, cancel]
						)
						
					case .failure(let error):
						let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
						UIAlertController.showAlert(
							title: "Error",
							message: error.localizedDescription,
							actions: [ok]
						)
					}
				}
            }
        } else {
            // Local or Semi-Local
            FR.signPackageFile(
                app,
                using: _temporaryOptions,
                icon: appIcon,
                certificate: cert
            ) { error in
                if let error {
                    _isSigningProcessPresented = false
                    let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel) { _ in
                        dismiss()
                    }
                    
                    UIAlertController.showAlert(
                        title: "Error",
                        message: error.localizedDescription,
                        actions: [ok]
                    )
                } else {
                    if
                        _temporaryOptions.post_deleteAppAfterSigned,
                        !app.isSigned
                    {
                        Storage.shared.deleteApp(for: app)
                    }
                    
                    // Send notification if enabled
                    if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
                        NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
                    }
                    
                    if _temporaryOptions.post_installAppAfterSigned {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: nil)
                        }
                    }
                    dismiss()
                }
            }
        }
	}
    
    private func animationForPlatform() -> Animation {
        if #available(iOS 17.0, *) {
            return .smooth
        } else {
            return .easeInOut(duration: 0.35)
        }
    }
}
