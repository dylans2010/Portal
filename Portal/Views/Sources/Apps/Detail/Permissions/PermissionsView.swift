import SwiftUI
import AltSourceKit
import NimbleViews

// MARK: - PermissionsView
struct PermissionsView: View {
    var appPermissions: ASRepository.AppPermissions
    var dominantColor: Color = .accentColor
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let entitlements = appPermissions.entitlements, !entitlements.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [dominantColor, dominantColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(.localized("Entitlements"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Entitlements list
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(entitlements, id: \.name) { entitlement in
                                HStack(alignment: .center, spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [dominantColor.opacity(0.2), dominantColor.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(dominantColor)
                                    }
                                    .shadow(color: dominantColor.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    Text(entitlement.name)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Spacer(minLength: 0)
                                }
                                .padding(14)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        dominantColor.opacity(0.08),
                                                        dominantColor.opacity(0.03)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(dominantColor.opacity(0.2), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text(.localized("Entitlements"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary.opacity(0.5))
                            
                            Text(.localized("No Entitlements Listed"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.clear)
                        )
                    }
                }
                
                if let privacyItems = appPermissions.privacy, !privacyItems.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        // Section Header
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            Text(.localized("Privacy Permissions"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        // Privacy items
                        VStack(spacing: 12) {
                            ForEach(privacyItems, id: \.self) { item in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top, spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color.orange.opacity(0.2), Color.orange.opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "hand.raised.fill")
                                                .font(.title3)
                                                .foregroundStyle(Color.orange)
                                        }
                                        .shadow(color: Color.orange.opacity(0.2), radius: 4, x: 0, y: 2)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text(item.name)
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.primary)
                                            
                                            Text(item.usageDescription)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        Spacer(minLength: 0)
                                    }
                                }
                                .padding(16)
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.orange.opacity(0.08),
                                                        Color.orange.opacity(0.03)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                        
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                                    }
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                            Text(.localized("Privacy Permissions"))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        .padding(.horizontal, 4)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "hand.raised")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary.opacity(0.5))
                            
                            Text(.localized("No Privacy Permissions Listed"))
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.clear)
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color.clear)
        .navigationTitle(.localized("Permissions"))
        .navigationBarTitleDisplayMode(.large)
    }
}
