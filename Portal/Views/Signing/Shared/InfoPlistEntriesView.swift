import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

struct InfoPlistEntriesView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var options: Options
    
    @State private var editingKey: String?
    @State private var showAddEntryDialog = false
    @State private var showImportSheet = false
    @State private var showPresetSheet = false
    @State private var showEditSheet = false
    @State private var showSearchReplaceSheet = false
    @State private var searchText = ""
    @State private var searchReplaceTarget = ""
    @State private var searchReplaceNewValue = ""
    @State private var showDeleteConfirmation = false
    @State private var entryToDelete: String?
    @State private var showBatchActionsSheet = false
    @State private var selectedEntries: Set<String> = []
    @State private var isSelectionMode = false
    
    @State private var newKey = ""
    @State private var newValueType: InfoPlistValueType = .string
    @State private var newStringValue = ""
    @State private var newBoolValue = false
    @State private var newNumberValue = ""
    @State private var newArrayItems: [String] = []
    @State private var newDictItems: [String: String] = [:]
    
    @State private var editKey = ""
    @State private var editValueType: InfoPlistValueType = .string
    @State private var editStringValue = ""
    @State private var editBoolValue = false
    @State private var editNumberValue = ""
    
    enum InfoPlistValueType: String, CaseIterable {
        case string = "String"
        case boolean = "Boolean"
        case number = "Number"
        case array = "Array"
        case dictionary = "Dictionary"
        
        var icon: String {
            switch self {
            case .string: return "text.quote"
            case .boolean: return "togglepower"
            case .number: return "number"
            case .array: return "list.bullet.rectangle"
            case .dictionary: return "curlybraces"
            }
        }
        
        var color: Color {
            switch self {
            case .string: return .blue
            case .boolean: return .green
            case .number: return .orange
            case .array: return .purple
            case .dictionary: return .pink
            }
        }
    }
    
    private var filteredEntries: [(key: String, value: AnyCodable)] {
        let entries = options.customInfoPlistEntries.map { (key: $0.key, value: $0.value) }
        var result = entries
        
        if !searchText.isEmpty {
            result = result.filter { $0.key.localizedCaseInsensitiveContains(searchText) || 
                valueDescription(for: $0.value.value).localizedCaseInsensitiveContains(searchText) }
        }
        
        return result.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showPresetSheet = true
                    } label: {
                        Label(.localized("Presets"), systemImage: "sparkles")
                    }
                    
                    Button {
                        showImportSheet = true
                    } label: {
                        Label(.localized("Import from .plist"), systemImage: "square.and.arrow.down")
                    }
                    
                    Button {
                        showSearchReplaceSheet = true
                    } label: {
                        Label(.localized("Search & Replace"), systemImage: "magnifyingglass")
                    }
                    
                    Button {
                        exportPlistFile()
                    } label: {
                        Label(.localized("Export"), systemImage: "square.and.arrow.up")
                    }
                    .disabled(options.customInfoPlistEntries.isEmpty)
                    
                    if !options.customInfoPlistEntries.isEmpty {
                        Button(role: .destructive) {
                            withAnimation {
                                options.customInfoPlistEntries.removeAll()
                            }
                            HapticsManager.shared.success()
                        } label: {
                            Label(.localized("Clear All"), systemImage: "arrow.counterclockwise")
                        }
                    }
                } header: {
                    Text(.localized("Quick Actions"))
                }
                
                if filteredEntries.isEmpty {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.largeTitle)
                                    .foregroundStyle(.secondary)
                                Text(.localized("No Entries Yet"))
                                    .font(.headline)
                                Text(.localized("Add custom Info.plist entries\nto modify app behavior"))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                Button {
                                    showAddEntryDialog = true
                                } label: {
                                    Label(.localized("Add Entry"), systemImage: "plus.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 24)
                            Spacer()
                        }
                    }
                } else {
                    Section {
                        ForEach(Array(filteredEntries.enumerated()), id: \.element.key) { index, entry in
                            ModernEntryRow(
                                key: entry.key,
                                value: entry.value,
                                isFirst: index == 0,
                                isLast: index == filteredEntries.count - 1,
                                isSelected: selectedEntries.contains(entry.key),
                                isSelectionMode: isSelectionMode,
                                onTap: {
                                    if isSelectionMode {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            if selectedEntries.contains(entry.key) {
                                                selectedEntries.remove(entry.key)
                                            } else {
                                                selectedEntries.insert(entry.key)
                                            }
                                        }
                                    } else {
                                        prepareEdit(key: entry.key, value: entry.value)
                                        showEditSheet = true
                                    }
                                },
                                onToggle: entry.value.value is Bool ? { newValue in
                                    withAnimation {
                                        options.customInfoPlistEntries[entry.key] = AnyCodable(newValue)
                                    }
                                    HapticsManager.shared.softImpact()
                                } : nil,
                                onDelete: {
                                    entryToDelete = entry.key
                                    showDeleteConfirmation = true
                                },
                                onDuplicate: {
                                    duplicateEntry(key: entry.key, value: entry.value)
                                }
                            )
                        }
                    } header: {
                        HStack {
                            Text(.localized("Entries (\(filteredEntries.count))"))
                            Spacer()
                            if !options.customInfoPlistEntries.isEmpty {
                                Button {
                                    withAnimation {
                                        isSelectionMode.toggle()
                                        if !isSelectionMode {
                                            selectedEntries.removeAll()
                                        }
                                    }
                                } label: {
                                    Text(isSelectionMode ? .localized("Cancel") : .localized("Select"))
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                        }
                    }
                    
                    if isSelectionMode && !selectedEntries.isEmpty {
                        Section {
                            Button(role: .destructive) {
                                withAnimation {
                                    for key in selectedEntries {
                                        _ = options.customInfoPlistEntries.removeValue(forKey: key)
                                    }
                                    selectedEntries.removeAll()
                                    isSelectionMode = false
                                }
                                HapticsManager.shared.success()
                            } label: {
                                Label(.localized("Delete \(selectedEntries.count) Selected"), systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: .localized("Search Entries"))
            .navigationTitle(.localized("Info.plist Entries"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAddEntryDialog) { addEntrySheet }
            .sheet(isPresented: $showPresetSheet) { presetOptionsSheet }
            .sheet(isPresented: $showEditSheet) { editEntrySheet }
            .sheet(isPresented: $showBatchActionsSheet) { batchActionsSheet }
            .sheet(isPresented: $showSearchReplaceSheet) { searchReplaceSheet }
            .sheet(isPresented: $showImportSheet) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.propertyList, .xml],
                    onDocumentsPicked: { urls in
                        guard let url = urls.first else { return }
                        importPlistFile(url: url)
                    }
                )
                .ignoresSafeArea()
            }
            .confirmationDialog(.localized("Delete Entry"), isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button(.localized("Delete"), role: .destructive) {
                    if let key = entryToDelete {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            _ = options.customInfoPlistEntries.removeValue(forKey: key)
                        }
                        HapticsManager.shared.success()
                    }
                }
                Button(.localized("Cancel"), role: .cancel) { }
            } message: {
                Text(.localized("Are you sure you want to delete this entry?"))
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
            Button {
                showAddEntryDialog = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.indigo)
            }
        }
    }
    
    @ViewBuilder
    private var addEntrySheet: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Key"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                            
                            TextField(.localized("Enter Key Name"), text: $newKey)
                                .font(.system(size: 16))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.clear)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Type"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(InfoPlistValueType.allCases, id: \.self) { type in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                newValueType = type
                                            }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: type.icon)
                                                    .font(.system(size: 12, weight: .semibold))
                                                Text(type.rawValue)
                                                    .font(.system(size: 13, weight: .medium))
                                            }
                                            .foregroundStyle(newValueType == type ? .white : type.color)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(newValueType == type ? type.color : type.color.opacity(0.15))
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Value"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                            
                            valueInputView
                        }
                        
                        Button {
                            addEntry()
                        } label: {
                            Label(.localized("Add Entry"), systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newKey.isEmpty)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(.localized("Add Entry"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        showAddEntryDialog = false
                        resetForm()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private var valueInputView: some View {
        switch newValueType {
        case .string:
            TextField(.localized("Enter String Value"), text: $newStringValue)
                .font(.system(size: 16))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )
            
        case .boolean:
            HStack {
                Text(.localized("Value"))
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: $newBoolValue)
                    .labelsHidden()
                    .tint(.indigo)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
            )
            
        case .number:
            TextField(.localized("Enter Number"), text: $newNumberValue)
                .font(.system(size: 16))
                .keyboardType(.numbersAndPunctuation)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )
            
        case .array:
            VStack(spacing: 8) {
                ForEach(newArrayItems.indices, id: \.self) { index in
                    HStack {
                        TextField(.localized("Item \(index + 1)"), text: $newArrayItems[index])
                            .font(.system(size: 15))
                        
                        Button {
                            newArrayItems.remove(at: index)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.clear)
                    )
                }
                
                Button {
                    newArrayItems.append("")
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(.localized("Add Item"))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.indigo)
                    .padding(.vertical, 8)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
            )
            
        case .dictionary:
            VStack(spacing: 8) {
                Text(.localized("Dictionary entries will be created empty."))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
            )
        }
    }
    
    @ViewBuilder
    private var editEntrySheet: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Key"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                            
                            Text(editKey)
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.clear)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Value"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                            
                            editValueInputView
                        }
                        
                        Button {
                            saveEdit()
                        } label: {
                            Label(.localized("Save Changes"), systemImage: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(.localized("Edit Entry"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        showEditSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    
    @ViewBuilder
    private var editValueInputView: some View {
        switch editValueType {
        case .string:
            TextField(.localized("Enter String Value"), text: $editStringValue)
                .font(.system(size: 16))
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )
            
        case .boolean:
            HStack {
                Text(.localized("Value"))
                    .font(.system(size: 16))
                    .foregroundStyle(.primary)
                Spacer()
                Toggle("", isOn: $editBoolValue)
                    .labelsHidden()
                    .tint(.indigo)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
            )
            
        case .number:
            TextField(.localized("Enter Number"), text: $editNumberValue)
                .font(.system(size: 16))
                .keyboardType(.numbersAndPunctuation)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )
            
        default:
            Text(.localized("Complex types cannot be edited directly"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.clear)
                )
        }
    }
    
    @ViewBuilder
    private var presetOptionsSheet: some View {
        NavigationStack {
            List {
                Section {
                    PresetButton(
                        title: .localized("Custom Display Name"),
                        subtitle: .localized("Overwrite App Name"),
                        icon: "textformat"
                    ) {
                        addSimpleEntry(key: "CFBundleDisplayName", value: "New Name")
                    }

                    PresetButton(
                        title: .localized("Custom Version"),
                        subtitle: .localized("Overwrite Version String"),
                        icon: "tag"
                    ) {
                        addSimpleEntry(key: "CFBundleShortVersionString", value: "1.0.0")
                    }
                } header: {
                    Label(.localized("Essential & Identity"), systemImage: "person.text.rectangle.fill")
                }

                Section {
                    PresetButton(
                        title: .localized("Portrait Only"),
                        subtitle: .localized("Lock To Portrait Mode"),
                        icon: "rectangle.portrait.fill"
                    ) {
                        addOrientationPreset(.portrait)
                    }
                    
                    PresetButton(
                        title: .localized("Landscape Only"),
                        subtitle: .localized("Lock To Landscape Mode"),
                        icon: "rectangle.fill"
                    ) {
                        addOrientationPreset(.landscape)
                    }
                    
                    PresetButton(
                        title: .localized("All Orientations"),
                        subtitle: .localized("Allow All Rotations"),
                        icon: "rotate.3d.fill"
                    ) {
                        addOrientationPreset(.all)
                    }
                } header: {
                    Label(.localized("Orientation"), systemImage: "rotate.right.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Background Audio"),
                        subtitle: .localized("Play Audio In Background"),
                        icon: "music.note"
                    ) {
                        addBackgroundMode(.audio)
                    }
                    
                    PresetButton(
                        title: .localized("Background Location"),
                        subtitle: .localized("Access Location In Background"),
                        icon: "location.fill"
                    ) {
                        addBackgroundMode(.location)
                    }
                    
                    PresetButton(
                        title: .localized("VoIP"),
                        subtitle: .localized("Voice Over IP Support"),
                        icon: "phone.fill"
                    ) {
                        addBackgroundMode(.voip)
                    }
                    
                    PresetButton(
                        title: .localized("Background Fetch"),
                        subtitle: .localized("Fetch Content Periodically"),
                        icon: "arrow.down.circle.fill"
                    ) {
                        addBackgroundMode(.fetch)
                    }
                    
                    PresetButton(
                        title: .localized("Background Processing"),
                        subtitle: .localized("Run Background Tasks"),
                        icon: "cpu.fill"
                    ) {
                        addBackgroundMode(.processing)
                    }
                    
                    PresetButton(
                        title: .localized("Remote Notifications"),
                        subtitle: .localized("Receive Push Notifications"),
                        icon: "bell.badge.fill"
                    ) {
                        addBackgroundMode(.remoteNotification)
                    }
                } header: {
                    Label(.localized("Background Modes"), systemImage: "moon.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Require Full Screen"),
                        subtitle: .localized("Disable Multitasking"),
                        icon: "rectangle.expand.vertical"
                    ) {
                        addSimpleEntry(key: "UIRequiresFullScreen", value: true)
                    }
                    
                    PresetButton(
                        title: .localized("Hide Status Bar"),
                        subtitle: .localized("Hide The System Status Bar"),
                        icon: "eye.slash.fill"
                    ) {
                        addSimpleEntry(key: "UIStatusBarHidden", value: true)
                    }
                    
                    PresetButton(
                        title: .localized("Force Dark Mode"),
                        subtitle: .localized("Always Use Dark Appearance"),
                        icon: "moon.fill"
                    ) {
                        addSimpleEntry(key: "UIUserInterfaceStyle", value: "Dark")
                    }
                    
                    PresetButton(
                        title: .localized("Force Light Mode"),
                        subtitle: .localized("Always Use Light Appearance"),
                        icon: "sun.max.fill"
                    ) {
                        addSimpleEntry(key: "UIUserInterfaceStyle", value: "Light")
                    }
                } header: {
                    Label(.localized("Display & UI"), systemImage: "paintbrush.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("File Sharing"),
                        subtitle: .localized("Enable iTunes/Finder File Sharing"),
                        icon: "folder.fill"
                    ) {
                        addSimpleEntry(key: "UIFileSharingEnabled", value: true)
                    }
                    
                    PresetButton(
                        title: .localized("Document Browser"),
                        subtitle: .localized("Support Document Browser"),
                        icon: "doc.fill"
                    ) {
                        addSimpleEntry(key: "UISupportsDocumentBrowser", value: true)
                    }
                } header: {
                    Label(.localized("File Access"), systemImage: "folder.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Camera Usage"),
                        subtitle: .localized("Add Camera Permission"),
                        icon: "camera.fill"
                    ) {
                        addSimpleEntry(key: "NSCameraUsageDescription", value: "This app needs camera access.")
                    }
                    
                    PresetButton(
                        title: .localized("Photo Library"),
                        subtitle: .localized("Add Photo Library Permission"),
                        icon: "photo.fill"
                    ) {
                        addSimpleEntry(key: "NSPhotoLibraryUsageDescription", value: "This app needs photo library access.")
                    }
                    
                    PresetButton(
                        title: .localized("Microphone"),
                        subtitle: .localized("Add Microphone Permission"),
                        icon: "mic.fill"
                    ) {
                        addSimpleEntry(key: "NSMicrophoneUsageDescription", value: "This app needs microphone access.")
                    }
                    
                    PresetButton(
                        title: .localized("Location"),
                        subtitle: .localized("Add Location Permission"),
                        icon: "location.fill"
                    ) {
                        addSimpleEntry(key: "NSLocationWhenInUseUsageDescription", value: "This app needs location access.")
                    }
                    
                    PresetButton(
                        title: .localized("Contacts"),
                        subtitle: .localized("Add Contacts Permission"),
                        icon: "person.crop.circle.fill"
                    ) {
                        addSimpleEntry(key: "NSContactsUsageDescription", value: "This app needs contacts access.")
                    }
                    
                    PresetButton(
                        title: .localized("Face ID"),
                        subtitle: .localized("Add Face ID Permission"),
                        icon: "faceid"
                    ) {
                        addSimpleEntry(key: "NSFaceIDUsageDescription", value: "This app uses Face ID for authentication.")
                    }
                    
                    PresetButton(
                        title: .localized("Bluetooth"),
                        subtitle: .localized("Add Bluetooth Permission"),
                        icon: "antenna.radiowaves.left.and.right"
                    ) {
                        addSimpleEntry(key: "NSBluetoothAlwaysUsageDescription", value: "This app needs Bluetooth access.")
                    }
                } header: {
                    Label(.localized("Privacy Permissions"), systemImage: "hand.raised.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Add URL Scheme"),
                        subtitle: .localized("Custom Deep Linking Scheme"),
                        icon: "link.circle.fill"
                    ) {
                        addURLScheme("test-app")
                    }
                } header: {
                    Label(.localized("URL Schemes"), systemImage: "link.badge.plus")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Allow HTTP"),
                        subtitle: .localized("Allow Insecure HTTP Connections"),
                        icon: "network"
                    ) {
                        let atsDict: [String: Any] = ["NSAllowsArbitraryLoads": true]
                        addSimpleEntry(key: "NSAppTransportSecurity", value: atsDict)
                    }
                } header: {
                    Label(.localized("App Transport Security"), systemImage: "lock.shield.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Substrate Safe Mode"),
                        subtitle: .localized("Run In Safe Mode On Jailbroken Devices"),
                        icon: "shield.checkered"
                    ) {
                        addSimpleEntry(key: "SBAppTags", value: ["hidden"])
                    }
                    
                    PresetButton(
                        title: .localized("Unrestricted Web GL"),
                        subtitle: .localized("Allow WebGL Without Restrictions"),
                        icon: "cube.transparent"
                    ) {
                        addSimpleEntry(key: "WebKitWebGLEnabled", value: true)
                    }
                    
                    PresetButton(
                        title: .localized("Disable Tracking"),
                        subtitle: .localized("Disable App Tracking Transparency"),
                        icon: "hand.raised.slash.fill"
                    ) {
                        addSimpleEntry(key: "NSUserTrackingUsageDescription", value: "This app does not track you.")
                    }
                } header: {
                    Label(.localized("Jailbreak & Device"), systemImage: "gear.badge.checkmark")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Game Center"),
                        subtitle: .localized("Enable Game Center Integration"),
                        icon: "gamecontroller.fill"
                    ) {
                        addSimpleEntry(key: "UIRequiredDeviceCapabilities", value: ["gamekit"])
                    }
                    
                    PresetButton(
                        title: .localized("Hide Launch Screen"),
                        subtitle: .localized("Remove Launch Storyboard"),
                        icon: "gauge.high"
                    ) {
                        addSimpleEntry(key: "UILaunchStoryboardName", value: "")
                    }
                    
                    PresetButton(
                        title: .localized("Metal Support"),
                        subtitle: .localized("Enable Metal Graphics API"),
                        icon: "cpu"
                    ) {
                        addSimpleEntry(key: "MetalCaptureEnabled", value: true)
                    }
                } header: {
                    Label(.localized("Game & Performance"), systemImage: "gamecontroller.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Shake To Undo"),
                        subtitle: .localized("Enable Shake To Undo/Edit"),
                        icon: "app.badge"
                    ) {
                        addSimpleEntry(key: "UIApplicationSupportsShakeToEdit", value: true)
                    }
                    
                    PresetButton(
                        title: .localized("Critical Alerts"),
                        subtitle: .localized("Allow Critical Alerts Permission"),
                        icon: "exclamationmark.triangle.fill"
                    ) {
                        addSimpleEntry(key: "UNAuthorizationOptionCriticalAlert", value: true)
                    }
                } header: {
                    Label(.localized("Notifications & Badges"), systemImage: "bell.badge.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Third-Party Keyboards"),
                        subtitle: .localized("Allow thRird Party Keyboard Extensions"),
                        icon: "keyboard.badge.ellipsis"
                    ) {
                        addSimpleEntry(key: "UIKeyboardExtensionPointIdentifier", value: true)
                    }
                    
                    PresetButton(
                        title: .localized("Dictation"),
                        subtitle: .localized("Enable Voice Dictation"),
                        icon: "mic.badge.plus"
                    ) {
                        addSimpleEntry(key: "UIDictationEnabled", value: true)
                    }
                } header: {
                    Label(.localized("Keyboard & Input"), systemImage: "keyboard.fill")
                }
                
                Section {
                    PresetButton(
                        title: .localized("WiFi Required"),
                        subtitle: .localized("Require WiFi Connection"),
                        icon: "wifi"
                    ) {
                        addSimpleEntry(key: "UIRequiresPersistentWiFi", value: true)
                    }
                    
                    PresetButton(
                        title: .localized("AirDrop Support"),
                        subtitle: .localized("Enable AirDrop Sharing"),
                        icon: "airplayaudio"
                    ) {
                        addSimpleEntry(key: "UIActivityContinuationTypes", value: ["public.data"])
                    }
                    
                    PresetButton(
                        title: .localized("Local Network"),
                        subtitle: .localized("Add Local Network Permission"),
                        icon: "network"
                    ) {
                        addSimpleEntry(key: "NSLocalNetworkUsageDescription", value: "This app needs access to local network.")
                    }
                    
                    PresetButton(
                        title: .localized("NFC Reader"),
                        subtitle: .localized("Add NFC Reader Permission"),
                        icon: "wave.3.right"
                    ) {
                        addSimpleEntry(key: "NFCReaderUsageDescription", value: "This app needs NFC access.")
                    }
                } header: {
                    Label(.localized("Networking & Wireless"), systemImage: "wifi")
                }
                
                Section {
                    PresetButton(
                        title: .localized("Photo Library Add"),
                        subtitle: .localized("Permission To Add Photos"),
                        icon: "photo.badge.plus"
                    ) {
                        addSimpleEntry(key: "NSPhotoLibraryAddUsageDescription", value: "This app needs to save photos.")
                    }
                    
                    PresetButton(
                        title: .localized("Media Library"),
                        subtitle: .localized("Access Music And Media Library"),
                        icon: "music.note.list"
                    ) {
                        addSimpleEntry(key: "NSAppleMusicUsageDescription", value: "This app needs access to your music library.")
                    }
                    
                    PresetButton(
                        title: .localized("Speech Recognition"),
                        subtitle: .localized("Enable Speech Recognition"),
                        icon: "waveform"
                    ) {
                        addSimpleEntry(key: "NSSpeechRecognitionUsageDescription", value: "This app needs speech recognition.")
                    }
                } header: {
                    Label(.localized("Media & Content"), systemImage: "photo.on.rectangle.angled")
                }
            }
            .navigationTitle(.localized("Presets"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) {
                        showPresetSheet = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var batchActionsSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            for key in selectedEntries {
                                options.customInfoPlistEntries.removeValue(forKey: key)
                            }
                            selectedEntries.removeAll()
                            isSelectionMode = false
                        }
                        HapticsManager.shared.success()
                        showBatchActionsSheet = false
                    } label: {
                        Label(.localized("Delete \(selectedEntries.count) Selected"), systemImage: "trash")
                    }
                    .disabled(selectedEntries.isEmpty)

                    Button {
                        selectedEntries.removeAll()
                        isSelectionMode = false
                        showBatchActionsSheet = false
                    } label: {
                        Label(.localized("Deselect All"), systemImage: "xmark.circle")
                    }
                } header: {
                    Label(.localized("Selected Entries (\(selectedEntries.count))"), systemImage: "checkmark.circle.fill")
                }
            }
            .navigationTitle(.localized("Batch Actions"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        showBatchActionsSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var searchReplaceSheet: some View {
        NavigationStack {
            ZStack {
                Color.clear.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Search Value"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            TextField(.localized("Value to Find"), text: $searchReplaceTarget)
                                .font(.system(size: 16))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.clear)
                                )
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text(.localized("Replace With"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)

                            TextField(.localized("Replacement Value"), text: $searchReplaceNewValue)
                                .font(.system(size: 16))
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.clear)
                                )
                        }

                        Button {
                            for (key, val) in options.customInfoPlistEntries {
                                if let strVal = val.value as? String,
                                   strVal.contains(searchReplaceTarget) {
                                    let replaced = strVal.replacingOccurrences(of: searchReplaceTarget, with: searchReplaceNewValue)
                                    options.customInfoPlistEntries[key] = AnyCodable(replaced)
                                }
                            }
                            HapticsManager.shared.success()
                            showSearchReplaceSheet = false
                        } label: {
                            Label(.localized("Replace All"), systemImage: "arrow.triangle.2.circlepath")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(searchReplaceTarget.isEmpty)
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(.localized("Search & Replace"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Cancel")) {
                        showSearchReplaceSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    struct PresetButton: View {
        let title: String
        let subtitle: String
        let icon: String
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(.indigo)
                        .frame(width: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // ... rest of the file ...
    
    private func addSimpleEntry(key: String, value: Any) {
        withAnimation {
            options.customInfoPlistEntries[key] = AnyCodable(value)
        }
        HapticsManager.shared.success()
    }
    
    private func addOrientationPreset(_ preset: OrientationPreset) {
        let values: [String]
        switch preset {
        case .portrait:
            values = ["UIInterfaceOrientationPortrait"]
        case .landscape:
            values = ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]
        case .all:
            values = ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]
        }
        
        addSimpleEntry(key: "UISupportedInterfaceOrientations", value: values)
    }
    
    enum OrientationPreset {
        case portrait, landscape, all
    }
    
    private func addBackgroundMode(_ mode: BackgroundMode) {
        var currentModes = (options.customInfoPlistEntries["UIBackgroundModes"]?.value as? [String]) ?? []
        let modeString: String
        switch mode {
        case .audio: modeString = "audio"
        case .location: modeString = "location"
        case .voip: modeString = "voip"
        case .fetch: modeString = "fetch"
        case .processing: modeString = "processing"
        case .remoteNotification: modeString = "remote-notification"
        }
        
        if !currentModes.contains(modeString) {
            currentModes.append(modeString)
            addSimpleEntry(key: "UIBackgroundModes", value: currentModes)
        }
    }
    
    enum BackgroundMode {
        case audio, location, voip, fetch, processing, remoteNotification
    }
    
    private func addURLScheme(_ scheme: String) {
        let entry: [[String: Any]] = [
            ["CFBundleURLSchemes": [scheme]]
        ]
        addSimpleEntry(key: "CFBundleURLTypes", value: entry)
    }
    
    private func prepareEdit(key: String, value: AnyCodable) {
        editKey = key
        if let val = value.value as? String {
            editValueType = .string
            editStringValue = val
        } else if let val = value.value as? Bool {
            editValueType = .boolean
            editBoolValue = val
        } else if let val = value.value as? Int {
            editValueType = .number
            editNumberValue = String(val)
        } else if let val = value.value as? Double {
            editValueType = .number
            editNumberValue = String(val)
        } else if value.value is [Any] {
            editValueType = .array
        } else if value.value is [String: Any] {
            editValueType = .dictionary
        }
    }
    
    private func saveEdit() {
        let newValue: Any
        switch editValueType {
        case .string:
            newValue = editStringValue
        case .boolean:
            newValue = editBoolValue
        case .number:
            if let intVal = Int(editNumberValue) {
                newValue = intVal
            } else if let doubleVal = Double(editNumberValue) {
                newValue = doubleVal
            } else {
                newValue = editNumberValue
            }
        default:
            return
        }
        
        withAnimation {
            options.customInfoPlistEntries[editKey] = AnyCodable(newValue)
        }
        showEditSheet = false
        HapticsManager.shared.success()
    }
    
    private func addEntry() {
        let value: Any
        switch newValueType {
        case .string:
            value = newStringValue
        case .boolean:
            value = newBoolValue
        case .number:
            if let intVal = Int(newNumberValue) {
                value = intVal
            } else if let doubleVal = Double(newNumberValue) {
                value = doubleVal
            } else {
                value = newNumberValue
            }
        case .array:
            value = newArrayItems
        case .dictionary:
            value = [String: Any]()
        }
        
        withAnimation {
            options.customInfoPlistEntries[newKey] = AnyCodable(value)
        }
        showAddEntryDialog = false
        resetForm()
        HapticsManager.shared.success()
    }
    
    private func resetForm() {
        newKey = ""
        newStringValue = ""
        newBoolValue = false
        newNumberValue = ""
        newArrayItems = []
        newDictItems = [:]
    }
    
    private func duplicateEntry(key: String, value: AnyCodable) {
        var newKey = key + "_copy"
        var counter = 1
        while options.customInfoPlistEntries[newKey] != nil {
            newKey = key + "_copy_\(counter)"
            counter += 1
        }
        
        withAnimation {
            options.customInfoPlistEntries[newKey] = value
        }
        HapticsManager.shared.success()
    }
    
    private func valueDescription(for value: Any) -> String {
        if let s = value as? String { return s }
        if let b = value as? Bool { return b ? "True" : "False" }
        if let n = value as? NSNumber { return n.stringValue }
        if let a = value as? [Any] { return "Array (\(a.count) items)" }
        if let d = value as? [String: Any] { return "Dictionary (\(d.count) items)" }
        return String(describing: value)
    }
    
    private func exportPlistFile() {
        // Implementation for exporting
    }
    
    private func importPlistFile(url: URL) {
        // Implementation for importing
    }
}

struct ModernEntryRow: View {
    let key: String
    let value: AnyCodable
    let isFirst: Bool
    let isLast: Bool
    let isSelected: Bool
    let isSelectionMode: Bool
    let onTap: () -> Void
    let onToggle: ((Bool) -> Void)?
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .indigo : .secondary)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(key)
                        .font(.system(size: 15, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                    
                    if let onToggle = onToggle, let boolVal = value.value as? Bool {
                        Toggle("", isOn: Binding(get: { boolVal }, set: onToggle))
                            .labelsHidden()
                            .tint(.indigo)
                    } else {
                        Text(String(describing: value.value))
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if !isSelectionMode {
                    Menu {
                        Button(action: onDuplicate) {
                            Label(.localized("Duplicate"), systemImage: "plus.square.on.square")
                        }
                        Button(role: .destructive, action: onDelete) {
                            Label(.localized("Delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
