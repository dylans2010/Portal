import SwiftUI

// MARK: - SF Symbols Picker
struct SFSymbolsPickerView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @Environment(\.dismiss) var dismiss
    
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
    
    // Symbol weights
    private let weights = ["ultraLight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black"]
    
    // Symbol scales
    private let scales = ["small", "medium", "large"]
    
    // Rendering modes
    private let renderingModes = ["monochrome", "multicolor", "hierarchical", "palette"]
    
    var filteredSymbols: [String] {
        var symbols: [String] = []
        
        if viewModel.selectedCategory == "All" {
            symbols = symbolsByCategory.values.flatMap { $0 }
        } else {
            symbols = symbolsByCategory[viewModel.selectedCategory] ?? []
        }
        
        if !viewModel.searchText.isEmpty {
            symbols = symbols.filter { 
                $0.lowercased().contains(viewModel.searchText.lowercased()) 
            }
        }
        
        return symbols
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search SF Symbols", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                }
                .padding(8)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(10)
                .padding()
                
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedCategory = category
                                }
                            } label: {
                                Text(category)
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.selectedCategory == category ? 
                                                  Color.accentColor : 
                                                  Color(uiColor: .secondarySystemGroupedBackground))
                                    )
                                    .foregroundStyle(viewModel.selectedCategory == category ? 
                                                    .white : 
                                                    .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
                

                
                // Tabs for Recents and Favorites
                if !viewModel.recentSymbols.isEmpty || !viewModel.favoriteSymbols.isEmpty {
                    HStack(spacing: 0) {
                        if !viewModel.recentSymbols.isEmpty {
                            Button {
                                withAnimation {
                                    viewModel.selectedCategory = "Recents"
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text("Recents")
                                        .font(.subheadline)
                                    Rectangle()
                                        .fill(viewModel.selectedCategory == "Recents" ? Color.accentColor : Color.clear)
                                        .frame(height: 2)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if !viewModel.favoriteSymbols.isEmpty {
                            Button {
                                withAnimation {
                                    viewModel.selectedCategory = "Favorites"
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Text("Favorites")
                                        .font(.subheadline)
                                    Rectangle()
                                        .fill(viewModel.selectedCategory == "Favorites" ? Color.accentColor : Color.clear)
                                        .frame(height: 2)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Symbol grid
                ScrollView {
                    if viewModel.selectedCategory == "Recents" && !viewModel.recentSymbols.isEmpty {
                        symbolGrid(for: viewModel.recentSymbols)
                    } else if viewModel.selectedCategory == "Favorites" && !viewModel.favoriteSymbols.isEmpty {
                        symbolGrid(for: viewModel.favoriteSymbols)
                    } else {
                        symbolGrid(for: filteredSymbols)
                    }
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
            }
        }
    }
    
    @ViewBuilder
    private func symbolGrid(for symbols: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
            ForEach(symbols, id: \.self) { symbol in
                symbolCell(symbol: symbol)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func symbolCell(symbol: String) -> some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectSymbol(symbol)
                    }
                } label: {
                    VStack(spacing: 4) {
                        symbolImage(symbol)
                            .font(fontForSymbol())
                            .foregroundStyle(viewModel.sfSymbol == symbol ? 
                                           Color(hex: viewModel.colorHex) : 
                                           .secondary)
                            .frame(width: 60, height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(viewModel.sfSymbol == symbol ? 
                                         Color.accentColor.opacity(0.1) : 
                                         Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(viewModel.sfSymbol == symbol ? 
                                           Color.accentColor : 
                                           Color.clear, lineWidth: 2)
                            )
                        
                        Text(symbol.split(separator: ".").first?.capitalized ?? symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(.plain)
                
                // Favorite button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.toggleFavorite(symbol)
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite(symbol) ? "heart.fill" : "heart")
                        .font(.caption)
                        .foregroundStyle(viewModel.isFavorite(symbol) ? .red : .secondary)
                        .padding(4)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .offset(x: 5, y: -5)
            }
        }
    }
    
    private func symbolImage(_ name: String) -> Image {
        Image(systemName: name)
    }
    
    private func fontForSymbol() -> Font {
        let baseFont: Font
        switch viewModel.selectedScale {
        case "small":
            baseFont = .title3
        case "large":
            baseFont = .title
        default:
            baseFont = .title2
        }
        
        return baseFont.weight(.regular)
    }
}
