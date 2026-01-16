import SwiftUI
import NimbleViews
import Zsign

// MARK: - View
struct LibraryInfoView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	var app: AppInfoPresentable
	@State private var dominantColors: [Color] = []
	@State private var isLoadingColors = true
	@State private var appearAnimation = false
	
	// MARK: Body
	var body: some View {
		ZStack {
			// Animated gradient background
			if _useGradients && !dominantColors.isEmpty {
				MeshGradientBackground(colors: dominantColors)
					.ignoresSafeArea()
			}
			
			NBNavigationView(app.name ?? "", displayMode: .inline) {
				ScrollView {
					VStack(spacing: 20) {
						// Hero App Card
						heroAppCard
							.opacity(appearAnimation ? 1 : 0)
							.offset(y: appearAnimation ? 0 : 20)
						
						// Quick Stats Row
						quickStatsRow
							.opacity(appearAnimation ? 1 : 0)
							.offset(y: appearAnimation ? 0 : 15)
						
						// Details Card
						detailsCard
							.opacity(appearAnimation ? 1 : 0)
							.offset(y: appearAnimation ? 0 : 10)
						
						// Certificate Card
						if let cert = Storage.shared.getCertificate(from: app) {
							certificateCard(cert: cert)
								.opacity(appearAnimation ? 1 : 0)
								.offset(y: appearAnimation ? 0 : 10)
						}
						
						// Bundle & Executable Cards
						bundleCard
							.opacity(appearAnimation ? 1 : 0)
							.offset(y: appearAnimation ? 0 : 10)
						
						// Actions Card
						actionsCard
							.opacity(appearAnimation ? 1 : 0)
							.offset(y: appearAnimation ? 0 : 10)
					}
					.padding(20)
				}
				.scrollContentBackground(.hidden)
				.toolbar {
					NBToolbarButton(role: .close)
				}
			}
		}
		.onAppear {
			extractAppIconColors()
			withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
				appearAnimation = true
			}
		}
	}
	
	// MARK: - Hero App Card
	private var heroAppCard: some View {
		VStack(spacing: 0) {
			// Top gradient accent
			Rectangle()
				.fill(
					LinearGradient(
						colors: dominantColors.isEmpty 
							? [.accentColor.opacity(0.8), .accentColor.opacity(0.4)]
							: [dominantColors[0].opacity(0.8), dominantColors.count > 1 ? dominantColors[1].opacity(0.4) : dominantColors[0].opacity(0.4)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
				.frame(height: 4)
			
			VStack(spacing: 20) {
				// App Icon with glow
				ZStack {
					// Animated glow rings
					ForEach(0..<3, id: \.self) { index in
						Circle()
							.stroke(
								(dominantColors.isEmpty ? Color.accentColor : dominantColors[0])
									.opacity(0.15 - Double(index) * 0.04),
								lineWidth: 2
							)
							.frame(width: 110 + CGFloat(index) * 20, height: 110 + CGFloat(index) * 20)
					}
					
					// Soft glow
					Circle()
						.fill(
							RadialGradient(
								colors: [
									(dominantColors.isEmpty ? .accentColor : dominantColors[0]).opacity(0.3),
									Color.clear
								],
								center: .center,
								startRadius: 30,
								endRadius: 70
							)
						)
						.frame(width: 140, height: 140)
						.blur(radius: 10)
					
					FRAppIconView(app: app, size: 90)
						.shadow(
							color: (dominantColors.isEmpty ? .black : dominantColors[0]).opacity(0.3),
							radius: 20,
							x: 0,
							y: 10
						)
				}
				.padding(.top, 10)
				
				// App Info
				VStack(spacing: 8) {
					Text(app.name ?? .localized("Unknown"))
						.font(.system(size: 24, weight: .bold, design: .rounded))
						.foregroundStyle(.primary)
						.multilineTextAlignment(.center)
					
					if let version = app.version {
						HStack(spacing: 6) {
							Text("v\(version)")
								.font(.system(size: 14, weight: .semibold, design: .rounded))
								.foregroundStyle(.white)
								.padding(.horizontal, 10)
								.padding(.vertical, 4)
								.background(
									Capsule()
										.fill(
											LinearGradient(
												colors: dominantColors.isEmpty 
													? [.accentColor, .accentColor.opacity(0.7)]
													: [dominantColors[0], dominantColors[0].opacity(0.7)],
												startPoint: .leading,
												endPoint: .trailing
											)
										)
								)
						}
					}
					
					if let identifier = app.identifier {
						Text(identifier)
							.font(.system(size: 12, weight: .medium, design: .monospaced))
							.foregroundStyle(.secondary)
							.lineLimit(1)
					}
				}
				
				// Date badge
				if let date = app.date {
					HStack(spacing: 6) {
						Image(systemName: "calendar")
							.font(.system(size: 11, weight: .medium))
						Text("Added \(date.formatted(date: .abbreviated, time: .omitted))")
							.font(.system(size: 12, weight: .medium))
					}
					.foregroundStyle(.tertiary)
					.padding(.bottom, 4)
				}
			}
			.padding(20)
		}
		.background(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.fill(.ultraThinMaterial)
				.shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 24, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [.white.opacity(0.3), .white.opacity(0.1)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1
				)
		)
		.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
	}
	
	// MARK: - Quick Stats Row
	private var quickStatsRow: some View {
		HStack(spacing: 12) {
			// Signed Status
			quickStatPill(
				icon: app.isSigned ? "checkmark.seal.fill" : "xmark.seal.fill",
				title: app.isSigned ? .localized("Signed") : .localized("Unsigned"),
				color: app.isSigned ? .green : .orange
			)
			
			Spacer()
		}
	}
	
	private func quickStatPill(icon: String, title: String, color: Color) -> some View {
		HStack(spacing: 8) {
			Image(systemName: icon)
				.font(.system(size: 14, weight: .semibold))
				.foregroundStyle(color)
			
			Text(title)
				.font(.system(size: 13, weight: .semibold))
				.foregroundStyle(color)
		}
		.padding(.horizontal, 14)
		.padding(.vertical, 10)
		.background(
			Capsule()
				.fill(color.opacity(0.12))
				.overlay(
					Capsule()
						.stroke(color.opacity(0.2), lineWidth: 1)
				)
		)
	}
	
	// MARK: - Details Card
	private var detailsCard: some View {
		VStack(alignment: .leading, spacing: 16) {
			// Section Header
			HStack(spacing: 8) {
				Image(systemName: "info.circle.fill")
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(dominantColors.isEmpty ? .accentColor : dominantColors[0])
				Text(.localized("Details"))
					.font(.system(size: 15, weight: .bold))
					.foregroundStyle(.primary)
			}
			
			VStack(spacing: 0) {
				if let name = app.name {
					modernDetailRow(icon: "textformat", title: .localized("Name"), value: name, isFirst: true)
				}
				
				if let ver = app.version {
					modernDetailRow(icon: "number", title: .localized("Version"), value: ver)
				}
				
				if let id = app.identifier {
					modernDetailRow(icon: "tag", title: .localized("Bundle ID"), value: id, isLast: true)
				}
			}
			.background(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.fill(Color(UIColor.tertiarySystemGroupedBackground))
			)
		}
		.padding(18)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(.ultraThinMaterial)
				.shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 8)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(Color.white.opacity(0.2), lineWidth: 1)
		)
	}
	
	private func modernDetailRow(icon: String, title: String, value: String, isFirst: Bool = false, isLast: Bool = false) -> some View {
		VStack(spacing: 0) {
			HStack(spacing: 12) {
				Image(systemName: icon)
					.font(.system(size: 14, weight: .medium))
					.foregroundStyle(.secondary)
					.frame(width: 24)
				
				Text(title)
					.font(.system(size: 14, weight: .medium))
					.foregroundStyle(.secondary)
				
				Spacer()
				
				Text(value)
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(.primary)
					.lineLimit(1)
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 14)
			.copyableText(value)
			
			if !isLast {
				Divider()
					.padding(.leading, 50)
			}
		}
	}
	
	// MARK: - Certificate Card
	private func certificateCard(cert: CertificatePair) -> some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack(spacing: 8) {
				Image(systemName: "checkmark.seal.fill")
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(.green)
				Text(.localized("Certificate"))
					.font(.system(size: 15, weight: .bold))
					.foregroundStyle(.primary)
			}
			
			CertificatesCellView(cert: cert)
				.padding(14)
				.background(
					RoundedRectangle(cornerRadius: 14, style: .continuous)
						.fill(Color(UIColor.tertiarySystemGroupedBackground))
				)
		}
		.padding(18)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(.ultraThinMaterial)
				.shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 8)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(Color.white.opacity(0.2), lineWidth: 1)
		)
	}
	
	// MARK: - Bundle Card
	private var bundleCard: some View {
		VStack(alignment: .leading, spacing: 16) {
			HStack(spacing: 8) {
				Image(systemName: "shippingbox.fill")
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(.purple)
				Text(.localized("Bundle"))
					.font(.system(size: 15, weight: .bold))
					.foregroundStyle(.primary)
			}
			
			VStack(spacing: 0) {
				NavigationLink {
					SigningAlternativeIconView(app: app, appIcon: .constant(nil), isModifing: .constant(false))
				} label: {
					modernNavRow(icon: "app.badge", title: .localized("Alternative Icons"), isFirst: true)
				}
				
				NavigationLink {
					SigningFrameworksView(app: app, options: .constant(nil))
				} label: {
					modernNavRow(icon: "puzzlepiece.extension", title: .localized("Frameworks & PlugIns"))
				}
				
				NavigationLink {
					SigningDylibView(app: app, options: .constant(nil))
				} label: {
					modernNavRow(icon: "gearshape.2", title: .localized("Dylibs"), isLast: true)
				}
			}
			.background(
				RoundedRectangle(cornerRadius: 14, style: .continuous)
					.fill(Color(UIColor.tertiarySystemGroupedBackground))
			)
		}
		.padding(18)
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(.ultraThinMaterial)
				.shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 8)
		)
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(Color.white.opacity(0.2), lineWidth: 1)
		)
	}
	
	private func modernNavRow(icon: String, title: String, isFirst: Bool = false, isLast: Bool = false) -> some View {
		VStack(spacing: 0) {
			HStack(spacing: 12) {
				Image(systemName: icon)
					.font(.system(size: 14, weight: .medium))
					.foregroundStyle(.secondary)
					.frame(width: 24)
				
				Text(title)
					.font(.system(size: 14, weight: .medium))
					.foregroundStyle(.primary)
				
				Spacer()
				
				Image(systemName: "chevron.right")
					.font(.system(size: 12, weight: .semibold))
					.foregroundStyle(.tertiary)
			}
			.padding(.horizontal, 14)
			.padding(.vertical, 14)
			
			if !isLast {
				Divider()
					.padding(.leading, 50)
			}
		}
	}
	
	// MARK: - Actions Card
	private var actionsCard: some View {
		Button {
			UIApplication.open(Storage.shared.getUuidDirectory(for: app)!.toSharedDocumentsURL()!)
		} label: {
			HStack(spacing: 12) {
				ZStack {
					Circle()
						.fill(
							LinearGradient(
								colors: [.blue.opacity(0.2), .blue.opacity(0.1)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 40, height: 40)
					
					Image(systemName: "folder.fill")
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(.blue)
				}
				
				VStack(alignment: .leading, spacing: 2) {
					Text(.localized("Open in Files"))
						.font(.system(size: 15, weight: .semibold))
						.foregroundStyle(.primary)
					Text(.localized("View app bundle contents"))
						.font(.system(size: 12, weight: .medium))
						.foregroundStyle(.secondary)
				}
				
				Spacer()
				
				Image(systemName: "arrow.up.right")
					.font(.system(size: 14, weight: .semibold))
					.foregroundStyle(.tertiary)
			}
			.padding(16)
			.background(
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.fill(.ultraThinMaterial)
					.shadow(color: .black.opacity(0.06), radius: 15, x: 0, y: 8)
			)
			.overlay(
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.stroke(Color.white.opacity(0.2), lineWidth: 1)
			)
		}
		.buttonStyle(.plain)
	}
	
	// MARK: - Color Extraction
	private func extractAppIconColors() {
		Task {
			guard let iconData = await getAppIconData() else {
				dominantColors = [.accentColor]
				isLoadingColors = false
				return
			}
			
			guard let uiImage = UIImage(data: iconData),
				  let cgImage = uiImage.cgImage else {
				dominantColors = [.accentColor]
				isLoadingColors = false
				return
			}
			
			let ciImage = CIImage(cgImage: cgImage)
			let filter = CIFilter(name: "CIAreaAverage")
			filter?.setValue(ciImage, forKey: kCIInputImageKey)
			filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
			
			var colors: [Color] = []
			
			if let outputImage = filter?.outputImage {
				var pixel = [UInt8](repeating: 0, count: 4)
				let context = CIContext()
				context.render(
					outputImage,
					toBitmap: &pixel,
					rowBytes: 4,
					bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
					format: .RGBA8,
					colorSpace: nil
				)
				
				let r = Double(pixel[0]) / 255.0
				let g = Double(pixel[1]) / 255.0
				let b = Double(pixel[2]) / 255.0
				colors.append(Color(red: r, green: g, blue: b))
			}
			
			let quarterExtent = CGRect(
				x: ciImage.extent.width * 0.25,
				y: ciImage.extent.height * 0.25,
				width: ciImage.extent.width * 0.5,
				height: ciImage.extent.height * 0.5
			)
			
			let filter2 = CIFilter(name: "CIAreaAverage")
			filter2?.setValue(ciImage, forKey: kCIInputImageKey)
			filter2?.setValue(CIVector(cgRect: quarterExtent), forKey: kCIInputExtentKey)
			
			if let outputImage2 = filter2?.outputImage {
				var pixel2 = [UInt8](repeating: 0, count: 4)
				let context = CIContext()
				context.render(
					outputImage2,
					toBitmap: &pixel2,
					rowBytes: 4,
					bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
					format: .RGBA8,
					colorSpace: nil
				)
				
				let r2 = Double(pixel2[0]) / 255.0
				let g2 = Double(pixel2[1]) / 255.0
				let b2 = Double(pixel2[2]) / 255.0
				let secondColor = Color(red: r2, green: g2, blue: b2)
				
				if !colors.isEmpty {
					let diff = abs(r2 - (colors[0].cgColor?.components?[0] ?? 0)) +
							   abs(g2 - (colors[0].cgColor?.components?[1] ?? 0)) +
							   abs(b2 - (colors[0].cgColor?.components?[2] ?? 0))
					if diff > 0.3 {
						colors.append(secondColor)
					}
				}
			}
			
			await MainActor.run {
				dominantColors = colors.isEmpty ? [.accentColor] : colors
				isLoadingColors = false
			}
		}
	}
	
	private func getAppIconData() async -> Data? {
		guard let iconPath = Storage.shared.getAppIconFile(for: app) else { return nil }
		return try? Data(contentsOf: iconPath)
	}
}

// MARK: - Mesh Gradient Background
struct MeshGradientBackground: View {
	let colors: [Color]
	@State private var animate = false
	
	var body: some View {
		ZStack {
			Color(UIColor.systemGroupedBackground)
			
			// Animated gradient blobs
			ForEach(0..<3, id: \.self) { index in
				Circle()
					.fill(
						RadialGradient(
							colors: [
								colors[index % colors.count].opacity(0.25),
								colors[index % colors.count].opacity(0.1),
								Color.clear
							],
							center: .center,
							startRadius: 50,
							endRadius: 200
						)
					)
					.frame(width: 300, height: 300)
					.offset(
						x: animate ? CGFloat.random(in: -100...100) : CGFloat.random(in: -50...50),
						y: animate ? CGFloat.random(in: -200...200) : CGFloat.random(in: -100...100)
					)
					.blur(radius: 60)
			}
		}
		.onAppear {
			withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
				animate = true
			}
		}
	}
}
