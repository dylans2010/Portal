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
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.2),
                    dominantColor.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    sourceHeaderCard
                    if _showNews, let news = repository?.news, !news.isEmpty {
                        featuredNewsSection(news: filteredNews.isEmpty && !_searchText.isEmpty ? [] : (filteredNews.isEmpty ? news : filteredNews))
                    }

                    if let apps = repository?.apps, !apps.isEmpty {
                        appsVerticalFeed(apps: filteredApps.isEmpty && !_searchText.isEmpty ? [] : filteredApps)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle(source.name ?? "Source")
        .navigationBarTitleDisplayMode(.inline)
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
    
    // MARK: - Source Header Card (Modern - Icon at top, info below)
    private var sourceHeaderCard: some View {
        VStack(spacing: 24) {
            if let iconURL = source.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .shadow(color: dominantColor.opacity(0.3), radius: 20, x: 0, y: 10)
                    } else {
                        iconPlaceholder
                    }
                }
            } else {
                iconPlaceholder
            }
            
            VStack(spacing: 6) {
                Text(source.name ?? String.localized("Unknown"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if let url = source.sourceURL?.host {
                    Text(url)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            if let repo = repository {
                HStack(spacing: 32) {
                    statItem(value: "\(repo.apps.count)", label: "Apps")
                    
                    if let news = repo.news, !news.isEmpty {
                        Divider().frame(height: 24)
                        statItem(value: "\(news.count)", label: "News")
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 0.5))
    }

    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(dominantColor.gradient)
            .frame(width: 100, height: 100)
            .overlay(
                Image(systemName: "globe")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: dominantColor.opacity(0.3), radius: 20, x: 0, y: 10)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
        }
    }
    
    @ViewBuilder
    private func featuredNewsSection(news: [ASRepository.News]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Latest News")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let fullNews = repository?.news, fullNews.count > 3 {
                    NavigationLink {
                        SourceNewsListView(news: fullNews, dominantColor: dominantColor)
                    } label: {
                        Text("View All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(dominantColor)
                    }
                }
            }
            
            if news.isEmpty {
                Text("No news are currently available, check back later.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Featured News Card
    private func featuredNewsCard(_ newsItem: ASRepository.News) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            if let imageURL = newsItem.imageURL {
                LazyImage(url: imageURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(dominantColor.opacity(0.1))
                    }
                }
                .frame(width: 240, height: 140)
                .clipped()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(newsItem.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(newsItem.caption)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(14)
        }
        .frame(width: 240)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 0.5))
    }
    
    // MARK: - Apps Vertical Feed
    @ViewBuilder
    private func appsVerticalFeed(apps: [ASRepository.App]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Apps")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let fullApps = repository?.apps, fullApps.count > 10 {
                    NavigationLink {
                        if let repo = repository {
                            SourceAppsListView(repository: repo, dominantColor: dominantColor)
                        }
                    } label: {
                        Text("View All")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(dominantColor)
                    }
                }
            }
            
            if apps.isEmpty {
                emptyAppsState
            } else {
                let recentApps = apps.sorted { ($0.currentDate?.date ?? .distantPast) > ($1.currentDate?.date ?? .distantPast) }.prefix(10)
                
                VStack(spacing: 0) {
                    ForEach(Array(recentApps), id: \.id) { app in
                        Button {
                            if let repo = repository {
                                _selectedRoute = SourceAppRoute(source: repo, app: app)
                            }
                        } label: {
                            appFeedCard(app)
                        }
                        .buttonStyle(.plain)

                        if app.id != recentApps.last?.id {
                            Divider().padding(.leading, 80)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.primary.opacity(0.05), lineWidth: 0.5))
            }
        }
    }
    
    // MARK: - App Feed Card
    private func appFeedCard(_ app: ASRepository.App) -> some View {
        HStack(spacing: 16) {
            // App icon
            Group {
                if let iconURL = app.iconURL {
                    LazyImage(url: iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            appIconPlaceholder
                        }
                    }
                } else {
                    appIconPlaceholder
                }
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? "Unknown")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let version = app.currentVersion {
                        Text("v\(version)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(dominantColor)
                    }

                    if let subtitle = app.subtitle {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .contentShape(Rectangle())
    }

    private var appIconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(dominantColor.opacity(0.1))
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(dominantColor.opacity(0.5))
            )
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
                                Text("\(filteredApps.count) Result\(filteredApps.count == 1 ? "" : "s")")
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
                                    Text("There is nothing to see here. Try a different search term.")
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
                                .fill(Color.clear)
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
                            .transition(AnyTransition.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 8)
                    .background(Color.clear)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: searchFieldFocused)
            }
        }
        .background(Color.clear)
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
