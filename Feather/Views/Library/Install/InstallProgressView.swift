import SwiftUI
import IDeviceSwift

struct InstallProgressView: View {
	@State private var _isPulsing = false
	@State private var dominantColor: Color = .accentColor
	@State private var _rotationAngle: Double = 0
	@State private var _glowScale: CGFloat = 1.0
	@State private var _particleOffset: CGFloat = 0
	
	var app: AppInfoPresentable
	@ObservedObject var viewModel: InstallerStatusViewModel
	
	var body: some View {
		VStack(spacing: 24) {
			// Main progress card
			progressCard
				.scaleEffect(_isPulsing ? 1.0 : 0.98)
				.animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: _isPulsing)
			
			// Status info
			statusInfo
		}
		.onAppear {
			_isPulsing = true
			extractDominantColor()
			startRotation()
			startGlowAnimation()
		}
	}
	
	// MARK: - Progress Card
	private var progressCard: some View {
		VStack(spacing: 20) {
			// App icon with effects
			appIconWithEffects
			
			// Progress bar
			if !viewModel.isCompleted {
				modernProgressBar
			}
		}
		.padding(28)
		.background(
			ZStack {
				// Glassmorphism background
				RoundedRectangle(cornerRadius: 28, style: .continuous)
					.fill(.ultraThinMaterial)
				
				// Gradient overlay
				RoundedRectangle(cornerRadius: 28, style: .continuous)
					.fill(
						LinearGradient(
							colors: [
								dominantColor.opacity(0.08),
								dominantColor.opacity(0.02),
								Color.clear
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				
				// Animated border glow
				RoundedRectangle(cornerRadius: 28, style: .continuous)
					.stroke(
						LinearGradient(
							colors: [
								dominantColor.opacity(0.4),
								dominantColor.opacity(0.1),
								dominantColor.opacity(0.2)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 1.5
					)
					.scaleEffect(_glowScale)
					.opacity(viewModel.isCompleted ? 0.8 : 0.5)
			}
		)
		.shadow(color: dominantColor.opacity(0.2), radius: 30, x: 0, y: 15)
		.shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
	}
	
	// MARK: - App Icon with Effects
	private var appIconWithEffects: some View {
		ZStack {
			// Outer animated rings
			ForEach(0..<3, id: \.self) { index in
				Circle()
					.stroke(
						dominantColor.opacity(0.15 - Double(index) * 0.04),
						lineWidth: 2
					)
					.frame(width: 100 + CGFloat(index) * 25, height: 100 + CGFloat(index) * 25)
					.scaleEffect(_isPulsing ? 1.05 : 1.0)
					.animation(
						.easeInOut(duration: 1.5 + Double(index) * 0.2)
						.repeatForever(autoreverses: true)
						.delay(Double(index) * 0.1),
						value: _isPulsing
					)
			}
			
			// Soft glow background
			Circle()
				.fill(
					RadialGradient(
						colors: [
							dominantColor.opacity(viewModel.isCompleted ? 0.5 : 0.35),
							dominantColor.opacity(0.15),
							Color.clear
						],
						center: .center,
						startRadius: 20,
						endRadius: 80
					)
				)
				.frame(width: 160, height: 160)
				.blur(radius: 15)
				.scaleEffect(_glowScale)
			
			// Rotating progress ring
			if !viewModel.isCompleted {
				Circle()
					.stroke(
						AngularGradient(
							colors: [
								dominantColor.opacity(0.9),
								dominantColor.opacity(0.5),
								dominantColor.opacity(0.2),
								Color.clear,
								Color.clear,
								dominantColor.opacity(0.9)
							],
							center: .center,
							startAngle: .degrees(0),
							endAngle: .degrees(360)
						),
						style: StrokeStyle(lineWidth: 4, lineCap: .round)
					)
					.frame(width: 85, height: 85)
					.rotationEffect(.degrees(_rotationAngle))
			}
			
			// Progress track
			Circle()
				.stroke(
					dominantColor.opacity(0.15),
					style: StrokeStyle(lineWidth: 6, lineCap: .round)
				)
				.frame(width: 75, height: 75)
			
			// Progress fill
			Circle()
				.trim(from: 0, to: viewModel.overallProgress)
				.stroke(
					LinearGradient(
						colors: [dominantColor, dominantColor.opacity(0.7)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					),
					style: StrokeStyle(lineWidth: 6, lineCap: .round)
				)
				.frame(width: 75, height: 75)
				.rotationEffect(.degrees(-90))
				.animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.overallProgress)
			
			// App icon container
			ZStack {
				// Shadow
				FRAppIconView(app: app)
					.frame(width: 58, height: 58)
					.opacity(0.2)
					.blur(radius: 6)
					.offset(y: 4)
				
				// Main icon
				FRAppIconView(app: app)
					.frame(width: 58, height: 58)
					.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
					.overlay(
						RoundedRectangle(cornerRadius: 14, style: .continuous)
							.stroke(Color.white.opacity(0.3), lineWidth: 1)
					)
					.shadow(color: dominantColor.opacity(0.4), radius: 10, x: 0, y: 5)
			}
			
			// Success overlay
			if viewModel.isCompleted {
				ZStack {
					Circle()
						.fill(
							LinearGradient(
								colors: [.green, .green.opacity(0.8)],
								startPoint: .topLeading,
								endPoint: .bottomTrailing
							)
						)
						.frame(width: 36, height: 36)
						.shadow(color: .green.opacity(0.5), radius: 8, x: 0, y: 4)
					
					Image(systemName: "checkmark")
						.font(.system(size: 18, weight: .bold))
						.foregroundStyle(.white)
				}
				.offset(x: 30, y: 30)
				.transition(.scale.combined(with: .opacity))
			}
		}
	}
	
	// MARK: - Modern Progress Bar
	private var modernProgressBar: some View {
		VStack(spacing: 10) {
			// Progress bar
			GeometryReader { geometry in
				ZStack(alignment: .leading) {
					// Track
					RoundedRectangle(cornerRadius: 6, style: .continuous)
						.fill(dominantColor.opacity(0.15))
						.frame(height: 8)
					
					// Fill with gradient
					RoundedRectangle(cornerRadius: 6, style: .continuous)
						.fill(
							LinearGradient(
								colors: [dominantColor, dominantColor.opacity(0.7)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.frame(width: geometry.size.width * viewModel.overallProgress, height: 8)
						.animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.overallProgress)
					
					// Shimmer effect
					if viewModel.overallProgress > 0 && viewModel.overallProgress < 1 {
						RoundedRectangle(cornerRadius: 6, style: .continuous)
							.fill(
								LinearGradient(
									colors: [
										Color.white.opacity(0),
										Color.white.opacity(0.4),
										Color.white.opacity(0)
									],
									startPoint: .leading,
									endPoint: .trailing
								)
							)
							.frame(width: 40, height: 8)
							.offset(x: _particleOffset * geometry.size.width - 20)
							.mask(
								RoundedRectangle(cornerRadius: 6, style: .continuous)
									.frame(width: geometry.size.width * viewModel.overallProgress, height: 8)
							)
					}
				}
			}
			.frame(height: 8)
			
			// Percentage
			Text("\(Int(viewModel.overallProgress * 100))%")
				.font(.system(size: 14, weight: .bold, design: .rounded))
				.foregroundStyle(dominantColor)
		}
		.onAppear {
			startShimmerAnimation()
		}
	}
	
	// MARK: - Status Info
	private var statusInfo: some View {
		VStack(spacing: 8) {
			if viewModel.isCompleted {
				HStack(spacing: 8) {
					Image(systemName: "checkmark.circle.fill")
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(.green)
					
					Text("Installation Complete")
						.font(.system(size: 15, weight: .semibold))
						.foregroundStyle(.primary)
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 10)
				.background(
					Capsule()
						.fill(.green.opacity(0.12))
						.overlay(
							Capsule()
								.stroke(.green.opacity(0.2), lineWidth: 1)
						)
				)
			} else {
				Text("\(viewModel.currentStep)")
					.font(.system(size: 13, weight: .medium))
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.lineLimit(2)
			}
		}
		.animation(.easeInOut(duration: 0.3), value: viewModel.isCompleted)
	}
	
	// MARK: - Animations
	private func startRotation() {
		withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
			_rotationAngle = 360
		}
	}
	
	private func startGlowAnimation() {
		withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
			_glowScale = 1.05
		}
	}
	
	private func startShimmerAnimation() {
		withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
			_particleOffset = 1.2
		}
	}
	
	private func extractDominantColor() {
		Task {
			if let iconURL = app.iconURL,
			   let data = try? Data(contentsOf: iconURL),
			   let uiImage = UIImage(data: data),
			   let cgImage = uiImage.cgImage {
				
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
	
	struct PieShape: Shape {
		var progress: Double
		
		func path(in rect: CGRect) -> Path {
			var path = Path()
			let center = CGPoint(x: rect.midX, y: rect.midY)
			let radius = min(rect.width, rect.height) / 2
			let startAngle = Angle(degrees: -90)
			let endAngle = Angle(degrees: -90 + progress * 360)
			
			path.move(to: center)
			path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
			path.closeSubpath()
			
			return path
		}
		
		var animatableData: Double {
			get { progress }
			set { progress = newValue }
		}
	}
}
