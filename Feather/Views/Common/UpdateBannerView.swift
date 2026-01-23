import SwiftUI

struct UpdateBannerView: View {
    let version: String
    let message: String
    let onDismiss: () -> Void
    let onUpdate: () -> Void
    
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.green)
                
                Text("v\(version) available")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Button("Update") {
                    onUpdate()
                    withAnimation { isVisible = false }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green, in: Capsule())
                
                Button {
                    withAnimation { isVisible = false }
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - App Update Banner View
struct AppUpdateBannerView: View {
    let update: AppUpdateInfo
    let onDismiss: () -> Void
    let onSignApp: () -> Void
    
    @State private var isVisible = true
    @State private var iconImage: UIImage?
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                // App Icon
                if let iconURLString = update.iconURL, let iconURL = URL(string: iconURLString) {
                    AsyncImage(url: iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.green.opacity(0.2))
                            .overlay(
                                Image(systemName: "app.fill")
                                    .foregroundStyle(.green)
                            )
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "app.fill")
                                .foregroundStyle(.green)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(update.appName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                    }
                    
                    Text("v\(update.currentVersion) → v\(update.newVersion)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    onSignApp()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVisible = false
                    }
                } label: {
                    Text("Sign")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green, in: Capsule())
                }
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVisible = false
                    }
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .move(edge: .top).combined(with: .opacity)
            ))
        }
    }
}

// MARK: - Multiple App Updates Banner View
struct MultipleAppUpdatesBannerView: View {
    let updates: [AppUpdateInfo]
    let onDismiss: () -> Void
    let onViewAll: () -> Void
    
    @State private var isVisible = true
    
    var body: some View {
        if isVisible && !updates.isEmpty {
            HStack(spacing: 12) {
                // Stacked icons indicator
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(updates.count) App Updates Available")
                        .font(.subheadline.weight(.semibold))
                    
                    Text(updates.prefix(3).map { $0.appName }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button {
                    onViewAll()
                } label: {
                    Text("View")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.green, in: Capsule())
                }
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isVisible = false
                    }
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
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
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "arrow.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Update Available")
                        .font(.subheadline.weight(.semibold))
                    Text("v\(version)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button {
                    if let url = URL(string: releaseURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("View")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green, in: Capsule())
                }
                
                Button {
                    withAnimation { isVisible = false }
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
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
