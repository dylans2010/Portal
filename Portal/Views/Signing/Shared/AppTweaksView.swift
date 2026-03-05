import SwiftUI
import NimbleViews
import ZsignSwift
import Zip

// MARK: - App Tweaks View
struct AppTweaksView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var app: AppInfoPresentable
    @Binding var options: Options

    @State private var showExtractView = false
    @State private var showAddUrlView = false
    @State private var searchText = ""

    // Data
    @State private var dylibs: [String] = []
    @State private var frameworks: [String] = []
    @State private var bundles: [String] = []

    var body: some View {
        NavigationStack {
            List {
                overviewSection
                injectionSection
                componentsSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(String.localized("App Tweaks"))
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: String.localized("Search Tweaks"))
            .toolbar { toolbarContent }
            .onAppear {
                loadData()
            }
            .sheet(isPresented: $showExtractView) {
                ExtractTweaksView(app: app, frameworks: frameworks, bundles: bundles, dylibs: dylibs)
            }
            .sheet(isPresented: $showAddUrlView) {
                AddTweakUrlView { url in
                    options.injectionFiles.append(url)
                    HapticsManager.shared.success()
                }
            }
        }
    }

    private var overviewSection: some View {
        Section {
            HStack {
                Label(String.localized("Frameworks"), systemImage: "cube.box.fill")
                    .foregroundStyle(.blue)
                Spacer()
                Text("\(frameworks.count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label(String.localized("Bundles"), systemImage: "shippingbox.fill")
                    .foregroundStyle(.purple)
                Spacer()
                Text("\(bundles.count)")
                    .foregroundStyle(.secondary)
            }
            HStack {
                Label(String.localized("Dylibs"), systemImage: "puzzlepiece.fill")
                    .foregroundStyle(.orange)
                Spacer()
                Text("\(dylibs.count)")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text(String.localized("Overview"))
        }
    }

    private var injectionSection: some View {
        Section {
            if options.injectionFiles.isEmpty {
                Button {
                    showAddUrlView = true
                } label: {
                    Label(String.localized("Add Custom Tweaks"), systemImage: "plus.circle")
                }
            } else {
                ForEach(options.injectionFiles, id: \.self) { url in
                    HStack {
                        Label(url.lastPathComponent, systemImage: "syringe.fill")
                            .foregroundStyle(.green)
                        Spacer()
                        Button(role: .destructive) {
                            withAnimation {
                                options.injectionFiles.removeAll { $0 == url }
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onDelete { indexSet in
                    options.injectionFiles.remove(atOffsets: indexSet)
                }
            }
        } header: {
            Text(String.localized("Injection Queue"))
        }
    }

    private var componentsSection: some View {
        Section {
            DisclosureGroup {
                componentList(items: frameworks, prefix: "Frameworks/", optionsKey: "removeFiles")
            } label: {
                Label(String.localized("Frameworks"), systemImage: "cube.fill")
                    .foregroundStyle(.blue)
            }

            DisclosureGroup {
                componentList(items: bundles, prefix: "PlugIns/", optionsKey: "removeFiles")
            } label: {
                Label(String.localized("Bundles & Extensions"), systemImage: "shippingbox.fill")
                    .foregroundStyle(.purple)
            }

            DisclosureGroup {
                componentList(items: dylibs, prefix: "", optionsKey: "disInjectionFiles")
            } label: {
                Label(String.localized("Dylibs"), systemImage: "puzzlepiece.fill")
                    .foregroundStyle(.orange)
            }
        } header: {
            Text(String.localized("Components"))
        }
    }

    @ViewBuilder
    private func componentList(items: [String], prefix: String, optionsKey: String) -> some View {
        let filteredItems = searchText.isEmpty ? items : items.filter { $0.localizedCaseInsensitiveContains(searchText) }

        if filteredItems.isEmpty {
            Text(String.localized("No Items Found"))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            ForEach(filteredItems, id: \.self) { item in
                let fullPath = prefix.isEmpty ? item : "\(prefix)\(item)"
                let isEnabled = optionsKey == "removeFiles" ? !options.removeFiles.contains(fullPath) : !options.disInjectionFiles.contains(fullPath)

                HStack {
                    Button {
                        toggleComponent(fullPath, key: optionsKey)
                    } label: {
                        Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(isEnabled ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text(item)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    Menu {
                        Button(role: .destructive) {
                            removeComponent(item, from: prefix, key: optionsKey)
                        } label: {
                            Label(String.localized("Remove From List"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showAddUrlView = true
                } label: {
                    Label(String.localized("Add From URL"), systemImage: "link")
                }

                Button {
                    showExtractView = true
                } label: {
                    Label(String.localized("Extract Components"), systemImage: "arrow.up.doc")
                }

                Divider()

                Button {
                    enableAll()
                } label: {
                    Label(String.localized("Enable All"), systemImage: "checkmark.circle")
                }

                Button {
                    disableAll()
                } label: {
                    Label(String.localized("Disable All"), systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
            }
        }
    }

    // Actions
    private func loadData() {
        guard let path = Storage.shared.getAppDirectory(for: app) else { return }
        frameworks = (try? FileManager.default.contentsOfDirectory(atPath: path.appendingPathComponent("Frameworks").path)) ?? []
        bundles = (try? FileManager.default.contentsOfDirectory(atPath: path.appendingPathComponent("PlugIns").path)) ?? []

        // Load dylibs
        let bundle = Bundle(url: path)
        let execPath = path.appendingPathComponent(bundle?.exec ?? "").relativePath
        let allDylibs = Zsign.listDylibs(appExecutable: execPath).map { $0 as String }
        dylibs = allDylibs.filter { $0.hasPrefix("@rpath") || $0.hasPrefix("@executable_path") }
    }

    private func toggleComponent(_ path: String, key: String) {
        withAnimation {
            if key == "removeFiles" {
                if let index = options.removeFiles.firstIndex(of: path) {
                    options.removeFiles.remove(at: index)
                } else {
                    options.removeFiles.append(path)
                }
            } else {
                if let index = options.disInjectionFiles.firstIndex(of: path) {
                    options.disInjectionFiles.remove(at: index)
                } else {
                    options.disInjectionFiles.append(path)
                }
            }
        }
        HapticsManager.shared.impact()
    }

    private func removeComponent(_ item: String, from prefix: String, key: String) {
        if prefix == "Frameworks/" {
            frameworks.removeAll { $0 == item }
        } else if prefix == "PlugIns/" {
            bundles.removeAll { $0 == item }
        } else {
            dylibs.removeAll { $0 == item }
        }

        let fullPath = prefix.isEmpty ? item : "\(prefix)\(item)"
        if key == "removeFiles" {
            if let index = options.removeFiles.firstIndex(of: fullPath) {
                options.removeFiles.remove(at: index)
            }
        } else {
            if let index = options.disInjectionFiles.firstIndex(of: fullPath) {
                options.disInjectionFiles.remove(at: index)
            }
        }
        HapticsManager.shared.success()
    }

    private func enableAll() {
        withAnimation {
            options.removeFiles.removeAll { path in
                frameworks.contains { path.contains($0) } || bundles.contains { path.contains($0) }
            }
            options.disInjectionFiles.removeAll { path in
                dylibs.contains { path.contains($0) }
            }
        }
        HapticsManager.shared.success()
    }

    private func disableAll() {
        withAnimation {
            for f in frameworks {
                let p = "Frameworks/\(f)"
                if !options.removeFiles.contains(p) { options.removeFiles.append(p) }
            }
            for b in bundles {
                let p = "PlugIns/\(b)"
                if !options.removeFiles.contains(p) { options.removeFiles.append(p) }
            }
            for d in dylibs {
                if !options.disInjectionFiles.contains(d) { options.disInjectionFiles.append(d) }
            }
        }
        HapticsManager.shared.success()
    }
}

// MARK: - Add Tweak URL View
struct AddTweakUrlView: View {
    @Environment(\.dismiss) var dismiss
    @State private var urlString = ""
    let onAdd: (URL) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/tweak.dylib", text: $urlString)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(String.localized("Enter Tweak URL"))
                } footer: {
                    Text(String.localized("Support for .dylib, .deb, and .framework (zip)."))
                }

                Button {
                    if let url = URL(string: urlString) {
                        onAdd(url)
                        dismiss()
                    }
                } label: {
                    Text(String.localized("Add Tweak"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(urlString.isEmpty || URL(string: urlString) == nil)
            }
            .navigationTitle(String.localized("Add From URL"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String.localized("Cancel")) { dismiss() }
                }
            }
        }
        .presentationDetents([.height(250)])
    }
}

// MARK: - Extract Tweaks View
struct ExtractTweaksView: View {
    @Environment(\.dismiss) var dismiss

    var app: AppInfoPresentable
    var frameworks: [String]
    var bundles: [String]
    var dylibs: [String]

    @State private var selectedFrameworks = Set<String>()
    @State private var selectedBundles = Set<String>()
    @State private var selectedDylibs = Set<String>()
    @State private var isExtracting = false
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                if isExtracting {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text(String.localized("Extracting Components..."))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    List {
                        if !frameworks.isEmpty {
                            Section(String.localized("Frameworks")) {
                                ForEach(frameworks, id: \.self) { item in
                                    Toggle(item, isOn: Binding(
                                        get: { selectedFrameworks.contains(item) },
                                        set: { if $0 { selectedFrameworks.insert(item) } else { selectedFrameworks.remove(item) } }
                                    ))
                                }
                            }
                        }

                        if !bundles.isEmpty {
                            Section(String.localized("Bundles")) {
                                ForEach(bundles, id: \.self) { item in
                                    Toggle(item, isOn: Binding(
                                        get: { selectedBundles.contains(item) },
                                        set: { if $0 { selectedBundles.insert(item) } else { selectedBundles.remove(item) } }
                                    ))
                                }
                            }
                        }

                        if !dylibs.isEmpty {
                            Section(String.localized("Dylibs")) {
                                ForEach(dylibs, id: \.self) { item in
                                    Toggle(item, isOn: Binding(
                                        get: { selectedDylibs.contains(item) },
                                        set: { if $0 { selectedDylibs.insert(item) } else { selectedDylibs.remove(item) } }
                                    ))
                                }
                            }
                        }
                    }

                    VStack {
                        Spacer()
                        Button {
                            performExtract()
                        } label: {
                            Text(String.localized("Extract Selected"))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding()
                        .disabled(selectedFrameworks.isEmpty && selectedBundles.isEmpty && selectedDylibs.isEmpty)
                    }
                }
            }
            .navigationTitle(String.localized("Extract Tweaks"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String.localized("Cancel")) { dismiss() }
                }
            }
            .alert(String.localized("Success"), isPresented: $showSuccessAlert) {
                Button(String.localized("OK")) { dismiss() }
            } message: {
                Text(String.localized("Tweaks extracted to Portal's Documents directory."))
            }
        }
    }

    private func performExtract() {
        isExtracting = true

        Task {
            do {
                guard let appPath = Storage.shared.getAppDirectory(for: app) else {
                    throw NSError(domain: "ExtractTweaks", code: -1, userInfo: [NSLocalizedDescriptionKey: "App Directory Not Found"])
                }

                // Create temporary directory for extraction
                let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

                // Copy selected frameworks
                if !selectedFrameworks.isEmpty {
                    let frameworksDir = tempDir.appendingPathComponent("Frameworks")
                    try FileManager.default.createDirectory(at: frameworksDir, withIntermediateDirectories: true)

                    for framework in selectedFrameworks {
                        let source = appPath.appendingPathComponent("Frameworks").appendingPathComponent(framework)
                        let dest = frameworksDir.appendingPathComponent(framework)
                        try FileManager.default.copyItem(at: source, to: dest)
                    }
                }

                // Copy selected bundles
                if !selectedBundles.isEmpty {
                    let bundlesDir = tempDir.appendingPathComponent("Plugins")
                    try FileManager.default.createDirectory(at: bundlesDir, withIntermediateDirectories: true)

                    for bundle in selectedBundles {
                        let source = appPath.appendingPathComponent("Plugins").appendingPathComponent(bundle)
                        let dest = bundlesDir.appendingPathComponent(bundle)
                        try FileManager.default.copyItem(at: source, to: dest)
                    }
                }

                // Copy selected dylibs
                if !selectedDylibs.isEmpty {
                    let dylibsDir = tempDir.appendingPathComponent("Dylibs")
                    try FileManager.default.createDirectory(at: dylibsDir, withIntermediateDirectories: true)

                    for dylibPath in selectedDylibs {
                        let actualName = dylibPath.components(separatedBy: "/").last ?? dylibPath

                        let possibleSources = [
                            appPath.appendingPathComponent(actualName),
                            appPath.appendingPathComponent("Frameworks").appendingPathComponent(actualName)
                        ]

                        var copied = false
                        for source in possibleSources {
                            if FileManager.default.fileExists(atPath: source.path) {
                                let dest = dylibsDir.appendingPathComponent(actualName)
                                try FileManager.default.copyItem(at: source, to: dest)
                                copied = true
                                break
                            }
                        }

                        if !copied {
                            print("Could not find dylib file for: \(dylibPath)")
                        }
                    }
                }

                // Create zip file in Documents directory
                let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let zipFileName = "ExtractedAppTweaks_\(Int(Date().timeIntervalSince1970)).zip"
                let zipURL = documentsDir.appendingPathComponent(zipFileName)

                // Create zip
                try Zip.zipFiles(paths: [tempDir], zipFilePath: zipURL, password: nil, progress: nil)

                // Clean up temp directory
                try? FileManager.default.removeItem(at: tempDir)

                await MainActor.run {
                    isExtracting = false
                    showSuccessAlert = true
                    HapticsManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    isExtracting = false
                    HapticsManager.shared.error()
                    UIAlertController.showAlertWithOk(
                        title: String.localized("Error"),
                        message: String.localized("Failed to extract tweaks: \(error.localizedDescription)")
                    )
                }
            }
        }
    }
}
