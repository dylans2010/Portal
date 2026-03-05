import SwiftUI
import ActivityKit
import WidgetKit

/// Live Activity view for app installation progress
@available(iOS 16.1, *)
struct InstallationLiveActivityView: View {
    let context: ActivityViewContext<InstallationActivityAttributes>
    
    private var currentStep: Int {
        switch context.state.status {
        case .preparing, .downloading, .unzipping:
            return 1
        case .signing, .rezipping:
            return 2
        case .installing, .verifying, .completed, .failed, .paused, .cancelled:
            return 3
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            // Top Row
            HStack(alignment: .top, spacing: 12) {
                // App Icon
                appIconView
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.appName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("Step \(currentStep)/3")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "signature")
                            .font(.system(size: 10, weight: .bold))
                        Text(context.state.status.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .overlay(alignment: .topTrailing) {
                Text(context.state.progressPercentage)
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .offset(y: -2)
            }
            
            // Middle: Segmented Progress Bar
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { step in
                    Capsule()
                        .fill(step <= currentStep ? Color(red: 0, green: 1, blue: 0.25) : Color(red: 0, green: 0.1, blue: 0.25))
                        .frame(height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentStep)
                }
            }

            // Bottom Row
            HStack {
                // Flashlight Style Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "flashlight.on.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("• X Notification")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                // Camera Style Icon
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(red: 0, green: 0.1, blue: 0.25), Color(red: 0, green: 0.2, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var appIconView: some View {
        Group {
            if let iconData = context.attributes.appIcon,
               let uiImage = UIImage(data: iconData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Color.white.opacity(0.1)
                    
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
        }
    }
}
