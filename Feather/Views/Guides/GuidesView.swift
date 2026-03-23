import SwiftUI
import NimbleViews

// MARK: - GuidesView
struct GuidesView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedGuide: Guide?
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @StateObject private var hideManager = GuidesHideManager.shared
    @State private var guides: [Guide] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NBNavigationView(.localized("Guides")) {
            Group {
                if forceShowGuides {
                    if !hideManager.isHidden("guides.guidesList") {
                        guidesListView
                    }
                } else {
                    if !hideManager.isHidden("guides.placeholderView") {
                        placeholderView
                    }
                }
            }
            .globalTheme()
        }
        .sheet(item: $selectedGuide) { guide in
            GuideDetailView(guide: guide)
        }
        .onReceive(NotificationCenter.default.publisher(for: .gestureOpenGuideDetails)) { notification in
            if let guide = notification.object as? Guide {
                selectedGuide = guide
            }
        }
        .task {
            if forceShowGuides && guides.isEmpty {
                await fetchGuides()
            }
        }
        .onChange(of: forceShowGuides) { newValue in
            if newValue && guides.isEmpty {
                Task {
                    await fetchGuides()
                }
            }
        }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.fill")
                .font(.system(size: 70))
                .foregroundStyle(.secondary)
            
            Text(.localized("Why are you here?"))
                .font(.title2)
                .fontWeight(.semibold)
                .themedText(.primary)
            
            Text(.localized("Are you lost, or why are you here? You shouldn't even be here on this view lol."))
                .font(.subheadline)
                .themedText(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var guidesListView: some View {
        Group {
            if isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .tint(themeManager.accentColor)
                    Text("Loading Guides")
                        .font(.subheadline)
                        .themedText(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(Color(hex: themeManager.resolvedColors.destructive))
                    
                    Text("Failed To Load Guides")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .themedText(.primary)
                    
                    Text(error)
                        .font(.subheadline)
                        .themedText(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button("Retry") {
                        Task {
                            await fetchGuides()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if guides.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    
                    Text("No Guides Available")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .themedText(.primary)
                    
                    Text("There are no guides in the repository yet.")
                        .font(.subheadline)
                        .themedText(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(guides) { guide in
                            NavigationLink(destination: GuideDetailView(guide: guide)) {
                                HStack {
                                    Image(systemName: guide.type == .file ? "doc.text" : "folder")
                                        .foregroundStyle(.blue)
                                        .font(.title3)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(guide.displayName)
                                            .font(.body)
                                            .themedText(.primary)
                                        
                                        if guide.type == .directory {
                                            Text("Directory")
                                                .font(.caption)
                                                .themedText(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .onTapGesture {
                                Task {
                                    await GestureManager.shared.performAction(for: .singleTap, in: .guides, context: guide)
                                }
                            }
                            .onTapGesture(count: 2) {
                                Task {
                                    await GestureManager.shared.performAction(for: .doubleTap, in: .guides, context: guide)
                                }
                            }
                            .onLongPressGesture {
                                Task {
                                    await GestureManager.shared.performAction(for: .longPress, in: .guides, context: guide)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task {
                                        await GestureManager.shared.performAction(for: .leftSwipe, in: .guides, context: guide)
                                    }
                                } label: {
                                    Label("Action", systemImage: "hand.tap")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task {
                                        await GestureManager.shared.performAction(for: .rightSwipe, in: .guides, context: guide)
                                    }
                                } label: {
                                    Label("Action", systemImage: "hand.tap")
                                }
                                .tint(.accentColor)
                            }
                        }
                    } header: {
                        Text("Available Guides")
                            .themedText(.header)
                    } footer: {
                        Text("Read helpful tips, guides, and more.")
                    }
                }
            .scrollContentBackground(.hidden)
                .refreshable {
                    await fetchGuides()
                }
            }
        }
    }
    
    private func fetchGuides() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedGuides = try await GitHubGuidesService.shared.fetchGuides()
            guides = fetchedGuides
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
