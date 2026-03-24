import SwiftUI
import NimbleViews

// MARK: - View
struct SigningEntitlementsView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @Environment(\.colorScheme) var colorScheme
    @State private var _isAddingPresenting = false
    @State private var _isCreatingPresenting = false
    @State private var _appearAnimation = false
    @State private var _floatingAnimation = false
    @State private var _parsedEntitlements: [String: Any] = [:]
    @AppStorage("Feather.showEntitlementsSplash") private var _showSplash = true
    
    @Binding var bindingValue: URL?
    var app: AppInfoPresentable?
    
    // MARK: Body
    var body: some View {
        ZStack {
            // Modern animated background
            modernBackground
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header illustration
                    headerSection
                        .opacity(_appearAnimation ? 1 : 0)
                        .offset(y: _appearAnimation ? 0 : 20)
                    
                    // Main Buttons
                    mainButtonsSection
                        .opacity(_appearAnimation ? 1 : 0)
                        .offset(y: _appearAnimation ? 0 : 25)

                    // Content card
                    contentCard
                        .opacity(_appearAnimation ? 1 : 0)
                        .offset(y: _appearAnimation ? 0 : 30)
                    
                    // Parsed Entitlements List
                    if !_parsedEntitlements.isEmpty {
                        entitlementsListView
                            .opacity(_appearAnimation ? 1 : 0)
                            .offset(y: _appearAnimation ? 0 : 35)
                    }

                    // Info section
                    infoSection
                        .opacity(_appearAnimation ? 1 : 0)
                        .offset(y: _appearAnimation ? 0 : 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("Entitlements")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $_isAddingPresenting) {
            FileImporterRepresentableView(
                allowedContentTypes: [.xmlPropertyList, .plist, .entitlements],
                onDocumentsPicked: { urls in
                    guard let selectedFileURL = urls.first else { return }
                    
                    FileManager.default.moveAndStore(selectedFileURL, with: "FeatherEntitlement") { url in
                        bindingValue = url
                        _parseEntitlements(at: url)
                    }
                }
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $_isCreatingPresenting) {
            NavigationStack {
                EntitlementsCreateView()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                _appearAnimation = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                _floatingAnimation = true
            }

            if let url = bindingValue {
                _parseEntitlements(at: url)
            }
        }
        .sheet(isPresented: $_showSplash) {
            EntitlementsSplashView()
        }
    }
    
    // MARK: - Modern Background
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeManager.accentColor.opacity(0.15), themeManager.accentColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: _floatingAnimation ? -30 : 30, y: _floatingAnimation ? -20 : 20)
                    .position(x: geo.size.width * 0.8, y: geo.size.height * 0.15)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [themeManager.accentColor.opacity(0.1), themeManager.accentColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: _floatingAnimation ? 20 : -20, y: _floatingAnimation ? 15 : -15)
                    .position(x: geo.size.width * 0.2, y: geo.size.height * 0.7)
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Main Buttons Section
    @ViewBuilder
    private var mainButtonsSection: some View {
        HStack(spacing: 16) {
            Button {
                if let app = app {
                    _loadFromApp(app)
                } else {
                    _isAddingPresenting = true
                }
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 24))
                    Text(app != nil ? "Load From App" : "Load Entitlements")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(themeManager.primaryTextColor.opacity(0.1), lineWidth: 1))
            }

            Button {
                _isCreatingPresenting = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "plus.square.on.square")
                        .font(.system(size: 24))
                    Text("Create New")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(themeManager.primaryTextColor.opacity(0.1), lineWidth: 1))
            }
        }
    }

    // MARK: - Entitlements List View
    @ViewBuilder
    private var entitlementsListView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.rectangle.fill")
                    .foregroundStyle(themeManager.accentColor)
                Text("Entitlements Content")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                ForEach(Array(_parsedEntitlements.keys.sorted()), id: \.self) { key in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(key)
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.bold)
                                .foregroundStyle(themeManager.primaryTextColor)
                            Spacer()
                        }

                        Text(String(describing: _parsedEntitlements[key] ?? ""))
                            .font(.caption2)
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 8).fill(themeManager.primaryTextColor.opacity(0.05)))
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(themeManager.primaryTextColor.opacity(0.1), lineWidth: 1))
    }

    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(themeManager.accentColor.opacity(_floatingAnimation ? 0.3 : 0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 25)
                    .scaleEffect(_floatingAnimation ? 1.1 : 1.0)
                
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [themeManager.accentColor.opacity(0.3), themeManager.accentColor.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: themeManager.accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Entitlements")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(themeManager.primaryTextColor)
                    
                    Text("Beta")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(themeManager.buttonTextColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(themeManager.accentColor)
                        )
                }
                
                Text("Customize App Permissions And Capabilities")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Content Card
    @ViewBuilder
    private var contentCard: some View {
        VStack(spacing: 0) {
            if let ent = bindingValue {
                // File selected state
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [themeManager.accentColor.opacity(0.3), themeManager.accentColor.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "doc.badge.checkmark.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(themeManager.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected File")
                            .font(.caption)
                            .foregroundStyle(themeManager.secondaryTextColor)
                        Text(ent.lastPathComponent)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(themeManager.primaryTextColor)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            FileManager.default.deleteStored(ent) { _ in
                                bindingValue = nil
                            }
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                }
                .padding(16)
            } else {
                // Empty state - select file
                Button {
                    if let app = app {
                        _loadFromApp(app)
                    } else {
                        _isAddingPresenting = true
                    }
                } label: {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(themeManager.accentColor.opacity(0.1))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(themeManager.accentColor)
                        }
                        
                        VStack(spacing: 6) {
                            Text(app != nil ? "Load From App" : "Select Entitlements File")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(themeManager.primaryTextColor)
                            
                            Text(app != nil ? "Extract entitlements from the app bundle" : "Choose Entitlements File")
                                .font(.caption)
                                .foregroundStyle(themeManager.secondaryTextColor)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
    }
    
    // MARK: - Info Section
    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(themeManager.accentColor)
                
                Text("About Entitlements")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                infoRow(icon: "checkmark.shield.fill", text: "Override Default App Permissions", color: .green)
                infoRow(icon: "key.fill", text: "Add Custom Capabilities", color: .blue)
                infoRow(icon: "exclamationmark.triangle.fill", text: "Notice: Incorrect entitlements may cause app crashes which means you have to resign the app.", color: .orange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.clear)
            )
        }
    }
    
    private func _loadFromApp(_ app: AppInfoPresentable) {
        guard let appURL = Storage.shared.getAppDirectory(for: app) else { return }
        let provisioningPath = appURL.appendingPathComponent("embedded.mobileprovision")

        guard FileManager.default.fileExists(atPath: provisioningPath.path) else {
            AppLogManager.shared.error("embedded.mobileprovision not found", category: "Entitlements")
            return
        }

        do {
            let provisioningData = try Data(contentsOf: provisioningPath)
            if let xmlStart = provisioningData.range(of: Data("<?xml".utf8)),
               let plistEnd = provisioningData.range(of: Data("</plist>".utf8)) {
                let xmlEndIndex = plistEnd.upperBound
                let xmlData = provisioningData.subdata(in: xmlStart.lowerBound..<xmlEndIndex)

                if let plist = try PropertyListSerialization.propertyList(from: xmlData, format: nil) as? [String: Any],
                   let entitlements = plist["Entitlements"] as? [String: Any] {

                    let data = try PropertyListSerialization.data(fromPropertyList: entitlements, format: .xml, options: 0)
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(app.name ?? "App").entitlements")
                    try data.write(to: tempURL)

                    FileManager.default.moveAndStore(tempURL, with: "FeatherEntitlement") { url in
                        bindingValue = url
                        _parseEntitlements(at: url)
                        HapticsManager.shared.success()
                    }
                }
            }
        } catch {
            AppLogManager.shared.error("Failed to extract entitlements: \(error.localizedDescription)", category: "Entitlements")
        }
    }

    private func _parseEntitlements(at url: URL) {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return
        }
        _parsedEntitlements = plist
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(themeManager.primaryTextColor)
        }
    }
}
