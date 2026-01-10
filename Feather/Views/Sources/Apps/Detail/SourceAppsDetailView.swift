import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import NukeUI

// MARK: - SourceAppsDetailView
struct SourceAppsDetailView: View {
	@ObservedObject var downloadManager = DownloadManager.shared
	@State private var _downloadProgress: Double = 0
	@State var cancellable: AnyCancellable? // Combine
	@State private var _isScreenshotPreviewPresented: Bool = false
	@State private var _selectedScreenshotIndex: Int = 0
	@State private var dominantColor: Color = .accentColor
	
	private let containerCornerRadius: CGFloat = 24
	
	var currentDownload: Download? {
		downloadManager.getDownload(by: app.currentUniqueId)
	}
	
	var source: ASRepository
	var app: ASRepository.App
	
    var body: some View {
		ScrollView {
			if #available(iOS 18, *) {
				_header().flexibleHeaderContent()
			}
			
			// Main content container with rounded corners
			VStack(alignment: .leading, spacing: 16) {
				// App header section with icon and download button
				appHeaderSection
				
				// Screenshots section
				if let screenshotURLs = app.screenshotURLs {
					NBSection(.localized("Screenshots")) {
						_screenshots(screenshotURLs: screenshotURLs)
					}
					
					Divider()
						.padding(.horizontal)
				}
				
				// What's New section
				if let currentVer = app.currentVersion,
				   let whatsNewDesc = app.currentAppVersion?.localizedDescription {
					NBSection(.localized("What's New")) {
						AppVersionInfo(
							version: currentVer,
							date: app.currentDate?.date,
							description: whatsNewDesc
						)
						if let versions = app.versions {
							NavigationLink(
								destination: VersionHistoryView(app: app, versions: versions)
									.navigationTitle(.localized("Version History"))
									.navigationBarTitleDisplayMode(.large)
							) {
								Text(.localized("Version History"))
							}
						}
					}
					
					Divider()
						.padding(.horizontal)
				}
				
				// Description section
				if let appDesc = app.localizedDescription {
					NBSection(.localized("Description")) {
						VStack(alignment: .leading, spacing: 2) {
							ExpandableText(text: appDesc, lineLimit: 3)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
					}
					
					Divider()
						.padding(.horizontal)
				}
				
				// Information section with rounded container
				NBSection(.localized("Information")) {
					VStack(spacing: 12) {
						if let sourceName = source.name {
							_infoRow(title: .localized("Source"), value: sourceName, icon: "globe")
						}
						
						if let developer = app.developer {
							_infoRow(title: .localized("Developer"), value: developer, icon: "person.circle")
						}
						
						if let size = app.size {
							_infoRow(title: .localized("App Size"), value: size.formattedByteCount, icon: "archivebox")
						}
						
						if let category = app.category {
							_infoRow(title: .localized("Category"), value: category.capitalized, icon: "tag")
						}
						
						if let version = app.currentVersion {
							_infoRow(title: .localized("Version"), value: version, icon: "number")
						}
						
						if let date = app.currentDate?.date {
							_infoRow(title: .localized("Updated"), value: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none), icon: "calendar")
						}
						
						if let bundleId = app.id {
							_infoRow(title: .localized("Bundle ID"), value: bundleId, icon: "barcode")
						}
					}
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 16, style: .continuous)
							.fill(
								LinearGradient(
									colors: [
										dominantColor.opacity(0.15),
										dominantColor.opacity(0.05)
									],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
					)
					.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: 16, style: .continuous)
							.stroke(dominantColor.opacity(0.25), lineWidth: 1.5)
					)
				}
				
				// Permissions section
				if let appPermissions = app.appPermissions {
					NBSection(.localized("Permissions")) {
						NavigationLink(destination: PermissionsView(appPermissions: appPermissions, dominantColor: dominantColor)) {
							NBTitleWithSubtitleView(
								title: .localized("Permissions"),
								subtitle: .localized("See which permissions this app requires")
							)
						}
						.padding()
						.background(
							RoundedRectangle(cornerRadius: 16, style: .continuous)
								.fill(
									LinearGradient(
										colors: [
											dominantColor.opacity(0.15),
											dominantColor.opacity(0.05)
										],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
						)
						.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
						.overlay(
							RoundedRectangle(cornerRadius: 16, style: .continuous)
								.stroke(dominantColor.opacity(0.25), lineWidth: 1.5)
						)
					}
				}
			}
			.padding(.horizontal)
			.padding(.bottom, 20)
			.padding(.top, {
				if #available(iOS 18, *) {
					8
				} else {
					0
				}
			}())
		}
		.background(
			ZStack {
				// Base background color
				Color(UIColor.systemBackground)
					.ignoresSafeArea()
				
				// Top rounded gradient container
				VStack {
					let hasIcon = app.iconURL != nil
					RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
						.fill(
							LinearGradient(
								colors: hasIcon ? [
									dominantColor.opacity(0.45),
									dominantColor.opacity(0.25),
									dominantColor.opacity(0.12),
									Color(UIColor.systemBackground).opacity(0.95)
								] : [
									dominantColor.opacity(0.6),
									dominantColor.opacity(0.4),
									dominantColor.opacity(0.25),
									Color(UIColor.systemBackground).opacity(0.95)
								],
								startPoint: .top,
								endPoint: .bottom
							)
						)
						.frame(height: 350)
						.clipShape(
							RoundedCorner(radius: containerCornerRadius, corners: [.topLeft, .topRight])
						)
					
					Spacer()
				}
				.ignoresSafeArea(edges: .top)
				
				// Radial gradient overlay for depth
				RadialGradient(
					colors: [
						dominantColor.opacity(0.35),
						dominantColor.opacity(0.15),
						Color.clear
					],
					center: .top,
					startRadius: 30,
					endRadius: 400
				)
				.ignoresSafeArea()
			}
		)
		.flexibleHeaderScrollView()
		.shouldSetInset()
		.fullScreenCover(isPresented: $_isScreenshotPreviewPresented) {
			if let screenshotURLs = app.screenshotURLs {
				ScreenshotPreviewView(
					screenshotURLs: screenshotURLs,
					initialIndex: _selectedScreenshotIndex
				)
			}
		}
		.onAppear {
			if let iconURL = app.iconURL {
				extractDominantColor(from: iconURL)
			}
		}
    }
	
	// MARK: - App Header Section
	@ViewBuilder
	private var appHeaderSection: some View {
		HStack(spacing: 12) {
			// App Icon with rounded corners
			if let iconURL = app.iconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image.appIconStyle(size: 100, isCircle: false)
					} else {
						standardIcon
					}
				}
			} else {
				standardIcon
			}
			
			VStack(alignment: .leading, spacing: 8) {
				Text(app.currentName)
					.font(.title2)
					.fontWeight(.semibold)
					.foregroundColor(.primary)
					.lineLimit(2)
				
				Spacer()
				
				DownloadButtonView(app: app)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.fill(
					LinearGradient(
						colors: [
							dominantColor.opacity(0.2),
							dominantColor.opacity(0.08),
							Color(UIColor.secondarySystemGroupedBackground).opacity(0.9)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		)
		.clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
		.overlay(
			RoundedRectangle(cornerRadius: 20, style: .continuous)
				.stroke(
					LinearGradient(
						colors: [dominantColor.opacity(0.4), dominantColor.opacity(0.2)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					lineWidth: 1.5
				)
		)
		.shadow(color: dominantColor.opacity(0.2), radius: 10, x: 0, y: 4)
	}
	
	var standardIcon: some View {
		Image("App_Unknown").appIconStyle(size: 100, isCircle: false)
	}
	
	var standardHeader: some View {
		Image("App_Unknown")
			.resizable()
			.aspectRatio(contentMode: .fill)
			.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
			.clipped()
	}
}

// MARK: - RoundedCorner Shape Helper
struct RoundedCorner: Shape {
	var radius: CGFloat = .infinity
	var corners: UIRectCorner = .allCorners
	
	func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(
			roundedRect: rect,
			byRoundingCorners: corners,
			cornerRadii: CGSize(width: radius, height: radius)
		)
		return Path(path.cgPath)
	}
}

// MARK: - SourceAppsDetailView (Extension): Builders
extension SourceAppsDetailView {
	@available(iOS 18.0, *)
	@ViewBuilder
	private func _header() -> some View {
		ZStack {
			if let iconURL = source.currentIconURL {
				LazyImage(url: iconURL) { state in
					if let image = state.image {
						image.resizable()
							.aspectRatio(contentMode: .fill)
							.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
							.clipped()
					} else {
						standardHeader
					}
				}
			} else {
				standardHeader
			}
			
			NBVariableBlurView()
				.rotationEffect(.degrees(-180))
				.overlay(
					LinearGradient(
						gradient: Gradient(colors: [
							Color.black.opacity(0.8),
							Color.black.opacity(0)
						]),
						startPoint: .top,
						endPoint: .bottom
					)
				)
		}
	}
	
	@ViewBuilder
	private func _infoPills(app: ASRepository.App) -> some View {
		let pillItems = _buildPills(from: app)
		HStack(spacing: 6) {
			ForEach(pillItems.indices, id: \.hashValue) { index in
				let pill = pillItems[index]
				NBPillView(
					title: pill.title,
					icon: pill.icon,
					color: pill.color,
					index: index,
					count: pillItems.count
				)
			}
		}
	}
	
	private func _buildPills(from app: ASRepository.App) -> [NBPillItem] {
		let pills: [NBPillItem] = []
		return pills
	}
	
	@ViewBuilder
	private func _infoRow(title: String, value: String, icon: String? = nil) -> some View {
		HStack(spacing: 12) {
			if let icon = icon {
				Image(systemName: icon)
					.font(.system(size: 15))
					.foregroundStyle(.secondary)
					.frame(width: 24)
			}
			LabeledContent {
				Text(value)
					.foregroundStyle(.primary)
			} label: {
				Text(title)
					.foregroundStyle(.secondary)
			}
		}
		Divider()
	}
	
	@ViewBuilder
	private func _screenshots(screenshotURLs: [URL]) -> some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 12) {
				ForEach(screenshotURLs.indices, id: \.self) { index in
					let url = screenshotURLs[index]
					LazyImage(url: url) { state in
						if let image = state.image {
							image
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(
									maxWidth: UIScreen.main.bounds.width - 32,
									maxHeight: 400
								)
								.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
								.overlay {
									RoundedRectangle(cornerRadius: 16, style: .continuous)
										.strokeBorder(.gray.opacity(0.3), lineWidth: 1)
								}
								.onTapGesture {
									_selectedScreenshotIndex = index
									_isScreenshotPreviewPresented = true
								}
						}
					}
				}
			}
			.padding(.horizontal)
			.compatScrollTargetLayout()
		}
		.compatScrollTargetBehavior()
		.padding(.horizontal, -16)
	}
	
	// MARK: - Color Extraction
	private func extractDominantColor(from url: URL) {
		Task {
			guard let data = try? Data(contentsOf: url),
				  let uiImage = UIImage(data: data),
				  let cgImage = uiImage.cgImage else { return }
			
			let ciImage = CIImage(cgImage: cgImage)
			let filter = CIFilter(name: "CIAreaAverage")
			filter?.setValue(ciImage, forKey: kCIInputImageKey)
			filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
			
			guard let outputImage = filter?.outputImage else { return }
			
			var pixel = [UInt8](repeating: 0, count: 4)
			CIContext().render(
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
			
			await MainActor.run {
				dominantColor = Color(red: r, green: g, blue: b)
			}
		}
	}
}
