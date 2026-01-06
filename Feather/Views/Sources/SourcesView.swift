import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews

// MARK: - View
struct SourcesView: View {
	// MARK: - Constants
	private static let certificateURL = "https://techybuff.com/wsf-certificates/"
	
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	#if !NIGHTLY && !DEBUG
	@AppStorage("Feather.shouldStar") private var _shouldStar: Int = 0
	#endif
	@AppStorage("Feather.certificateTooltipDismissed") private var _certificateTooltipDismissed: Bool = false
	@AppStorage("Feather.greetingsName") private var _greetingsName: String = ""
	@StateObject var viewModel = SourcesViewModel.shared
	@State private var _isAddingPresenting = false
	@State private var _addingSourceLoading = false
	@State private var _searchText = ""
	@State private var _showFilterSheet = false
	@State private var _showEditSourcesView = false
	@State private var _sortOrder: SortOrder = .custom
	@State private var _filterByPinned: FilterOption = .all
	@State private var _showCertificateTooltip = false
	
	enum SortOrder: String, CaseIterable {
		case custom = "Custom Order"
		case alphabetical = "A-Z"
		case recentlyAdded = "Recently Added"
		case appCount = "Most Apps"
	}
	
	enum FilterOption: String, CaseIterable {
		case all = "All"
		case pinned = "Pinned Only"
		case unpinned = "Unpinned Only"
	}
	
	// Greeting helper
	private var greetingText: String {
		let hour = Calendar.current.component(.hour, from: Date())
		let greeting: String
		
		if hour >= 5 && hour < 12 {
			greeting = String.localized("Good Morning")
		} else if hour >= 12 && hour < 17 {
			greeting = String.localized("Good Afternoon")
		} else {
			greeting = String.localized("Good Night")
		}
		
		if _greetingsName.isEmpty {
			return greeting
		} else {
			return "\(greeting), \(_greetingsName)!"
		}
	}
	
	private var _filteredSources: [AltSource] {
		// Apply search filter
		var filtered = _sources.filter { 
			_searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) 
		}
		
		// Apply pinned filter
		switch _filterByPinned {
		case .pinned:
			filtered = filtered.filter { viewModel.isPinned($0) }
		case .unpinned:
			filtered = filtered.filter { !viewModel.isPinned($0) }
		case .all:
			break
		}
		
		// Apply sorting
		return filtered.sorted { s1, s2 in
			switch _sortOrder {
			case .custom:
				// FetchRequest already sorts by order, just preserve it
				return s1.order < s2.order
			case .alphabetical:
				let p1 = viewModel.isPinned(s1)
				let p2 = viewModel.isPinned(s2)
				if p1 && !p2 { return true }
				if !p1 && p2 { return false }
				return (s1.name ?? "") < (s2.name ?? "")
			case .recentlyAdded:
				// Sort by date descending (most recent first)
				return (s1.date ?? Date.distantPast) > (s2.date ?? Date.distantPast)
			case .appCount:
				let count1 = viewModel.sources[s1]?.apps.count ?? 0
				let count2 = viewModel.sources[s2]?.apps.count ?? 0
				if count1 != count2 { return count1 > count2 }
				return (s1.name ?? "") < (s2.name ?? "")
			}
		}
	}
	
	@FetchRequest(
		entity: AltSource.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)],
		animation: .easeInOut(duration: 0.35)
	) private var _sources: FetchedResults<AltSource>
	
	// MARK: Body
	var body: some View {
		NBNavigationView(greetingText) {
			contentList
				.searchable(text: $_searchText, placement: .platform())
				.overlay {
					emptyStateView
				}
				.toolbar {
					toolbarContent
				}
				.refreshable {
					await viewModel.fetchSources(_sources, refresh: true)
				}
				.sheet(isPresented: $_isAddingPresenting) {
					addSourceSheet
				}
				.sheet(isPresented: $_showFilterSheet) {
					filterSheet
				}
				.sheet(isPresented: $_showEditSourcesView) {
					EditSourcesView(sources: _sources)
						.presentationDetents([.large])
						.presentationDragIndicator(.visible)
				}
				.sheet(isPresented: $_showCertificateTooltip) {
					certificateTooltipView
				}
		}
		.task(id: Array(_sources)) {
			await viewModel.fetchSources(_sources)
		}
		#if !NIGHTLY && !DEBUG
		.onAppear {
			showStarPromptIfNeeded()
		}
		#endif
	}
	
	// MARK: - View Components
	
	private var contentList: some View {
		NBListAdaptable {
			if !_filteredSources.isEmpty {
				allAppsSection
				repositoriesSection
			}
		}
	}
	
	private var allAppsSection: some View {
		Section {
			NavigationLink {
				AllAppsWrapperView(object: Array(_sources), viewModel: viewModel)
			} label: {
				AllAppsCardView(
					horizontalSizeClass: horizontalSizeClass,
					totalApps: _sources.reduce(0) { count, source in
						count + (viewModel.sources[source]?.apps.count ?? 0)
					}
				)
			}
			.buttonStyle(.plain)
		}
		.listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
		.listRowBackground(Color.clear)
	}
	
	private var repositoriesSection: some View {
		NBSection(
			.localized("Repositories"),
			secondary: _filteredSources.count.description
		) {
			ForEach(_filteredSources) { source in
				NavigationLink {
					SourceDetailsView(source: source, viewModel: viewModel)
				} label: {
					SourcesCellView(source: source)
				}
				.buttonStyle(.plain)
			}
		}
	}
	
	@ViewBuilder
	private var emptyStateView: some View {
		if _filteredSources.isEmpty {
			if #available(iOS 17, *) {
				ContentUnavailableView {
					ConditionalLabel(title: .localized("No Repositories"), systemImage: "globe.desk.fill")
				} description: {
					Text(.localized("Get started by adding your first repository."))
				} actions: {
					Button {
						_isAddingPresenting = true
					} label: {
						NBButton(.localized("Add Source"), style: .text)
					}
				}
			}
		}
	}
	
	@ToolbarContentBuilder
	private var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .topBarTrailing) {
			Button {
				_showCertificateTooltip = true
			} label: {
				Image(systemName: "sparkles")
					.font(.system(size: 17, weight: .medium))
					.foregroundStyle(.tint)
			}
		}
		
		ToolbarItem(placement: .topBarTrailing) {
			Button {
				_showEditSourcesView = true
			} label: {
				Image(systemName: "pencil")
					.font(.system(size: 17, weight: .medium))
					.foregroundStyle(.orange)
			}
		}
		
		ToolbarItem(placement: .topBarTrailing) {
			Button {
				_isAddingPresenting = true
			} label: {
				Image(systemName: "plus")
					.font(.system(size: 17, weight: .medium))
					.foregroundStyle(.green)
			}
			.disabled(_addingSourceLoading)
		}
	}
	
	private var addSourceSheet: some View {
		SourcesAddView()
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
	}
	
	private var filterSheet: some View {
		NavigationView {
			List {
				sortSection
				filterSection
				resetSection
			}
			.navigationTitle(.localized("Filter & Sort"))
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				NBToolbarButton(role: .close)
			}
		}
		.presentationDetents([.medium, .large])
		.presentationDragIndicator(.visible)
	}
	
	private var sortSection: some View {
		NBSection(.localized("Sort By")) {
			ForEach(SourcesView.SortOrder.allCases, id: \.self) { (order: SourcesView.SortOrder) in
				Button {
					_sortOrder = order
				} label: {
					HStack {
						Text(order.rawValue)
							.foregroundStyle(.primary)
						Spacer()
						if _sortOrder == order {
							Image(systemName: "checkmark")
								.foregroundStyle(.tint)
						}
					}
				}
			}
		}
	}
	
	private var filterSection: some View {
		NBSection(.localized("Filter")) {
			ForEach(SourcesView.FilterOption.allCases, id: \.self) { (option: SourcesView.FilterOption) in
				Button {
					_filterByPinned = option
				} label: {
					HStack {
						Text(option.rawValue)
							.foregroundStyle(.primary)
						Spacer()
						if _filterByPinned == option {
							Image(systemName: "checkmark")
								.foregroundStyle(.tint)
						}
					}
				}
			}
		}
	}
	
	private var resetSection: some View {
		NBSection("") {
			Button {
				_sortOrder = .custom
				_filterByPinned = .all
				_searchText = ""
			} label: {
				HStack {
					Spacer()
					Text(.localized("Reset All Filters"))
						.foregroundStyle(.red)
					Spacer()
				}
			}
		}
	}
	
	private var certificateTooltipView: some View {
		NavigationView {
			ScrollView {
				VStack(spacing: 24) {
					// Header with icon
					VStack(spacing: 16) {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 80, height: 80)
							
							Image(systemName: "checkmark.shield.fill")
								.font(.system(size: 40))
								.foregroundStyle(
									LinearGradient(
										gradient: Gradient(colors: [.blue, .purple]),
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
						}
						
						Text("Developer Certificates")
							.font(.title2.bold())
							.multilineTextAlignment(.center)
					}
					.padding(.top, 20)
					
					// Content sections
					VStack(alignment: .leading, spacing: 20) {
						// Section 1: Stability
						certificateSectionCard(
							icon: "checkmark.circle.fill",
							iconColor: .green,
							title: "Superior Stability",
							description: "Developer certificates offer significantly better stability and reliability than enterprise certificates. They are issued directly by Apple for app development and testing, which means apps signed with them are far less likely to be revoked or suddenly stop working."
						)
						
						// Section 2: Enterprise Issues
						certificateSectionCard(
							icon: "exclamationmark.triangle.fill",
							iconColor: .orange,
							title: "Enterprise Certificate Risks",
							description: "Enterprise certificates are meant only for internal company use and are frequently abused for public distribution. Apple actively revokes these certificates, causing apps to break without warning. This makes them unreliable for users who expect long term access."
						)
						
						// Section 3: Future-proof
						certificateSectionCard(
							icon: "star.fill",
							iconColor: .blue,
							title: "Future-Proof Choice",
							description: "Overall, developer certificates follow Apple's intended security model and work more consistently with iOS features. They are the safer, more future proof option for anyone who values stability and trust."
						)
					}
					.padding(.horizontal, 20)
					
					// Action button
					Button {
						_showCertificateTooltip = false
						_certificateTooltipDismissed = true
						UIApplication.open(Self.certificateURL)
					} label: {
						HStack {
							Image(systemName: "cart.fill")
							Text("Get Developer Certificate")
								.font(.headline)
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.background(
							LinearGradient(
								gradient: Gradient(colors: [.blue, .purple]),
								startPoint: .leading,
								endPoint: .trailing
							)
						)
						.foregroundStyle(.white)
						.cornerRadius(12)
					}
					.padding(.horizontal, 20)
					
					// Dismiss button
					Button {
						_showCertificateTooltip = false
						_certificateTooltipDismissed = true
					} label: {
						Text("Maybe Later")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
					.padding(.bottom, 20)
				}
			}
			.navigationTitle("Developer Certificates")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button {
						_showCertificateTooltip = false
						_certificateTooltipDismissed = true
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.system(size: 20))
							.foregroundStyle(.secondary)
					}
				}
			}
		}
		.presentationDetents([.large])
		.presentationDragIndicator(.visible)
	}
	
	@ViewBuilder
	private func certificateSectionCard(icon: String, iconColor: Color, title: String, description: String) -> some View {
		HStack(alignment: .top, spacing: 12) {
			Image(systemName: icon)
				.font(.system(size: 24))
				.foregroundStyle(iconColor)
				.frame(width: 40, height: 40)
			
			VStack(alignment: .leading, spacing: 6) {
				Text(title)
					.font(.headline)
					.foregroundStyle(.primary)
				
				Text(description)
					.font(.subheadline)
					.foregroundStyle(.secondary)
					.fixedSize(horizontal: false, vertical: true)
			}
		}
		.padding(16)
		.background(Color(uiColor: .secondarySystemGroupedBackground))
		.cornerRadius(12)
	}
	
	#if !NIGHTLY && !DEBUG
	private func showStarPromptIfNeeded() {
		guard _shouldStar < 6 else { return }
		_shouldStar += 1
		guard _shouldStar == 6 else { return }
		
		let github = UIAlertAction(title: "GitHub", style: .default) { _ in
			UIApplication.open("https://github.com/aoyn1xw/Feather")
		}
		
		let cancel = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
		
		UIAlertController.showAlert(
			title: .localized("Enjoying %@?", arguments: Bundle.main.name),
			message: .localized("Go to our GitHub and give us a star!"),
			actions: [github, cancel]
		)
	}
	#endif
}

// MARK: - AllAppsCardView
private struct AllAppsCardView: View {
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	
	let horizontalSizeClass: UserInterfaceSizeClass?
	let totalApps: Int
	
	// Get app icon for the gradient - use the system's app icon
	@State private var appIconColor: Color = .accentColor
	
	var body: some View {
		let isRegular = horizontalSizeClass != .compact
		
		VStack(spacing: 0) {
			// Content only - no gradient banner
			contentSection(isRegular: isRegular)
		}
		.background(cardBackground)
		.overlay(cardStroke)
		.shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
		.shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
		.onAppear {
			extractAppIconColor()
		}
	}
	
	// Extract color from app icon
	private func extractAppIconColor() {
		guard let iconName = Bundle.main.iconFileName,
			  let appIcon = UIImage(named: iconName) else {
			appIconColor = .accentColor
			return
		}
		
		guard let inputImage = CIImage(image: appIcon) else {
			appIconColor = .accentColor
			return
		}
		
		let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
		
		guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else {
			appIconColor = .accentColor
			return
		}
		guard let outputImage = filter.outputImage else {
			appIconColor = .accentColor
			return
		}
		
		var bitmap = [UInt8](repeating: 0, count: 4)
		// Use a shared context for better performance
		let context = Self.sharedCIContext
		context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
		
		appIconColor = Color(red: Double(bitmap[0]) / 255, green: Double(bitmap[1]) / 255, blue: Double(bitmap[2]) / 255)
	}
	
	// Shared CIContext for performance
	private static let sharedCIContext = CIContext(options: [.workingColorSpace: kCFNull as Any])
	
	private func contentSection(isRegular: Bool) -> some View {
		HStack(spacing: 12) {
			iconView
			
			textContent
			
			Spacer()
		}
		.padding(.horizontal, isRegular ? 12 : 10)
		.padding(.vertical, isRegular ? 10 : 8)
	}
	
	private var iconView: some View {
		ZStack {
			Circle()
				.fill(
					LinearGradient(
						colors: [
							appIconColor.opacity(0.15),
							appIconColor.opacity(0.08)
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
				.frame(width: 44, height: 44)
				.shadow(color: appIconColor.opacity(0.2), radius: 4, x: 0, y: 2)
			
			Image(systemName: "app.badge.fill")
				.font(.system(size: 20, weight: .semibold))
				.foregroundStyle(
					LinearGradient(
						colors: [appIconColor, appIconColor.opacity(0.8)],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
				)
		}
	}
	
	private var textContent: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(.localized("All Apps"))
				.font(.system(size: 16, weight: .bold))
				.foregroundStyle(.primary)
			Text(.localized("Browse your complete app collection"))
				.font(.caption)
				.foregroundStyle(.secondary)
				.lineLimit(1)
			
			appsBadge
		}
	}
	
	private var appsBadge: some View {
		HStack(spacing: 4) {
			Image(systemName: "square.stack.3d.up.fill")
				.font(.system(size: 9))
			Text("\(totalApps) \(totalApps == 1 ? "App" : "Apps")")
				.font(.system(size: 10, weight: .bold))
		}
		.foregroundStyle(.white)
		.padding(.horizontal, 8)
		.padding(.vertical, 3.5)
		.background(
			Capsule()
				.fill(
					LinearGradient(
						colors: [appIconColor, appIconColor.opacity(0.85)],
						startPoint: .leading,
						endPoint: .trailing
					)
				)
		)
		.shadow(color: appIconColor.opacity(0.3), radius: 3, x: 0, y: 1.5)
	}
	
	private var cardBackground: some View {
		RoundedRectangle(cornerRadius: 14, style: .continuous)
			.fill(Color(uiColor: .secondarySystemGroupedBackground))
	}
	
	private var cardStroke: some View {
		RoundedRectangle(cornerRadius: 14, style: .continuous)
			.stroke(Color.primary.opacity(0.1), lineWidth: 1)
	}
}
