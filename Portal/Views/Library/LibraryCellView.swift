import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - LibraryCellView - Modern Minimal Design
struct LibraryCellView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.editMode) private var editMode

    let app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    @Binding var selectedAppUUIDs: Set<String>
    
    private var certInfo: Date.ExpirationInfo? {
        Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
    }
    
    private var certRevoked: Bool {
        Storage.shared.getCertificate(from: app)?.revoked == true
    }
    
    private var appName: String {
        app.name ?? String.localized("Unknown")
    }
    
    private var isSelected: Bool {
        guard let uuid = app.uuid else { return false }
        return selectedAppUUIDs.contains(uuid)
    }
    
    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        HStack(spacing: 0) {
            // Main row button
            Button {
                handleTap(isEditing: isEditing)
            } label: {
                HStack(spacing: 14) {
                    if isEditing {
                        selectionButton
                    }

                    FRAppIconView(app: app, size: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

                    appInfoStack

                    Spacer()
                }
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if !isEditing {
                actionButton
                    .padding(.vertical, 12)
                    .padding(.trailing, 16)
            }
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
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
        }
        .buttonStyle(.borderless)
    }
    
    @ViewBuilder
    private var appInfoStack: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            HStack(spacing: 6) {
                if let version = app.version {
                    Text(version)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                
                if app.isSigned {
                    Text("•")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary.opacity(0.5))
                    
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 11))
                        Text("Signed")
                            .font(.system(size: 13, weight: .medium))
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
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(app.isSigned ? Color.green : Color.accentColor)
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
                Label(String.localized("Install"), systemImage: "arrow.down.circle")
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
                Label(String.localized("Install"), systemImage: "arrow.down.circle")
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