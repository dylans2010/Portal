import SwiftUI
import NimbleViews

// MARK: - View
struct SigningOptionsView: View {
	@Binding var options: Options
	var temporaryOptions: Options?
	@State private var accentColor: Color = .accentColor
	@State private var showPPQInfo = false
	
	// Check if any certificate has PPQCheck
	private var hasCertificateWithPPQCheck: Bool {
		let certificates = Storage.shared.getAllCertificates()
		return certificates.contains { $0.ppQCheck }
	}
	
	// MARK: Body
	var body: some View {
		if (temporaryOptions == nil) {
			Section {
				Toggle(isOn: Binding(
					get: { options.ppqProtection },
					set: { newValue in
						// Only allow disabling if no certificate has PPQCheck
						if !hasCertificateWithPPQCheck || newValue {
							options.ppqProtection = newValue
						}
					}
				)) {
					Label(.localized("PPQ Protection"), systemImage: "shield.checkered")
				}
				.disabled(hasCertificateWithPPQCheck)
				
				Button {
					HapticsManager.shared.impact()
					showPPQInfo = true
				} label: {
					HStack(spacing: 12) {
						Image(systemName: "questionmark.circle.fill")
							.foregroundStyle(
								LinearGradient(
									colors: [accentColor, accentColor.opacity(0.7)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
						Text(.localized("What is PPQ?"))
							.foregroundStyle(.primary)
						Spacer()
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
				}
			} header: {
				HStack(spacing: 8) {
					Image(systemName: "shield.lefthalf.filled")
						.font(.subheadline)
						.foregroundStyle(
							LinearGradient(
								colors: [accentColor, accentColor.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
					Text(.localized("Protection"))
						.fontWeight(.semibold)
				}
				.textCase(.none)
			} footer: {
				if hasCertificateWithPPQCheck {
					Text(.localized("PPQ Protection is automatically enabled and required because one or more of your certificates has PPQCheck. This helps protect your Apple ID from being flagged."))
				} else {
					Text(.localized("Enabling any protection will append a random string to the bundleidentifiers of the apps you sign, this is to ensure your Apple ID does not get flagged by Apple. However, when using a signing service you can ignore this."))
				}
			}
		}
		
		Section {
			Self.picker(
				.localized("Appearance"),
				systemImage: "paintpalette.fill",
				selection: $options.appAppearance,
				values: Options.AppAppearance.allCases
			)
			
			Self.picker(
				.localized("Minimum Requirement"),
				systemImage: "ruler.fill",
				selection: $options.minimumAppRequirement,
				values: Options.MinimumAppRequirement.allCases
			)
		} header: {
			HStack(spacing: 8) {
				Image(systemName: "gearshape.2.fill")
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [accentColor, accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("General"))
					.fontWeight(.semibold)
			}
			.textCase(.none)
		}
		
		Section {
			Self.picker(
				.localized("Signing Type"),
				systemImage: "signature",
				selection: $options.signingOption,
				values: Options.SigningOption.allCases
			)
		} header: {
			HStack(spacing: 8) {
				Image(systemName: "pencil.and.scribble")
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [accentColor, accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("Signing"))
					.fontWeight(.semibold)
			}
			.textCase(.none)
		}
		
		Section {
			_toggle(
				.localized("File Sharing"),
				systemImage: "folder.fill.badge.person.crop",
				isOn: $options.fileSharing,
				temporaryValue: temporaryOptions?.fileSharing
			)
			
			_toggle(
				.localized("iTunes File Sharing"),
				systemImage: "music.note.list",
				isOn: $options.itunesFileSharing,
				temporaryValue: temporaryOptions?.itunesFileSharing
			)
			
			_toggle(
				.localized("Pro Motion"),
				systemImage: "gauge.with.dots.needle.67percent",
				isOn: $options.proMotion,
				temporaryValue: temporaryOptions?.proMotion
			)
			
			_toggle(
				.localized("Game Mode"),
				systemImage: "gamecontroller.fill",
				isOn: $options.gameMode,
				temporaryValue: temporaryOptions?.gameMode
			)
			
			_toggle(
				.localized("iPad Fullscreen"),
				systemImage: "ipad.landscape",
				isOn: $options.ipadFullscreen,
				temporaryValue: temporaryOptions?.ipadFullscreen
			)
		} header: {
			HStack(spacing: 8) {
				Image(systemName: "sparkles")
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [accentColor, accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("App Features"))
					.fontWeight(.semibold)
			}
			.textCase(.none)
		}
		
		Section {
			_toggle(
				.localized("Remove URL Scheme"),
				systemImage: "link.badge.minus",
				isOn: $options.removeURLScheme,
				temporaryValue: temporaryOptions?.removeURLScheme
			)
			
			_toggle(
				.localized("Remove Provisioning"),
				systemImage: "doc.badge.minus",
				isOn: $options.removeProvisioning,
				temporaryValue: temporaryOptions?.removeProvisioning
			)
		} header: {
			HStack(spacing: 8) {
				Image(systemName: "trash.slash.fill")
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.red, Color.red.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("Removal"))
					.fontWeight(.semibold)
			}
			.textCase(.none)
		} footer: {
			Text(.localized("Removing the provisioning file will exclude the mobileprovision file from being embedded inside of the application when signing, to help prevent any detection."))
		}
		
		Section {
			_toggle(
				.localized("Force Localize"),
				systemImage: "character.bubble.fill",
				isOn: $options.changeLanguageFilesForCustomDisplayName,
				temporaryValue: temporaryOptions?.changeLanguageFilesForCustomDisplayName
			)
		} header: {
			HStack(spacing: 8) {
				Image(systemName: "globe.badge.chevron.backward")
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [accentColor, accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("Localization"))
					.fontWeight(.semibold)
			}
			.textCase(.none)
		} footer: {
			Text(.localized("By default, localized titles for the app won't be changed, however this option overrides it."))
		}
		
		Section {
            _toggle(
                .localized("Install After Signing"),
                systemImage: "arrow.down.circle.fill",
                isOn: $options.post_installAppAfterSigned,
                temporaryValue: temporaryOptions?.post_installAppAfterSigned
            )
			_toggle(
				.localized("Delete After Signing"),
				systemImage: "trash.fill",
				isOn: $options.post_deleteAppAfterSigned,
				temporaryValue: temporaryOptions?.post_deleteAppAfterSigned
			)
		} header: {
			HStack(spacing: 8) {
				Image(systemName: "clock.arrow.circlepath")
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [accentColor, accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("Post Signing"))
					.fontWeight(.semibold)
			}
			.textCase(.none)
		} footer: {
			Text(.localized("This will delete your imported application after signing, to save on using unneeded space."))
		}
		
		Section {
			_toggle(
				.localized("Replace Substrate with ElleKit"),
				systemImage: "arrow.triangle.2.circlepath.circle.fill",
				isOn: $options.experiment_replaceSubstrateWithEllekit,
				temporaryValue: temporaryOptions?.experiment_replaceSubstrateWithEllekit
			)
			
			_toggle(
				.localized("Enable Liquid Glass"),
				systemImage: "sparkles.rectangle.stack.fill",
				isOn: $options.experiment_supportLiquidGlass,
				temporaryValue: temporaryOptions?.experiment_supportLiquidGlass
			)
		} header: {
			HStack(spacing: 8) {
				Image(systemName: "flask.fill")
					.font(.subheadline)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.purple, Color.purple.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				Text(.localized("Experiments"))
					.fontWeight(.semibold)
			}
			.textCase(.none)
		} footer: {
			Text(.localized("This option force converts apps to try to use the new liquid glass redesign iOS 26 introduced, this may not work for all applications due to differing frameworks."))
		}
		.alert(.localized("What is PPQ?"), isPresented: $showPPQInfo) {
			Button(.localized("OK"), role: .cancel) {}
		} message: {
			Text(.localized("PPQ is a check Apple has added to certificates. If you have this check, change your Bundle IDs when signing apps to avoid Apple revoking your certificates."))
		}
	}
	
	@ViewBuilder
	static func picker<SelectionValue: Hashable, T: Hashable & LocalizedDescribable>(
		_ title: String,
		systemImage: String,
		selection: Binding<SelectionValue>,
		values: [T]
	) -> some View {
		Picker(selection: selection) {
			ForEach(values, id: \.self) { value in
				Text(value.localizedDescription)
			}
		} label: {
			Label(title, systemImage: systemImage)
		}
	}
	
	@ViewBuilder
	private func _toggle(
		_ title: String,
		systemImage: String,
		isOn: Binding<Bool>,
		temporaryValue: Bool? = nil
	) -> some View {
		Toggle(isOn: isOn) {
			Label {
				if let tempValue = temporaryValue, tempValue != isOn.wrappedValue {
					Text(title).bold()
				} else {
					Text(title)
				}
			} icon: {
				Image(systemName: systemImage)
			}
		}
	}
}
