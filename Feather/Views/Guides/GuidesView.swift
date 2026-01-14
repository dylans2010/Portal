import SwiftUI
import NimbleViews

// MARK: - GuidesView
struct GuidesView: View {
    @AppStorage("forceShowGuides") private var forceShowGuides = false
    @State private var guides: [Guide] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NBNavigationView(.localized("Guides")) {
            Group {
                if forceShowGuides {
                    guidesListView
                } else {
                    placeholderView
                }
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
            
            Text(.localized("Guides are coming soon"))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(.localized("Check back later for helpful guides and tutorials."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                    Text("Loading guides...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.red)
                    
                    Text("Failed to load guides")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                    
                    Text("There are no guides in the repository yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                                            .foregroundStyle(.primary)
                                        
                                        if guide.type == .directory {
                                            Text("Directory")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    } header: {
                        Text("Available Guides")
                    } footer: {
                        Text("Read guides for helpful tips and tools.")
                    }
                }
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
