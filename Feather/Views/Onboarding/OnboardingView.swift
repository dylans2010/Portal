import SwiftUI
import NimbleViews

@available(iOS 17.0, *)
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Simple solid background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Simple content container
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 40) {
                    // App Icon
                    Image(uiImage: AppIconView.altImage(nil))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(28)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    VStack(spacing: 16) {
                        // Title
                        Text("Welcome to Portal")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        // Subtitle
                        Text("Your all in one iOS app sideloading Portal!")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 32)
                    
                    // Feature highlights
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "square.stack.3d.up.fill",
                            title: "Browse Sources",
                            description: "Add surces to Portal and install apps with ease",
                            delay: 0.2
                        )
                        
                        FeatureRow(
                            icon: "signature",
                            title: "Sign Apps",
                            description: "Easy certificate management",
                            delay: 0.3
                        )
                        
                        FeatureRow(
                            icon: "arrow.down.circle.fill",
                            title: "Install Anywhere",
                            description: "Seamless installation process",
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1.0 : 0.0)
                    
                    // Get Started Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            hasCompletedOnboarding = true
                        }
                        HapticsManager.shared.success()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    }
                    .padding(.horizontal, 24)
                    .scaleEffect(animateButton ? 1.0 : 0.9)
                    .opacity(animateButton ? 1.0 : 0.0)
                }
                .padding(.vertical, 48)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                animateButton = true
            }
        }
    }
}

@available(iOS 17.0, *)
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    OnboardingView()
}

// MARK: - Legacy iOS 16 Support
struct OnboardingViewLegacy: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var animateContent = false
    @State private var animateButton = false
    
    var body: some View {
        ZStack {
            // Simple solid background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            // Simple content container
            VStack(spacing: 0) {
                Spacer()
                
                // Main content
                VStack(spacing: 40) {
                    // App Icon
                    Image(uiImage: AppIconView.altImage(nil))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .cornerRadius(28)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .opacity(animateContent ? 1.0 : 0.0)
                    
                    VStack(spacing: 16) {
                        // Title
                        Text("Welcome to Portal")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                        
                        // Subtitle
                        Text("Your all in one iOS app sideloading Portal")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .offset(y: animateContent ? 0 : 20)
                    }
                    .padding(.horizontal, 32)
                    
                    // Feature highlights
                    VStack(spacing: 16) {
                        FeatureRowLegacy(
                            icon: "square.stack.3d.up.fill",
                            title: "Browse Sources",
                            description: "Add your favorite AltStore sources and download apps.",
                            delay: 0.2
                        )
                        
                        FeatureRowLegacy(
                            icon: "signature",
                            title: "Sign Apps",
                            description: "Easy certificate management, add as many as you want and view info on them.",
                            delay: 0.3
                        )
                        
                        FeatureRowLegacy(
                            icon: "arrow.down.circle.fill",
                            title: "Install Anywhere",
                            description: "Seamless installation process with fully local or cloud servers.",
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 24)
                    .opacity(animateContent ? 1.0 : 0.0)
                    
                    // Get Started Button
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            hasCompletedOnboarding = true
                        }
                        HapticsManager.shared.success()
                    } label: {
                        HStack(spacing: 12) {
                            Text("Let's Go!")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.accentColor)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 20, x: 0, y: 10)
                        )
                    }
                    .padding(.horizontal, 24)
                    .scaleEffect(animateButton ? 1.0 : 0.9)
                    .opacity(animateButton ? 1.0 : 0.0)
                }
                .padding(.vertical, 48)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5)) {
                animateButton = true
            }
        }
    }
}

struct FeatureRowLegacy: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon container
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay)) {
                isVisible = true
            }
        }
    }
}
