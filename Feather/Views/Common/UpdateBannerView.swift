// UpdateBannerView is for users to know about a new Portal update
// (WIP) UI fixes

import SwiftUI

struct UpdateBannerView: View {
    let version: String
    let message: String
    let onDismiss: () -> Void
    let onUpdate: () -> Void
    
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    // Update icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.blue)
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Update Available")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("\(message) (v\(version))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Update button
                    Button(action: {
                        onUpdate()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                        HapticsManager.shared.success()
                    }) {
                        Text("Update")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                        onDismiss()
                        HapticsManager.shared.softImpact()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color(UIColor.tertiarySystemBackground))
                            )
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(UIColor.secondarySystemBackground),
                                    Color(UIColor.tertiarySystemBackground)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Update Available View
struct UpdateAvailableView: View {
    let version: String
    let releaseURL: String
    let onDismiss: () -> Void
    let onNavigateToUpdates: () -> Void
    
    @State private var isVisible = true
    @State private var pulseAnimation = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        if isVisible {
            Button {
                onNavigateToUpdates()
                HapticsManager.shared.success()
            } label: {
                HStack(spacing: 14) {
                    // Animated update icon
                    ZStack {
                        // Pulse effect
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0 : 0.5)
                        
                        // Main circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
                        
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text("Update Available!")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            // NEW badge
                            Text("New")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                        }
                        
                        Text("Portal v\(version) has released!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // GitHub Release button
                    Button {
                        if let url = URL(string: releaseURL) {
                            UIApplication.shared.open(url)
                            HapticsManager.shared.softImpact()
                            AppLogManager.shared.info("Opening GitHub release page", category: "Updates")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "link")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Release")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Dismiss button
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isVisible = false
                        }
                        onDismiss()
                        HapticsManager.shared.softImpact()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(Color(UIColor.tertiarySystemBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            colorScheme == .dark ?
                            Color(UIColor.secondarySystemBackground) :
                            Color.white
                        )
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 15, x: 0, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.green.opacity(0.4), Color.green.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.95)),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    pulseAnimation = true
                }
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct UpdateBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UpdateBannerView(
                version: "1.2.0",
                message: "New features and bug fixes",
                onDismiss: {},
                onUpdate: {}
            )
            
            UpdateAvailableView(
                version: "1.2.0",
                releaseURL: "https://github.com/aoyn1xw/Portal/releases/tag/v1.2.0",
                onDismiss: {},
                onNavigateToUpdates: {}
            )
            
            Spacer()
        }
        .background(Color(UIColor.systemBackground))
    }
}
#endif
