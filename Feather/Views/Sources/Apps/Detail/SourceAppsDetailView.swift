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
    
    var currentDownload: Download? {
        downloadManager.getDownload(by: app.currentUniqueId)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Header
                heroHeader
                
                // Content
                VStack(alignment: .leading, spacing: 24) {
                    // Screenshots
                    if let screenshotURLs = app.screenshotURLs, !screenshotURLs.isEmpty {
                        screenshotsSection(screenshotURLs)
                    }
                    
                    // What's New
                    if let currentVer = app.currentVersion,
                       let whatsNewDesc = app.currentAppVersion?.localizedDescription {
                        whatsNewSection(version: currentVer, description: whatsNewDesc)
                    }
                    
                    // Description
                    if let appDesc = app.localizedDescription {
                        descriptionSection(appDesc)
                    }
                    
                    // Information Grid
                    informationSection
                    
                    // Permissions
                    if let appPermissions = app.appPermissions {
                        permissionsSection(appPermissions)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(backgroundView)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .fullScreenCover(isPresented: $isScreenshotPreviewPresented) {
            if let screenshotURLs = app.screenshotURLs {
                ScreenshotPreviewView(
                    screenshotURLs: screenshotURLs,
                    initialIndex: selectedScreenshotIndex
                )
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
    
    // MARK: - Hero Header
    @ViewBuilder
    private var heroHeader: some View {
        VStack(spacing: 20) {
            // App Icon
            Group {
                if let iconURL = app.iconURL {
                    LazyImage(url: iconURL) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            iconPlaceholder
                        }
                    }
                } else {
                    iconPlaceholder
                }
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: dominantColor.opacity(0.4), radius: 20, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            // App Name & Developer
            VStack(spacing: 6) {
                Text(app.currentName)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                if let developer = app.developer {
                    Text(developer)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
                
                // Quick Info Pills
                HStack(spacing: 12) {
                    if let version = app.currentVersion {
                        infoPill(icon: "tag.fill", text: "v\(version)")
                    }
                    if let size = app.size {
                        infoPill(icon: "internaldrive.fill", text: size.formattedByteCount)
                    }
                    if let category = app.category {
                        infoPill(icon: "square.grid.2x2.fill", text: category.capitalized)
                    }
                }
                .padding(.top, 8)
            }
            
            // Download Button
            DownloadButtonView(app: app)
                .padding(.top, 8)
        }
        .padding(.vertical, 30)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.25),
                    dominantColor.opacity(0.1),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(UIColor.tertiarySystemBackground))
        )
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Color.secondary.opacity(0.3), Color.secondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            )
    }
    
    // MARK: - Screenshots Section
    @ViewBuilder
    private func screenshotsSection(_ urls: [URL]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: .localized("Screenshots"), icon: "photo.on.rectangle")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(urls.indices, id: \.self) { index in
                        LazyImage(url: urls[index]) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 400)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    .onTapGesture {
                                        selectedScreenshotIndex = index
                                        isScreenshotPreviewPresented = true
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color.secondary.opacity(0.1))
                                    .frame(width: 200, height: 400)
                                    .overlay(ProgressView())
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, -4)
        }
    }
    
    // MARK: - What's New Section
    @ViewBuilder
    private func whatsNewSection(version: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeader(title: .localized("What's New?"), icon: "sparkles")
                Spacer()
                if let versions = app.versions {
                    NavigationLink {
                        VersionHistoryView(app: app, versions: versions)
                    } label: {
                        Text(.localized("Version History"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(dominantColor)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Version \(version)")
                        .font(.system(size: 15, weight: .semibold))
                    
                    if let date = app.currentDate?.date {
                        Text("•")
                            .foregroundStyle(.tertiary)
                        Text(date, style: .date)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    // MARK: - Description Section
    @ViewBuilder
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: .localized("Description"), icon: "text.alignleft")
            
            ExpandableText(text: description, lineLimit: 4)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
        }
    }
    
    // MARK: - Information Section
    @ViewBuilder
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: .localized("Information"), icon: "info.circle")
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                if let sourceName = source.name {
                    infoCard(title: .localized("Source"), value: sourceName, icon: "globe", color: .blue)
                }
                if let developer = app.developer {
                    infoCard(title: .localized("Developer"), value: developer, icon: "person.fill", color: .purple)
                }
                if let size = app.size {
                    infoCard(title: .localized("Size"), value: size.formattedByteCount, icon: "internaldrive.fill", color: .orange)
                }
                if let category = app.category {
                    infoCard(title: .localized("Category"), value: category.capitalized, icon: "tag.fill", color: .pink)
                }
                if let version = app.currentVersion {
                    infoCard(title: .localized("Version"), value: version, icon: "number.circle.fill", color: .green)
                }
                if let date = app.currentDate?.date {
                    infoCard(title: .localized("Updated"), value: DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none), icon: "calendar", color: .cyan)
                }
            }
            
            // Bundle ID (full width)
            if let bundleId = app.id {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "barcode")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("Bundle ID"))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(bundleId)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button {
                        UIPasteboard.general.string = bundleId
                        HapticsManager.shared.success()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundStyle(dominantColor)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
        }
    }
    
    private func infoCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Permissions Section
    @ViewBuilder
    private func permissionsSection(_ permissions: ASRepository.AppPermissions) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: .localized("Permissions"), icon: "lock.shield")
            
            NavigationLink {
                PermissionsView(appPermissions: permissions, dominantColor: dominantColor)
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(dominantColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(dominantColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(.localized("App Permissions"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(.localized("See which permissions this app requires"))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Section Header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(dominantColor)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Background
    @ViewBuilder
    private var backgroundView: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [
                    dominantColor.opacity(0.3),
                    dominantColor.opacity(0.2),
                    dominantColor.opacity(0.1),
                    dominantColor.opacity(0.05),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 350)
            
            Color(UIColor.systemBackground)
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
                    dominantColor = Color(red: Double(pixel[0]) / 255.0, green: Double(pixel[1]) / 255.0, blue: Double(pixel[2]) / 255.0)
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
