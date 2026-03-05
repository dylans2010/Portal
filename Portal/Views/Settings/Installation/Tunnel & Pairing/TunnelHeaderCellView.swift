import SwiftUI

struct TunnelHeaderView: View {
	@State var lastHeartbeatTime = Date()
	
	var body: some View {
		HStack(spacing: 16) {
			ZStack {
				Circle()
					.fill(
						LinearGradient(
							colors: [
								Color.green.opacity(0.15),
								Color.mint.opacity(0.1)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 44, height: 44)
					.shadow(color: Color.green.opacity(0.2), radius: 6, x: 0, y: 3)
				
				TunnelPulseRing(lastHeartbeat: $lastHeartbeatTime)
			}
			
			Text(.localized("Status"))
				.font(.body)
				.fontWeight(.medium)
				.foregroundStyle(
					LinearGradient(
						colors: [Color.primary, Color.primary.opacity(0.8)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
			
			Spacer()
		}
		.padding(.vertical, 4)
		.onReceive(NotificationCenter.default.publisher(for: .heartbeat)) { _ in
			lastHeartbeatTime = Date()
		}
	}
}

struct TunnelPulseRing: View {
	@State private var _animationProgress = 0.0
	
	private let _animationDuration = 10.0
	private let _colorStartThreshold = 0.5
	private let _colorTransitionDuration = 9.0
	
	@Binding var lastHeartbeat: Date
	
	var body: some View {
		TimelineView(.animation) { timeline in
			let timeSinceHeartbeat = timeline.date.timeIntervalSince(lastHeartbeat)
			let progress = min(1.0, max(0.0, timeSinceHeartbeat / _animationDuration))
			
			let colorTransitionProgress = min(1.0,
				max(0.0, (timeSinceHeartbeat - _colorStartThreshold) / _colorTransitionDuration)
			)
			
			ZStack {
				// Outer glow ring
				Circle()
					.stroke(
						LinearGradient(
							colors: [
								Color(
									red: colorTransitionProgress,
									green: 1.0 - (0.7 * colorTransitionProgress),
									blue: 0.0
								).opacity(0.3),
								Color(
									red: colorTransitionProgress,
									green: 1.0 - (0.7 * colorTransitionProgress),
									blue: 0.0
								).opacity(0.1)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						),
						lineWidth: 2
					)
					.frame(width: 18 + (6 * (1.0 - progress)), height: 18 + (6 * (1.0 - progress)))
					.opacity(1.0 - (0.8 * progress))
				
				// Inner solid circle
				Circle()
					.fill(
						LinearGradient(
							colors: [
								Color(
									red: colorTransitionProgress,
									green: 1.0 - (0.7 * colorTransitionProgress),
									blue: 0.0
								),
								Color(
									red: colorTransitionProgress,
									green: 1.0 - (0.7 * colorTransitionProgress),
									blue: 0.0
								).opacity(0.8)
							],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 14, height: 14)
					.shadow(
						color: Color(
							red: colorTransitionProgress,
							green: 1.0 - (0.7 * colorTransitionProgress),
							blue: 0.0
						).opacity(0.6),
						radius: 6,
						x: 0,
						y: 2
					)
			}
			.animation(.easeInOut(duration: 0.3), value: lastHeartbeat)
		}
	}
}
