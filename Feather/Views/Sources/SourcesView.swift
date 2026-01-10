import CoreData
import AltSourceKit
import SwiftUI
import NimbleViews
import NukeUI

// MARK: - Modern Sources View with Blue Gradient Background
struct SourcesView: View {
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
        var filtered = _sources.filter { 
            _searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(_searchText) ?? false) 
        }
        
        switch _filterByPinned {
        case .pinned:
            filtered = filtered.filter { viewModel.isPinned($0) }
        case .unpinned:
            filtered = filtered.filter { !viewModel.isPinned($0) }
        case .all:
            break
        }
        
        return filtered.sorted { s1, s2 in
            switch _sortOrder {
            case .custom:
                return s1.order < s2.order
            case .alphabetical:
                let p1 = viewModel.isPinned(s1)
                let p2 = viewModel.isPinned(s2)
                if p1 && !p2 { return true }
                if !p1 && p2 { return false }
                return (s1.name ?? "") < (s2.name ?? "")
            case .recentlyAdded:
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Simple background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Custom top navigation area
                        customNavigationBar
                        
                        // Main content
                        VStack(spacing: 20) {
                            if !_filteredSources.isEmpty {
                                // All Apps Card
                                allAppsCard
                                
                                // Source Cards
                                sourcesCardsSection
                            } else {
                                emptyStateView
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                .refreshable {
                    await viewModel.fetchSources(_sources, refresh: true)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $_isAddingPresenting) {
                SourcesAddView()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Text("Manage your sources")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                // Sparkles button
                Button {
                    _showCertificateTooltip = true
                } label: {
                    navBarButton(systemImage: "sparkles", color: .cyan)
                }
                
                // Edit button
                Button {
                    _showEditSourcesView = true
                } label: {
                    navBarButton(systemImage: "pencil", color: .orange)
                }
                
                // Add button
                Button {
                    _isAddingPresenting = true
                } label: {
                    navBarButton(systemImage: "plus", color: .green)
                }
                .disabled(_addingSourceLoading)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }
    
    private func navBarButton(systemImage: String, color: Color) -> some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 36, height: 36)
            
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
        }
    }
    
    // MARK: - All Apps Card
    private var allAppsCard: some View {
        NavigationLink {
            AllAppsWrapperView(object: Array(_sources), viewModel: viewModel)
        } label: {
            ModernSourceCard(
                title: String.localized("All Apps"),
                subtitle: "\(_sources.reduce(0) { $0 + (viewModel.sources[$1]?.apps.count ?? 0) }) apps available",
                iconSystemName: "app.badge.fill",
                isPinned: false,
                accentColor: .cyan
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Sources Cards Section
    private var sourcesCardsSection: some View {
        VStack(spacing: 16) {
            ForEach(_filteredSources) { source in
                NavigationLink {
                    SourceDetailsView(source: source, viewModel: viewModel)
                } label: {
                    ModernSourceCardWithIcon(
                        source: source,
                        viewModel: viewModel
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Empty State
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)
            
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.12))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "globe.desk.fill")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(.cyan)
            }
            
            VStack(spacing: 12) {
                Text(String.localized("No Repositories"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(String.localized("Get started by adding your first repository."))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                _isAddingPresenting = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text(String.localized("Add Source"))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(.cyan)
                )
                .shadow(color: .cyan.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            Spacer(minLength: 60)
        }
    }
    
    // MARK: - Certificate Tooltip View
    private var certificateTooltipView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                        }
                        
                        Text("Developer Certificates")
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        certificateSectionCard(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            title: "Superior Stability",
                            description: "Developer certificates offer significantly better stability and reliability than enterprise certificates."
                        )
                        
                        certificateSectionCard(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange,
                            title: "Enterprise Certificate Risks",
                            description: "Enterprise certificates are frequently abused and Apple actively revokes them."
                        )
                        
                        certificateSectionCard(
                            icon: "star.fill",
                            iconColor: .blue,
                            title: "Future-Proof Choice",
                            description: "Developer certificates follow Apple's intended security model."
                        )
                    }
                    .padding(.horizontal, 20)
                    
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
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    
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
            UIApplication.open("https://github.com/aoyn1xw/Portal")
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

// MARK: - Modern Source Card (Generic)
struct ModernSourceCard: View {
    let title: String
    let subtitle: String
    let iconSystemName: String
    let isPinned: Bool
    var accentColor: Color = .cyan
    
    var body: some View {
        HStack(spacing: 16) {
            // Floating icon container with glow
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                
                Image(systemName: iconSystemName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.2))
                    )
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Source Card with Icon from URL
struct ModernSourceCardWithIcon: View {
    let source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    @State private var dominantColor: Color = .cyan
    
    private var isPinned: Bool {
        viewModel.isPinned(source)
    }
    
    private var appCount: Int {
        viewModel.sources[source]?.apps.count ?? 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Floating icon container with glow
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(dominantColor.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)
                
                if let iconURL = source.iconURL {
                    LazyImage(url: iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onAppear {
                                    if let uiImage = state.imageContainer?.image {
                                        extractDominantColor(from: uiImage)
                                    }
                                }
                        } else {
                            Image(systemName: "globe")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(source.name ?? String.localized("Unknown"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 10))
                    Text("\(appCount) \(appCount == 1 ? "app" : "apps")")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
            
            if isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(dominantColor)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(dominantColor.opacity(0.2))
                    )
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .contextMenu {
            Button {
                viewModel.togglePin(for: source)
            } label: {
                Label(isPinned ? "Unpin" : "Pin", systemImage: isPinned ? "pin.slash" : "pin")
            }
            
            Button {
                UIPasteboard.general.string = source.sourceURL?.absoluteString
            } label: {
                Label(String.localized("Copy"), systemImage: "doc.on.clipboard")
            }
            
            Divider()
            
            Button(role: .destructive) {
                Storage.shared.deleteSource(for: source)
            } label: {
                Label(String.localized("Delete"), systemImage: "trash")
            }
        }
    }
    
    private func extractDominantColor(from image: UIImage) {
        guard let inputImage = CIImage(image: image) else { return }
        let extentVector = CIVector(x: inputImage.extent.origin.x, y: inputImage.extent.origin.y, z: inputImage.extent.size.width, w: inputImage.extent.size.height)
        
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]) else { return }
        guard let outputImage = filter.outputImage else { return }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        dominantColor = Color(red: Double(bitmap[0]) / 255, green: Double(bitmap[1]) / 255, blue: Double(bitmap[2]) / 255)
    }
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
				.fill(appIconColor.opacity(0.12))
				.frame(width: 44, height: 44)
			
			Image(systemName: "app.badge.fill")
				.font(.system(size: 20, weight: .semibold))
				.foregroundStyle(appIconColor)
		}
	}
	
	private var textContent: some View {
		VStack(alignment: .leading, spacing: 4) {
			Text(.localized("All Apps"))
				.font(.system(size: 16, weight: .bold))
				.foregroundStyle(.primary)
			Text(.localized("See all yor apps in one page"))
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
				.fill(appIconColor)
		)
		.shadow(color: appIconColor.opacity(0.2), radius: 2, x: 0, y: 1)
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
