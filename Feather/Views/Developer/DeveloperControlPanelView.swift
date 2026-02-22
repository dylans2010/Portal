import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct DeveloperControlPanelView: View {
    @StateObject private var authManager = DeveloperAuthManager.shared
    @State private var showResetConfirmation = false
    @State private var showNearbyShareIntro = false
    @AppStorage("Feather.enableCustomTabBar") private var enableCustomTabBar = false
    @AppStorage("Feather.simulateNearbyTransfer") private var simulateNearbyTransfer = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var searchText = ""

    // Grouped menu items for cleaner organization
    private var menuCategories: [(title: String, icon: String, color: Color, items: [DevMenuItem])] {
        [
            ("App Management", "app.badge.fill", .blue, [
                DevMenuItem(icon: "arrow.down.circle.fill", title: "Updates & Releases", color: .blue, destination: AnyView(UpdatesReleasesView())),
                DevMenuItem(icon: "server.rack", title: "Sources & Library", color: .purple, destination: AnyView(SourcesLibraryDevView())),
                DevMenuItem(icon: "doc.zipper", title: "Install & IPA", color: .orange, destination: AnyView(InstallIPADevView()))
            ]),
            ("Signing", "signature", .green, [
                DevMenuItem(icon: "signature", title: "Signing Dashboard", color: .blue, destination: AnyView(IPASigningDashboardView())),
                DevMenuItem(icon: "flag.fill", title: "Feature Flags", color: .mint, destination: AnyView(FeatureFlagsView()))
            ]),
            ("Interface", "paintbrush.fill", .pink, [
                DevMenuItem(icon: "paintbrush.fill", title: "UI & Layout", color: .pink, destination: AnyView(UILayoutDevView())),
                DevMenuItem(icon: "house.fill", title: "Home UI Testing", color: .blue, destination: AnyView(HomeUITestingView())),
                DevMenuItem(icon: "antenna.radiowaves.left.and.right", title: "Test Nearby Share", color: .purple, destination: AnyView(NearbyShareUITestingView())),
                DevMenuItem(icon: "eye.fill", title: "UI View Testing", color: .orange, destination: AnyView(UIViewTestingView())),
                DevMenuItem(icon: "app.badge.fill", title: "Live Activity Settings", color: .indigo, destination: AnyView(LiveActivitySettingsView()))
            ]),
            ("System", "gearshape.2.fill", .gray, [
                DevMenuItem(icon: "network", title: "Network & System", color: .green, destination: AnyView(NetworkSystemDevView())),
                DevMenuItem(icon: "cylinder.split.1x2.fill", title: "State & Persistence", color: .cyan, destination: AnyView(StatePersistenceDevView())),
                DevMenuItem(icon: "gauge.with.dots.needle.67percent", title: "Performance", color: .purple, destination: AnyView(PerformanceMonitorView()))
            ]),
            ("Diagnostics", "stethoscope", .red, [
                DevMenuItem(icon: "terminal.fill", title: "App Logs", color: .gray, destination: AnyView(AppLogsView())),
                DevMenuItem(icon: "iphone", title: "Device Info", color: .indigo, destination: AnyView(DeviceInfoView())),
                DevMenuItem(icon: "gearshape.2.fill", title: "Environment", color: .teal, destination: AnyView(EnvironmentInspectorView())),
                DevMenuItem(icon: "exclamationmark.triangle.fill", title: "Crash Logs", color: .red, destination: AnyView(CrashLogViewer())),
                DevMenuItem(icon: "bell.badge.fill", title: "Notifications", color: .yellow, destination: AnyView(TestNotificationsView()))
            ]),
            ("Tools", "bolt.fill", .yellow, [
                DevMenuItem(icon: "bolt.fill", title: "Quick Actions", color: .yellow, destination: AnyView(QuickActionsDevView())),
                DevMenuItem(icon: "sparkles", title: "Easter Eggs", color: .pink, destination: AnyView(EasterEggsView()))
            ])
        ]
    }

    var filteredCategories: [(title: String, icon: String, color: Color, items: [DevMenuItem])] {
        if searchText.isEmpty { return menuCategories }
        return menuCategories.compactMap { category in
            let filtered = category.items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
            return filtered.isEmpty ? nil : (category.title, category.icon, category.color, filtered)
        }
    }

    var body: some View {
        NBNavigationView("Developer Mode") {
            _mainContent
        }
        .withToast()
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                authManager.lockDeveloperMode()
            }
        }
        .sheet(isPresented: $showNearbyShareIntro) {
            if #available(iOS 17.0, *) {
                NearbyShareIntroView()
            } else {
                NearbyShareIntroViewLegacy()
            }
        }
    }

    @ViewBuilder
    private var _mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header Card
                devHeaderCard

                // Quick Toggle Card
                quickToggleCard

                // Category Cards
                ForEach(filteredCategories, id: \.title) { category in
                    devCategoryCard(category)
                }

                // Security Card
                securityCard
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.clear)
        .searchable(text: $searchText, prompt: "Search Developer")
    }

    // MARK: - Header Card
    private var devHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 50, height: 50)
                Image(systemName: "hammer.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Developer Mode")
                    .font(.headline)
                Text("Advanced tools and debugging options")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Active")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(.green))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
        )
    }

    // MARK: - Quick Toggle Card
    private var quickToggleCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.cyan)
                Text("EXPERIMENTAL")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Toggle(isOn: $enableCustomTabBar) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.cyan.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "dock.rectangle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.cyan)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Modern Tab Bar")
                            .font(.subheadline.weight(.medium))
                        Text("Glass effects & animations")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.cyan)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Divider()
                .padding(.horizontal, 16)

            Toggle(isOn: $simulateNearbyTransfer) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "wifi.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.purple)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Simulate Nearby Transfer")
                            .font(.subheadline.weight(.medium))
                        Text("UI preview mode without actual transfer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .tint(.purple)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if simulateNearbyTransfer {
                Divider()
                    .padding(.horizontal, 16)

                NavigationLink(destination: NearbyTransferSimulationView()) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Open Simulation")
                                .font(.subheadline.weight(.medium))
                            Text("Test UI flows and interactions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
        )
    }

    // MARK: - Category Card
    private func devCategoryCard(_ category: (title: String, icon: String, color: Color, items: [DevMenuItem])) -> some View {
        VStack(spacing: 0) {
            // Category Header
            HStack(spacing: 10) {
                Image(systemName: category.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(category.color)
                Text(category.title.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(category.items.count + (category.title == "Interface" ? 1 : 0))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Menu Items
            ForEach(category.items.indices, id: \.self) { index in
                let item = category.items[index]
                NavigationLink(destination: item.destination) {
                    devMenuItemRow(item: item, isLast: (category.title != "Interface" && index == category.items.count - 1))
                }
                .buttonStyle(.plain)
            }

            // Special button for Nearby Share Intro (Interface category only)
            if category.title == "Interface" {
                Button {
                    showNearbyShareIntro = true
                    HapticsManager.shared.softImpact()
                } label: {
                    VStack(spacing: 0) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.purple)
                            }

                            Text("Nearby Share Intro")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "arrow.up.forward.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
        )
    }

    private func devMenuItemRow(item: DevMenuItem, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(item.color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: item.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(item.color)
                }

                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            if !isLast {
                Divider()
                    .padding(.leading, 64)
            }
        }
    }

    // MARK: - Security Card
    private var securityCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("SECURITY")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            NavigationLink(destination: DeveloperSecurityView()) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.orange)
                    }
                    Text("Security Settings")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 64)

            Button {
                authManager.lockDeveloperMode()
                UserDefaults.standard.set(false, forKey: "isDeveloperModeEnabled")
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.red)
                    }
                    Text("Lock Developer Mode")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .padding(.bottom, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.clear)
        )
    }
}
