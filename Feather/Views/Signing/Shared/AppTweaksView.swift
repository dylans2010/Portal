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

    @State private var selectedTab = 0
    @State private var expandedFrameworks = false
    @State private var expandedBundles = false
    @State private var expandedDylibs = false
    @State private var showExtractView = false
    @State private var showAddUrlView = false
    @State private var searchText = ""
    @FocusState private var searchFieldFocused: Bool

    @State private var floatingAnimation = false
    @State private var appearAnimation = false

    // Data
    @State private var dylibs: [String] = []
    @State private var frameworks: [String] = []
    @State private var bundles: [String] = []

    var body: some View {
        NavigationStack {
            ZStack {
                modernBackground

                VStack(spacing: 0) {
                    headerSection
                    searchBar
                    mainContent
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .onAppear {
                loadData()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appearAnimation = true
                }
            }
            .sheet(isPresented: $showExtractView) {
                ExtractTweaksView(app: app, frameworks: frameworks, bundles: bundles)
            }
            .sheet(isPresented: $showAddUrlView) {
                AddTweakUrlView { url in
                    options.injectionFiles.append(url)
                    HapticsManager.shared.success()
                }
            }
        }
    }

    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.purple.opacity(0.04),
                    Color(UIColor.systemBackground).opacity(0.95),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: floatingAnimation ? -30 : 30, y: floatingAnimation ? -20 : 20)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.1)

                Circle()
                    .fill(Color.purple.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: floatingAnimation ? 20 : -20, y: floatingAnimation ? 15 : -15)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.8)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                floatingAnimation = true
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)

                Image(systemName: "cube.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(appearAnimation ? 1 : 0.5)
            .opacity(appearAnimation ? 1 : 0)

            VStack(spacing: 4) {
                Text("App Tweaks")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("\(frameworks.count + bundles.count + dylibs.count) Components Found")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .opacity(appearAnimation ? 1 : 0)
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("Search Tweaks", text: $searchText)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)
                    .focused($searchFieldFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchFieldFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overview
                overviewSection

                // Active Injection
                injectionSection

                // Components
                componentsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Overview")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
            }
            .padding(.leading, 4)

            HStack(spacing: 12) {
                statCard(title: "Frameworks", value: "\(frameworks.count)", icon: "cube.box.fill", color: .blue)
                statCard(title: "Bundles", value: "\(bundles.count)", icon: "shippingbox.fill", color: .purple)
                statCard(title: "Dylibs", value: "\(dylibs.count)", icon: "puzzlepiece.fill", color: .orange)
            }
        }
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.03), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var injectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Injection Queue")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
                Spacer()
                Text("\(options.injectionFiles.count) Files")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)

            if options.injectionFiles.isEmpty {
                Button {
                    showAddUrlView = true
                } label: {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("Tap To Add Custom Tweaks")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 24)
                        Spacer()
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.black.opacity(0.03), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 1) {
                    ForEach(options.injectionFiles, id: \.self) { url in
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.green.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "syringe.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.green)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                    .font(.system(size: 14, weight: .medium))
                                    .lineLimit(1)
                                Text(url.scheme == "http" || url.scheme == "https" ? "Remote URL" : "Local File")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                withAnimation {
                                    options.injectionFiles.removeAll { $0 == url }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
            }
        }
    }

    @ViewBuilder
    private var componentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Components")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 2) {
                // Frameworks
                componentGroupRow(
                    title: "Frameworks",
                    count: frameworks.count,
                    icon: "cube.fill",
                    color: .blue,
                    isExpanded: $expandedFrameworks
                )

                if expandedFrameworks {
                    componentList(items: frameworks, prefix: "Frameworks/", optionsKey: "removeFiles")
                }

                Divider().padding(.leading, 56)

                // Bundles
                componentGroupRow(
                    title: "Bundles & Extensions",
                    count: bundles.count,
                    icon: "shippingbox.fill",
                    color: .purple,
                    isExpanded: $expandedBundles
                )

                if expandedBundles {
                    componentList(items: bundles, prefix: "PlugIns/", optionsKey: "removeFiles")
                }

                Divider().padding(.leading, 56)

                // Dylibs
                componentGroupRow(
                    title: "Dylibs",
                    count: dylibs.count,
                    icon: "puzzlepiece.fill",
                    color: .orange,
                    isExpanded: $expandedDylibs
                )

                if expandedDylibs {
                    componentList(items: dylibs, prefix: "", optionsKey: "disInjectionFiles")
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.03), lineWidth: 0.5)
            )
        }
    }

    @ViewBuilder
    private func componentGroupRow(title: String, count: Int, icon: String, color: Color, isExpanded: Binding<Bool>) -> some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isExpanded.wrappedValue.toggle()
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                    Text("\(count) Items Found")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.quaternary)
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func componentList(items: [String], prefix: String, optionsKey: String) -> some View {
        let filteredItems = searchText.isEmpty ? items : items.filter { $0.localizedCaseInsensitiveContains(searchText) }

        VStack(spacing: 0) {
            if filteredItems.isEmpty {
                Text("No Items Matching Search")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 16)
            } else {
                ForEach(filteredItems, id: \.self) { item in
                    let fullPath = prefix.isEmpty ? item : "\(prefix)\(item)"
                    let isEnabled = optionsKey == "removeFiles" ? !options.removeFiles.contains(fullPath) : !options.disInjectionFiles.contains(fullPath)

                    HStack(spacing: 12) {
                        Button {
                            toggleComponent(fullPath, key: optionsKey)
                        } label: {
                            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(isEnabled ? .green : .secondary)
                        }
                        .buttonStyle(.plain)

                        Text(item)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)

                        Spacer()

                        // Action menu
                        Menu {
                            Button(role: .destructive) {
                                removeComponent(item, from: prefix, key: optionsKey)
                            } label: {
                                Label("Remove From List", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundStyle(.tertiary)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.02))
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
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    showAddUrlView = true
                } label: {
                    Label("Add From URL", systemImage: "link")
                }

                Button {
                    showExtractView = true
                } label: {
                    Label("Extract Components", systemImage: "arrow.up.doc")
                }

                Divider()

                Button {
                    enableAll()
                } label: {
                    Label("Enable All", systemImage: "checkmark.circle")
                }

                Button {
                    disableAll()
                } label: {
                    Label("Disable All", systemImage: "xmark.circle")
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
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
                    Text("Enter Tweak URL")
                } footer: {
                    Text("Support for .dylib, .deb, and .framework (zip).")
                }

                Button {
                    if let url = URL(string: urlString) {
                        onAdd(url)
                        dismiss()
                    }
                } label: {
                    Text("Add Tweak")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .disabled(urlString.isEmpty || URL(string: urlString) == nil)
            }
            .navigationTitle("Add From URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
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

    @State private var selectedFrameworks = Set<String>()
    @State private var selectedBundles = Set<String>()
    @State private var isExtracting = false
    @State private var showSuccessAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    if isExtracting {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Extracting Components...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            if !frameworks.isEmpty {
                                Section("Frameworks") {
                                    ForEach(frameworks, id: \.self) { item in
                                        Toggle(item, isOn: Binding(
                                            get: { selectedFrameworks.contains(item) },
                                            set: { if $0 { selectedFrameworks.insert(item) } else { selectedFrameworks.remove(item) } }
                                        ))
                                    }
                                }
                            }

                            if !bundles.isEmpty {
                                Section("Bundles") {
                                    ForEach(bundles, id: \.self) { item in
                                        Toggle(item, isOn: Binding(
                                            get: { selectedBundles.contains(item) },
                                            set: { if $0 { selectedBundles.insert(item) } else { selectedBundles.remove(item) } }
                                        ))
                                    }
                                }
                            }
                        }

                        Button {
                            performExtract()
                        } label: {
                            Text("Extract Selected")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(20)
                        .disabled(selectedFrameworks.isEmpty && selectedBundles.isEmpty)
                    }
                }
            }
            .navigationTitle("Extract Tweaks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Tweaks extracted to Documents directory.")
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

                // Create zip file in Documents directory
                let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let zipFileName = "ExtractedTweaks_\(Date().timeIntervalSince1970).zip"
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
                        title: "Error",
                        message: "Failed to extract tweaks: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
}
