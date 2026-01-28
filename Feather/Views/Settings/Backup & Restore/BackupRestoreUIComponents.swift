import SwiftUI
import NimbleViews

// MARK: - BackupOptionsView
struct BackupOptionsView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var options: BackupOptions
	let onConfirm: () -> Void

	var body: some View {
		NavigationView {
			ScrollView {
				VStack(spacing: 24) {
					// Header
					VStack(spacing: 16) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 80, height: 80)

							Image(systemName: "square.and.arrow.up.fill")
								.font(.system(size: 40, weight: .semibold))
								.foregroundStyle(
									LinearGradient(
										gradient: Gradient(colors: [.blue, .purple]),
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
						}

						Text(.localized("What would you like in this Portal Backup?"))
							.font(.title2.bold())
							.multilineTextAlignment(.center)
							.padding(.horizontal)

						Text(.localized("Select the data you want to include in your backup"))
							.font(.subheadline)
							.foregroundStyle(.secondary)
							.multilineTextAlignment(.center)
							.padding(.horizontal)
					}
					.padding(.top, 20)

					// Options
					VStack(spacing: 12) {
						backupOptionToggle(
							icon: "checkmark.seal.fill",
							iconColor: .blue,
							title: .localized("Certificates"),
							description: .localized("Your signing certificates and provisioning profiles"),
							isOn: $options.includeCertificates
						)

						backupOptionToggle(
							icon: "app.badge.fill",
							iconColor: .green,
							title: .localized("Signed Apps"),
							description: .localized("Apps you have signed with your certificates"),
							isOn: $options.includeSignedApps
						)

						backupOptionToggle(
							icon: "square.and.arrow.down.fill",
							iconColor: .orange,
							title: .localized("Imported Apps"),
							description: .localized("Apps imported from files or other sources"),
							isOn: $options.includeImportedApps
						)

						backupOptionToggle(
							icon: "globe.fill",
							iconColor: .purple,
							title: .localized("Sources"),
							description: .localized("Your configured app sources and repositories"),
							isOn: $options.includeSources
						)

						backupOptionToggle(
							icon: "puzzlepiece.extension.fill",
							iconColor: .cyan,
							title: .localized("Default Frameworks"),
							description: .localized("Your automatically injected frameworks (.dylib, .deb)"),
							isOn: $options.includeDefaultFrameworks
						)
					}
					.padding(.horizontal, 20)

					// Warning notice
					if options.includeSignedApps || options.includeImportedApps {
						HStack(alignment: .top, spacing: 12) {
							Image(systemName: "exclamationmark.triangle.fill")
								.font(.system(size: 20))
								.foregroundStyle(.orange)

							VStack(alignment: .leading, spacing: 4) {
								Text(.localized("Large Backup Size"))
									.font(.headline)
									.foregroundStyle(.primary)

								Text(.localized("If you include Signed and Imported Apps, this backup will be large."))
									.font(.subheadline)
									.foregroundStyle(.secondary)
									.fixedSize(horizontal: false, vertical: true)
							}
						}
						.padding(16)
						.background(Color.orange.opacity(0.1))
						.cornerRadius(12)
						.padding(.horizontal, 20)
					}

					// Create button
					Button {
						onConfirm()
					} label: {
						HStack {
							Image(systemName: "checkmark.circle.fill")
							Text(.localized("Create Backup"))
								.font(.headline)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(
							LinearGradient(
								gradient: Gradient(colors: [.blue, .purple]),
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.foregroundStyle(.white)
						.cornerRadius(12)
					}
					.padding(.horizontal, 20)
					.padding(.top, 8)

					// Cancel button
					Button {
						dismiss()
					} label: {
						Text(.localized("Cancel"))
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					.padding(.bottom, 20)
				}
			}
			.navigationTitle(.localized("Backup Options"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.system(size: 20))
							.foregroundStyle(.secondary)
					}
				}
			}
		}
		.presentationDetents([.large])
		.presentationDragIndicator(.visible)
	}

	@ViewBuilder
	private func backupOptionToggle(
		icon: String,
		iconColor: Color,
		title: LocalizedStringKey,
		description: LocalizedStringKey,
		isOn: Binding<Bool>
	) -> some View {
		Button {
			isOn.wrappedValue.toggle()
			HapticsManager.shared.softImpact()
		} label: {
			HStack(alignment: .top, spacing: 12) {
				ZStack {
					Circle()
						.fill(iconColor.opacity(0.15))
						.frame(width: 44, height: 44)

					Image(systemName: icon)
						.font(.system(size: 20, weight: .semibold))
						.foregroundStyle(iconColor)
				}

				VStack(alignment: .leading, spacing: 4) {
					Text(title)
						.font(.headline)
						.foregroundStyle(.primary)

					Text(description)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.fixedSize(horizontal: false, vertical: true)
				}

				Spacer()

				Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
					.font(.system(size: 24))
					.foregroundStyle(isOn.wrappedValue ? .blue : .gray.opacity(0.3))
			}
			.padding(16)
			.background(Color(uiColor: .secondarySystemGroupedBackground))
			.cornerRadius(12)
		}
		.buttonStyle(.plain)
	}
}

// MARK: - RestoreLoadingOverlay
struct RestoreLoadingOverlay: View {
	let progress: Double
	@State private var rotation: Double = 0

	var body: some View {
		ZStack {
			// Blurred background
			Color.black.opacity(0.5)
				.ignoresSafeArea()

			// Card
			VStack(spacing: 24) {
				// Animated icon
				ZStack {
					Circle()
						.fill(
							LinearGradient(
								colors: [Color.green.opacity(0.2), Color.green.opacity(0.1)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 100, height: 100)

					Circle()
						.stroke(Color.green.opacity(0.3), lineWidth: 4)
						.frame(width: 100, height: 100)
						.rotationEffect(.degrees(rotation))

					Image(systemName: "arrow.down.circle.fill")
						.font(.system(size: 50))
						.foregroundStyle(
							LinearGradient(
								colors: [.green, .green.opacity(0.7)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
				}

				// Text
				VStack(spacing: 8) {
					Text("Restoring Backup")
						.font(.title2.bold())
						.foregroundStyle(.white)

					Text("Please wait while we restore your data...")
						.font(.subheadline)
						.foregroundStyle(.white.opacity(0.8))
						.multilineTextAlignment(.center)
				}

				// Progress bar
				VStack(spacing: 8) {
					GeometryReader { geometry in
						ZStack(alignment: .leading) {
							// Background
							RoundedRectangle(cornerRadius: 8)
								.fill(Color.white.opacity(0.2))
								.frame(height: 8)

							// Progress
							RoundedRectangle(cornerRadius: 8)
								.fill(
									LinearGradient(
										colors: [.green, .green.opacity(0.8)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.frame(width: geometry.size.width * progress, height: 8)
								.animation(.easeInOut(duration: 0.3), value: progress)
						}
					}
					.frame(height: 8)

					Text("\(Int(progress * 100))%")
						.font(.caption)
						.foregroundStyle(.white.opacity(0.8))
				}
			}
			.padding(32)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.fill(Color(uiColor: .systemBackground))
					.opacity(0.95)
			)
			.padding(.horizontal, 40)
			.shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
		}
		.onAppear {
			withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
				rotation = 360
			}
		}
	}
}
