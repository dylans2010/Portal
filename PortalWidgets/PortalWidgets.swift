import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Constants
private let APP_GROUP_ID = "group.ayon1xw.Portal"

// MARK: - Data Models
struct WidgetApp: Codable {
    let name: String
    let icon: String?
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let certName: String
    let expiryDate: Date?
    let daysRemaining: Int?
    let recentApps: [WidgetApp]
    let isPlaceholder: Bool

    // Configuration options (from Intent on iOS 17, or defaults on iOS 16)
    var customTitle: String? = nil
    var showExpiry: Bool = true

    static var placeholder: WidgetEntry {
        WidgetEntry(
            date: Date(),
            certName: "Developer Certificate",
            expiryDate: Date().addingTimeInterval(86400 * 30),
            daysRemaining: 30,
            recentApps: [
                WidgetApp(name: "Feather", icon: nil),
                WidgetApp(name: "Example", icon: nil),
                WidgetApp(name: "Portal", icon: nil)
            ],
            isPlaceholder: true
        )
    }

    static var empty: WidgetEntry {
        WidgetEntry(
            date: Date(),
            certName: "No Certificate",
            expiryDate: nil,
            daysRemaining: nil,
            recentApps: [],
            isPlaceholder: false
        )
    }
}

// MARK: - Shared Logic
struct WidgetDataFetcher {
    static func fetchLatestEntry() -> WidgetEntry {
        let userDefaults = UserDefaults(suiteName: APP_GROUP_ID) ?? .standard

        let certName = userDefaults.string(forKey: "widget.selectedCertName") ?? "No Certificate"
        let expiryTime = userDefaults.double(forKey: "widget.selectedCertExpiry")

        var expiryDate: Date? = nil
        var daysRemaining: Int? = nil

        if expiryTime > 0 {
            expiryDate = Date(timeIntervalSince1970: expiryTime)
            daysRemaining = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate!).day
        }

        var recentApps: [WidgetApp] = []
        if let data = userDefaults.data(forKey: "widget.recentApps"),
           let decoded = try? JSONDecoder().decode([WidgetApp].self, from: data) {
            recentApps = decoded
        }

        return WidgetEntry(
            date: Date(),
            certName: certName,
            expiryDate: expiryDate,
            daysRemaining: daysRemaining,
            recentApps: recentApps,
            isPlaceholder: false
        )
    }
}

#if compiler(>=5.9)
// MARK: - iOS 17+ App Intents
@available(iOS 17.0, *)
struct PortalConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Portal Configuration"
    static var description = IntentDescription("Customize your Portal widget.")

    @Parameter(title: "Custom Title", default: "Portal")
    var customTitle: String?

    @Parameter(title: "Show Expiry Date", default: true)
    var showExpiry: Bool
}


// MARK: - Timeline Providers

@available(iOS 17.0, *)
struct PortalAppIntentTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        .placeholder
    }
    
    func snapshot(for configuration: PortalConfigurationIntent, in context: Context) async -> WidgetEntry {
        if context.isPreview { return .placeholder }
        var entry = WidgetDataFetcher.fetchLatestEntry()
        entry.customTitle = configuration.customTitle
        entry.showExpiry = configuration.showExpiry
        return entry
    }
    
    func timeline(for configuration: PortalConfigurationIntent, in context: Context) async -> Timeline<WidgetEntry> {
        var entry = WidgetDataFetcher.fetchLatestEntry()
        entry.customTitle = configuration.customTitle
        entry.showExpiry = configuration.showExpiry

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}
#endif

struct PortalLegacyTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        .placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(WidgetDataFetcher.fetchLatestEntry())
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        let entry = WidgetDataFetcher.fetchLatestEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Bundle

#if compiler(>=5.9)
@main
struct PortalWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 17.0, *) {
            QuickActionsWidget()
            CertificateStatusWidget()
            AllInOneWidget()
        } else {
            QuickActionsWidgetLegacy()
            CertificateStatusWidgetLegacy()
            AllInOneWidgetLegacy()
        }
    }
}
#else
@main
struct PortalWidgetsBundleLegacy: WidgetBundle {
    var body: some Widget {
        QuickActionsWidgetLegacy()
        CertificateStatusWidgetLegacy()
        AllInOneWidgetLegacy()
    }
}
#endif

// MARK: - Widgets (Modern iOS 17+)

#if compiler(>=5.9)
@available(iOS 17.0, *)
struct QuickActionsWidget: Widget {
    let kind: String = "QuickActionsWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PortalConfigurationIntent.self, provider: PortalAppIntentTimelineProvider()) { entry in
            QuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quickly access Portal tools.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@available(iOS 17.0, *)
struct CertificateStatusWidget: Widget {
    let kind: String = "CertificateStatusWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PortalConfigurationIntent.self, provider: PortalAppIntentTimelineProvider()) { entry in
            CertificateStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Certificate Status")
        .description("Monitor your certificate status.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

@available(iOS 17.0, *)
struct AllInOneWidget: Widget {
    let kind: String = "AllInOneWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: PortalConfigurationIntent.self, provider: PortalAppIntentTimelineProvider()) { entry in
            AllInOneWidgetView(entry: entry)
        }
        .configurationDisplayName("All In One")
        .description("Complete access to all Portal features.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
#endif

// MARK: - Widgets (Legacy iOS 16)

struct QuickActionsWidgetLegacy: Widget {
    let kind: String = "QuickActionsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PortalLegacyTimelineProvider()) { entry in
            QuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Quick Actions")
        .description("Quickly access Portal tools.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct CertificateStatusWidgetLegacy: Widget {
    let kind: String = "CertificateStatusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PortalLegacyTimelineProvider()) { entry in
            CertificateStatusWidgetView(entry: entry)
        }
        .configurationDisplayName("Certificate Status")
        .description("Monitor your certificate status.")
        .supportedFamilies([.systemSmall])
    }
}

struct AllInOneWidgetLegacy: Widget {
    let kind: String = "AllInOneWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PortalLegacyTimelineProvider()) { entry in
            AllInOneWidgetView(entry: entry)
        }
        .configurationDisplayName("All In One")
        .description("Complete access to all Portal features.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Views

struct QuickActionsWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            case .accessoryCircular:
                accessoryCircular
            case .accessoryRectangular:
                accessoryRectangular
            default:
                smallWidget
            }
        }
        .widgetBackground()
    }
    
    private var smallWidget: some View {
        VStack(spacing: 8) {
            HeaderView(title: entry.customTitle ?? "Portal", icon: "bolt.fill")
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ActionButton(title: "Sign", icon: "signature", color: .blue, url: "portal://sign-app")
                ActionButton(title: "Add", icon: "plus.circle.fill", color: .green, url: "portal://add-source")
                ActionButton(title: "Cert", icon: "checkmark.seal.fill", color: .purple, url: "portal://add-certificate")
                ActionButton(title: "Config", icon: "gearshape.fill", color: .orange, url: "portal://open-settings")
            }
        }
        .padding(12)
    }
    
    private var mediumWidget: some View {
        VStack(spacing: 12) {
            HeaderView(title: entry.customTitle ?? "Portal Quick Actions", icon: "bolt.fill")

            HStack(spacing: 10) {
                ActionCard(title: "Add Source", icon: "plus.circle.fill", color: .blue, url: "portal://add-source")
                ActionCard(title: "Add Cert", icon: "checkmark.seal.fill", color: .green, url: "portal://add-certificate")
                ActionCard(title: "Sign App", icon: "signature", color: .purple, url: "portal://sign-app")
            }
        }
        .padding(14)
    }
    
    private var accessoryCircular: some View {
        Image(systemName: "bolt.fill")
            .font(.title)
            .widgetURL(URL(string: "portal://quick-actions"))
    }
    
    private var accessoryRectangular: some View {
        VStack(alignment: .leading) {
            Label(entry.customTitle ?? "Portal", systemImage: "bolt.fill")
                .font(.headline)
            Text("Quick Actions")
                .font(.caption)
        }
        .widgetURL(URL(string: "portal://quick-actions"))
    }
}

struct CertificateStatusWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family

    private var statusColor: Color {
        guard let days = entry.daysRemaining else { return .secondary }
        if days < 7 { return .red }
        if days < 30 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HeaderView(title: "Certificate", icon: "checkmark.seal.fill", color: statusColor)

            Spacer()

            if entry.certName == "No Certificate" && !entry.isPlaceholder {
                Text("No Certificate Found")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
                Text("Open Portal to add one")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            } else {
                Text(entry.certName)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(2)

                if entry.showExpiry, let days = entry.daysRemaining {
                    Text("\(days) days remaining")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(statusColor)
                }
            }

            Spacer()
        }
        .padding(12)
        .widgetBackground()
        .widgetURL(URL(string: "portal://open-certificates"))
    }
}

struct AllInOneWidgetView: View {
    var entry: WidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                HeaderView(title: entry.customTitle ?? "Portal", icon: "square.grid.2x2.fill")
                Spacer()
                if family == .systemLarge {
                    Text("Pro")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.2))
                        .clipShape(Capsule())
                }
            }

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    ActionButton(title: "Sign", icon: "signature", color: .blue, url: "portal://sign-app")
                    ActionButton(title: "Add", icon: "plus.app.fill", color: .green, url: "portal://add-and-sign")
                    ActionButton(title: "Source", icon: "plus.circle.fill", color: .orange, url: "portal://add-source")
                }

                if family == .systemLarge {
                    HStack(spacing: 8) {
                        ActionButton(title: "Certs", icon: "checkmark.seal.fill", color: .purple, url: "portal://open-certificates")
                        ActionButton(title: "Clear", icon: "trash.fill", color: .red, url: "portal://clear-caches")
                        ActionButton(title: "Logs", icon: "doc.text.fill", color: .gray, url: "portal://export-logs")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recently Signed")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            if entry.recentApps.isEmpty {
                                Text("No apps signed yet")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 4)
                            } else {
                                ForEach(entry.recentApps.prefix(4), id: \.name) { app in
                                    RecentAppIconView(app: app)
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.accentColor.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if family == .systemLarge {
                Spacer(minLength: 0)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.certName)
                            .font(.system(size: 11, weight: .bold))
                        if entry.showExpiry, let days = entry.daysRemaining {
                            Text("\(days) days left")
                                .font(.system(size: 9))
                                .foregroundStyle(days < 7 ? .red : .secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "shield.checkered")
                        .foregroundStyle(entry.daysRemaining ?? 0 < 7 ? .orange : .green)
                }
                .padding(8)
                .background(Color.accentColor.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .widgetBackground()
    }
}

// MARK: - Components

struct HeaderView: View {
    let title: String
    let icon: String
    var color: Color = .accentColor
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let url: String

    var body: some View {
        Link(destination: URL(string: url) ?? URL(string: "portal://home")!) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let url: String

    var body: some View {
        Link(destination: URL(string: url) ?? URL(string: "portal://home")!) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(8)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct RecentAppIconView: View {
    let app: WidgetApp

    var body: some View {
        VStack(spacing: 4) {
            Group {
                if let iconPath = app.icon, let image = UIImage(contentsOfFile: iconPath) {
                    Image(uiImage: image)
                        .resizable()
                } else if let iconName = app.icon, let image = UIImage(named: iconName) {
                    Image(uiImage: image)
                        .resizable()
                } else {
                    ZStack {
                        Color.accentColor.opacity(0.1)
                        Image(systemName: "app.badge")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .frame(width: 28, height: 28)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Text(app.name)
                .font(.system(size: 7, weight: .medium))
                .lineLimit(1)
                .frame(width: 32)
        }
    }
}

// MARK: - Extensions
extension View {
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            return self.containerBackground(for: .widget) {
                Color(uiColor: .systemBackground)
            }
        } else {
            return self.background(Color(uiColor: .systemBackground))
        }
    }
}
