import SwiftUI
import NimbleViews
import UniformTypeIdentifiers
import CoreTransferable

struct RepoMeta: Codable {
    var repoName: String
    var iconURL: String
}

struct RepoVersion: Codable, Identifiable {
    var id = UUID()
    var version: String = ""
    var date: String = ""
    var localizedDescription: String = ""
    var downloadURL: String = ""
    var size: String = ""

    enum CodingKeys: String, CodingKey {
        case version, date, localizedDescription, downloadURL, size
    }

    init(version: String = "", date: String = "", localizedDescription: String = "", downloadURL: String = "", size: String = "") {
        self.version = version
        self.date = date
        self.localizedDescription = localizedDescription
        self.downloadURL = downloadURL
        self.size = size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        date = try container.decode(String.self, forKey: .date)
        localizedDescription = try container.decode(String.self, forKey: .localizedDescription)
        downloadURL = try container.decode(String.self, forKey: .downloadURL)

        if let intSize = try? container.decode(Int64.self, forKey: .size) {
            size = String(intSize)
        } else {
            size = (try? container.decode(String.self, forKey: .size)) ?? ""
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(date, forKey: .date)
        try container.encode(localizedDescription, forKey: .localizedDescription)
        try container.encode(downloadURL, forKey: .downloadURL)
        let sizeValue = Int64(size.filter { "0123456789".contains($0) }) ?? 0
        try container.encode(sizeValue, forKey: .size)
    }
}

struct RepoNews: Codable, Identifiable {
    var id = UUID().uuidString
    var title: String = ""
    var caption: String = ""
    var date: String = ""
    var imageURL: String = ""
    var notify: Bool = false
    var appID: String?

    enum CodingKeys: String, CodingKey {
        case id = "identifier"
        case title, caption, date, imageURL, notify, appID
    }
}

struct RepoApp: Codable, Identifiable {
    var id = UUID()
    var name: String = ""
    var bundleIdentifier: String = ""
    var developerName: String = ""
    var subtitle: String = ""
    var localizedDescription: String = ""
    var version: String = ""
    var versionDate: String = ""
    var versionDescription: String = ""
    var size: String = ""
    var iconURL: String = ""
    var downloadURL: String = ""
    var type: Int = 1
    var category: String = ""
    var beta: Bool = false
    var screenshots: [String] = []
    var versions: [RepoVersion]? = nil

    // For News aggregation in the builder
    var newsTitle: String = ""
    var newsCaption: String = ""
    var newsImageURL: String = ""

    enum CodingKeys: String, CodingKey {
        case name, bundleIdentifier, developerName, subtitle, localizedDescription, version, versionDate, versionDescription, size, iconURL, downloadURL, type, category, beta, screenshots, versions
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        developerName = try container.decode(String.self, forKey: .developerName)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        localizedDescription = try container.decode(String.self, forKey: .localizedDescription)
        version = try container.decode(String.self, forKey: .version)
        versionDate = try container.decode(String.self, forKey: .versionDate)
        versionDescription = try container.decode(String.self, forKey: .versionDescription)

        if let intSize = try? container.decode(Int64.self, forKey: .size) {
            size = String(intSize)
        } else {
            size = (try? container.decode(String.self, forKey: .size)) ?? ""
        }

        iconURL = try container.decode(String.self, forKey: .iconURL)
        downloadURL = try container.decode(String.self, forKey: .downloadURL)
        type = try container.decode(Int.self, forKey: .type)
        category = try container.decode(String.self, forKey: .category)
        beta = try container.decode(Bool.self, forKey: .beta)
        screenshots = (try? container.decode([String].self, forKey: .screenshots)) ?? []
        versions = try? container.decode([RepoVersion].self, forKey: .versions)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(developerName, forKey: .developerName)
        try container.encode(subtitle, forKey: .subtitle)
        try container.encode(localizedDescription, forKey: .localizedDescription)
        try container.encode(version, forKey: .version)
        try container.encode(versionDate, forKey: .versionDate)
        try container.encode(versionDescription, forKey: .versionDescription)

        let sizeValue = Int64(size.filter { "0123456789".contains($0) }) ?? 0
        try container.encode(sizeValue, forKey: .size)

        try container.encode(iconURL, forKey: .iconURL)
        try container.encode(downloadURL, forKey: .downloadURL)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(beta, forKey: .beta)

        if !screenshots.isEmpty {
            try container.encode(screenshots, forKey: .screenshots)
        }

        // Also include in versions array for AltStore compatibility
        let currentVersion = RepoVersion(
            version: version,
            date: versionDate,
            localizedDescription: versionDescription,
            downloadURL: downloadURL,
            size: size
        )
        try container.encode([currentVersion], forKey: .versions)
    }
}

struct SavedRepoSource: Codable, Identifiable {
    var id = UUID()
    var date = Date()
    var name: String?
    var source: RepoSource
}

struct SourceDocument: FileDocument, Transferable, Identifiable {
    var id = UUID()
    static var readableContentTypes: [UTType] = [.json]
    var text: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { document in
            document.text.data(using: .utf8)!
        }
    }

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(data: data, encoding: .utf8) ?? ""
        } else {
            text = ""
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}

struct RepoSource: Codable, Identifiable {
    var id: String { identifier }

    var name: String
    var identifier: String
    var sourceURL: String
    var iconURL: String
    var website: String = ""
    var subtitle: String = ""
    var description: String = ""
    var apps: [RepoApp]
    var news: [RepoNews] = []

    var isAltSource: Bool = false

    enum CodingKeys: String, CodingKey {
        case name, identifier, sourceURL, iconURL, website, subtitle, description, apps, news, META
    }

    init(name: String, identifier: String, sourceURL: String, iconURL: String, website: String = "", subtitle: String = "", description: String = "", apps: [RepoApp], news: [RepoNews] = [], isAltSource: Bool = false) {
        self.name = name
        self.identifier = identifier
        self.sourceURL = sourceURL
        self.iconURL = iconURL
        self.website = website
        self.subtitle = subtitle
        self.description = description
        self.apps = apps
        self.news = news
        self.isAltSource = isAltSource
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        identifier = try container.decode(String.self, forKey: .identifier)
        sourceURL = try container.decode(String.self, forKey: .sourceURL)
        iconURL = try container.decode(String.self, forKey: .iconURL)
        website = (try? container.decode(String.self, forKey: .website)) ?? ""
        subtitle = (try? container.decode(String.self, forKey: .subtitle)) ?? ""
        description = (try? container.decode(String.self, forKey: .description)) ?? ""
        apps = try container.decode([RepoApp].self, forKey: .apps)
        news = (try? container.decode([RepoNews].self, forKey: .news)) ?? []

        isAltSource = !container.contains(.META)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(identifier, forKey: .identifier)
        try container.encode(sourceURL, forKey: .sourceURL)
        try container.encode(iconURL, forKey: .iconURL)
        if !website.isEmpty { try container.encode(website, forKey: .website) }
        if !subtitle.isEmpty { try container.encode(subtitle, forKey: .subtitle) }
        if !description.isEmpty { try container.encode(description, forKey: .description) }
        try container.encode(apps, forKey: .apps)
        if !news.isEmpty { try container.encode(news, forKey: .news) }

        if !isAltSource {
            try container.encode(RepoMeta(repoName: name, iconURL: iconURL), forKey: .META)
        }
    }
}

struct RepoBuilder: View {
    @AppStorage("Feather.repoBuilder.savedSources") private var savedSourcesData: Data = Data()
    @AppStorage("Feather.showHeaderViews") private var showHeaderViews = true

    @State private var repoName = ""
    @State private var repoIdentifier = ""
    @State private var sourceURL = ""
    @State private var iconURL = ""
    @State private var website = ""
    @State private var subtitle = ""
    @State private var description = ""
    @State private var isAltSource = false
    @State private var apps: [RepoApp] = []
    @State private var news: [RepoNews] = []

    @State private var showingAddApp = false
    @State private var showingGuide = false
    @State private var showingImportPicker = false
    @State private var showingExportDialog = false
    @State private var exportDocument: SourceDocument?
    @State private var editingApp: RepoApp?

    @State private var generatedJSON = ""
    @State private var showingSuccessAlert = false

    @State private var selectedSavedSource: SavedRepoSource?
    @State private var showingSaveNameAlert = false
    @State private var saveName = ""
    @State private var showingEditWarning = false

    var savedSources: [SavedRepoSource] {
        get {
            (try? JSONDecoder().decode([SavedRepoSource].self, from: savedSourcesData)) ?? []
        }
        nonmutating set {
            if let data = try? JSONEncoder().encode(newValue) {
                savedSourcesData = data
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.06),
                        Color.purple.opacity(0.04),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Form {
                    if showHeaderViews {
                        Section {
                            RepoBuilderHeaderView()
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                        }
                    }

                Section(header: Label(String.localized("Source Information"), systemImage: "info.circle.fill")) {
                    HStack {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Source Name"), text: $repoName)
                    }
                    HStack {
                        Image(systemName: "barcode")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Source Identifier"), text: $repoIdentifier)
                    }
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Source URL"), text: $sourceURL)
                    }
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Icon URL"), text: $iconURL)
                    }
                    HStack {
                        Image(systemName: "globe")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Website (Optional)"), text: $website)
                    }
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Subtitle (Optional)"), text: $subtitle)
                    }
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Description (Optional)"), text: $description)
                    }

                    Toggle(isOn: $isAltSource) {
                        HStack(spacing: 12) {
                            Image(systemName: "gearshape")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(String.localized("Create AltSource"))
                                    .bold()
                                Text(String.localized("Generate a standard AltStore compatible source."))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if let selected = selectedSavedSource {
                    Section(header: Label(String.localized("Saved Source JSON"), systemImage: "curlybraces")) {
                        TextEditor(text: .constant(encodeSource(selected.source)))
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 200)

                        HStack {
                            Button {
                                showingEditWarning = true
                            } label: {
                                Label(String.localized("Edit"), systemImage: "pencil")
                            }
                            .buttonStyle(.bordered)

                            Spacer()

                            Button {
                                withAnimation {
                                    selectedSavedSource = nil
                                }
                            } label: {
                                Text(String.localized("Close"))
                            }
                        }
                    }
                }

                Section(header: Label(String.localized("Apps (\(apps.count))"), systemImage: "square.grid.2x2.fill")) {
                    ForEach(apps) { app in
                        Button {
                            editingApp = app
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(app.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { indices in
                        apps.remove(atOffsets: indices)
                    }

                    Button {
                        showingAddApp = true
                    } label: {
                        Label(String.localized("Add App"), systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Button(action: generateSource) {
                        Text(String.localized("Generate Source"))
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if !generatedJSON.isEmpty {
                    Section(header: Label(String.localized("New Source"), systemImage: "doc.text.fill")) {
                        TextEditor(text: $generatedJSON)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 200)

                        HStack {
                            Spacer()

                            Menu {
                                Button {
                                    UIPasteboard.general.string = generatedJSON
                                    ToastManager.shared.show(String.localized("Copied To Clipboard!"), type: .success)
                                } label: {
                                    Label(String.localized("Copy"), systemImage: "doc.on.doc")
                                }

                                Button {
                                    saveName = repoName
                                    showingSaveNameAlert = true
                                } label: {
                                    Label(String.localized("Save"), systemImage: "tray.and.arrow.down")
                                }

                                Button {
                                    exportDocument = SourceDocument(text: generatedJSON)
                                    showingExportDialog = true
                                } label: {
                                    Label(String.localized("Export"), systemImage: "square.and.arrow.up")
                                }
                            } label: {
                                Label(String.localized("Options"), systemImage: "ellipsis.circle")
                                    .font(.title3)
                            }
                        }
                    }
                }

                if !savedSources.isEmpty {
                    Section(header: Label(String.localized("Saved Sources"), systemImage: "archivebox.fill")) {
                        ForEach(savedSources) { saved in
                            Button {
                                withAnimation {
                                    if selectedSavedSource?.id == saved.id {
                                        selectedSavedSource = nil
                                    } else {
                                        selectedSavedSource = saved
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(saved.name ?? saved.source.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(saved.source.identifier)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(saved.date, style: .date)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteSavedSource(saved)
                                } label: {
                                    Label(String.localized("Delete"), systemImage: "trash")
                                }

                                Button {
                                    UIPasteboard.general.string = encodeSource(saved.source)
                                    ToastManager.shared.show(String.localized("Copied To Clipboard!"), type: .success)
                                } label: {
                                    Label(String.localized("Copy"), systemImage: "doc.on.doc")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showingImportPicker = true
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                        }

                        Button {
                            showingGuide = true
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddApp) {
                AddRepoAppView { newApp in
                    apps.append(newApp)
                }
            }
            .sheet(item: $editingApp) { appToEdit in
                AddRepoAppView(app: appToEdit) { updatedApp in
                    if let index = apps.firstIndex(where: { $0.id == appToEdit.id }) {
                        apps[index] = updatedApp
                    }
                }
            }
            .sheet(isPresented: $showingImportPicker) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.json],
                    onDocumentsPicked: { urls in
                        guard let url = urls.first else { return }
                        importJSON(from: url)
                    }
                )
                .ignoresSafeArea()
            }
            .repoFileExporter(isPresented: $showingExportDialog, item: exportDocument, repoName: repoName)
            .sheet(isPresented: $showingGuide) {
                RepoBuilderGuideView()
            }
            .alert(String.localized("Source Generated!"), isPresented: $showingSuccessAlert) {
                Button(String.localized("Copy JSON"), action: {
                    UIPasteboard.general.string = generatedJSON
                    ToastManager.shared.show(String.localized("Copied to clipboard!"), type: .success)
                })
                Button(String.localized("Done"), role: .cancel) { }
            } message: {
                Text(String.localized("The source JSON has been generated and copied to your clipboard. You can now host it on GitHub or any other service."))
            }
            .alert(String.localized("Save Source"), isPresented: $showingSaveNameAlert) {
                TextField(String.localized("Source Name"), text: $saveName)
                Button(String.localized("Save")) {
                    saveCurrentToSavedSources(withName: saveName)
                }
                Button(String.localized("Cancel"), role: .cancel) { }
            } message: {
                Text(String.localized("Enter a name for this saved source."))
            }
            .alert(String.localized("Overwrite Current Data?"), isPresented: $showingEditWarning) {
                Button(String.localized("Overwrite"), role: .destructive) {
                    if let selected = selectedSavedSource {
                        loadSource(selected.source)
                        selectedSavedSource = nil
                    }
                }
                Button(String.localized("Cancel"), role: .cancel) { }
            } message: {
                Text(String.localized("This will replace all current information in the builder with the data from the saved source."))
            }
        }
        .navigationTitle(String.localized("Source Builder"))
        }
    }

    private func generateSource() {
        let source = constructSource()
        generatedJSON = encodeSource(source)
        UIPasteboard.general.string = generatedJSON
        showingSuccessAlert = true
        ToastManager.shared.show(String.localized("Source JSON copied to clipboard!"), type: .success)
        HapticsManager.shared.success()
    }

    private func constructSource() -> RepoSource {
        var finalNews = news

        for app in apps {
            if !app.newsTitle.isEmpty || !app.newsCaption.isEmpty {
                let newsItem = RepoNews(
                    title: app.newsTitle,
                    caption: app.newsCaption,
                    date: app.versionDate,
                    imageURL: app.newsImageURL,
                    notify: true,
                    appID: app.bundleIdentifier
                )

                if let index = finalNews.firstIndex(where: { $0.appID == app.bundleIdentifier && $0.title == app.newsTitle }) {
                    finalNews[index] = newsItem
                } else if let index = finalNews.firstIndex(where: { $0.appID == app.bundleIdentifier }) {
                    finalNews[index] = newsItem
                } else {
                    finalNews.insert(newsItem, at: 0)
                }
            }
        }

        return RepoSource(
            name: repoName,
            identifier: repoIdentifier,
            sourceURL: sourceURL,
            iconURL: iconURL,
            website: website,
            subtitle: subtitle,
            description: description,
            apps: apps,
            news: finalNews,
            isAltSource: isAltSource
        )
    }

    private func encodeSource(_ source: RepoSource) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        if let data = try? encoder.encode(source), let string = String(data: data, encoding: .utf8) {
            return string
        }
        return ""
    }

    private func loadSource(_ source: RepoSource) {
        repoName = source.name
        repoIdentifier = source.identifier
        sourceURL = source.sourceURL
        iconURL = source.iconURL
        website = source.website
        subtitle = source.subtitle
        description = source.description
        isAltSource = source.isAltSource

        var loadedApps = source.apps
        for i in 0..<loadedApps.count {
            if let newsItem = source.news.first(where: { $0.appID == loadedApps[i].bundleIdentifier }) {
                loadedApps[i].newsTitle = newsItem.title
                loadedApps[i].newsCaption = newsItem.caption
                loadedApps[i].newsImageURL = newsItem.imageURL
            }
        }
        apps = loadedApps
        news = source.news

        generatedJSON = encodeSource(source)
        HapticsManager.shared.impact(.light)
    }

    private func importJSON(from url: URL) {
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer { if isSecurityScoped { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let source = try decoder.decode(RepoSource.self, from: data)
            loadSource(source)
            ToastManager.shared.show(String.localized("Source Imported!"), type: .success)
        } catch {
            ToastManager.shared.show(String.localized("Failed to import JSON: \(error.localizedDescription)"), type: .error)
        }
    }

    private func saveCurrentToSavedSources(withName name: String) {
        let source = constructSource()
        var currentSaved = savedSources
        let newSaved = SavedRepoSource(name: name, source: source)

        if let index = currentSaved.firstIndex(where: { $0.source.identifier == source.identifier }) {
            currentSaved[index] = newSaved
        } else {
            currentSaved.insert(newSaved, at: 0)
        }

        savedSources = currentSaved
        ToastManager.shared.show(String.localized("Source saved!"), type: .success)
    }

    private func deleteSavedSource(_ saved: SavedRepoSource) {
        var currentSaved = savedSources
        currentSaved.removeAll(where: { $0.id == saved.id })
        savedSources = currentSaved
    }
}

extension View {
    @ViewBuilder
    func repoFileExporter(isPresented: Binding<Bool>, item: SourceDocument?, repoName: String) -> some View {
        if #available(iOS 17.0, *) {
            self.fileExporter(
                isPresented: isPresented,
                item: item,
                contentTypes: [.json],
                defaultFilename: "\(repoName.isEmpty ? "repo" : repoName).json"
            ) { result in
                switch result {
                case .success(let url):
                    ToastManager.shared.show(String.localized("Saved To \(url.lastPathComponent)"), type: .success)
                case .failure(let error):
                    ToastManager.shared.show(String.localized("Failed to export: \(error.localizedDescription)"), type: .error)
                }
            }
        } else {
            self.fileExporter(
                isPresented: isPresented,
                document: item,
                contentType: .json,
                defaultFilename: "\(repoName.isEmpty ? "repo" : repoName).json"
            ) { result in
                switch result {
                case .success(let url):
                    ToastManager.shared.show(String.localized("Saved to \(url.lastPathComponent)"), type: .success)
                case .failure(let error):
                    ToastManager.shared.show(String.localized("Failed to export: \(error.localizedDescription)"), type: .error)
                }
            }
        }
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    var value: String
}

struct AddRepoAppView: View {
    @Environment(\.dismiss) var dismiss
    @State private var app: RepoApp
    @State private var converterValue: String = ""
    @State private var converterUnit: String = "MB"
    @State private var editableScreenshots: [IdentifiableURL]
    @State private var versionDateValue: Date = Date()
    var onAdd: (RepoApp) -> Void

    init(app: RepoApp = RepoApp(), onAdd: @escaping (RepoApp) -> Void) {
        self._app = State(initialValue: app)
        self._editableScreenshots = State(initialValue: app.screenshots.map { IdentifiableURL(value: $0) })

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: app.versionDate) {
            self._versionDateValue = State(initialValue: date)
        } else {
            self._versionDateValue = State(initialValue: Date())
        }

        self.onAdd = onAdd
    }

    private func applyConversion() {
        guard let value = Double(converterValue) else { return }
        let bytes: Int64
        if converterUnit == "MB" {
            bytes = Int64(value * 1024 * 1024)
        } else {
            bytes = Int64(value * 1024 * 1024 * 1024)
        }
        app.size = String(bytes)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text(String.localized("Size Converter"))) {
                    HStack(spacing: 12) {
                        Image(systemName: "scalemass")
                            .foregroundStyle(.blue)

                        TextField(String.localized("Value"), text: $converterValue)
                            .keyboardType(.decimalPad)

                        Picker("", selection: $converterUnit) {
                            Text("MB").tag("MB")
                            Text("GB").tag("GB")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        Button(String.localized("Apply")) {
                            applyConversion()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }

                    if !app.size.isEmpty && app.size != "0" {
                        Text(String.localized("Result: \(app.size) Bytes"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Label(String.localized("App Details"), systemImage: "app.badge.fill")) {
                    HStack {
                        Image(systemName: "app")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("App Name"), text: $app.name)
                    }
                    HStack {
                        Image(systemName: "id.badge.plus")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Bundle ID"), text: $app.bundleIdentifier)
                    }
                    HStack {
                        Image(systemName: "person")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Developer Name"), text: $app.developerName)
                    }
                    HStack {
                        Image(systemName: "text.alignleft")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Subtitle"), text: $app.subtitle)
                    }
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Category"), text: $app.category)
                    }
                    HStack {
                        Image(systemName: "number")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Version"), text: $app.version)
                    }

                    DatePicker(String.localized("Version Date"), selection: $versionDateValue, displayedComponents: .date)
                        .onChange(of: versionDateValue) { newValue in
                            let formatter = DateFormatter()
                            formatter.dateFormat = "yyyy-MM-dd"
                            app.versionDate = formatter.string(from: newValue)
                        }

                    TextField(String.localized("Size (Bytes)"), text: $app.size)
                        .keyboardType(.numberPad)

                    Toggle(String.localized("Is Beta"), isOn: $app.beta)

                    Stepper(value: $app.type, in: 1...10) {
                        HStack {
                            Text(String.localized("Type"))
                            Spacer()
                            Text("\(app.type)")
                        }
                    }
                }

                Section(header: Label(String.localized("Content & Media"), systemImage: "photo.on.rectangle.fill")) {
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Icon URL"), text: $app.iconURL)
                    }
                    HStack {
                        Image(systemName: "link")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("Download URL (.ipa)"), text: $app.downloadURL)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(String.localized("Screenshots"), systemImage: "photo.on.rectangle.angled")
                                .font(.subheadline)
                                .bold()

                            Spacer()

                            Button {
                                withAnimation {
                                    editableScreenshots.append(IdentifiableURL(value: ""))
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                            }
                        }

                        ForEach($editableScreenshots) { $item in
                            HStack(spacing: 12) {
                                TextField(String.localized("https://..."), text: $item.value)
                                    .textFieldStyle(.plain)
                                    .font(.subheadline)

                                Button(role: .destructive) {
                                    withAnimation {
                                        if let index = editableScreenshots.firstIndex(where: { $0.id == item.id }) {
                                            editableScreenshots.remove(at: index)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section(header: Label(String.localized("Descriptions"), systemImage: "text.justify.left")) {
                    VStack(alignment: .leading) {
                        Label(String.localized("Version Description"), systemImage: "text.badge.plus")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $app.versionDescription)
                            .frame(minHeight: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading) {
                        Label(String.localized("Localized Description"), systemImage: "text.alignleft")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $app.localizedDescription)
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Label(String.localized("News / Changelog"), systemImage: "newspaper.fill")) {
                    HStack {
                        Image(systemName: "newspaper")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("News Title"), text: $app.newsTitle)
                    }
                    HStack {
                        Image(systemName: "text.bubble")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("News Content"), text: $app.newsCaption)
                    }
                    HStack {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField(String.localized("News Image URL"), text: $app.newsImageURL)
                    }
                }
            }
            .navigationTitle(String.localized("Add App"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(String.localized("Cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String.localized("Add")) {
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        app.versionDate = formatter.string(from: versionDateValue)

                        app.screenshots = editableScreenshots.map { $0.value }.filter { !$0.isEmpty }
                        onAdd(app)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct RepoBuilderGuideView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    guideSection(
                        title: String.localized("What is each slot for?"),
                        content: [
                            String.localized("• Source Name: The display name of your repository."),
                            String.localized("• Source Identifier: A unique ID (e.g., com.example.repo)."),
                            String.localized("• Source URL: The direct URL to your JSON file."),
                            String.localized("• Icon URL: A link to a square image (PNG/JPG)."),
                            String.localized("• Website/Subtitle: Optional metadata for your repository."),
                            String.localized("• App Name: The name of the application."),
                            String.localized("• Bundle ID: The unique identifier of the app (e.g., com.apple.Stocks)."),
                            String.localized("• News: What's new in this specific version. This will also appear in the global news section."),
                            String.localized("• Size: The size of the IPA file in bytes."),
                            String.localized("• Version Date: The release date of the version (YYYY-MM-DD)."),
                            String.localized("• Type: The app type (usually 1 for normal apps)."),
                            String.localized("• Is Beta: Mark this app as a beta version."),
                            String.localized("• Screenshots: Add links to images showing your app. Put each link on a new line.")
                        ]
                    )

                    guideSection(
                        title: String.localized("AltSource vs Other Source"),
                        content: [
                            String.localized("• Other Sources: Includes extra 'META' information used by Feather, ESign and other signers for better repository identification."),
                            String.localized("• AltSource: A pure AltStore-compatible format that works with AltStore, SideStore, and other similar installers without any extra fields.")
                        ]
                    )

                    guideSection(
                        title: String.localized("How to host the repository?"),
                        content: [
                            String.localized("1. Generate the JSON using this tool."),
                            String.localized("2. Create a new repository on GitHub (or use GitHub Pages)."),
                            String.localized("3. Upload the generated JSON (e.g., as 'repo.json')."),
                            String.localized("4. Click on the file, then click 'Raw' to get the direct link."),
                            String.localized("5. This Raw link is what users will add as a Source."),
                            String.localized("6. You can share this link to others or add it here on Portal or diffrent signers."),
                            String.localized("TIP: You can also use services like Vercel or Netlify.")
                        ]
                    )

                    guideSection(
                        title: String.localized("Common Mistakes"),
                        content: [
                            String.localized("• Invalid URLs: Make sure all URLs start with https:// and point directly to the .ipa file."),
                            String.localized("• Bundle ID Mismatch: If the Bundle ID doesn't match the IPA, some installers might fail to show the icon."),
                            String.localized("• Size: Always use bytes for the size (e.g., 1048576 for 1MB). Use the converter feature on the Add App view to help with this.")
                        ]
                    )
                }
                .padding()
            }
            .navigationTitle(String.localized("Guide"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(String.localized("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func guideSection(title: String, content: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .bold()

            ForEach(content, id: \.self) { line in
                Text(line)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
