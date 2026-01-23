import SwiftUI
import NimbleViews

// MARK: - View
struct DefaultFrameworksView: View {
    @StateObject private var manager = DefaultFrameworksManager.shared
    @State private var isAddingPresenting = false
    
    var body: some View {
        NBList(.localized("Default Frameworks")) {
            frameworksSection
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isAddingPresenting = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $isAddingPresenting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.dylib, .deb],
                allowsMultipleSelection: true,
                onDocumentsPicked: handleDocumentsPicked
            )
            .ignoresSafeArea()
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: manager.frameworks)
    }
    
    // MARK: - Sections
    private var frameworksSection: some View {
        Section {
            if manager.frameworks.isEmpty {
                emptyStateView
            } else {
                ForEach(manager.frameworks, id: \.absoluteString) { framework in
                    FrameworkRowView(
                        framework: framework,
                        onDelete: { deleteFramework(framework) }
                    )
                }
                .onDelete(perform: deleteFrameworks)
            }
        } header: {
            Label("Frameworks", systemImage: "puzzlepiece.extension.fill")
        } footer: {
            Text(.localized("Frameworks added here will be available to inject when signing apps via the Tweaks section."))
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "puzzlepiece.extension")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.accentColor.opacity(0.6))
            }
            
            VStack(spacing: 4) {
                Text(.localized("No Frameworks"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(.localized("Tap + to add your first framework."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Actions
    private func handleDocumentsPicked(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        
        for url in urls {
            manager.addFramework(url) { result in
                switch result {
                case .success:
                    HapticsManager.shared.success()
                case .failure(let error):
                    HapticsManager.shared.error()
                    UIAlertController.showAlertWithOk(
                        title: .localized("Error"),
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    private func deleteFramework(_ framework: URL) {
        manager.removeFramework(framework) {
            HapticsManager.shared.impact()
        }
    }
    
    private func deleteFrameworks(at offsets: IndexSet) {
        for index in offsets {
            let framework = manager.frameworks[index]
            deleteFramework(framework)
        }
    }
}

// MARK: - Framework Row View
private struct FrameworkRowView: View {
    let framework: URL
    let onDelete: () -> Void
    
    private var fileExtension: String {
        framework.pathExtension.lowercased()
    }
    
    private var iconName: String {
        fileExtension == "deb" ? "shippingbox.fill" : "puzzlepiece.extension.fill"
    }
    
    private var iconColor: Color {
        fileExtension == "deb" ? .orange : .accentColor
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(framework.deletingPathExtension().lastPathComponent)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(framework.pathExtension.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.8))
                        .cornerRadius(4)
                    
                    if let size = fileSize {
                        Text(size)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private var fileSize: String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: framework.path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
