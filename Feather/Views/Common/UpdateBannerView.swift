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
