import SwiftUI
import NimbleViews

struct FolderCustomizationView: View {
    @Environment(\.dismiss) var dismiss
    let folderURL: URL
    
    @State private var selectedIcon: String = "folder.fill"
    
    private let availableIcons = [
        "folder.fill", "folder.badge.plus", "folder.badge.gearshape",
        "folder.badge.person.crop", "star.fill", "heart.fill",
        "photo.fill", "music.note", "video.fill", "doc.fill",
        "book.fill", "briefcase.fill", "house.fill", "building.2.fill"
    ]
    
    var body: some View {
        NBNavigationView(.localized("Customize Folder"), displayMode: .inline) {
            Form {
                Section {
                    Text(folderURL.lastPathComponent)
                        .font(.headline)
                } header: {
                    Text(.localized("Folder Name"))
                }
                
                Section {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 60))
                    ], spacing: 16) {
                        ForEach(availableIcons, id: \.self) { icon in
                            iconButton(for: icon)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text(.localized("Icon"))
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        if let savedIcon = UserDefaults.standard.string(forKey: "folder_icon_\(folderURL.path)") {
            selectedIcon = savedIcon
        }
    }
    
    private func saveIcon() {
        UserDefaults.standard.set(selectedIcon, forKey: "folder_icon_\(folderURL.path)")
        HapticsManager.shared.impact()
        FileManagerService.shared.loadFiles()
    }
    
    private func iconButton(for icon: String) -> some View {
        let isSelected = selectedIcon == icon
        let iconColor: Color = isSelected ? .accentColor : .secondary
        let backgroundColor: Color = isSelected ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1)
        
        return Button {
            selectedIcon = icon
            saveIcon()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(iconColor)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(backgroundColor)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
