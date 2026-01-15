import SwiftUI
import NimbleViews

// MARK: - View
struct SigningTweaksView: View {
	@State private var _isAddingPresenting = false
	@StateObject private var _defaultFrameworksManager = DefaultFrameworksManager.shared
	
	@Binding var options: Options
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Tweaks")) {
			NBSection(.localized("Injection")) {
				SigningOptionsView.picker(
					.localized("Injection Path"),
					systemImage: "doc.badge.gearshape",
					selection: $options.injectPath,
					values: Options.InjectPath.allCases
				)
				.padding(.vertical, 4)
				
				SigningOptionsView.picker(
					.localized("Injection Folder"),
					systemImage: "folder.badge.gearshape",
					selection: $options.injectFolder,
					values: Options.InjectFolder.allCases
				)
				.padding(.vertical, 4)
			}
			
			NBSection(.localized("Tweaks"), systemName: "wrench.and.screwdriver.fill") {
				// Add Default Frameworks button
				if !_defaultFrameworksManager.frameworks.isEmpty {
					Button {
						_addDefaultFrameworks()
					} label: {
						HStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [Color.blue, Color.cyan, Color.blue.opacity(0.7)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 40, height: 40)
									.shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 3)
								
								Image(systemName: "plus.rectangle.on.folder.fill")
									.font(.system(size: 18))
									.foregroundStyle(.white)
							}
							
							VStack(alignment: .leading, spacing: 2) {
								Text(.localized("Add Default Frameworks"))
									.font(.body)
									.foregroundStyle(.primary)
								
								Text(.localized("\(_defaultFrameworksManager.frameworks.count) framework(s) available"))
									.font(.caption)
									.foregroundStyle(.secondary)
							}
							
							Spacer()
							
							Image(systemName: "chevron.right")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						.padding(.vertical, 4)
					}
					.buttonStyle(.plain)
				}
				
				if !options.injectionFiles.isEmpty {
					ForEach(options.injectionFiles, id: \.absoluteString) { tweak in
						_file(tweak: tweak)
					}
				} else {
					HStack {
						Spacer()
						VStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [
												Color.purple.opacity(0.3),
												Color.pink.opacity(0.2),
												Color.purple.opacity(0.1)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 50, height: 50)
									.shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 4)
								
								Image(systemName: "puzzlepiece.extension")
									.font(.system(size: 40))
									.foregroundStyle(
										LinearGradient(
											colors: [Color.purple, Color.pink, Color.purple.opacity(0.7)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							Text(verbatim: .localized("No Files Chosen"))
								.font(.subheadline)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.secondary, Color.secondary.opacity(0.7)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
						}
						.padding(.vertical, 20)
						Spacer()
					}
				}
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
						FileManager.default.moveAndStore(url, with: "PortalTweak") { url in
							options.injectionFiles.append(url)
						}
					}
				}
			)
			.ignoresSafeArea()
		}
		.animation(.spring(response: 0.5, dampingFraction: 0.8), value: options.injectionFiles)
	}
}

// MARK: - Extension: View
extension SigningTweaksView {
	/// Add all default frameworks to the current signing options
	private func _addDefaultFrameworks() {
		Task {
			var tempDirToCleanup: URL?
			
			// Ensure cleanup always happens
			defer {
				if let tempDir = tempDirToCleanup {
					try? FileManager.default.removeItem(at: tempDir)
				}
			}
			
			do {
				// finally ffs ts works 
				let (dylibURLs, tempDir) = try await _defaultFrameworksManager.extractDylibsFromFrameworks()
				tempDirToCleanup = tempDir
				
				await MainActor.run {
					var addedCount = 0
					
					// Add each dylib that's not already in the injection files
					for dylibURL in dylibURLs {
						// Check if this framework is already added (by filename)
						let fileName = dylibURL.lastPathComponent
						let alreadyExists = options.injectionFiles.contains { existingURL in
							existingURL.lastPathComponent == fileName
						}
						
						if !alreadyExists {
							// Store the dylib in PortalTweak directory
							FileManager.default.moveAndStore(dylibURL, with: "PortalTweak") { storedURL in
								options.injectionFiles.append(storedURL)
								addedCount += 1
							}
						}
					}
					
					// Provide haptic feedback
					if addedCount > 0 {
						HapticsManager.shared.success()
						
						// Show success alert
						UIAlertController.showAlertWithOk(
							title: .localized("Success"),
							message: .localized("Added \(addedCount) Default Framework(s)")
						)
					} else {
						HapticsManager.shared.impact()
						
						// Show info alert if all frameworks were already added
						UIAlertController.showAlertWithOk(
							title: .localized("Info"),
							message: .localized("All default frameworks are already added to this app, you may now sign the app.")
						)
					}
				}
			} catch {
				await MainActor.run {
					HapticsManager.shared.error()
					
					UIAlertController.showAlertWithOk(
						title: .localized("Error"),
						message: .localized("Failed to add default frameworks: \(error.localizedDescription)")
					)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _file(tweak: URL) -> some View {
		HStack(spacing: 12) {
			ZStack {
				Circle()
					.fill(
						LinearGradient(
							colors: [Color.accentColor, Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.6)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 40, height: 40)
					.shadow(color: Color.accentColor.opacity(0.4), radius: 8, x: 0, y: 3)
				
				Image(systemName: "puzzlepiece.extension.fill")
					.font(.system(size: 18))
					.foregroundStyle(.white)
			}
			
			VStack(alignment: .leading, spacing: 2) {
				Text(tweak.lastPathComponent)
					.font(.body)
					.lineLimit(1)
				
				Text(tweak.pathExtension.uppercased())
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer()
		}
		.padding(.vertical, 4)
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
			_fileActions(tweak: tweak)
		}
		.contextMenu {
			_fileActions(tweak: tweak)
		}
	}
	
	@ViewBuilder
	private func _fileActions(tweak: URL) -> some View {
		Button(role: .destructive) {
			FileManager.default.deleteStored(tweak) { url in
				if let index = options.injectionFiles.firstIndex(where: { $0 == url }) {
					_ = withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
						options.injectionFiles.remove(at: index)
					}
				}
			}
		} label: {
			Label(.localized("Delete"), systemImage: "trash")
		}
	}
}
