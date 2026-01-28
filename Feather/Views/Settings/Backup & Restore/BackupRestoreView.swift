// (TODO) Fix full functionality then add to SettingsView. Update lready added but beta

import SwiftUI
import NimbleViews
import ZIPFoundation
import UniformTypeIdentifiers
import CoreData

// MARK: - View
struct BackupRestoreView: View {
	@Environment(\.dismiss) var dismiss
	@StateObject private var manager = BackupRestoreManager.shared
	@State private var isRestoreFilePickerPresented = false
	@State private var isVerifyFilePickerPresented = false
	@State private var showRestoreDialog = false
	@State private var pendingRestoreURL: URL?
	@State private var isBackupOptionsPresented = false
	@State private var backupOptions = BackupOptions()
	@State private var showInvalidBackupError = false
	@State private var backupDocument: BackupDocument?
	@State private var showExporter = false
	@AppStorage("feature_advancedBackupTools") var advancedBackupTools = false
	
	// MARK: Body
	var body: some View {
		NBList(.localized("Backup & Restore")) {
			// Main View Header
			Section {
				VStack(spacing: 20) {
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [.blue.opacity(0.2), .green.opacity(0.2)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 100, height: 100)
							.shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)

						Image(systemName: "arrow.up.doc.fill")
							.font(.system(size: 44, weight: .bold))
							.foregroundStyle(
								LinearGradient(
									colors: [.blue, .green],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
					}

					VStack(spacing: 8) {
						Text(.localized("Backup & Restore"))
							.font(.title2.bold())
						Text(.localized("Keep your data safe by creating backups or restoring from a previous one."))
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 32)
					}
				}
				.frame(maxWidth: .infinity)
				.padding(.vertical, 24)
			}
			.listRowBackground(Color.clear)
			.listRowInsets(EdgeInsets())

			// Modernized Header Card
			Section {
				VStack(spacing: 0) {
					HStack(spacing: 12) {
						// Backup Card
						VStack(spacing: 20) {
							ZStack {
								Circle()
									.fill(Color.blue.opacity(0.12))
									.frame(width: 72, height: 72)
								
								Image(systemName: "arrow.up.doc.fill")
									.font(.system(size: 32, weight: .bold))
									.foregroundStyle(
										LinearGradient(
											colors: [.blue, .cyan],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							VStack(spacing: 6) {
								Text(.localized("Backup"))
									.font(.system(.headline, design: .rounded, weight: .bold))
								Text(.localized("Save your data"))
									.font(.system(.caption, design: .rounded))
									.foregroundStyle(.secondary)
							}
							
							Button {
								isBackupOptionsPresented = true
							} label: {
								HStack(spacing: 8) {
									Image(systemName: "plus.circle.fill")
										.font(.system(size: 14, weight: .bold))
									Text(.localized("Create"))
										.font(.system(.subheadline, design: .rounded, weight: .bold))
								}
								.foregroundStyle(.white)
								.frame(maxWidth: .infinity)
								.padding(.vertical, 12)
								.background(
									LinearGradient(
										colors: [.blue, .cyan],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.clipShape(RoundedRectangle(cornerRadius: 16))
								.shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
							}
						}
						.padding(24)
						.background(
							RoundedRectangle(cornerRadius: 28, style: .continuous)
								.fill(.ultraThinMaterial)
								.overlay(
									RoundedRectangle(cornerRadius: 28, style: .continuous)
										.stroke(Color.blue.opacity(0.15), lineWidth: 1)
								)
						)
						
						// Restore Card
						VStack(spacing: 20) {
							ZStack {
								Circle()
									.fill(Color.green.opacity(0.12))
									.frame(width: 72, height: 72)
								
								Image(systemName: "arrow.down.doc.fill")
									.font(.system(size: 32, weight: .bold))
									.foregroundStyle(
										LinearGradient(
											colors: [.green, .mint],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							VStack(spacing: 6) {
								Text(.localized("Restore"))
									.font(.system(.headline, design: .rounded, weight: .bold))
								Text(.localized("Load a backup"))
									.font(.system(.caption, design: .rounded))
									.foregroundStyle(.secondary)
							}
							
							Button {
								isRestoreFilePickerPresented = true
							} label: {
								HStack(spacing: 8) {
									Image(systemName: "arrow.down.circle.fill")
										.font(.system(size: 14, weight: .bold))
									Text(.localized("Import"))
										.font(.system(.subheadline, design: .rounded, weight: .bold))
								}
								.foregroundStyle(.white)
								.frame(maxWidth: .infinity)
								.padding(.vertical, 12)
								.background(
									LinearGradient(
										colors: [.green, .mint],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.clipShape(RoundedRectangle(cornerRadius: 16))
								.shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
							}
						}
						.padding(24)
						.background(
							RoundedRectangle(cornerRadius: 28, style: .continuous)
								.fill(.ultraThinMaterial)
								.overlay(
									RoundedRectangle(cornerRadius: 28, style: .continuous)
										.stroke(Color.green.opacity(0.15), lineWidth: 1)
								)
						)
					}
				}
				.listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
			}
			.listRowBackground(Color.clear)
			
			// Advanced Tools Section
			if advancedBackupTools {
				Section {
					Button {
						Task {
							do {
								let url = try await manager.exportFullDatabase()
								backupDocument = BackupDocument(url: url)
								showExporter = true
							} catch {
								UIAlertController.showAlertWithOk(title: "Error", message: error.localizedDescription)
							}
						}
					} label: {
						Label(.localized("Export Full Database"), systemImage: "cylinder.split.1x2.fill")
					}

					Button {
						isVerifyFilePickerPresented = true
					} label: {
						Label(.localized("Verify Backup Integrity"), systemImage: "shield.checkerboard")
					}
				} header: {
					AppearanceSectionHeader(title: String.localized("Advanced Tools"), icon: "wrench.and.screwdriver.fill")
				}
			}

			// Information sections with modern cards
			Section {
				infoCard(
					icon: "checkmark.shield.fill",
					iconColor: .blue,
					title: .localized("What's Included"),
					description: .localized("Backups can include certificates, provisioning profiles, signed apps, imported apps, sources, and all app settings.")
				)
				
				infoCard(
					icon: "exclamationmark.triangle.fill",
					iconColor: .orange,
					title: .localized("Important"),
					description: .localized("Restoring requires the app to restart. Certificate restoration preserves files for manual re-import if needed.")
				)
			} header: {
				AppearanceSectionHeader(title: String.localized("About Backups (Beta)"), icon: "info.circle.fill")
			}
		}
		.sheet(isPresented: $isBackupOptionsPresented) {
			BackupOptionsView(
				options: $backupOptions,
				onConfirm: {
					isBackupOptionsPresented = false
					Task {
						do {
							let url = try await manager.prepareBackup(with: backupOptions)
							backupDocument = BackupDocument(url: url)
							showExporter = true
						} catch {
							UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
						}
					}
				}
			)
		}
		.sheet(isPresented: $isRestoreFilePickerPresented) {
			FileImporterRepresentableView(
				allowedContentTypes: [.zip],
				allowsMultipleSelection: false,
				onDocumentsPicked: { urls in
					isRestoreFilePickerPresented = false
					guard let url = urls.first else { return }
					pendingRestoreURL = url
					showRestoreDialog = true
				}
			)
			.ignoresSafeArea()
		}
		.sheet(isPresented: $isVerifyFilePickerPresented) {
			FileImporterRepresentableView(
				allowedContentTypes: [.zip],
				allowsMultipleSelection: false,
				onDocumentsPicked: { urls in
					isVerifyFilePickerPresented = false
					guard let url = urls.first else { return }
					Task {
						do {
							let isValid = try await manager.verifyBackup(at: url)
							if isValid {
								UIAlertController.showAlertWithOk(title: .localized("Verification Successful"), message: .localized("This backup file is valid and can be restored."))
							} else {
								showInvalidBackupError = true
							}
						} catch {
							UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Failed to verify backup: \(error.localizedDescription)"))
						}
					}
				}
			)
			.ignoresSafeArea()
		}
		.fileExporter(
			isPresented: $showExporter,
			document: backupDocument,
			contentType: .zip,
			defaultFilename: "PortalBackup_\(Date().formatted(date: .numeric, time: .omitted).replacingOccurrences(of: "/", with: "-"))"
		) { result in
			switch result {
			case .success(let url):
				AppLogManager.shared.success("Backup exported successfully to: \(url.path)", category: "Backup & Restore")
				HapticsManager.shared.success()
			case .failure(let error):
				AppLogManager.shared.error("Failed to export backup: \(error.localizedDescription)", category: "Backup & Restore")
				HapticsManager.shared.error()
			}
			// Clean up the temporary zip file after export attempt
			if let tempURL = backupDocument?.url {
				try? FileManager.default.removeItem(at: tempURL)
			}
			backupDocument = nil
		}
		.alert(.localized("Restart Required"), isPresented: $showRestoreDialog) {
			Button(.localized("No"), role: .cancel) {
				if let url = pendingRestoreURL {
					// Mark for deferred restore
					UserDefaults.standard.set(url.path, forKey: "pendingRestorePath")
					pendingRestoreURL = nil
				}
			}
			Button(.localized("Yes")) {
				if let url = pendingRestoreURL {
					Task {
						do {
							try await manager.performRestore(from: url, restart: true)
						} catch {
							UIAlertController.showAlertWithOk(title: .localized("Error"), message: error.localizedDescription)
						}
					}
				}
			}
		} message: {
			Text(.localized("Portal has to restart in order to apply this backup, do you want to proceed?"))
		}
		.alert(.localized("Invalid Backup File"), isPresented: $showInvalidBackupError) {
			Button(.localized("OK"), role: .cancel) { }
		} message: {
			Text(.localized("Not a valid Backup file because Portal couldn't find the checker inside the file. Please upload an actual .zip file of a backup."))
		}
		.overlay {
			if manager.isRestoring {
				RestoreLoadingOverlay(progress: manager.restoreProgress)
			}

			if manager.isVerifying {
				ZStack {
					Color.black.opacity(0.4).ignoresSafeArea()
					VStack(spacing: 12) {
						ProgressView()
							.tint(.white)
						Text("Verifying...")
							.foregroundStyle(.white)
					}
					.padding(24)
					.background(.ultraThinMaterial)
					.cornerRadius(16)
				}
			}
		}
	}
	
	// MARK: - Info Card View
	@ViewBuilder
	private func infoCard(icon: String, iconColor: Color, title: LocalizedStringKey, description: LocalizedStringKey) -> some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 22, weight: .semibold))
				.foregroundStyle(iconColor)
				.frame(width: 36)
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.headline)
					.foregroundStyle(.primary)
				
				Text(description)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.padding(.vertical, 4)
	}
	
}

