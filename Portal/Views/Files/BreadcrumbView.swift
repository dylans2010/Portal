import SwiftUI

// MARK: - BreadcrumbView
struct BreadcrumbView: View {
    let currentPath: String
    let baseDirectory: URL
    let onNavigate: (URL) -> Void
    
    private var pathComponents: [(name: String, url: URL)] {
        let basePath = baseDirectory.path
        let relativePath = currentPath.replacingOccurrences(of: basePath, with: "")
        
        var components: [(String, URL)] = []
        var buildPath = basePath
        
        // Add root/base
        components.append(("Files", baseDirectory))
        
        // Split relative path and build components
        let pathParts = relativePath.split(separator: "/").map(String.init)
        for part in pathParts {
            if !part.isEmpty {
                buildPath += "/\(part)"
                components.append((part, URL(fileURLWithPath: buildPath)))
            }
        }
        
        return components
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                    Button {
                        HapticsManager.shared.impact()
                        onNavigate(component.url)
                    } label: {
                        HStack(spacing: 6) {
                            if index == 0 {
                                Image(systemName: "folder.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            
                            Text(component.name)
                                .font(.subheadline)
                                .fontWeight(index == pathComponents.count - 1 ? .semibold : .regular)
                                .foregroundStyle(index == pathComponents.count - 1 ? .primary : .secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(index == pathComponents.count - 1 
                                      ? Color.accentColor.opacity(0.12)
                                      : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    if index < pathComponents.count - 1 {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.clear)
    }
}

// MARK: - Preview
struct BreadcrumbView_Previews: PreviewProvider {
    static var previews: some View {
        let baseDir = URL(fileURLWithPath: "/var/mobile/Documents/PortalFiles")
        let currentPath = "/var/mobile/Documents/PortalFiles/Apps/MyApp/Resources"
        
        BreadcrumbView(
            currentPath: currentPath,
            baseDirectory: baseDir,
            onNavigate: { _ in }
        )
    }
}
