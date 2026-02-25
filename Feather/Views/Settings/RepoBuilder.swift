import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

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

struct RepoSource: Codable {
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

struct SourceDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var json: String

    init(json: String = "{}") {
        self.json = json
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            json = String(data: data, encoding: .utf8) ?? "{}"
        } else {
            json = "{}"
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = json.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

struct RepoBuilder: View {
    @State private var repoName = ""
    @State private var repoIdentifier = ""
    @State private var sourceURL = ""
    @State private var iconURL = ""
    @State private var website = ""
    @State private var subtitle = ""
    @State private var description = ""
    @State private var isAltSource = false
    @State private var apps: [RepoApp] = []

    @State private var showingAddApp = false
    @State private var showingGuide = false

    @State private var generatedJSON = ""
    @State private var showGeneratedSource = false
    @State private var isImportingJSON = false
    @State private var isExportingJSON = false
    @State private var showingSuccessAlert = false

    var body: some View {
        NBNavigationView(String.localized("Repository Builder")) {
            Form {
                Section(header: Text(String.localized("Source Information"))) {
                    TextField(String.localized("Source Name"), text: $repoName)
                    TextField(String.localized("Source Identifier"), text: $repoIdentifier)
                    TextField(String.localized("Source URL"), text: $sourceURL)
                    TextField(String.localized("Icon URL"), text: $iconURL)
                    TextField(String.localized("Website (Optional)"), text: $website)
                    TextField(String.localized("Subtitle (Optional)"), text: $subtitle)
                    TextField(String.localized("Description (Optional)"), text: $description)

                    Toggle(isOn: $isAltSource) {
                        VStack(alignment: .leading) {
                            Text(String.localized("Create AltSource"))
                                .bold()
                            Text(String.localized("Generate a standard AltStore compatible source without Feather metadata."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section(header: Text(String.localized("Apps (\(apps.count))"))) {
                    ForEach(apps) { app in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name)
                                .font(.headline)
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundStyle(.secondary)
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

                if showGeneratedSource && !generatedJSON.isEmpty {
                    Section(header: Text(String.localized("New Source"))) {
                        TextEditor(text: .constant(generatedJSON))
                            .frame(minHeight: 200)
                            .font(.system(.caption, design: .monospaced))

                        Button {
                            UIPasteboard.general.string = generatedJSON
                            ToastManager.shared.show(String.localized("Copied to clipboard!"), type: .success)
                        } label: {
                            Label(String.localized("Copy JSON"), systemImage: "doc.on.clipboard")
                        }
                    }
                }

                Section {
                    Button {
                        isImportingJSON = true
                    } label: {
                        Label(String.localized("Import JSON"), systemImage: "square.and.arrow.down")
                    }

                    if !generatedJSON.isEmpty {
                        Button {
                            isExportingJSON = true
                        } label: {
                            Label(String.localized("Save JSON"), systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingGuide = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddApp) {
                AddRepoAppView { newApp in
                    apps.append(newApp)
                }
            }
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
            .sheet(isPresented: $isImportingJSON) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.json],
                    allowsMultipleSelection: false,
                    onDocumentsPicked: { urls in
                        if let url = urls.first {
                            importJSON(from: url)
                        }
                    }
                )
                .ignoresSafeArea()
            }
            .fileExporter(
                isPresented: $isExportingJSON,
                document: SourceDocument(json: generatedJSON),
                contentType: .json,
                defaultFilename: "repo.json"
            ) { result in
                switch result {
                case .success(let url):
                    ToastManager.shared.show(String.localized("Saved to \(url.lastPathComponent)"), type: .success)
                case .failure(let error):
                    ToastManager.shared.show(String.localized("Failed to save: \(error.localizedDescription)"), type: .error)
                }
            }
        }
    }

    private func importJSON(from url: URL) {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let data = try Data(contentsOf: url)
            let source = try JSONDecoder().decode(RepoSource.self, from: data)

            repoName = source.name
            repoIdentifier = source.identifier
            sourceURL = source.sourceURL
            iconURL = source.iconURL
            website = source.website
            subtitle = source.subtitle
            description = source.description
            apps = source.apps
            isAltSource = source.isAltSource

            ToastManager.shared.show(String.localized("Source JSON imported successfully!"), type: .success)
            HapticsManager.shared.success()
        } catch {
            print("Import error: \(error)")
            ToastManager.shared.show(String.localized("Failed to import JSON: \(error.localizedDescription)"), type: .error)
        }
    }

    private func generateSource() {
        var allNews: [RepoNews] = []

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
                allNews.append(newsItem)
            }
        }

        let source = RepoSource(
            name: repoName,
            identifier: repoIdentifier,
            sourceURL: sourceURL,
            iconURL: iconURL,
            website: website,
            subtitle: subtitle,
            description: description,
            apps: apps,
            news: allNews,
            isAltSource: isAltSource
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]

        do {
            let data = try encoder.encode(source)
            if let jsonString = String(data: data, encoding: .utf8) {
                generatedJSON = jsonString
                UIPasteboard.general.string = jsonString
                showGeneratedSource = true
                showingSuccessAlert = true
                ToastManager.shared.show(String.localized("Source JSON copied to clipboard!"), type: .success)
                HapticsManager.shared.success()
            }
        } catch {
            print("Encoding error: \(error)")
            ToastManager.shared.show(String.localized("Failed to generate JSON: \(error.localizedDescription)"), type: .error)
        }
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    var value: String
}

struct AddRepoAppView: View {
    @Environment(\.dismiss) var dismiss
    @State private var app = RepoApp()
    @State private var converterValue: String = ""
    @State private var converterUnit: String = "MB"
    @State private var editableScreenshots: [IdentifiableURL] = []
    var onAdd: (RepoApp) -> Void

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
                    HStack {
                        TextField(String.localized("Value"), text: $converterValue)
                            .keyboardType(.decimalPad)

                        Picker("", selection: $converterUnit) {
                            Text("MB").tag("MB")
                            Text("GB").tag("GB")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)

                        Button(String.localized("Apply")) {
                            applyConversion()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Text(String.localized("Result: \(app.size) bytes"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(header: Text(String.localized("App Details"))) {
                    TextField(String.localized("App Name"), text: $app.name)
                    TextField(String.localized("Bundle ID"), text: $app.bundleIdentifier)
                    TextField(String.localized("Developer Name"), text: $app.developerName)
                    TextField(String.localized("Subtitle"), text: $app.subtitle)
                    TextField(String.localized("Category"), text: $app.category)
                    TextField(String.localized("Version"), text: $app.version)
                    TextField(String.localized("Version Date (YYYY-MM-DD)"), text: $app.versionDate)
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

                Section(header: Text(String.localized("Content & Media"))) {
                    TextField(String.localized("Icon URL"), text: $app.iconURL)
                    TextField(String.localized("Download URL (.ipa)"), text: $app.downloadURL)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String.localized("Screenshots URLs"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                editableScreenshots.append(IdentifiableURL(value: ""))
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }

                        ForEach($editableScreenshots) { $item in
                            HStack {
                                TextField(String.localized("URL"), text: $item.value)

                                Button(role: .destructive) {
                                    if let index = editableScreenshots.firstIndex(where: { $0.id == item.id }) {
                                        editableScreenshots.remove(at: index)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text(String.localized("Descriptions"))) {
                    VStack(alignment: .leading) {
                        Text(String.localized("Version Description"))
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
                        Text(String.localized("Localized Description"))
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

                Section(header: Text(String.localized("News / Changelog"))) {
                    TextField(String.localized("News Title"), text: $app.newsTitle)
                    TextField(String.localized("News Content"), text: $app.newsCaption)
                    TextField(String.localized("News Image URL"), text: $app.newsImageURL)
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
                        title: String.localized("AltSource vs Feather Source"),
                        content: [
                            String.localized("• Feather Source: Includes extra 'META' information used by Feather and E-Sign for better repository identification."),
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
                            String.localized("TIP: You can also use services like Vercel, Netlify, or even a Discord message link (though less recommended).")
                        ]
                    )

                    guideSection(
                        title: String.localized("Common Mistakes"),
                        content: [
                            String.localized("• Invalid URLs: Make sure all URLs start with https:// and point directly to the file."),
                            String.localized("• Bundle ID Mismatch: If the Bundle ID doesn't match the IPA, some installers might fail to show the icon."),
                            String.localized("• Size: Always use bytes for the size (e.g., 1048576 for 1MB).")
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
