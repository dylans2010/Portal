import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - LibraryCellView - Premium Glassy Card Design
struct LibraryCellView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.editMode) private var editMode

    let app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    @Binding var selectedAppUUIDs: Set<String>
    
    @State private var dominantColor: Color = .cyan
    
    private var certInfo: Date.ExpirationInfo? {
        Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
    }
    
    private var certRevoked: Bool {
        Storage.shared.getCertificate(from: app)?.revoked == true
    }
    
    private var appName: String {
        app.name ?? String.localized("Unknown")
    }
    
    private var appDescription: String {
        if let version = app.version, let id = app.identifier {
            return "\(version) • \(id)"
        } else {
            return String.localized("Unknown")
        }
    }
    
    private var isSelected: Bool {
        guard let uuid = app.uuid else { return false }
        return selectedAppUUIDs.contains(uuid)
    }
    
    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        HStack(spacing: 16) {
            // Selection checkbox in edit mode
            if isEditing {
                selectionButton
            }
            
            // Elevated app icon container
            iconContainer
            
            // App info text
            appInfoStack
            
            // Action button when not editing
            if !isEditing {
                actionButton
            }
        }
        .padding(18)
        .background(premiumCardBackground(isEditing: isEditing))
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(isEditing: isEditing)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !isEditing {
                deleteAction
            }
        }
        .contextMenu {
            if !isEditing {
                contextMenuContent
            }
        }
    }
    
    // MARK: - View Components
    @ViewBuilder
    private var selectionButton: some View {
        Button {
            toggleSelection()
        } label: {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.cyan : Color.white.opacity(0.1))
                    .frame(width: 28, height: 28)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.borderless)
    }
    
    @ViewBuilder
    private var iconContainer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            dominantColor.opacity(0.4),
                            dominantColor.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .shadow(color: dominantColor.opacity(0.4), radius: 8, x: 0, y: 4)
            
            FRAppIconView(app: app, size: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    @ViewBuilder
    private var appInfoStack: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
            
            if let identifier = app.identifier {
                Text(identifier)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            
            HStack(spacing: 8) {
                if let version = app.version {
                    Text("v\(version)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(dominantColor)
                }
                
                if app.isSigned {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                        Text("Signed")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var actionButton: some View {
        Button {
            if app.isSigned {
                selectedInstallAppPresenting = AnyApp(base: app)
            } else {
                selectedSigningAppPresenting = AnyApp(base: app)
            }
        } label: {
            Text(app.isSigned ? "Install" : "Sign")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: app.isSigned ? [.green, .green.opacity(0.8)] : [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: (app.isSigned ? Color.green : Color.cyan).opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var deleteAction: some View {
        Button(role: .destructive) {
            Storage.shared.deleteApp(for: app)
        } label: {
            Label(String.localized("Delete"), systemImage: "trash")
        }
    }
    
    @ViewBuilder
    private var contextMenuContent: some View {
        Button {
            selectedInfoAppPresenting = AnyApp(base: app)
        } label: {
            Label(String.localized("Details"), systemImage: "info.circle")
        }
        
        Divider()
        
        if app.isSigned {
            if let id = app.identifier {
                Button {
                    UIApplication.openApp(with: id)
                } label: {
                    Label(String.localized("Open"), systemImage: "app.badge.checkmark")
                }
            }
            Button {
                selectedInstallAppPresenting = AnyApp(base: app)
            } label: {
                Label(String.localized("Install"), systemImage: "square.and.arrow.down")
            }
            Button {
                selectedSigningAppPresenting = AnyApp(base: app)
            } label: {
                Label(String.localized("ReSign"), systemImage: "signature")
            }
            Button {
                selectedInstallAppPresenting = AnyApp(base: app, archive: true)
            } label: {
                Label(String.localized("Export"), systemImage: "square.and.arrow.up")
            }
        } else {
            Button {
                selectedInstallAppPresenting = AnyApp(base: app)
            } label: {
                Label(String.localized("Install"), systemImage: "square.and.arrow.down")
            }
            Button {
                selectedSigningAppPresenting = AnyApp(base: app)
            } label: {
                Label(String.localized("Sign"), systemImage: "signature")
            }
        }
        
        Divider()
        
        Button(role: .destructive) {
            Storage.shared.deleteApp(for: app)
        } label: {
            Label(String.localized("Delete"), systemImage: "trash")
        }
    }
    
    // MARK: - Premium Card Background
    @ViewBuilder
    private func premiumCardBackground(isEditing: Bool) -> some View {
        ZStack {
            // Glassy dark gradient background
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.18, blue: 0.35),
                            Color(red: 0.08, green: 0.12, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Inner highlight for glassy effect
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(isSelected && isEditing ? 0.4 : 0.2),
                            .white.opacity(0.05),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isSelected && isEditing ? 2 : 1
                )
            
            // Subtle accent glow
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(dominantColor.opacity(isSelected && isEditing ? 0.15 : 0.05))
        }
        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 8)
        .shadow(color: dominantColor.opacity(0.1), radius: 16, x: 0, y: 10)
    }
    
    private func handleTap(isEditing: Bool) {
        if isEditing {
            toggleSelection()
        } else {
            selectedInfoAppPresenting = AnyApp(base: app)
        }
    }
    
    private func toggleSelection() {
        guard let uuid = app.uuid else { return }
        if selectedAppUUIDs.contains(uuid) {
            selectedAppUUIDs.remove(uuid)
        } else {
            selectedAppUUIDs.insert(uuid)
        }
    }
}