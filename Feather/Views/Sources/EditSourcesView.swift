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
				// Background gradient
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.05),
						Color.clear
					],
					startPoint: .top,
					endPoint: .bottom
				)
				.ignoresSafeArea()
				
				NBList(.localized("Edit Sources")) {
					ForEach(Array(sources), id: \.objectID) { source in
						sourceRow(source)
							.listRowBackground(
								RoundedRectangle(cornerRadius: 10, style: .continuous)
									.fill(Color(uiColor: .secondarySystemGroupedBackground))
									.padding(.horizontal, 4)
									.padding(.vertical, 2)
							)
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
			.alert(.localized("Delete Source"), isPresented: $showDeleteAlert) {
				Button(.localized("Cancel"), role: .cancel) {}
				Button(.localized("Delete"), role: .destructive) {
					if let source = sourceToDelete {
						Storage.shared.deleteSource(for: source)
					}
				}
			} message: {
				Text(.localized("Are you sure you want to delete this source? This action cannot be undone."))
			}
		}
	}
	
	// MARK: - Source Row
	@ViewBuilder
	private func sourceRow(_ source: AltSource) -> some View {
		HStack(spacing: 14) {
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
				.frame(width: 56, height: 56)
				.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
				.shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
			} else {
				placeholderIcon
					.shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
			}
			
			// Name and URL with better spacing
			VStack(alignment: .leading, spacing: 5) {
				Text(source.name ?? .localized("Unknown"))
					.font(.system(size: 16, weight: .semibold))
					.foregroundStyle(.primary)
				
				if let url = source.sourceURL?.absoluteString {
					Text(url)
						.font(.caption)
						.foregroundStyle(.secondary)
						.lineLimit(1)
				}
			}
			
			Spacer()
			
			// Drag indicator
			Image(systemName: "line.3.horizontal")
				.font(.system(size: 14))
				.foregroundStyle(.tertiary)
		}
		.padding(.vertical, 8)
	}
	
	private var placeholderIcon: some View {
		RoundedRectangle(cornerRadius: 14, style: .continuous)
			.fill(
				LinearGradient(
					colors: [
						Color.accentColor.opacity(0.2),
						Color.accentColor.opacity(0.1)
					],
					startPoint: .topLeading,
					endPoint: .bottomTrailing
				)
			)
			.frame(width: 56, height: 56)
			.overlay(
				Image(systemName: "globe")
					.font(.title2)
					.foregroundStyle(
						LinearGradient(
							colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			)
	}
	
	// MARK: - Empty State
	@ViewBuilder
	private var emptyStateView: some View {
		if #available(iOS 17, *) {
			ContentUnavailableView {
				ConditionalLabel(title: .localized("No Sources"), systemImage: "globe.desk.fill")
			} description: {
				Text(.localized("Add sources from the home screen to get started."))
			}
		} else {
			VStack(spacing: 12) {
				Image(systemName: "globe.desk.fill")
					.font(.system(size: 48))
					.foregroundStyle(.secondary)
				Text(.localized("No Sources"))
					.font(.headline)
				Text(.localized("Add sources from the home screen to get started."))
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
