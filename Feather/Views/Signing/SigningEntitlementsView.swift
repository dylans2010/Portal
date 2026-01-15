import SwiftUI
import NimbleViews

// MARK: - View
struct SigningEntitlementsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var _isAddingPresenting = false
    @State private var _appearAnimation = false
    @State private var _floatingAnimation = false
    
    @Binding var bindingValue: URL?
    
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
                    
                    // Content card
                    contentCard
                        .opacity(_appearAnimation ? 1 : 0)
                        .offset(y: _appearAnimation ? 0 : 30)
                    
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
                    }
                }
            )
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                _appearAnimation = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                _floatingAnimation = true
            }
        }
    }
    
    // MARK: - Modern Background
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.15), Color.orange.opacity(0)],
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
                            colors: [Color.purple.opacity(0.1), Color.purple.opacity(0)],
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
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color.orange.opacity(_floatingAnimation ? 0.3 : 0.2))
                    .frame(width: 100, height: 100)
                    .blur(radius: 25)
                    .scaleEffect(_floatingAnimation ? 1.1 : 1.0)
                
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.15)],
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
                .shadow(color: Color.orange.opacity(0.3), radius: 15, x: 0, y: 8)
            }
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text("Entitlements")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("Beta")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
                
                Text("Customize App Permissions And Capabilities")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                                    colors: [Color.green.opacity(0.3), Color.green.opacity(0.15)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "doc.badge.checkmark.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected File")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(ent.lastPathComponent)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
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
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(16)
            } else {
                // Empty state - select file
                Button {
                    _isAddingPresenting = true
                } label: {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(.orange)
                        }
                        
                        VStack(spacing: 6) {
                            Text("Select Entitlements File")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                            
                            Text("Choose Entitlements File")
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
                    .foregroundStyle(.orange)
                
                Text("About Entitlements")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                infoRow(icon: "checkmark.shield.fill", text: "Override Default App Permissions", color: .green)
                infoRow(icon: "key.fill", text: "Add Custom Capabilities", color: .blue)
                infoRow(icon: "exclamationmark.triangle.fill", text: "Notice: Incorrect entitlements may cause app crashes which means you have to resign the app", color: .orange)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
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
                .foregroundStyle(.primary)
        }
    }
}
