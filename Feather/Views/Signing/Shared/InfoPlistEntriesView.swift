import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

struct InfoPlistEntriesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
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
    
    @State private var floatingAnimation = false
    @State private var appearAnimation = false
    
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
            .sheet(isPresented: $showAddEntryDialog) { addEntrySheet }
            .sheet(isPresented: $showPresetSheet) { presetOptionsSheet }
            .sheet(isPresented: $showEditSheet) { editEntrySheet }
            .sheet(isPresented: $showBatchActionsSheet) { batchActionsSheet }
            .sheet(isPresented: $showSearchReplaceSheet) { searchReplaceSheet }
            .sheet(isPresented: $showImportSheet) {
                FileImporterRepresentableView(
                    allowedContentTypes: [.propertyList, .xml],
                    allowsMultipleSelection: false,
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
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appearAnimation = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.indigo.opacity(0.08),
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
                    .fill(
                        RadialGradient(
                            colors: [Color.indigo.opacity(0.15), Color.indigo.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)
                    .blur(radius: 60)
                    .offset(x: floatingAnimation ? -30 : 30, y: floatingAnimation ? -20 : 20)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.15)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.purple.opacity(0.12), Color.purple.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(x: floatingAnimation ? 20 : -20, y: floatingAnimation ? 15 : -15)
                    .position(x: geo.size.width * 0.15, y: geo.size.height * 0.7)
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
                            colors: [Color.indigo.opacity(0.3), Color.purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.indigo.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "doc.badge.gearshape.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .scaleEffect(appearAnimation ? 1 : 0.5)
            .opacity(appearAnimation ? 1 : 0)
            
            VStack(spacing: 4) {
                Text(.localized("Info.plist Entries"))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                
                Text(.localized("\(options.customInfoPlistEntries.count) Custom Entries"))
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
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                
                TextField(.localized("Search Entries"), text: $searchText)
                    .font(.system(size: 15))
                    .textInputAutocapitalization(.never)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
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
            
            if !options.customInfoPlistEntries.isEmpty {
                Button {
                    withAnimation {
                        isSelectionMode.toggle()
                        if !isSelectionMode {
                            selectedEntries.removeAll()
                        }
                    }
                } label: {
                    Image(systemName: isSelectionMode ? "checkmark.circle.fill" : "checklist")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelectionMode ? .indigo : .secondary)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                quickActionsSection
                    .padding(.horizontal, 16)
                
                if filteredEntries.isEmpty {
                    emptyStateView
                        .padding(.top, 40)
                } else {
                    entriesSection
                        .padding(.horizontal, 16)
                }
                
                if isSelectionMode && !selectedEntries.isEmpty {
                    batchActionBar
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 80)
        }
    }
    
    @ViewBuilder
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(.localized("Quick Actions"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    QuickActionCard(
                        icon: "sparkles",
                        title: .localized("Presets"),
                        subtitle: .localized("Common Options"),
                        gradient: [.purple, .indigo]
                    ) {
                        showPresetSheet = true
                    }
                    
                    QuickActionCard(
                        icon: "square.and.arrow.down",
                        title: .localized("Import"),
                        subtitle: .localized("From .plist"),
                        gradient: [.green, .teal]
                    ) {
                        showImportSheet = true
                    }
                    
                    QuickActionCard(
                        icon: "magnifyingglass",
                        title: .localized("Replace"),
                        subtitle: .localized("Bulk Edit"),
                        gradient: [.orange, .red]
                    ) {
                        showSearchReplaceSheet = true
                    }

                    QuickActionCard(
                        icon: "square.and.arrow.up",
                        title: .localized("Export"),
                        subtitle: .localized("Save Entries"),
                        gradient: [.blue, .cyan]
                    ) {
                        exportPlistFile()
                    }
                    .opacity(options.customInfoPlistEntries.isEmpty ? 0.5 : 1)
                    .disabled(options.customInfoPlistEntries.isEmpty)
                    
                    if !options.customInfoPlistEntries.isEmpty {
                        QuickActionCard(
                            icon: "arrow.counterclockwise",
                            title: .localized("Clear All"),
                            subtitle: .localized("Remove All"),
                            gradient: [.red, .orange]
                        ) {
                            withAnimation {
                                options.customInfoPlistEntries.removeAll()
                            }
                            HapticsManager.shared.success()
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.indigo)
            }
            
            VStack(spacing: 8) {
                Text(.localized("No Entries Yet"))
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(.localized("Add custom Info.plist entries\nto modify app behavior"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showAddEntryDialog = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text(.localized("Add Entry"))
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .indigo.opacity(0.4), radius: 10, x: 0, y: 5)
            }
        }
    }
    
    @ViewBuilder
    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(.localized("Entries (\(filteredEntries.count))"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if isSelectionMode {
                    Button {
                        if selectedEntries.count == filteredEntries.count {
                            selectedEntries.removeAll()
                        } else {
                            selectedEntries = Set(filteredEntries.map { $0.key })
                        }
                    } label: {
                        Text(selectedEntries.count == filteredEntries.count ? .localized("Deselect All") : .localized("Select All"))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.indigo)
                    }
                }
            }
            .padding(.leading, 4)
            
            VStack(spacing: 2) {
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
            }
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    @ViewBuilder
    private var batchActionBar: some View {
        HStack(spacing: 16) {
            Text(.localized("\(selectedEntries.count) Selected"))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button {
                withAnimation {
                    for key in selectedEntries {
                        _ = options.customInfoPlistEntries.removeValue(forKey: key)
                    }
                    selectedEntries.removeAll()
                    isSelectionMode = false
                }
                HapticsManager.shared.success()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text(.localized("Delete"))
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.red)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
        .padding(.horizontal, 16)
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
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
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
                                        .fill(Color(.secondarySystemGroupedBackground))
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
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text(.localized("Add Entry"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: newKey.isEmpty ? [.gray] : [.indigo, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: newKey.isEmpty ? .clear : .indigo.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
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
                        .fill(Color(.secondarySystemGroupedBackground))
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
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
        case .number:
            TextField(.localized("Enter Number"), text: $newNumberValue)
                .font(.system(size: 16))
                .keyboardType(.numbersAndPunctuation)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
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
                            .fill(Color(.tertiarySystemGroupedBackground))
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
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
        case .dictionary:
            VStack(spacing: 8) {
                Text(.localized("Dictionary entries will be created empty"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
    
    @ViewBuilder
    private var editEntrySheet: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                
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
                                        .fill(Color(.secondarySystemGroupedBackground))
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
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(.localized("Save Changes"))
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .indigo.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
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
                        .fill(Color(.secondarySystemGroupedBackground))
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
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            
        case .number:
            TextField(.localized("Enter Number"), text: $editNumberValue)
                .font(.system(size: 16))
                .keyboardType(.numbersAndPunctuation)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
            
        default:
            Text(.localized("Complex types cannot be edited directly"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
        }
    }
    
    @ViewBuilder
    private var presetOptionsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    PresetSection(
                        title: .localized("Essential & Identity"),
                        icon: "person.text.rectangle.fill",
                        color: .indigo
                    ) {
                        PresetButton(
                            title: .localized("Custom Display Name"),
                            subtitle: .localized("Overwrite app name"),
                            icon: "textformat",
                            color: .blue
                        ) {
                            addSimpleEntry(key: "CFBundleDisplayName", value: "New Name")
                        }

                        PresetButton(
                            title: .localized("Custom Version"),
                            subtitle: .localized("Overwrite version string"),
                            icon: "tag",
                            color: .purple
                        ) {
                            addSimpleEntry(key: "CFBundleShortVersionString", value: "1.0.0")
                        }
                    }

                    PresetSection(
                        title: .localized("Orientation"),
                        icon: "rotate.right.fill",
                        color: .blue
                    ) {
                        PresetButton(
                            title: .localized("Portrait Only"),
                            subtitle: .localized("Lock to portrait mode"),
                            icon: "rectangle.portrait.fill",
                            color: .blue
                        ) {
                            addOrientationPreset(.portrait)
                        }
                        
                        PresetButton(
                            title: .localized("Landscape Only"),
                            subtitle: .localized("Lock to landscape mode"),
                            icon: "rectangle.fill",
                            color: .green
                        ) {
                            addOrientationPreset(.landscape)
                        }
                        
                        PresetButton(
                            title: .localized("All Orientations"),
                            subtitle: .localized("Allow all rotations"),
                            icon: "rotate.3d.fill",
                            color: .purple
                        ) {
                            addOrientationPreset(.all)
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Background Modes"),
                        icon: "moon.fill",
                        color: .indigo
                    ) {
                        PresetButton(
                            title: .localized("Background Audio"),
                            subtitle: .localized("Play audio in background"),
                            icon: "music.note",
                            color: .pink
                        ) {
                            addBackgroundMode(.audio)
                        }
                        
                        PresetButton(
                            title: .localized("Background Location"),
                            subtitle: .localized("Access location in background"),
                            icon: "location.fill",
                            color: .orange
                        ) {
                            addBackgroundMode(.location)
                        }
                        
                        PresetButton(
                            title: .localized("VoIP"),
                            subtitle: .localized("Voice over IP support"),
                            icon: "phone.fill",
                            color: .cyan
                        ) {
                            addBackgroundMode(.voip)
                        }
                        
                        PresetButton(
                            title: .localized("Background Fetch"),
                            subtitle: .localized("Fetch content periodically"),
                            icon: "arrow.down.circle.fill",
                            color: .teal
                        ) {
                            addBackgroundMode(.fetch)
                        }
                        
                        PresetButton(
                            title: .localized("Background Processing"),
                            subtitle: .localized("Run background tasks"),
                            icon: "cpu.fill",
                            color: .purple
                        ) {
                            addBackgroundMode(.processing)
                        }
                        
                        PresetButton(
                            title: .localized("Remote Notifications"),
                            subtitle: .localized("Receive push notifications"),
                            icon: "bell.badge.fill",
                            color: .red
                        ) {
                            addBackgroundMode(.remoteNotification)
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Display & UI"),
                        icon: "paintbrush.fill",
                        color: .purple
                    ) {
                        PresetButton(
                            title: .localized("Require Full Screen"),
                            subtitle: .localized("Disable multitasking"),
                            icon: "rectangle.expand.vertical",
                            color: .purple
                        ) {
                            addSimpleEntry(key: "UIRequiresFullScreen", value: true)
                        }
                        
                        PresetButton(
                            title: .localized("Hide Status Bar"),
                            subtitle: .localized("Hide the system status bar"),
                            icon: "eye.slash.fill",
                            color: .gray
                        ) {
                            addSimpleEntry(key: "UIStatusBarHidden", value: true)
                        }
                        
                        PresetButton(
                            title: .localized("Force Dark Mode"),
                            subtitle: .localized("Always use dark appearance"),
                            icon: "moon.fill",
                            color: .indigo
                        ) {
                            addSimpleEntry(key: "UIUserInterfaceStyle", value: "Dark")
                        }
                        
                        PresetButton(
                            title: .localized("Force Light Mode"),
                            subtitle: .localized("Always use light appearance"),
                            icon: "sun.max.fill",
                            color: .orange
                        ) {
                            addSimpleEntry(key: "UIUserInterfaceStyle", value: "Light")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("File Access"),
                        icon: "folder.fill",
                        color: .cyan
                    ) {
                        PresetButton(
                            title: .localized("File Sharing"),
                            subtitle: .localized("Enable iTunes/Finder file sharing"),
                            icon: "folder.fill",
                            color: .cyan
                        ) {
                            addSimpleEntry(key: "UIFileSharingEnabled", value: true)
                        }
                        
                        PresetButton(
                            title: .localized("Document Browser"),
                            subtitle: .localized("Support document browser"),
                            icon: "doc.fill",
                            color: .brown
                        ) {
                            addSimpleEntry(key: "UISupportsDocumentBrowser", value: true)
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Privacy Permissions"),
                        icon: "hand.raised.fill",
                        color: .red
                    ) {
                        PresetButton(
                            title: .localized("Camera Usage"),
                            subtitle: .localized("Add camera permission"),
                            icon: "camera.fill",
                            color: .blue
                        ) {
                            addSimpleEntry(key: "NSCameraUsageDescription", value: "This app needs camera access.")
                        }
                        
                        PresetButton(
                            title: .localized("Photo Library"),
                            subtitle: .localized("Add photo library permission"),
                            icon: "photo.fill",
                            color: .purple
                        ) {
                            addSimpleEntry(key: "NSPhotoLibraryUsageDescription", value: "This app needs photo library access.")
                        }
                        
                        PresetButton(
                            title: .localized("Microphone"),
                            subtitle: .localized("Add microphone permission"),
                            icon: "mic.fill",
                            color: .red
                        ) {
                            addSimpleEntry(key: "NSMicrophoneUsageDescription", value: "This app needs microphone access.")
                        }
                        
                        PresetButton(
                            title: .localized("Location"),
                            subtitle: .localized("Add location permission"),
                            icon: "location.fill",
                            color: .green
                        ) {
                            addSimpleEntry(key: "NSLocationWhenInUseUsageDescription", value: "This app needs location access.")
                        }
                        
                        PresetButton(
                            title: .localized("Contacts"),
                            subtitle: .localized("Add contacts permission"),
                            icon: "person.crop.circle.fill",
                            color: .orange
                        ) {
                            addSimpleEntry(key: "NSContactsUsageDescription", value: "This app needs contacts access.")
                        }
                        
                        PresetButton(
                            title: .localized("Face ID"),
                            subtitle: .localized("Add Face ID permission"),
                            icon: "faceid",
                            color: .indigo
                        ) {
                            addSimpleEntry(key: "NSFaceIDUsageDescription", value: "This app uses Face ID for authentication.")
                        }
                        
                        PresetButton(
                            title: .localized("Bluetooth"),
                            subtitle: .localized("Add Bluetooth permission"),
                            icon: "antenna.radiowaves.left.and.right",
                            color: .blue
                        ) {
                            addSimpleEntry(key: "NSBluetoothAlwaysUsageDescription", value: "This app needs Bluetooth access.")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("URL Schemes"),
                        icon: "link.badge.plus",
                        color: .orange
                    ) {
                        PresetButton(
                            title: .localized("Add URL Scheme"),
                            subtitle: .localized("Custom deep linking scheme"),
                            icon: "link.circle.fill",
                            color: .orange
                        ) {
                            addURLScheme("myapp")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("App Transport Security"),
                        icon: "lock.shield.fill",
                        color: .green
                    ) {
                        PresetButton(
                            title: .localized("Allow HTTP"),
                            subtitle: .localized("Allow insecure HTTP connections"),
                            icon: "network",
                            color: .orange
                        ) {
                            let atsDict: [String: Any] = ["NSAllowsArbitraryLoads": true]
                            addSimpleEntry(key: "NSAppTransportSecurity", value: atsDict)
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Jailbreak & Device"),
                        icon: "gear.badge.checkmark",
                        color: .yellow
                    ) {
                        PresetButton(
                            title: .localized("Substrate Safe Mode"),
                            subtitle: .localized("Run in safe mode on jailbroken devices"),
                            icon: "shield.checkered",
                            color: .yellow
                        ) {
                            addSimpleEntry(key: "SBAppTags", value: ["hidden"])
                        }
                        
                        PresetButton(
                            title: .localized("Unrestricted Web GL"),
                            subtitle: .localized("Allow WebGL without restrictions"),
                            icon: "cube.transparent",
                            color: .cyan
                        ) {
                            addSimpleEntry(key: "WebKitWebGLEnabled", value: true)
                        }
                        
                        PresetButton(
                            title: .localized("Disable Tracking"),
                            subtitle: .localized("Disable app tracking transparency"),
                            icon: "hand.raised.slash.fill",
                            color: .red
                        ) {
                            addSimpleEntry(key: "NSUserTrackingUsageDescription", value: "This app does not track you.")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Game & Performance"),
                        icon: "gamecontroller.fill",
                        color: .mint
                    ) {
                        PresetButton(
                            title: .localized("Game Center"),
                            subtitle: .localized("Enable Game Center integration"),
                            icon: "gamecontroller.fill",
                            color: .mint
                        ) {
                            addSimpleEntry(key: "UIRequiredDeviceCapabilities", value: ["gamekit"])
                        }
                        
                        PresetButton(
                            title: .localized("Hide Launch Screen"),
                            subtitle: .localized("Remove launch storyboard"),
                            icon: "gauge.high",
                            color: .pink
                        ) {
                            addSimpleEntry(key: "UILaunchStoryboardName", value: "")
                        }
                        
                        PresetButton(
                            title: .localized("Metal Support"),
                            subtitle: .localized("Enable Metal graphics API"),
                            icon: "cpu",
                            color: .purple
                        ) {
                            addSimpleEntry(key: "MetalCaptureEnabled", value: true)
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Notifications & Badges"),
                        icon: "bell.badge.fill",
                        color: .red
                    ) {
                        PresetButton(
                            title: .localized("Shake to Undo"),
                            subtitle: .localized("Enable shake to undo/edit"),
                            icon: "app.badge",
                            color: .red
                        ) {
                            addSimpleEntry(key: "UIApplicationSupportsShakeToEdit", value: true)
                        }
                        
                        PresetButton(
                            title: .localized("Critical Alerts"),
                            subtitle: .localized("Allow critical alerts permission"),
                            icon: "exclamationmark.triangle.fill",
                            color: .orange
                        ) {
                            addSimpleEntry(key: "UNAuthorizationOptionCriticalAlert", value: true)
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Keyboard & Input"),
                        icon: "keyboard.fill",
                        color: .gray
                    ) {
                        PresetButton(
                            title: .localized("Third-Party Keyboards"),
                            subtitle: .localized("Allow third-party keyboard extensions"),
                            icon: "keyboard.badge.ellipsis",
                            color: .blue
                        ) {
                            addSimpleEntry(key: "UIKeyboardExtensionPointIdentifier", value: true)
                        }
                        
                        PresetButton(
                            title: .localized("Dictation"),
                            subtitle: .localized("Enable voice dictation"),
                            icon: "mic.badge.plus",
                            color: .purple
                        ) {
                            addSimpleEntry(key: "UIDictationEnabled", value: true)
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Networking & Wireless"),
                        icon: "wifi",
                        color: .blue
                    ) {
                        PresetButton(
                            title: .localized("WiFi Required"),
                            subtitle: .localized("Require WiFi connection"),
                            icon: "wifi",
                            color: .blue
                        ) {
                            addSimpleEntry(key: "UIRequiresPersistentWiFi", value: true)
                        }
                        
                        PresetButton(
                            title: .localized("AirDrop Support"),
                            subtitle: .localized("Enable AirDrop sharing"),
                            icon: "airplayaudio",
                            color: .cyan
                        ) {
                            addSimpleEntry(key: "UIActivityContinuationTypes", value: ["public.data"])
                        }
                        
                        PresetButton(
                            title: .localized("Local Network"),
                            subtitle: .localized("Add local network permission"),
                            icon: "network",
                            color: .green
                        ) {
                            addSimpleEntry(key: "NSLocalNetworkUsageDescription", value: "This app needs access to local network.")
                        }
                        
                        PresetButton(
                            title: .localized("NFC Reader"),
                            subtitle: .localized("Add NFC reader permission"),
                            icon: "wave.3.right",
                            color: .orange
                        ) {
                            addSimpleEntry(key: "NFCReaderUsageDescription", value: "This app needs NFC access.")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Media & Content"),
                        icon: "photo.on.rectangle.angled",
                        color: .pink
                    ) {
                        PresetButton(
                            title: .localized("Photo Library Add"),
                            subtitle: .localized("Permission to add photos"),
                            icon: "photo.badge.plus",
                            color: .pink
                        ) {
                            addSimpleEntry(key: "NSPhotoLibraryAddUsageDescription", value: "This app needs to save photos.")
                        }
                        
                        PresetButton(
                            title: .localized("Media Library"),
                            subtitle: .localized("Access music and media library"),
                            icon: "music.note.list",
                            color: .red
                        ) {
                            addSimpleEntry(key: "NSAppleMusicUsageDescription", value: "This app needs access to your music library.")
                        }
                        
                        PresetButton(
                            title: .localized("Speech Recognition"),
                            subtitle: .localized("Enable speech recognition"),
                            icon: "waveform",
                            color: .purple
                        ) {
                            addSimpleEntry(key: "NSSpeechRecognitionUsageDescription", value: "This app uses speech recognition.")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Health & Fitness"),
                        icon: "heart.fill",
                        color: .red
                    ) {
                        PresetButton(
                            title: .localized("Health Kit"),
                            subtitle: .localized("Access health data"),
                            icon: "heart.text.square.fill",
                            color: .red
                        ) {
                            addSimpleEntry(key: "NSHealthShareUsageDescription", value: "This app needs access to your health data.")
                        }
                        
                        PresetButton(
                            title: .localized("Motion & Fitness"),
                            subtitle: .localized("Access motion and fitness data"),
                            icon: "figure.walk",
                            color: .orange
                        ) {
                            addSimpleEntry(key: "NSMotionUsageDescription", value: "This app needs access to motion data.")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("Calendar & Reminders"),
                        icon: "calendar",
                        color: .orange
                    ) {
                        PresetButton(
                            title: .localized("Calendars Access"),
                            subtitle: .localized("Access calendar events"),
                            icon: "calendar.badge.plus",
                            color: .orange
                        ) {
                            addSimpleEntry(key: "NSCalendarsUsageDescription", value: "This app needs calendar access.")
                        }
                        
                        PresetButton(
                            title: .localized("Reminders Access"),
                            subtitle: .localized("Access reminders"),
                            icon: "checklist",
                            color: .blue
                        ) {
                            addSimpleEntry(key: "NSRemindersUsageDescription", value: "This app needs reminders access.")
                        }
                    }
                    
                    PresetSection(
                        title: .localized("HomeKit & Siri"),
                        icon: "house.fill",
                        color: .brown
                    ) {
                        PresetButton(
                            title: .localized("HomeKit"),
                            subtitle: .localized("Control HomeKit accessories"),
                            icon: "homekit",
                            color: .brown
                        ) {
                            addSimpleEntry(key: "NSHomeKitUsageDescription", value: "This app needs HomeKit access.")
                        }
                        
                        PresetButton(
                            title: .localized("Siri Integration"),
                            subtitle: .localized("Enable Siri shortcuts and intents"),
                            icon: "sparkles",
                            color: .purple
                        ) {
                            addSimpleEntry(key: "NSSiriUsageDescription", value: "This app uses Siri.")
                        }
                    }

                    PresetSection(
                        title: .localized("Advanced & System"),
                        icon: "cpu.fill",
                        color: .gray
                    ) {
                        PresetButton(
                            title: .localized("Enable JIT"),
                            subtitle: .localized("Allow Just-In-Time compilation. Requires a Developer certificate so the get-task entitlement can be present."),
                            icon: "bolt.fill",
                            color: .orange
                        ) {
                            addSimpleEntry(key: "dynamic-codesigning", value: true)
                        }

                        PresetButton(
                            title: .localized("Allow Insecure Loads"),
                            subtitle: .localized("Bypass ATS restrictions"),
                            icon: "lock.open.fill",
                            color: .red
                        ) {
                            addSimpleEntry(key: "NSAppTransportSecurity", value: ["NSAllowsArbitraryLoads": true])
                        }

                        PresetButton(
                            title: .localized("Hide iPad Home Bar"),
                            subtitle: .localized("Auto hide home indicator"),
                            icon: "minus",
                            color: .blue
                        ) {
                            addSimpleEntry(key: "UIViewControllerPrefersHomeIndicatorAutoHidden", value: true)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(.localized("Preset Options"))
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
    private var searchReplaceSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(.localized("Find"), text: $searchReplaceTarget)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField(.localized("Replace With"), text: $searchReplaceNewValue)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(.localized("Search And Replace Values"))
                } footer: {
                    Text(.localized("This will replace all occurrences in string values."))
                }

                Button {
                    performSearchReplace()
                } label: {
                    Text(.localized("Replace All"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .disabled(searchReplaceTarget.isEmpty)
            }
            .navigationTitle(.localized("Search And Replace"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(.localized("Done")) {
                        showSearchReplaceSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func performSearchReplace() {
        var count = 0
        withAnimation {
            for (key, value) in options.customInfoPlistEntries {
                if let strValue = value.value as? String {
                    if strValue.contains(searchReplaceTarget) {
                        let newValue = strValue.replacingOccurrences(of: searchReplaceTarget, with: searchReplaceNewValue)
                        options.customInfoPlistEntries[key] = AnyCodable(newValue)
                        count += 1
                    }
                }
            }
        }
        HapticsManager.shared.success()
        if count > 0 {
            ToastManager.shared.show("Replaced \(count) Values", type: .success)
        }
        showSearchReplaceSheet = false
    }

    @ViewBuilder
    private var batchActionsSheet: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        withAnimation {
                            options.customInfoPlistEntries.removeAll()
                        }
                        showBatchActionsSheet = false
                        HapticsManager.shared.success()
                    } label: {
                        Label(.localized("Clear All Entries"), systemImage: "trash.fill")
                    }
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
    }
    
    private enum Orientation {
        case portrait, landscape, all
    }
    
    private enum BackgroundMode: String {
        case audio = "audio"
        case location = "location"
        case voip = "voip"
        case fetch = "fetch"
        case processing = "processing"
        case remoteNotification = "remote-notification"
    }
    
    private func addOrientationPreset(_ orientation: Orientation) {
        let orientations: [String]
        switch orientation {
        case .portrait:
            orientations = ["UIInterfaceOrientationPortrait"]
        case .landscape:
            orientations = ["UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"]
        case .all:
            orientations = [
                "UIInterfaceOrientationPortrait",
                "UIInterfaceOrientationPortraitUpsideDown",
                "UIInterfaceOrientationLandscapeLeft",
                "UIInterfaceOrientationLandscapeRight"
            ]
        }
        
        withAnimation {
            options.customInfoPlistEntries["UISupportedInterfaceOrientations"] = AnyCodable(orientations)
        }
        
        HapticsManager.shared.success()
        showPresetSheet = false
    }
    
    private func addBackgroundMode(_ mode: BackgroundMode) {
        var modes: [String] = []
        
        if let existing = options.customInfoPlistEntries["UIBackgroundModes"]?.value as? [String] {
            modes = existing
        }
        
        if !modes.contains(mode.rawValue) {
            modes.append(mode.rawValue)
        }
        
        withAnimation {
            options.customInfoPlistEntries["UIBackgroundModes"] = AnyCodable(modes)
        }
        
        HapticsManager.shared.success()
        showPresetSheet = false
    }
    
    private func addSimpleEntry(key: String, value: Any) {
        withAnimation {
            options.customInfoPlistEntries[key] = AnyCodable(value)
        }
        
        HapticsManager.shared.success()
        showPresetSheet = false
    }
    
    private func addURLScheme(_ scheme: String) {
        var urlTypes: [[String: Any]] = []
        
        if let existing = options.customInfoPlistEntries["CFBundleURLTypes"]?.value as? [[String: Any]] {
            urlTypes = existing
        }
        
        let newType: [String: Any] = [
            "CFBundleURLName": scheme,
            "CFBundleURLSchemes": [scheme]
        ]
        urlTypes.append(newType)
        
        withAnimation {
            options.customInfoPlistEntries["CFBundleURLTypes"] = AnyCodable(urlTypes)
        }
        
        HapticsManager.shared.success()
        showPresetSheet = false
    }
    
    private func addEntry() {
        guard !newKey.isEmpty else { return }
        
        let value: Any
        switch newValueType {
        case .string:
            value = newStringValue
        case .boolean:
            value = newBoolValue
        case .number:
            if let intValue = Int(newNumberValue) {
                value = intValue
            } else if let doubleValue = Double(newNumberValue) {
                value = doubleValue
            } else {
                value = newNumberValue
            }
        case .array:
            value = newArrayItems.filter { !$0.isEmpty }
        case .dictionary:
            value = [String: Any]()
        }
        
        withAnimation {
            options.customInfoPlistEntries[newKey] = AnyCodable(value)
        }
        
        HapticsManager.shared.success()
        showAddEntryDialog = false
        resetForm()
    }
    
    private func prepareEdit(key: String, value: AnyCodable) {
        editKey = key
        
        if let stringValue = value.value as? String {
            editValueType = .string
            editStringValue = stringValue
        } else if let boolValue = value.value as? Bool {
            editValueType = .boolean
            editBoolValue = boolValue
        } else if let intValue = value.value as? Int {
            editValueType = .number
            editNumberValue = "\(intValue)"
        } else if let doubleValue = value.value as? Double {
            editValueType = .number
            editNumberValue = "\(doubleValue)"
        } else if value.value is [Any] {
            editValueType = .array
        } else if value.value is [String: Any] {
            editValueType = .dictionary
        } else {
            editValueType = .string
            editStringValue = "\(value.value)"
        }
    }
    
    private func saveEdit() {
        let value: Any
        switch editValueType {
        case .string:
            value = editStringValue
        case .boolean:
            value = editBoolValue
        case .number:
            if let intValue = Int(editNumberValue) {
                value = intValue
            } else if let doubleValue = Double(editNumberValue) {
                value = doubleValue
            } else {
                value = editNumberValue
            }
        default:
            showEditSheet = false
            return
        }
        
        withAnimation {
            options.customInfoPlistEntries[editKey] = AnyCodable(value)
        }
        
        HapticsManager.shared.success()
        showEditSheet = false
    }
    
    private func duplicateEntry(key: String, value: AnyCodable) {
        var newKey = key + "_copy"
        var counter = 1
        while options.customInfoPlistEntries.keys.contains(newKey) {
            newKey = "\(key)_copy\(counter)"
            counter += 1
        }
        
        withAnimation {
            options.customInfoPlistEntries[newKey] = value
        }
        
        HapticsManager.shared.success()
    }
    
    private func resetForm() {
        newKey = ""
        newValueType = .string
        newStringValue = ""
        newBoolValue = false
        newNumberValue = ""
        newArrayItems = []
        newDictItems = [:]
    }
    
    private func valueDescription(for value: Any?) -> String {
        guard let value = value else { return "Unknown" }
        
        if let string = value as? String {
            return string
        } else if let bool = value as? Bool {
            return bool ? "true" : "false"
        } else if let number = value as? Int {
            return "\(number)"
        } else if let number = value as? Double {
            return "\(number)"
        } else if let array = value as? [Any] {
            return "Array (\(array.count) Items)"
        } else if let dict = value as? [String: Any] {
            return "Dictionary (\(dict.count) Keys)"
        } else {
            return "\(value)"
        }
    }
    
    private func importPlistFile(url: URL) {
        do {
            let data = try Data(contentsOf: url)
            guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                UIAlertController.showAlertWithOk(
                    title: .localized("Error"),
                    message: .localized("Invalid Plist Format")
                )
                return
            }
            
            withAnimation {
                for (key, value) in plist {
                    options.customInfoPlistEntries[key] = AnyCodable(value)
                }
            }
            
            HapticsManager.shared.success()
            UIAlertController.showAlertWithOk(
                title: .localized("Success"),
                message: .localized("Imported \(plist.count) entries from .plist file.")
            )
        } catch {
            HapticsManager.shared.error()
            UIAlertController.showAlertWithOk(
                title: .localized("Error"),
                message: .localized("Failed to import plist: \(error.localizedDescription)")
            )
        }
    }
    
    private func exportPlistFile() {
        do {
            var exportDict: [String: Any] = [:]
            for (key, anyCodable) in options.customInfoPlistEntries {
                exportDict[key] = anyCodable.value
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: exportDict, format: .xml, options: 0)
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("CustomInfoPlist.plist")
            try data.write(to: tempURL)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                var topController = rootViewController
                while let presented = topController.presentedViewController {
                    topController = presented
                }
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = topController.view
                    popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                topController.present(activityVC, animated: true)
            }
            
            HapticsManager.shared.success()
        } catch {
            HapticsManager.shared.error()
            UIAlertController.showAlertWithOk(
                title: .localized("Error"),
                message: .localized("Failed to export plist: \(error.localizedDescription)")
            )
        }
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
    var onToggle: ((Bool) -> Void)?
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    
    private var valueType: InfoPlistEntriesView.InfoPlistValueType {
        if value.value is String { return .string }
        if value.value is Bool { return .boolean }
        if value.value is Int || value.value is Double { return .number }
        if value.value is [Any] { return .array }
        if value.value is [String: Any] { return .dictionary }
        return .string
    }
    
    private var valueDescription: String {
        if let string = value.value as? String {
            return string.isEmpty ? "(empty)" : string
        } else if let bool = value.value as? Bool {
            return bool ? "true" : "false"
        } else if let number = value.value as? Int {
            return "\(number)"
        } else if let number = value.value as? Double {
            return "\(number)"
        } else if let array = value.value as? [Any] {
            return "Array (\(array.count) Items)"
        } else if let dict = value.value as? [String: Any] {
            return "Dictionary (\(dict.count) Keys)"
        }
        return "\(value.value)"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .indigo : .secondary)
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(valueType.color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: valueType.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(valueType.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(key)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(valueDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let onToggle = onToggle, let boolValue = value.value as? Bool {
                    Toggle("", isOn: Binding(
                        get: { boolValue },
                        set: { onToggle($0) }
                    ))
                    .labelsHidden()
                    .tint(.indigo)
                } else if !isSelectionMode {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.quaternary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.indigo.opacity(0.1) : Color.clear)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label(.localized("Delete"), systemImage: "trash.fill")
            }
            
            Button(action: onDuplicate) {
                Label(.localized("Duplicate"), systemImage: "doc.on.doc.fill")
            }
            .tint(.blue)
        }
        .contextMenu {
            Button(action: onDuplicate) {
                Label(.localized("Duplicate"), systemImage: "doc.on.doc")
            }
            
            Button {
                UIPasteboard.general.string = key
                HapticsManager.shared.softImpact()
            } label: {
                Label(.localized("Copy Key"), systemImage: "doc.on.clipboard")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label(.localized("Delete"), systemImage: "trash")
            }
        }
    }
}

struct PresetSection<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
            .padding(.leading, 4)
            
            VStack(spacing: 2) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

struct PresetButton: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
