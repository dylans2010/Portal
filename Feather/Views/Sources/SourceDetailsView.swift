import SwiftUI
import AltSourceKit
import NimbleViews
import NukeUI

// MARK: - Modern Source Details View with Blue Gradient Background
struct SourceDetailsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("Feather.showNews") private var _showNews: Bool = true
    @State private var dominantColor: Color = .cyan
    @State private var _searchText = ""
    @State private var _selectedNewsPresenting: ASRepository.News?
    @State private var _selectedRoute: SourceAppRoute?
    
    var source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    @State private var repository: ASRepository?
    
    private var filteredApps: [ASRepository.App] {
        guard let repo = repository else { return [] }
        let apps = repo.apps
        if _searchText.isEmpty {
            return apps
        }
        return apps.filter { app in
            (app.name?.localizedCaseInsensitiveContains(_searchText) ?? false) ||
            (app.localizedDescription?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    private var filteredNews: [ASRepository.News] {
        guard let repo = repository, let news = repo.news else { return [] }
        if _searchText.isEmpty {
            return news
        }
        return news.filter { newsItem in
            newsItem.title.localizedCaseInsensitiveContains(_searchText) ||
            newsItem.caption.localizedCaseInsensitiveContains(_searchText)
        }
    }
    
    var body: some View {
        ZStack {
            // Gradient background based on source icon color - increased intensity
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.25),
                    dominantColor.opacity(0.12),
                    Color(.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Custom navigation area
                    customNavigationBar
                    
                    VStack(spacing: 24) {
                        // Prominent source header card
                        sourceHeaderCard
                        
                        // Featured horizontal card section
                        if _showNews, let news = repository?.news, !news.isEmpty {
                            featuredNewsSection(news: filteredNews.isEmpty && !_searchText.isEmpty ? [] : (filteredNews.isEmpty ? news : filteredNews))
                        }
                        
                        // Vertical feed of app cards
                        if let apps = repository?.apps, !apps.isEmpty {
                            appsVerticalFeed(apps: filteredApps.isEmpty && !_searchText.isEmpty ? [] : filteredApps)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if let repo = viewModel.sources[source] {
                repository = repo
            }
            if let iconURL = source.iconURL {
                extractDominantColor(from: iconURL)
            }
        }
        .fullScreenCover(item: $_selectedNewsPresenting) { news in
            SourceNewsCardInfoView(new: news)
        }
        .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        HStack(spacing: 16) {
            // Circular back button
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                }
            }
            
            Spacer()
            
            // Placeholder for symmetry
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Source Header Card (Modern - Icon at top, info below)
    private var sourceHeaderCard: some View {
        VStack(spacing: 20) {
            // Large centered icon
            ZStack {
                Circle()
                    .fill(dominantColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                if let iconURL = source.iconURL {
                    LazyImage(url: iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 88, height: 88)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .shadow(color: dominantColor.opacity(0.3), radius: 16, x: 0, y: 8)
                        } else {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(dominantColor.opacity(0.2))
                                .frame(width: 88, height: 88)
                                .overlay(
                                    Image(systemName: "globe")
                                        .font(.system(size: 36, weight: .semibold))
                                        .foregroundStyle(dominantColor)
                                )
                        }
                    }
                } else {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(dominantColor.opacity(0.2))
                        .frame(width: 88, height: 88)
                        .overlay(
                            Image(systemName: "globe")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(dominantColor)
                        )
                }
            }
            
            // Source info below icon
            VStack(spacing: 8) {
                Text(source.name ?? String.localized("Unknown"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                if let url = source.sourceURL?.host {
                    Text(url)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Stats row
            if let repo = repository {
                HStack(spacing: 24) {
                    // Apps count
                    VStack(spacing: 4) {
                        Text("\(repo.apps.count)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        Text("Apps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Divider
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 1, height: 36)
                    
                    // News count
                    if let news = repo.news, !news.isEmpty {
                        VStack(spacing: 4) {
                            Text("\(news.count)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("News")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Featured News Section (Horizontal Cards)
    @ViewBuilder
    private func featuredNewsSection(news: [ASRepository.News]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Source News")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if let fullNews = repository?.news, fullNews.count > 3 {
                    NavigationLink {
                        SourceNewsListView(news: fullNews, dominantColor: dominantColor)
                    } label: {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(dominantColor)
                    }
                }
            }
            
            if news.isEmpty {
                Text("No News Found")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(news.prefix(5)), id: \.id) { newsItem in
                            Button {
                                _selectedNewsPresenting = newsItem
                            } label: {
                                featuredNewsCard(newsItem)
                            }
                        }
                    }
                }
                .padding(.horizontal, -20)
                .padding(.leading, 20)
            }
        }
    }
    
    // MARK: - Featured News Card (Compact with depth and glow)
    private func featuredNewsCard(_ newsItem: ASRepository.News) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            ZStack {
                if let imageURL = newsItem.imageURL {
                    LazyImage(url: imageURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Rectangle()
                                .fill(dominantColor.opacity(0.3))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(dominantColor.opacity(0.12))
                        .overlay(
                            Image(systemName: "newspaper.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(dominantColor.opacity(0.5))
                        )
                }
            }
            .frame(width: 220, height: 130)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(newsItem.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(newsItem.caption)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(width: 220, alignment: .leading)
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Apps Vertical Feed
    @ViewBuilder
    private func appsVerticalFeed(apps: [ASRepository.App]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Apps")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if let fullApps = repository?.apps, fullApps.count > 10 {
                    NavigationLink {
                        if let repo = repository {
                            SourceAppsListView(repository: repo, dominantColor: dominantColor)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("See All")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(dominantColor)
                    }
                }
            }
            
            if apps.isEmpty {
                emptyAppsState
            } else {
                // Get the 10 most recently updated apps
                let recentApps = apps.sorted { app1, app2 in
                    let date1 = app1.currentDate?.date ?? .distantPast
                    let date2 = app2.currentDate?.date ?? .distantPast
                    return date1 > date2
                }.prefix(10)
                
                VStack(spacing: 14) {
                    ForEach(Array(recentApps), id: \.id) { app in
                        Button {
                            if let repo = repository {
                                _selectedRoute = SourceAppRoute(source: repo, app: app)
                            }
                        } label: {
                            appFeedCard(app)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - App Feed Card (Clean, no background)
    private func appFeedCard(_ app: ASRepository.App) -> some View {
        HStack(spacing: 14) {
            // App icon
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 52, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(dominantColor.opacity(0.15))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "app.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(dominantColor.opacity(0.5))
                            )
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(dominantColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(dominantColor.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? "Unknown")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let subtitle = app.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if let version = app.currentVersion {
                    Text("v\(version)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(dominantColor)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(18)
        .contentShape(Rectangle())
    }
    
    // MARK: - Empty Apps State
    private var emptyAppsState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(dominantColor.opacity(0.12))
                    .frame(width: 70, height: 70)
                
                Image(systemName: "app.badge.questionmark")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(dominantColor)
            }
            
            VStack(spacing: 8) {
                Text("No Apps Found")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(_searchText.isEmpty ? "This source doesn't have any apps yet." : "Try adjusting your search terms.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Color Extraction
    private func extractDominantColor(from url: URL) {
        Task {
            guard let data = try? Data(contentsOf: url),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else { return }
            
            let ciImage = CIImage(cgImage: cgImage)
            let filter = CIFilter(name: "CIAreaAverage")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
            
            guard let outputImage = filter?.outputImage else { return }
            
            var pixel = [UInt8](repeating: 0, count: 4)
            CIContext().render(
                outputImage,
                toBitmap: &pixel,
                rowBytes: 4,
                bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                format: .RGBA8,
                colorSpace: nil
            )
            
            let r = Double(pixel[0]) / 255.0
            let g = Double(pixel[1]) / 255.0
            let b = Double(pixel[2]) / 255.0
            
            await MainActor.run {
                dominantColor = Color(red: r, green: g, blue: b)
            }
        }
    }
    
    struct SourceAppRoute: Identifiable, Hashable {
        let source: ASRepository
        let app: ASRepository.App
        let id: String = UUID().uuidString
    }
}

// MARK: - News List View
struct SourceNewsListView: View {
	let news: [ASRepository.News]
	let dominantColor: Color
	@State private var _selectedNewsPresenting: ASRepository.News?
	
	var body: some View {
		NBList("News") {
			ForEach(news, id: \.id) { newsItem in
				Button {
					_selectedNewsPresenting = newsItem
				} label: {
					HStack(spacing: 12) {
						if let imageURL = newsItem.imageURL {
							LazyImage(url: imageURL) { state in
								if let image = state.image {
									image
										.resizable()
										.aspectRatio(contentMode: .fill)
								} else {
									Rectangle()
										.fill(Color.gray.opacity(0.2))
								}
							}
							.frame(width: 60, height: 60)
							.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
						}
						
						VStack(alignment: .leading, spacing: 4) {
							Text(newsItem.title)
								.font(.headline)
								.foregroundStyle(.primary)
							
							Text(newsItem.caption)
								.font(.caption)
								.foregroundStyle(.secondary)
								.lineLimit(2)
						}
						
						Spacer()
						
						Image(systemName: "chevron.right")
							.font(.caption)
							.foregroundStyle(.tertiary)
					}
				}
				.buttonStyle(.plain)
			}
		}
		.fullScreenCover(item: $_selectedNewsPresenting) { news in
			SourceNewsCardInfoView(new: news)
		}
	}
}

// MARK: - Apps List View (iOS 26 Style with Bottom Search)
struct SourceAppsListView: View {
    let repository: ASRepository
    let dominantColor: Color
    @State private var _selectedRoute: SourceAppRoute?
    @State private var searchText: String = ""
    @State private var isSearchFocused: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @FocusState private var searchFieldFocused: Bool
    
    private var filteredApps: [ASRepository.App] {
        if searchText.isEmpty {
            return repository.apps
        }
        return repository.apps.filter { app in
            (app.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (app.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (app.developer?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main content
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Header with app count
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(repository.apps.count)")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)
                                Text("Apps Available")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                        
                        // Results count when searching
                        if !searchText.isEmpty {
                            HStack {
                                Text("\(filteredApps.count) result\(filteredApps.count == 1 ? "" : "s")")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        }
                        
                        // Apps list
                        if filteredApps.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundStyle(.tertiary)
                                }
                                VStack(spacing: 6) {
                                    Text("No Results")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(.primary)
                                    Text("There is nothing here. Try a different search term.")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 80)
                        } else {
                            ForEach(filteredApps, id: \.id) { app in
                                Button {
                                    _selectedRoute = SourceAppRoute(source: repository, app: app)
                                } label: {
                                    ModernAppListRow(app: app, dominantColor: dominantColor)
                                }
                                .buttonStyle(.plain)
                                
                                if app.id != filteredApps.last?.id {
                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                        
                        // Bottom padding for search bar
                        Color.clear.frame(height: 100)
                    }
                }
                
                // iOS 26 Style Bottom Search Bar
                VStack(spacing: 0) {
                    // Blur effect divider
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .frame(height: 1)
                    
                    // Search bar container
                    HStack(spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                            
                            TextField("Search \(repository.apps.count) Apps", text: $searchText)
                                .font(.system(size: 16))
                                .focused($searchFieldFocused)
                            
                            if !searchText.isEmpty {
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        searchText = ""
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                        
                        if searchFieldFocused {
                            Button("Cancel") {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    searchText = ""
                                    searchFieldFocused = false
                                }
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.accentColor)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 8)
                    .background(.ultraThinMaterial)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: searchFieldFocused)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("All Apps")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    struct SourceAppRoute: Identifiable, Hashable {
        let source: ASRepository
        let app: ASRepository.App
        let id: String = UUID().uuidString
    }
}

// MARK: - Modern App List Row
struct ModernAppListRow: View {
    let app: ASRepository.App
    let dominantColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // App icon
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(dominantColor.opacity(0.1))
                            .overlay(
                                Image(systemName: "app.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(dominantColor.opacity(0.5))
                            )
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(dominantColor.opacity(0.1))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(dominantColor.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? "Unknown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let subtitle = app.subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                if let version = app.currentVersion {
                    Text("v\(version)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.quaternary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
