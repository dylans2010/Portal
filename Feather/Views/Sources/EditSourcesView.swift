import SwiftUI
import AltSourceKit
import NimbleViews
import CoreData

// MARK: - View
struct EditSourcesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel = SourcesViewModel.shared
    @State private var editMode: EditMode = .active
    @State private var sourceToDelete: AltSource?
    @State private var showDeleteAlert = false
    
    var sources: FetchedResults<AltSource>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(sources), id: \.objectID) { source in
                    sourceRow(source)
                }
                .onDelete(perform: deleteSource)
                .onMove(perform: moveSource)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Sources")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .overlay {
                if sources.isEmpty {
                    emptyStateView
                }
            }
            .alert("Delete Source?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let source = sourceToDelete {
                        Storage.shared.deleteSource(for: source)
                    }
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    @ViewBuilder
    private func sourceRow(_ source: AltSource) -> some View {
        HStack(spacing: 12) {
            if let iconURL = source.iconURL {
                AsyncImage(url: iconURL) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        placeholderIcon
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                placeholderIcon
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(source.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                
                if let host = source.sourceURL?.host {
                    Text(host)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
    
    private var placeholderIcon: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.accentColor.opacity(0.1))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "globe")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentColor)
            )
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: "globe.desk.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("No Sources")
                .font(.headline)
            Text("Add sources to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func deleteSource(at offsets: IndexSet) {
        guard let firstIndex = offsets.first else { return }
        sourceToDelete = sources[firstIndex]
        showDeleteAlert = true
    }
    
    private func moveSource(from source: IndexSet, to destination: Int) {
        var sourcesArray = Array(sources)
        sourcesArray.move(fromOffsets: source, toOffset: destination)
        Storage.shared.reorderSources(sourcesArray)
    }
}
