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
    
    private var appName: String {
        app.name ?? String.localized("Unknown")
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // App Icon
            FRAppIconView(app: app, size: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(appName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let version = app.version {
                        Text(version)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    
                    if app.isSigned {
                        Label {
                            Text("Signed")
                                .font(.system(size: 12, weight: .bold))
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Label {
                            Text("Imported")
                                .font(.system(size: 12, weight: .bold))
                        } icon: {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.system(size: 10))
                        }
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Action Button (hidden in edit mode)
            if editMode?.wrappedValue != .active {
                Button {
                    if app.isSigned {
                        selectedInstallAppPresenting = AnyApp(base: app)
                    } else {
                        selectedSigningAppPresenting = AnyApp(base: app)
                    }
                } label: {
                    Image(systemName: app.isSigned ? "arrow.down.circle.fill" : "signature")
                        .font(.system(size: 20))
                        .foregroundStyle(app.isSigned ? .green : .accentColor)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if editMode?.wrappedValue != .active {
                selectedInfoAppPresenting = AnyApp(base: app)
            }
        }
    }
}
