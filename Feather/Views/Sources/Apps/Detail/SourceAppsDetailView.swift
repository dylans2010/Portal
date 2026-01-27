import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import NukeUI

// MARK: - SourceAppsDetailView
struct SourceAppsDetailView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var downloadProgress: Double = 0
    @State var cancellable: AnyCancellable?
    @State private var isScreenshotPreviewPresented: Bool = false
    @State private var selectedScreenshotIndex: Int = 0
    @State private var dominantColor: Color = .accentColor
    @State private var scrollOffset: CGFloat = 0
    
    var source: ASRepository
    var app: ASRepository.App
    
    private let horizontalPadding: CGFloat = 20
    private let iconSize: CGFloat = 118
    private let iconCornerRadius: CGFloat = 26
    private let navButtonSize: CGFloat = 36
    
    // Check if app has minimal info (no screenshots, no description, no version history)
    private var hasMinimalInfo: Bool {
        let hasScreenshots = app.screenshotURLs?.isEmpty == false
        let hasDescription = app.localizedDescription?.isEmpty == false
        let hasVersionHistory = (app.versions?.count ?? 0) > 1
        let hasWhatsNew = app.currentAppVersion?.localizedDescription?.isEmpty == false
        
        return !hasScreenshots && !hasDescription && !hasVersionHistory && !hasWhatsNew
    }
    
    var currentDownload: Download? {
        downloadManager.getDownload(by: app.currentUniqueId)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                if hasMinimalInfo {
                    minimalInfoView(geometry: geometry)
                } else {
                    fullInfoView(geometry: geometry)
                }
                
                navigationOverlay(geometry: geometry)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isScreenshotPreviewPresented) {
            if let screenshotURLs = app.screenshotURLs {
                ScreenshotPreviewView(screenshotURLs: screenshotURLs, initialIndex: selectedScreenshotIndex)
            }
        }
        .onAppear {
            if let iconURL = app.iconURL {
                extractDominantColor(from: iconURL)
            }
        }
    }
    
    // MARK: - Navigation Overlay (No Share Button)
    
    private func navigationOverlay(geometry: GeometryProxy) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: navButtonSize, height: navButtonSize)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, geometry.safeAreaInsets.top + 8)
    }
    
    // MARK: - Minimal Info View (Modern, Clean Design)
    
    private func minimalInfoView(geometry: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Top spacing for nav bar
                Color.clear.frame(height: geometry.safeAreaInsets.top + 60)
                
                // App Card with Icon and Name inside
                VStack(spacing: 20) {
                    // Icon
                    minimalAppIcon
                    
                    // App Name and Developer
                    VStack(spacing: 6) {
                        Text(app.currentName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                        
                        if let developer = app.developer {
                            Text(developer)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(dominantColor)
                        }
                        
                        if let category = app.category {
                            Text(category.capitalized)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Download Button
                    DownloadButtonView(app: app)
                        .padding(.top, 8)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    dominantColor.opacity(colorScheme == .dark ? 0.15 : 0.1),
                                    dominantColor.opacity(colorScheme == .dark ? 0.08 : 0.05)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .padding(.horizontal, horizontalPadding)
                
                // Information Section (Left-aligned)
                minimalInformationSection
                    .padding(.top, 24)
                    .padding(.horizontal, horizontalPadding)
                
                Spacer(minLength: 100)
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private var minimalAppIcon: some View {
        Group {
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        minimalIconPlaceholder
                    }
                }
            } else {
                minimalIconPlaceholder
            }
        }
        .frame(width: 100, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: dominantColor.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private var minimalIconPlaceholder: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(dominantColor.opacity(0.2))
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(dominantColor)
            )
    }
    
    // MARK: - Minimal Information Section (Left-aligned)
    
    private var minimalInformationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Information")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 0) {
                if let sourceName = source.name {
                    minimalInfoRow(icon: "globe", label: "Source", value: sourceName)
                    Divider().padding(.leading, 44)
                }
                
                if let developer = app.developer {
                    minimalInfoRow(icon: "person.fill", label: "Developer", value: developer)
                    Divider().padding(.leading, 44)
                }
                
                if let size = app.size {
                    minimalInfoRow(icon: "arrow.down.circle", label: "Size", value: size.formattedByteCount)
                    Divider().padding(.leading, 44)
                }
                
                if let category = app.category {
                    minimalInfoRow(icon: "square.grid.2x2", label: "Category", value: category.capitalized)
                    Divider().padding(.leading, 44)
                }
                
                if let version = app.currentVersion {
                    minimalInfoRow(icon: "number", label: "Version", value: version)
                    Divider().padding(.leading, 44)
                }
                
                if let bundleId = app.id {
                    minimalInfoRow(icon: "doc.on.doc", label: "Bundle ID", value: bundleId, isCopyable: true)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
    }
    
    private func minimalInfoRow(icon: String, label: String, value: String, isCopyable: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(dominantColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                
                if isCopyable {
                    Button {
                        UIPasteboard.general.string = value
                        HapticsManager.shared.success()
                    } label: {
                        Text(value)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                } else {
                    Text(value)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if isCopyable {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Full Info View (Original with improvements)
    
    private func fullInfoView(geometry: GeometryProxy) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                heroBanner(geometry: geometry)
                mainContent
            }
        }
        .ignoresSafeArea(edges: .top)
    }
    
    private let heroHeight: CGFloat = UIScreen.main.bounds.height * 0.38
    
    // MARK: - Hero Banner
    
    private func heroBanner(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            dominantColor.opacity(colorScheme == .dark ? 0.4 : 0.3),
                            dominantColor.opacity(colorScheme == .dark ? 0.2 : 0.15),
                            dominantColor.opacity(colorScheme == .dark ? 0.1 : 0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)
                )
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 32,
                        bottomTrailingRadius: 32,
                        topTrailingRadius: 0
                    )
                )
        }
        .frame(height: heroHeight)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            appInfoRow
                .padding(.top, -60)
                .padding(.horizontal, horizontalPadding)
            
            statisticsRow
                .padding(.top, 24)
                .padding(.horizontal, horizontalPadding)
            
            Divider()
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 20)
            
            if let screenshotURLs = app.screenshotURLs, !screenshotURLs.isEmpty {
                screenshotsPreview(screenshotURLs)
                    .padding(.top, 20)
            }
            
            if let currentVer = app.currentVersion,
               let whatsNewDesc = app.currentAppVersion?.localizedDescription {
                whatsNewSection(version: currentVer, description: whatsNewDesc)
                    .padding(.top, 24)
                    .padding(.horizontal, horizontalPadding)
            }
            
            if let appDesc = app.localizedDescription {
                descriptionSection(appDesc)
                    .padding(.top, 24)
                    .padding(.horizontal, horizontalPadding)
            }
            
            informationSection
                .padding(.top, 24)
                .padding(.horizontal, horizontalPadding)
            
            if let appPermissions = app.appPermissions {
                permissionsSection(appPermissions)
                    .padding(.top, 24)
                    .padding(.horizontal, horizontalPadding)
            }
            
            Spacer(minLength: 60)
        }
    }
    
    // MARK: - App Info Row
    
    private var appInfoRow: some View {
        HStack(alignment: .top, spacing: 16) {
            appIcon
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.currentName)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let category = app.category {
                    Text(category.capitalized)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                
                if let developer = app.developer {
                    Text(developer)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.top, 8)
            
            Spacer(minLength: 8)
            
            VStack(spacing: 4) {
                DownloadButtonView(app: app)
                
                if app.size != nil {
                    Text("Free")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        }
    }
    
    private var appIcon: some View {
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
        .frame(width: iconSize, height: iconSize)
        .clipShape(RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.15), radius: 16, x: 0, y: 8)
    }
    
    private var iconPlaceholder: some View {
        RoundedRectangle(cornerRadius: iconCornerRadius, style: .continuous)
            .fill(Color(UIColor.secondarySystemBackground))
            .overlay(
                Image(systemName: "app.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.tertiary)
            )
    }
    
    // MARK: - Statistics Row
    
    private var statisticsRow: some View {
        HStack(spacing: 0) {
            statisticColumn(
                topLabel: app.versions?.count.description ?? "1",
                mainValue: app.currentVersion ?? "1.0",
                bottomContent: AnyView(
                    Text("Version")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                )
            )
            
            statisticDivider
            
            if let size = app.size {
                statisticColumn(
                    topLabel: "SIZE",
                    mainValue: size.formattedByteCount,
                    bottomContent: AnyView(
                        Text("Download")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    )
                )
                
                statisticDivider
            }
            
            if let category = app.category {
                statisticColumn(
                    topLabel: "CATEGORY",
                    mainValue: "#\(Int.random(in: 1...50))",
                    bottomContent: AnyView(
                        Text(category.capitalized)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    )
                )
                
                statisticDivider
            }
            
            statisticColumn(
                topLabel: "DEVELOPER",
                mainValue: "",
                bottomContent: AnyView(
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(UIColor.tertiarySystemFill))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            )
                        Text(app.developer ?? source.name ?? "Developer")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                ),
                hideMainValue: true
            )
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private func statisticColumn(topLabel: String, mainValue: String, bottomContent: AnyView, hideMainValue: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(topLabel)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            
            if !hideMainValue {
                Text(mainValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
            
            bottomContent
        }
        .frame(maxWidth: .infinity)
    }
    
    private var statisticDivider: some View {
        Rectangle()
            .fill(Color(UIColor.separator).opacity(0.3))
            .frame(width: 0.5, height: 44)
    }
    
    // MARK: - Screenshots Preview
    
    private func screenshotsPreview(_ urls: [URL]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal, horizontalPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(urls.indices, id: \.self) { index in
                        LazyImage(url: urls[index]) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: UIScreen.main.bounds.width * 0.7, height: 420)
                                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
                                    )
                                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 12, x: 0, y: 6)
                                    .onTapGesture {
                                        selectedScreenshotIndex = index
                                        isScreenshotPreviewPresented = true
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(UIColor.tertiarySystemFill))
                                    .frame(width: UIScreen.main.bounds.width * 0.7, height: 420)
                                    .overlay(ProgressView())
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
            }
        }
    }
    
    // MARK: - What's New Section
    
    private func whatsNewSection(version: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("What's New")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let versions = app.versions {
                    NavigationLink {
                        VersionHistoryView(app: app, versions: versions)
                    } label: {
                        Text("Version History")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            
            HStack {
                Text("Version \(version)")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                
                if let date = app.currentDate?.date {
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Text(date.formatted(.relative(presentation: .named)))
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }
            }
            
            ExpandableText(text: description, lineLimit: 3)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Description Section
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            ExpandableText(text: description, lineLimit: 4)
                .font(.system(size: 15))
                .foregroundStyle(.primary)
        }
    }
    
    // MARK: - Information Section
    
    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Information")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            // Horizontal scrollable info cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if let sourceName = source.name {
                        ModernInfoCard(
                            icon: "globe",
                            label: "Source",
                            value: sourceName,
                            color: dominantColor
                        )
                    }
                    
                    if let developer = app.developer {
                        ModernInfoCard(
                            icon: "person.fill",
                            label: "Developer",
                            value: developer,
                            color: .blue
                        )
                    }
                    
                    if let size = app.size {
                        ModernInfoCard(
                            icon: "arrow.down.circle.fill",
                            label: "Size",
                            value: size.formattedByteCount,
                            color: .green
                        )
                    }
                    
                    if let category = app.category {
                        ModernInfoCard(
                            icon: "square.grid.2x2.fill",
                            label: "Category",
                            value: category.capitalized,
                            color: .purple
                        )
                    }
                    
                    if let version = app.currentVersion {
                        ModernInfoCard(
                            icon: "number",
                            label: "Version",
                            value: version,
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            .padding(.horizontal, -4)
            
            // Bundle ID (copyable, full width)
            if let bundleId = app.id {
                Button {
                    UIPasteboard.general.string = bundleId
                    HapticsManager.shared.success()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bundle ID")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text(bundleId)
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Text("Tap to copy")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Permissions Section
    
    private func permissionsSection(_ permissions: ASRepository.AppPermissions) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Privacy")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
            
            NavigationLink {
                PermissionsView(appPermissions: permissions, dominantColor: dominantColor)
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("See Details")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color.accentColor)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
            }
            .buttonStyle(.plain)
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
                withAnimation(.easeInOut(duration: 0.4)) {
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

// MARK: - Modern Info Card
struct ModernInfoCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .frame(width: 110, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
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
