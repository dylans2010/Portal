import SwiftUI
import NimbleViews

// MARK: - Modern Install/Modify Dialog
struct InstallModifyDialogView: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	let app: AppInfoPresentable
	
	@State private var showInstallPreview = false
	@State private var animateSuccess = false
	
	var body: some View {
		NavigationStack {
			ZStack {
				// Modern gradient background
				LinearGradient(
					colors: [
						Color.green.opacity(0.08),
						Color.green.opacity(0.03),
						Color(.systemBackground)
					],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
				.ignoresSafeArea()
				
				ScrollView {
					VStack(spacing: 0) {
						// Success icon and message
						VStack(spacing: 24) {
							// Animated success icon
							ZStack {
								Circle()
									.fill(
										LinearGradient(
											colors: [Color.green.opacity(0.15), Color.green.opacity(0.08)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
									.frame(width: 120, height: 120)
									.overlay(
										Circle()
											.stroke(
												LinearGradient(
													colors: [Color.green.opacity(0.4), Color.green.opacity(0.1)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												),
												lineWidth: 3
											)
									)
								
								Image(systemName: "checkmark")
									.font(.system(size: 50, weight: .bold))
									.foregroundStyle(Color.green)
							}
							.shadow(color: Color.green.opacity(0.3), radius: 20, x: 0, y: 8)
							
							VStack(spacing: 10) {
								Text("Download Complete")
									.font(.system(size: 26, weight: .bold, design: .rounded))
									.foregroundStyle(.primary)
								
								Text("Choose what to do with \(app.name ?? "this app")")
									.font(.system(size: 15, weight: .medium))
									.foregroundStyle(.secondary)
									.multilineTextAlignment(.center)
									.padding(.horizontal, 30)
							}
						}
						.padding(.top, 50)
						.padding(.bottom, 30)
					
					// App info card - compact
					appInfoCard
						.padding(.horizontal, 20)
						.padding(.bottom, 20)
						.frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
					
						// Action buttons
						VStack(spacing: 14) {
							// Sign & Install button
							Button {
								dismiss()
								// Trigger signing and installation
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
									showInstallPreview = true
								}
							} label: {
								HStack(spacing: 12) {
									Image(systemName: "checkmark.seal.fill")
										.font(.system(size: 18, weight: .bold))
									Text("Sign & Install")
										.font(.system(size: 18, weight: .bold))
								}
								.foregroundStyle(.white)
								.frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
								.padding(.vertical, 18)
								.background(
									LinearGradient(
										colors: [Color.green, Color.green.opacity(0.85)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
								.shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 6)
							}
							.contentShape(Rectangle())
							
							// Modify button
							Button {
								dismiss()
								// Open signing view for modification
								DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
									NotificationCenter.default.post(
										name: Notification.Name("Feather.openSigningView"),
										object: app
									)
								}
							} label: {
								HStack(spacing: 12) {
									Image(systemName: "slider.horizontal.3")
										.font(.system(size: 18, weight: .bold))
									Text("Modify")
										.font(.system(size: 18, weight: .bold))
								}
								.foregroundStyle(.white)
								.frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
								.padding(.vertical, 18)
								.background(
									LinearGradient(
										colors: [Color.accentColor, Color.accentColor.opacity(0.85)],
										startPoint: .leading,
										endPoint: .trailing
									)
								)
								.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
								.shadow(color: Color.accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
							}
							.contentShape(Rectangle())
							
							// Cancel button
							Button {
								dismiss()
							} label: {
								Text("Cancel")
									.font(.system(size: 17, weight: .semibold))
									.foregroundStyle(.secondary)
									.frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
									.padding(.vertical, 16)
									.background(
										RoundedRectangle(cornerRadius: 16, style: .continuous)
											.fill(Color(UIColor.tertiarySystemGroupedBackground))
									)
							}
							.contentShape(Rectangle())
						}
						.padding(.horizontal, 24)
						.padding(.bottom, 30)
						
						Spacer(minLength: 20)
					}
					.frame(maxWidth: .infinity)
				}
			}
			.navigationBarTitleDisplayMode(.inline)
			.navigationBarHidden(true)
		}
		.sheet(isPresented: $showInstallPreview) {
			InstallPreviewView(app: app, isSharing: false, fromLibraryTab: false)
		}
	}
	
	// MARK: - App Info Card
	@ViewBuilder
	private var appInfoCard: some View {
		HStack(spacing: 12) {
			// App icon
			if let iconURL = (app as? Signed)?.iconURL ?? (app as? Imported)?.iconURL {
				AsyncImage(url: iconURL) { phase in
					switch phase {
					case .empty:
						iconPlaceholder
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(width: 48, height: 48)
							.clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
					case .failure:
						iconPlaceholder
					@unknown default:
						iconPlaceholder
					}
				}
			} else {
				iconPlaceholder
			}
			
			// App info
			VStack(alignment: .leading, spacing: 3) {
				Text(app.name ?? "Unknown")
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(.primary)
					.lineLimit(1)
				
				HStack(spacing: 8) {
					if let version = app.version {
						Label(version, systemImage: "number")
							.font(.system(size: 11, weight: .medium))
							.foregroundStyle(.secondary)
					}
					
					if let size = (app as? Signed)?.size ?? (app as? Imported)?.size {
						Label(size.formattedByteCount, systemImage: "internaldrive")
							.font(.system(size: 11, weight: .medium))
							.foregroundStyle(.secondary)
					}
				}
				.labelStyle(.titleOnly)
			}
			
			Spacer()
			
			// Ready badge
			Text("Ready")
				.font(.system(size: 10, weight: .bold))
				.foregroundStyle(.green)
				.padding(.horizontal, 8)
				.padding(.vertical, 4)
				.background(Color.green.opacity(0.15))
				.clipShape(Capsule())
		}
		.padding(18)
		.background(
			ZStack {
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.fill(Color(.secondarySystemGroupedBackground))
				
				RoundedRectangle(cornerRadius: 18, style: .continuous)
					.stroke(
						LinearGradient(
							colors: [Color.green.opacity(0.3), Color.green.opacity(0.1)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 2
					)
			}
		)
		.shadow(color: Color.green.opacity(0.15), radius: 12, x: 0, y: 6)
	}
	
	private var iconPlaceholder: some View {
		RoundedRectangle(cornerRadius: 11, style: .continuous)
			.fill(Color.secondary.opacity(0.15))
			.frame(width: 48, height: 48)
			.overlay(
				Image(systemName: "app.fill")
					.font(.system(size: 20))
					.foregroundStyle(.secondary)
			)
	}
}
