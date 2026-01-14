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
	
	// MARK: Body
	var body: some View {
		NavigationView {
			ZStack {
				// Glass background
				Color(.systemGroupedBackground)
					.ignoresSafeArea()
				
				NBList(.localized("Edit Sources")) {
					ForEach(Array(sources), id: \.objectID) { source in
						sourceRow(source)
					}
					.onDelete(perform: deleteSource)
					.onMove(perform: moveSource)
					
					if sources.isEmpty {
						emptyStateView
							.listRowBackground(Color.clear)
					}
				}
				.scrollContentBackground(.hidden)
			}
			.environment(\.editMode, $editMode)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						dismiss()
					} label: {
						Text(.localized("Done"))
							.fontWeight(.bold)
							.foregroundStyle(.white)
							.padding(.horizontal, 16)
							.padding(.vertical, 8)
							.background(
								Capsule()
									.fill(Color.accentColor)
							)
					}
				}
			}
			.alert(.localized("Delete Source?"), isPresented: $showDeleteAlert) {
				Button(.localized("Cancel"), role: .cancel) {}
				Button(.localized("Delete"), role: .destructive) {
					if let source = sourceToDelete {
						Storage.shared.deleteSource(for: source)
					}
				}
			} message: {
				Text(.localized("Are you sure you want to delete this source?"))
			}
		}
	}
	
	// MARK: - Source Row
	@ViewBuilder
	private func sourceRow(_ source: AltSource) -> some View {
		HStack(spacing: 12) {
			// Icon with shadow
			if let iconURL = source.iconURL {
				AsyncImage(url: iconURL) { phase in
					switch phase {
					case .success(let image):
						image
							.resizable()
							.aspectRatio(contentMode: .fill)
					case .empty, .failure:
						placeholderIcon
					@unknown default:
						placeholderIcon
					}
				}
				.frame(width: 48, height: 48)
				.clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
				.shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
			} else {
				placeholderIcon
					.shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
			}
			
			// Name and URL with better spacing
			VStack(alignment: .leading, spacing: 3) {
				Text(source.name ?? .localized("Unknown"))
					.font(.system(size: 15, weight: .semibold))
					.foregroundStyle(.primary)
				
				if let url = source.sourceURL?.absoluteString {
					Text(url)
						.font(.system(size: 11))
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
			
			Spacer()
		}
		.padding(.vertical, 6)
	}
	
	private var placeholderIcon: some View {
		RoundedRectangle(cornerRadius: 12, style: .continuous)
			.fill(Color.accentColor.opacity(0.12))
			.frame(width: 48, height: 48)
			.overlay(
				Image(systemName: "globe")
					.font(.system(size: 20))
					.foregroundStyle(Color.accentColor)
			)
	}
	
	// MARK: - Empty State
	@ViewBuilder
	private var emptyStateView: some View {
		if #available(iOS 17, *) {
			ContentUnavailableView {
				ConditionalLabel(title: .localized("No Sources"), systemImage: "globe.desk.fill")
			} description: {
				Text(.localized("Add sources from the Home Screen to get started."))
			}
		} else {
			VStack(spacing: 12) {
				Image(systemName: "globe.desk.fill")
					.font(.system(size: 48))
					.foregroundStyle(.secondary)
				Text(.localized("No Sources"))
					.font(.headline)
				Text(.localized("Add sources from the Home Screen to get started."))
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
			}
			.padding()
		}
	}
	
	// MARK: - Actions
	private func deleteSource(at offsets: IndexSet) {
		// Only handle single deletion - for multiple items, show alert for first one
		guard let firstIndex = offsets.first else { return }
		let source = sources[firstIndex]
		sourceToDelete = source
		showDeleteAlert = true
	}
	
	private func moveSource(from source: IndexSet, to destination: Int) {
		var sourcesArray = Array(sources)
		sourcesArray.move(fromOffsets: source, toOffset: destination)
		Storage.shared.reorderSources(sourcesArray)
	}
}
