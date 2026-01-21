import SwiftUI
import AltSourceKit
import NimbleViews
import UIKit

// MARK: - Sort Options
extension SourceAppsView {
    enum SortOption: String, CaseIterable {
        case `default` = "default"
        case name
        case date
        case size
        
        var displayName: String {
            switch self {
            case .default: return .localized("Default")
            case .name: return .localized("Name")
            case .date: return .localized("Date")
            case .size: return .localized("Size")
            }
        }
        
        var icon: String {
            switch self {
            case .default: return "list.bullet"
            case .name: return "textformat"
            case .date: return "calendar"
            case .size: return "internaldrive"
            }
        }
    }
    
    enum ViewStyle: String, CaseIterable {
        case list
        case grid
        case compact
        
        var displayName: String {
            switch self {
            case .list: return .localized("List")
            case .grid: return .localized("Grid")
            case .compact: return .localized("Compact")
            }
        }
        
        var icon: String {
            switch self {
            case .list: return "list.bullet"
            case .grid: return "square.grid.2x2"
            case .compact: return "rectangle.grid.1x2"
            }
        }
    }
}

// MARK: - SourceAppsView
struct SourceAppsView: View {
    @AppStorage("Feather.sortOptionRawValue") private var sortOptionRawValue: String = SortOption.default.rawValue
    @AppStorage("Feather.sortAscending") private var sortAscending: Bool = true
    @AppStorage("Feather.appsViewStyle") private var viewStyleRawValue: String = ViewStyle.list.rawValue
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var sortOption: SortOption = .default
    @State private var viewStyle: ViewStyle = .list
    @State private var selectedRoute: SourceAppRoute?
    @State private var isLoading = true
    @State private var hasLoadedOnce = false
    @State private var searchText = ""
    @State private var sources: [ASRepository]?
    
    var object: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    
    private var navigationTitle: String {
        if object.count == 1 {
            return object[0].name ?? .localized("Unknown")
        } else {
            return .localized("%lld Sources", arguments: object.count)
        }
    }
    
    private var allAppsWithSource: [(source: ASRepository, app: ASRepository.App)] {
        guard let sources = sources else { return [] }
        return sources.flatMap { source in
            source.apps.map { (source: source, app: $0) }
        }
    }
    
    private var filteredApps: [(source: ASRepository, app: ASRepository.App)] {
        let filtered = allAppsWithSource.filter { entry in
            searchText.isEmpty ||
            (entry.app.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (entry.app.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (entry.app.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (entry.app.localizedDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (entry.app.developer?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        return sortApps(filtered)
    }
    
    private func sortApps(_ apps: [(source: ASRepository, app: ASRepository.App)]) -> [(source: ASRepository, app: ASRepository.App)] {
        switch sortOption {
        case .default:
            return sortAscending ? apps : apps.reversed()
        case .date:
            return apps.sorted {
                let d1 = $0.app.currentDate?.date ?? .distantPast
                let d2 = $1.app.currentDate?.date ?? .distantPast
                return sortAscending ? (d1 < d2) : (d1 > d2)
            }
        case .name:
            return apps.sorted {
                let n1 = $0.app.name ?? ""
                let n2 = $1.app.name ?? ""
                let comparison = n1.localizedCaseInsensitiveCompare(n2) == .orderedAscending
                return sortAscending ? comparison : !comparison
            }
        case .size:
            return apps.sorted {
                let s1 = $0.app.size ?? 0
                let s2 = $1.app.size ?? 0
                return sortAscending ? (s1 < s2) : (s1 > s2)
            }
        }
    }
    
    private var totalAppCount: Int {
        allAppsWithSource.count
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            backgroundGradient
            
            if let sources = sources, !sources.isEmpty {
                contentView
            } else {
                loadingView
            }
        }
        .navigationTitle(navigationTitle)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: totalAppCount > 0 ? Text("Search \(totalAppCount) Apps") : Text("Search Apps")
        )
        .toolbarTitleMenu { titleMenuContent }
        .toolbar { toolbarContent }
        .onAppear(perform: handleOnAppear)
        .onChange(of: viewModel.isFinished) { _ in loadSources() }
        .onChange(of: sortOption) { sortOptionRawValue = $0.rawValue }
        .onChange(of: viewStyle) { viewStyleRawValue = $0.rawValue }
        .navigationDestinationIfAvailable(item: $selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
    }
    
    // MARK: - Background
    @ViewBuilder
    private var backgroundGradient: some View {
        // Use a single solid color that matches the navigation bar area
        // to ensure seamless appearance from top to content
        Color(UIColor.systemBackground)
            .ignoresSafeArea()
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(.localized("Loading Apps"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            switch viewStyle {
            case .list:
                listLayout
            case .grid:
                gridLayout
            case .compact:
                compactLayout
            }
        }
        .refreshable {
            await refreshSources()
        }
    }
    
    // MARK: - List Layout
    @ViewBuilder
    private var listLayout: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredApps, id: \.app.currentUniqueId) { entry in
                Button {
                    HapticsManager.shared.softImpact()
                    selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
                } label: {
                    ModernAppListCard(app: entry.app, source: entry.source)
                }
                .buttonStyle(ModernCardButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Grid Layout
    @ViewBuilder
    private var gridLayout: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(filteredApps, id: \.app.currentUniqueId) { entry in
                Button {
                    HapticsManager.shared.softImpact()
                    selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
                } label: {
                    ModernAppGridCard(app: entry.app, source: entry.source)
                }
                .buttonStyle(ModernCardButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Compact Layout
    @ViewBuilder
    private var compactLayout: some View {
        LazyVStack(spacing: 1) {
            ForEach(filteredApps, id: \.app.currentUniqueId) { entry in
                Button {
                    HapticsManager.shared.softImpact()
                    selectedRoute = SourceAppRoute(source: entry.source, app: entry.app)
                } label: {
                    ModernAppCompactRow(app: entry.app, source: entry.source)
                }
                .buttonStyle(.plain)
                
                if entry.app.currentUniqueId != filteredApps.last?.app.currentUniqueId {
                    Divider()
                        .padding(.leading, 68)
                }
            }
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Title Menu
    @ViewBuilder
    private var titleMenuContent: some View {
        if let sources = sources, sources.count == 1 {
            if let url = sources[0].website {
                Button(.localized("Visit Website"), systemImage: "globe") {
                    UIApplication.open(url)
                }
            }
            
            if let url = sources[0].patreonURL {
                Button(.localized("Visit Patreon"), systemImage: "dollarsign.circle") {
                    UIApplication.open(url)
                }
            }
        }
        
        Divider()
        
        Button(.localized("Copy Source URL"), systemImage: "doc.on.doc") {
            guard !object.isEmpty else {
                UIAlertController.showAlertWithOk(
                    title: .localized("Error"),
                    message: .localized("No Sources To Copy")
                )
                return
            }
            UIPasteboard.general.string = object.map {
                $0.sourceURL!.absoluteString
            }.joined(separator: "\n")
            HapticsManager.shared.success()
            UIAlertController.showAlertWithOk(
                title: .localized("Success"),
                message: .localized("Sources Copied To Clipboard")
            )
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                // View Style Section
                Section(.localized("View Style")) {
                    ForEach(ViewStyle.allCases, id: \.rawValue) { style in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewStyle = style
                            }
                            HapticsManager.shared.softImpact()
                        } label: {
                            Label(style.displayName, systemImage: viewStyle == style ? "checkmark" : style.icon)
                        }
                    }
                }
                
                Divider()
                
                // Sort Section
                Section(.localized("Sort By")) {
                    ForEach(SortOption.allCases, id: \.rawValue) { option in
                        Button {
                            if sortOption == option {
                                sortAscending.toggle()
                            } else {
                                sortOption = option
                                sortAscending = true
                            }
                            HapticsManager.shared.softImpact()
                        } label: {
                            HStack {
                                Label(option.displayName, systemImage: option.icon)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 17))
            }
        }
    }
    
    // MARK: - Actions
    private func handleOnAppear() {
        if !hasLoadedOnce, viewModel.isFinished {
            loadSources()
            hasLoadedOnce = true
        }
        sortOption = SortOption(rawValue: sortOptionRawValue) ?? .default
        viewStyle = ViewStyle(rawValue: viewStyleRawValue) ?? .list
    }
    
    private func loadSources() {
        isLoading = true
        Task {
            let loadedSources = object.compactMap { viewModel.sources[$0] }
            sources = loadedSources
            withAnimation(.easeIn(duration: 0.2)) {
                isLoading = false
            }
        }
    }
    
    private func refreshSources() async {
        // Simply reload the sources from the view model
        loadSources()
    }
    
    struct SourceAppRoute: Identifiable, Hashable {
        let source: ASRepository
        let app: ASRepository.App
        let id: String = UUID().uuidString
    }
}

// MARK: - Modern App List Card
struct ModernAppListCard: View {
    let app: ASRepository.App
    let source: ASRepository
    @State private var dominantColor: Color = .accentColor
    
    var body: some View {
        HStack(spacing: 14) {
            // App Icon
            appIcon
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text(app.currentName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let subtitle = app.subtitle ?? app.developer {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    if let version = app.currentVersion {
                        Label(version, systemImage: "tag")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    
                    if let size = app.size {
                        Label(size.formattedByteCount, systemImage: "internaldrive")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer(minLength: 8)
            
            // Get Button
            getButton
        }
        .padding(14)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(dominantColor.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            if let iconURL = app.iconURL {
                extractDominantColor(from: iconURL)
            }
        }
    }
    
    @ViewBuilder
    private var appIcon: some View {
        Group {
            if let iconURL = app.iconURL {
                AsyncImage(url: iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    default:
                        iconPlaceholder
                    }
                }
            } else {
                iconPlaceholder
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: dominantColor.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.secondary.opacity(0.2), Color.secondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            )
    }
    
    private var getButton: some View {
        Text("Get")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [dominantColor, dominantColor.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: dominantColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(UIColor.secondarySystemGroupedBackground))
    }
    
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
                withAnimation(.easeInOut(duration: 0.3)) {
                    dominantColor = Color(red: r, green: g, blue: b)
                }
            }
        }
    }
}

// MARK: - Modern App Grid Card
struct ModernAppGridCard: View {
    let app: ASRepository.App
    let source: ASRepository
    @State private var dominantColor: Color = .accentColor
    
    var body: some View {
        VStack(spacing: 12) {
            // App Icon
            Group {
                if let iconURL = app.iconURL {
                    AsyncImage(url: iconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            iconPlaceholder
                        }
                    }
                } else {
                    iconPlaceholder
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: dominantColor.opacity(0.25), radius: 6, x: 0, y: 3)
            
            // App Name
            Text(app.currentName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Version
            if let version = app.currentVersion {
                Text("v\(version)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 0)
            
            // Get Button
            Text("Get")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [dominantColor, dominantColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
        .padding(14)
        .frame(minHeight: 180)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(dominantColor.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            if let iconURL = app.iconURL {
                extractDominantColor(from: iconURL)
            }
        }
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
            )
    }
    
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
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dominantColor = Color(red: Double(pixel[0]) / 255.0, green: Double(pixel[1]) / 255.0, blue: Double(pixel[2]) / 255.0)
                }
            }
        }
    }
}

// MARK: - Modern App Compact Row
struct ModernAppCompactRow: View {
    let app: ASRepository.App
    let source: ASRepository
    
    var body: some View {
        HStack(spacing: 12) {
            // App Icon
            Group {
                if let iconURL = app.iconURL {
                    AsyncImage(url: iconURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        default:
                            iconPlaceholder
                        }
                    }
                } else {
                    iconPlaceholder
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            // App Info
            VStack(alignment: .leading, spacing: 2) {
                Text(app.currentName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                if let version = app.currentVersion {
                    Text("v\(version)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.secondary.opacity(0.2))
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
            )
    }
}

// MARK: - Modern Card Button Style
struct ModernCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Navigation Destination Extension
extension View {
    @ViewBuilder
    func navigationDestinationIfAvailable<Item: Identifiable & Hashable, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        if #available(iOS 17, *) {
            self.navigationDestination(item: item, destination: destination)
        } else {
            self
        }
    }
}
