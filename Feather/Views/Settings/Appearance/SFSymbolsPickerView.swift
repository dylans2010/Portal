import SwiftUI

// MARK: - Enhanced SF Symbols Picker
struct SFSymbolsPickerView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @Environment(\.dismiss) var dismiss
    @State private var customSymbolName = ""
    @State private var showCustomSymbolInput = false
    @State private var selectedWeight: Font.Weight = .regular
    @State private var selectedSize: CGFloat = 24
    @State private var previewColor: Color = .accentColor
    @State private var showCustomizationPanel = false
    
    // Symbol categories for filtering
    private let categories = [
        "All", "Communication", "Weather", "Objects", "Devices",
        "Gaming", "Health", "Nature", "Transportation", "Human",
        "Symbols", "Arrows", "Math", "Text Formatting"
    ]
    
    // Comprehensive SF Symbols catalog organized by category
    private let symbolsByCategory: [String: [String]] = [
        "Communication": [
            "message.fill", "message.circle.fill", "envelope.fill", "envelope.open.fill",
            "phone.fill", "phone.circle.fill", "video.fill", "video.circle.fill",
            "mic.fill", "mic.circle.fill", "speaker.wave.3.fill", "bell.fill",
            "bell.circle.fill", "bubble.left.fill", "bubble.right.fill", "bubble.left.and.bubble.right.fill",
            "antenna.radiowaves.left.and.right", "wifi", "wifi.circle.fill", "antenna.radiowaves.left.and.right.circle.fill"
        ],
        "Weather": [
            "sun.max.fill", "moon.fill", "moon.stars.fill", "cloud.fill",
            "cloud.sun.fill", "cloud.moon.fill", "cloud.rain.fill", "cloud.snow.fill",
            "cloud.bolt.fill", "cloud.fog.fill", "wind", "snowflake",
            "tornado", "thermometer.sun.fill", "thermometer.snowflake", "humidity.fill",
            "drop.fill", "drop.circle.fill", "flame.fill", "flame.circle.fill"
        ],
        "Objects": [
            "star.fill", "star.circle.fill", "heart.fill", "heart.circle.fill",
            "bolt.fill", "bolt.circle.fill", "sparkles", "flag.fill",
            "flag.circle.fill", "tag.fill", "bookmark.fill", "bookmark.circle.fill",
            "paperclip", "paperclip.circle.fill", "link", "link.circle.fill",
            "key.fill", "lock.fill", "lock.open.fill", "lock.circle.fill",
            "shield.fill", "checkmark.shield.fill", "xmark.shield.fill", "eye.fill",
            "eye.slash.fill", "eye.circle.fill", "magnifyingglass", "magnifyingglass.circle.fill"
        ],
        "Devices": [
            "iphone", "ipad", "laptopcomputer", "desktopcomputer",
            "applewatch", "airpods", "homepod.fill", "tv.fill",
            "display", "printer.fill", "scanner.fill", "camera.fill",
            "camera.circle.fill", "video.fill", "headphones", "headphones.circle.fill",
            "keyboard", "mouse.fill", "computermouse.fill", "externaldrive.fill"
        ],
        "Gaming": [
            "gamecontroller.fill", "dice.fill", "puzzlepiece.fill", "puzzlepiece.extension.fill",
            "circle.hexagongrid.fill", "target", "trophy.fill", "medal.fill",
            "crown.fill", "gift.fill", "wand.and.stars", "sparkles"
        ],
        "Health": [
            "heart.fill", "heart.circle.fill", "heart.text.square.fill", "bolt.heart.fill",
            "cross.fill", "cross.circle.fill", "pills.fill", "pill.fill",
            "cross.case.fill", "bandage.fill", "stethoscope", "syringe.fill",
            "lungs.fill", "figure.walk", "figure.run", "figure.yoga"
        ],
        "Nature": [
            "leaf.fill", "leaf.circle.fill", "tree.fill", "globe",
            "globe.americas.fill", "globe.europe.africa.fill", "globe.asia.australia.fill", "mountain.2.fill",
            "sunrise.fill", "sunset.fill", "moon.stars.fill", "sparkles",
            "allergens", "pawprint.fill", "pawprint.circle.fill", "ladybug.fill",
            "ant.fill", "hare.fill", "tortoise.fill", "bird.fill"
        ],
        "Transportation": [
            "car.fill", "car.circle.fill", "bus.fill", "tram.fill",
            "bicycle", "bicycle.circle.fill", "airplane", "airplane.circle.fill",
            "ferry.fill", "sailboat.fill", "train.side.front.car", "scooter",
            "rocket.fill", "fuelpump.fill", "parkingsign.circle.fill", "road.lanes"
        ],
        "Human": [
            "person.fill", "person.circle.fill", "person.2.fill", "person.3.fill",
            "figure.stand", "figure.walk", "figure.run", "figure.wave",
            "figure.arms.open", "hands.clap.fill", "hand.raised.fill", "hand.thumbsup.fill",
            "hand.thumbsdown.fill", "hand.wave.fill", "eye.fill", "ear.fill",
            "brain.head.profile", "facemask.fill"
        ],
        "Symbols": [
            "circle.fill", "square.fill", "triangle.fill", "diamond.fill",
            "hexagon.fill", "octagon.fill", "pentagon.fill", "seal.fill",
            "rectangle.fill", "capsule.fill", "oval.fill", "circle.grid.3x3.fill",
            "app.fill", "app.badge.fill", "square.grid.2x2.fill", "square.grid.3x3.fill"
        ],
        "Arrows": [
            "arrow.up", "arrow.down", "arrow.left", "arrow.right",
            "arrow.up.circle.fill", "arrow.down.circle.fill", "arrow.left.circle.fill", "arrow.right.circle.fill",
            "arrow.clockwise", "arrow.counterclockwise", "arrow.clockwise.circle.fill", "arrow.counterclockwise.circle.fill",
            "arrow.up.arrow.down", "arrow.left.arrow.right", "arrow.turn.up.right", "arrow.triangle.2.circlepath"
        ],
        "Math": [
            "plus", "minus", "multiply", "divide",
            "equal", "plus.circle.fill", "minus.circle.fill", "multiply.circle.fill",
            "divide.circle.fill", "percent", "number", "textformat.123",
            "sum", "function", "x.squareroot", "infinity"
        ],
        "Text Formatting": [
            "textformat", "textformat.size", "bold", "italic",
            "underline", "strikethrough", "textformat.alt", "character",
            "textformat.abc", "character.textbox", "list.bullet", "list.number",
            "text.alignleft", "text.aligncenter", "text.alignright", "text.justify"
        ]
    ]
    
    var filteredSymbols: [String] {
        var symbols: [String] = []
        
        if viewModel.selectedCategory == "All" {
            symbols = symbolsByCategory.values.flatMap { $0 }
        } else {
            symbols = symbolsByCategory[viewModel.selectedCategory] ?? []
        }
        
        if !viewModel.searchText.isEmpty {
            // Search in all symbols, not just the current category
            let allSymbols = symbolsByCategory.values.flatMap { $0 }
            symbols = allSymbols.filter { 
                $0.lowercased().contains(viewModel.searchText.lowercased()) 
            }
        }
        
        return Array(Set(symbols)).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Search Bar with Custom Symbol Input
                searchSection
                
                // Category Picker
                categoryPicker
                
                // Quick Access Tabs
                quickAccessTabs
                
                // Symbol Grid
                ScrollView {
                    if viewModel.selectedCategory == "Recents" && !viewModel.recentSymbols.isEmpty {
                        symbolGrid(for: viewModel.recentSymbols)
                    } else if viewModel.selectedCategory == "Favorites" && !viewModel.favoriteSymbols.isEmpty {
                        symbolGrid(for: viewModel.favoriteSymbols)
                    } else if filteredSymbols.isEmpty && !viewModel.searchText.isEmpty {
                        noResultsView
                    } else {
                        symbolGrid(for: filteredSymbols)
                    }
                }
                
                // Customization Panel
                if showCustomizationPanel {
                    customizationPanel
                }
            }
            .navigationTitle("SF Symbols")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCustomizationPanel.toggle()
                        }
                    } label: {
                        Image(systemName: showCustomizationPanel ? "slider.horizontal.3" : "slider.horizontal.3")
                            .foregroundColor(showCustomizationPanel ? .accentColor : .primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 12) {
            // Main Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search any SF Symbol...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            
            // Custom Symbol Input
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                
                TextField("Enter custom symbol name...", text: $customSymbolName)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                if !customSymbolName.isEmpty {
                    Button {
                        tryCustomSymbol()
                    } label: {
                        Text("Try")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.accentColor))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedCategory = category
                            HapticsManager.shared.softImpact()
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(viewModel.selectedCategory == category ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedCategory == category ? 
                                          Color.accentColor : 
                                          Color(UIColor.tertiarySystemGroupedBackground))
                            )
                            .foregroundStyle(viewModel.selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Quick Access Tabs
    @ViewBuilder
    private var quickAccessTabs: some View {
        if !viewModel.recentSymbols.isEmpty || !viewModel.favoriteSymbols.isEmpty {
            HStack(spacing: 0) {
                if !viewModel.recentSymbols.isEmpty {
                    quickAccessTab(title: "Recents", icon: "clock.fill", category: "Recents")
                }
                
                if !viewModel.favoriteSymbols.isEmpty {
                    quickAccessTab(title: "Favorites", icon: "heart.fill", category: "Favorites")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    private func quickAccessTab(title: String, icon: String, category: String) -> some View {
        Button {
            withAnimation {
                viewModel.selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(viewModel.selectedCategory == category ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(viewModel.selectedCategory == category ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(viewModel.selectedCategory == category ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No symbols found")
                .font(.headline)
            
            Text("Try a different search term or enter the exact SF Symbol name above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    customSymbolName = viewModel.searchText
                    tryCustomSymbol()
                } label: {
                    Label("Try as custom symbol", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
    }
    
    // MARK: - Customization Panel
    private var customizationPanel: some View {
        VStack(spacing: 16) {
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("CUSTOMIZATION")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                
                // Preview
                HStack {
                    Text("Preview")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: viewModel.sfSymbol)
                        .font(.system(size: selectedSize, weight: selectedWeight))
                        .foregroundStyle(previewColor)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        )
                }
                
                // Size Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Size")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(selectedSize)) pt")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $selectedSize, in: 12...48, step: 2)
                        .tint(.accentColor)
                }
                
                // Weight Picker
                HStack {
                    Text("Weight")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $selectedWeight) {
                        Text("Light").tag(Font.Weight.light)
                        Text("Regular").tag(Font.Weight.regular)
                        Text("Medium").tag(Font.Weight.medium)
                        Text("Semibold").tag(Font.Weight.semibold)
                        Text("Bold").tag(Font.Weight.bold)
                    }
                    .pickerStyle(.menu)
                }
                
                // Color Picker
                HStack {
                    Text("Color")
                        .font(.subheadline)
                    Spacer()
                    ColorPicker("", selection: $previewColor)
                        .labelsHidden()
                }
                
                // Apply Button
                Button {
                    applyCustomization()
                } label: {
                    Text("Apply Customization")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Symbol Grid
    @ViewBuilder
    private func symbolGrid(for symbols: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 75))], spacing: 16) {
            ForEach(symbols, id: \.self) { symbol in
                symbolCell(symbol: symbol)
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    private func symbolCell(symbol: String) -> some View {
        let isSelected = viewModel.sfSymbol == symbol
        
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectSymbol(symbol)
                        HapticsManager.shared.softImpact()
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: symbol)
                            .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color(hex: viewModel.colorHex) : .secondary)
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(UIColor.tertiarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        
                        Text(formatSymbolName(symbol))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(.plain)
                
                // Favorite button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleFavorite(symbol)
                        HapticsManager.shared.softImpact()
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite(symbol) ? "heart.fill" : "heart")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(viewModel.isFavorite(symbol) ? .red : .secondary)
                        .padding(5)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatSymbolName(_ name: String) -> String {
        let parts = name.split(separator: ".")
        if let first = parts.first {
            return String(first).capitalized
        }
        return name
    }
    
    private func tryCustomSymbol() {
        guard !customSymbolName.isEmpty else { return }
        
        // Check if the symbol exists by trying to create an image
        let testImage = UIImage(systemName: customSymbolName)
        if testImage != nil {
            viewModel.selectSymbol(customSymbolName)
            customSymbolName = ""
            HapticsManager.shared.success()
        } else {
            HapticsManager.shared.error()
        }
    }
    
    private func applyCustomization() {
        viewModel.iconSize = selectedSize
        viewModel.colorHex = previewColor.toHex() ?? "#007AFF"
        
        switch selectedWeight {
        case .ultraLight: viewModel.iconWeight = "ultralight"
        case .thin: viewModel.iconWeight = "thin"
        case .light: viewModel.iconWeight = "light"
        case .regular: viewModel.iconWeight = "regular"
        case .medium: viewModel.iconWeight = "medium"
        case .semibold: viewModel.iconWeight = "semibold"
        case .bold: viewModel.iconWeight = "bold"
        case .heavy: viewModel.iconWeight = "heavy"
        case .black: viewModel.iconWeight = "black"
        default: viewModel.iconWeight = "regular"
        }
        
        HapticsManager.shared.success()
        withAnimation {
            showCustomizationPanel = false
        }
    }
}
