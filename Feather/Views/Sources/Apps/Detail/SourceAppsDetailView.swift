import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import NukeUI

// MARK: - SourceAppsDetailView
struct SourceAppsDetailView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var downloadProgress: Double = 0
    @State var cancellable: AnyCancellable?
    @State private var isScreenshotPreviewPresented: Bool = false
    @State private var selectedScreenshotIndex: Int = 0
    @State private var dominantColor: Color = .accentColor
    @State private var showShareSheet = false
    
    var source: ASRepository
    var app: ASRepository.App
    
    private let cornerRadius: CGFloat = 20
    private let cardPadding: CGFloat = 16
    private let sectionSpacing: CGFloat = 20
    
    var currentDownload: Download? {
        downloadManager.getDownload(by: app.currentUniqueId)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                contentSection
            }
        }
        .background(adaptiveBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .fullScreenCover(isPresented: $isScreenshotPreviewPresented) {
            if let screenshotURLs = app.screenshotURLs {
                ScreenshotPreviewView(screenshotURLs: screenshotURLs, initialIndex: selectedScreenshotIndex)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let downloadURL = app.currentAppVersion?.downloadURL {
                ShareSheet(urls: [downloadURL])
            }
        }
        .onAppear {
            if let iconURL = app.iconURL {
                extractDominantColor(from: iconURL)
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 0) {
            ZStack {
                heroBackground
                
                VStack(spacing: 16) {
                    appHeaderRow
                    metadataRow
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }
    
    private var heroBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            dominantColor.opacity(colorScheme == .dark ? 0.35 : 0.25),
                            dominantColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
                            Color(UIColor.secondarySystemGroupedBackground).opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(0.5)
            
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.15 : 0.4),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: dominantColor.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    private var appHeaderRow: some View {
        HStack(spacing: 16) {
            appIconView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.currentName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                if let developer = app.developer {
                    Text(developer)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                if let category = app.category {
                    Text(category.capitalized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(dominantColor)
                }
            }
            
            Spacer()
            
            DownloadButtonView(app: app)
        }
    }
    
    private var appIconView: some View {
        Group {
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        iconPlaceholder
                    }
                }
            } else {
                iconPlaceholder
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: dominantColor.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)
            )
    }
    
    private var metadataRow: some View {
        HStack(spacing: 0) {
            if let version = app.currentVersion {
                metadataStat(value: "v\(version)", label: "Version")
            }
            if let size = app.size {
                metadataStat(value: size.formattedByteCount, label: "Size")
            }
            if let date = app.currentDate?.date {
                metadataStat(value: date.formatted(.dateTime.month(.abbreviated).day()), label: "Updated")
            }
            metadataStat(value: source.name ?? "Source", label: "Source")
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.systemBackground).opacity(colorScheme == .dark ? 0.3 : 0.6))
        )
    }
    
    private func metadataStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Content Section
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: sectionSpacing) {
            if let screenshotURLs = app.screenshotURLs, !screenshotURLs.isEmpty {
                screenshotsCard(screenshotURLs)
            }
            
            if let currentVer = app.currentVersion,
               let whatsNewDesc = app.currentAppVersion?.localizedDescription {
                whatsNewCard(version: currentVer, description: whatsNewDesc)
            }
            
            if let appDesc = app.localizedDescription {
                descriptionCard(appDesc)
            }
            
            informationCard
            
            if let appPermissions = app.appPermissions {
                permissionsCard(appPermissions)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, sectionSpacing)
        .padding(.bottom, 40)
    }
    
    // MARK: - Screenshots Card
    
    private func screenshotsCard(_ urls: [URL]) -> some View {
        promotionalCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: .localized("Screenshots"), icon: "photo.on.rectangle")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(urls.indices, id: \.self) { index in
                            LazyImage(url: urls[index]) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 380)
                                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                        )
                                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                        .onTapGesture {
                                            selectedScreenshotIndex = index
                                            isScreenshotPreviewPresented = true
                                        }
                                } else {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.secondary.opacity(0.1))
                                        .frame(width: 180, height: 380)
                                        .overlay(ProgressView())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, -cardPadding)
                .padding(.horizontal, cardPadding)
            }
        }
    }
    
    // MARK: - What's New Card
    
    private func whatsNewCard(version: String, description: String) -> some View {
        promotionalCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    cardHeader(title: .localized("What's New"), icon: "sparkles")
                    Spacer()
                    if let versions = app.versions {
                        NavigationLink {
                            VersionHistoryView(app: app, versions: versions)
                        } label: {
                            Text(.localized("Version History"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(dominantColor)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text("Version \(version)")
                            .font(.system(size: 14, weight: .semibold))
                        
                        if let date = app.currentDate?.date {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            Text(date, style: .date)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    ExpandableText(text: description, lineLimit: 3)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Description Card
    
    private func descriptionCard(_ description: String) -> some View {
        promotionalCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: .localized("Description"), icon: "text.alignleft")
                ExpandableText(text: description, lineLimit: 4)
                    .font(.system(size: 14))
            }
        }
    }
    
    // MARK: - Information Card
    
    private var informationCard: some View {
        promotionalCard {
            VStack(alignment: .leading, spacing: 12) {
                cardHeader(title: .localized("Information"), icon: "info.circle")
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ], spacing: 10) {
                    if let sourceName = source.name {
                        infoItem(title: "Source", value: sourceName, icon: "globe", color: .blue)
                    }
                    if let developer = app.developer {
                        infoItem(title: "Developer", value: developer, icon: "person.fill", color: .purple)
                    }
                    if let size = app.size {
                        infoItem(title: "Size", value: size.formattedByteCount, icon: "internaldrive.fill", color: .orange)
                    }
                    if let category = app.category {
                        infoItem(title: "Category", value: category.capitalized, icon: "tag.fill", color: .pink)
                    }
                }
                
                if let bundleId = app.id {
                    bundleIdRow(bundleId)
                }
            }
        }
    }
    
    private func infoItem(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
    
    private func bundleIdRow(_ bundleId: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "barcode")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.gray)
                .frame(width: 28, height: 28)
                .background(Color.gray.opacity(0.12))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Bundle ID")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(bundleId)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                UIPasteboard.general.string = bundleId
                HapticsManager.shared.success()
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 13))
                    .foregroundStyle(dominantColor)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(UIColor.tertiarySystemGroupedBackground))
        )
    }
    
    // MARK: - Permissions Card
    
    private func permissionsCard(_ permissions: ASRepository.AppPermissions) -> some View {
        promotionalCard {
            NavigationLink {
                PermissionsView(appPermissions: permissions, dominantColor: dominantColor)
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(dominantColor)
                        .frame(width: 44, height: 44)
                        .background(dominantColor.opacity(0.12))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("App Permissions"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(.localized("See which permissions this app requires"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Promotional Card Container
    
    private func promotionalCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.06), radius: 8, x: 0, y: 4)
            )
    }
    
    private func cardHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(dominantColor)
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Adaptive Background
    
    private var adaptiveBackground: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
            
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [
                        dominantColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
                        dominantColor.opacity(colorScheme == .dark ? 0.05 : 0.03),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let downloadURL = app.currentAppVersion?.downloadURL {
                    Button {
                        UIPasteboard.general.string = downloadURL.absoluteString
                        HapticsManager.shared.success()
                    } label: {
                        Label(.localized("Copy Download URL"), systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        showShareSheet = true
                    } label: {
                        Label(.localized("Share"), systemImage: "square.and.arrow.up")
                    }
                }
                
                if let bundleId = app.id {
                    Button {
                        UIPasteboard.general.string = bundleId
                        HapticsManager.shared.success()
                    } label: {
                        Label(.localized("Copy Bundle ID"), systemImage: "barcode")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 17))
                    .foregroundStyle(.primary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
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
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    dominantColor = Color(
                        red: Double(pixel[0]) / 255.0,
                        green: Double(pixel[1]) / 255.0,
                        blue: Double(pixel[2]) / 255.0
                    )
                }
            }
        }
    }
}

// MARK: - RoundedCorner Shape Helper
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
