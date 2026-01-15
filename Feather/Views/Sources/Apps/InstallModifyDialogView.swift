import SwiftUI
import NimbleViews

// MARK: - Modern Install/Modify Dialog (Full Screen)
struct InstallModifyDialogView: View {
    @Environment(\.dismiss) var dismiss
    let app: AppInfoPresentable
    
    @State private var isSigning = false
    @State private var showModifyView = false
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Content
                VStack(spacing: 32) {
                    // Success indicator
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.green)
                    }
                    .scaleEffect(appearAnimation ? 1 : 0.5)
                    .opacity(appearAnimation ? 1 : 0)
                    
                    // App info
                    VStack(spacing: 12) {
                        // App icon
                        appIcon
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        Text(app.name ?? "App")
                            .font(.title2.weight(.bold))
                        
                        if let version = app.version {
                            Text("Version \(version)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                    
                    Text("Download Complete")
                        .font(.headline)
                        .foregroundStyle(.green)
                        .opacity(appearAnimation ? 1 : 0)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    // Install button - triggers signing then installing
                    Button {
                        startSigningAndInstall()
                    } label: {
                        HStack(spacing: 10) {
                            if isSigning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                                Text("Signing...")
                            } else {
                                Image(systemName: "arrow.down.app.fill")
                                Text("Install")
                            }
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isSigning)
                    
                    // Modify button
                    Button {
                        showModifyView = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "slider.horizontal.3")
                            Text("Modify")
                        }
                        .font(.headline)
                        .foregroundStyle(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(isSigning)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
        .fullScreenCover(isPresented: $showModifyView) {
            ModernSigningView(app: app)
        }
    }
    
    @ViewBuilder
    private var appIcon: some View {
        if let iconURL = (app as? Signed)?.iconURL ?? (app as? Imported)?.iconURL {
            AsyncImage(url: iconURL) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    iconPlaceholder
                }
            }
        } else {
            iconPlaceholder
        }
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.secondary.opacity(0.1))
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            )
    }
    
    private func startSigningAndInstall() {
        isSigning = true
        
        // Start signing process in background
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Post notification to trigger signing
            NotificationCenter.default.post(
                name: Notification.Name("Feather.startSigningAndInstall"),
                object: app
            )
            
            // Dismiss after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                dismiss()
            }
        }
    }
}
