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
        NavigationStack {
            Form {
                _customizationOptions(for: app)
                _cert()
                _customizationProperties(for: app)
            }
            .navigationTitle(app.name ?? .localized("Unknown"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    _start()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "signature")
                        Text(.localized("Start Signing"))
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(.localized("Reset")) {
                        _temporaryOptions = OptionsManager.shared.options
                        appIcon = nil
                    }
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
                    .background(Color.clear)
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
		Section(.localized("Customization")) {
            HStack(spacing: 16) {
                Menu {
                    Button(.localized("Select Alternative Icon"), systemImage: "app.dashed") { _isAltPickerPresenting = true }
                    Button(.localized("Choose From Files"), systemImage: "folder") { _isFilePickerPresenting = true }
                    Button(.localized("Choose From Photos"), systemImage: "photo") { _isImagePickerPresenting = true }
                } label: {
                    if let icon = appIcon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .cornerRadius(12)
                    } else {
                        FRAppIconView(app: app, size: 60)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name ?? .localized("Unknown"))
                        .font(.headline)
                    Text(.localized("Tap icon to change"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)

            _infoCell(.localized("Name"), desc: _temporaryOptions.appName ?? app.name, icon: "pencil") {
                _isNameDialogPresenting = true
            }

            _infoCell(.localized("Identifier"), desc: _temporaryOptions.appIdentifier ?? app.identifier, icon: "barcode") {
                _isIdentifierDialogPresenting = true
            }

            _infoCell(.localized("Version"), desc: _temporaryOptions.appVersion ?? app.version, icon: "tag") {
                _isVersionDialogPresenting = true
            }
		}
	}
	
	@ViewBuilder
	private func _cert() -> some View {
		Section(.localized("Signing")) {
            if let cert = _selectedCert() {
                NavigationLink {
                    CertificatesView(selectedCert: $_temporaryCertificate)
                } label: {
                    CertificatesCellView(cert: cert)
                }
            } else {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(.localized("No Certificate"))
                                .font(.headline)
                            Text(.localized("Add a certificate to continue"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    Button {
                        _isAddingCertificatePresenting = true
                    } label: {
                        Text(.localized("Add Certificate"))
                            .font(.body.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.vertical, 8)
            }
		}
	}
	
	@ViewBuilder
	private func _customizationProperties(for app: AppInfoPresentable) -> some View {
		Section(.localized("Advanced")) {
            NavigationLink {
                SigningDylibView(
                    app: app,
                    options: $_temporaryOptions.optional()
                )
            } label: {
                Label(.localized("Existing Dylibs"), systemImage: "puzzlepiece")
            }

            NavigationLink {
                SigningFrameworksView(
                    app: app,
                    options: $_temporaryOptions.optional()
                )
            } label: {
                Label(.localized("Frameworks & Plugins"), systemImage: "cube.box")
            }

            #if NIGHTLY || DEBUG
            NavigationLink {
                SigningEntitlementsView(
                    bindingValue: $_temporaryOptions.appEntitlementsFile
                )
            } label: {
                Label(.localized("Entitlements") + " (BETA)", systemImage: "lock.shield")
            }
            #endif

            NavigationLink {
                SigningTweaksView(
                    options: $_temporaryOptions
                )
            } label: {
                Label(.localized("Tweaks"), systemImage: "wrench.and.screwdriver")
            }

			NavigationLink {
				Form { SigningOptionsView(
					options: $_temporaryOptions,
					temporaryOptions: _optionsManager.options
				)}
                .navigationTitle(.localized("Properties"))
			} label: {
                Label(.localized("Properties"), systemImage: "slider.horizontal.3")
            }
		}
	}
	
	@ViewBuilder
	private func _infoCell(_ title: String, desc: String?, icon: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			HStack {
				Label(title, systemImage: icon)
				Spacer()
				Text(desc ?? .localized("Unknown"))
					.foregroundStyle(.secondary)
			}
		}
		.foregroundStyle(.primary)
	}
}

// MARK: - Extension: View (import)
extension SigningView {
	private func _start() {
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
