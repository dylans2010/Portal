//
//  ExperimentalSourcesView.swift
//  Portal
//
//  Experimental UI redesigned Sources (Home) view
//

import SwiftUI
import NimbleViews
import CoreData
import AltSourceKit

struct ExperimentalSourcesView: View {
    @StateObject var viewModel = SourcesViewModel.shared
    @State private var searchText = ""
    @State private var showAddSource = false
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .easeInOut(duration: 0.35)
    ) private var sources: FetchedResults<AltSource>
    
    private var filteredSources: [AltSource] {
        let filtered = sources.filter { searchText.isEmpty || ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) }
        return filtered.sorted { s1, s2 in
            let p1 = viewModel.isPinned(s1)
            let p2 = viewModel.isPinned(s2)
            if p1 && !p2 { return true }
            if !p1 && p2 { return false }
            return (s1.name ?? "") < (s2.name ?? "")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ExperimentalUITheme.Spacing.lg) {
                    // Hero Header
                    ExperimentalHeroHeader(
                        title: "Sources",
                        subtitle: "Discover amazing apps",
                        icon: "house.fill"
                    )
                    
                    // Search Bar
                    ExperimentalSearchBar(text: $searchText, placeholder: "Search sources...")
                        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                    
                    // Featured Section (using actual sources)
                    if !filteredSources.isEmpty {
                        ExperimentalFeaturedSection(sources: Array(filteredSources.prefix(3)), viewModel: viewModel)
                    }
                    
                    // Sources Grid (using actual sources)
                    ExperimentalSourcesGrid(sources: filteredSources, viewModel: viewModel)
                }
                .padding(.bottom, 100) // Space for floating tab bar
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.fetchSources(Array(sources), refresh: false)
            }
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Hero Header
struct ExperimentalHeroHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: ExperimentalUITheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.xs) {
                    Text(title)
                        .font(ExperimentalUITheme.Typography.largeTitle)
                        .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(ExperimentalUITheme.Typography.subheadline)
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(ExperimentalUITheme.Gradients.primary)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            .padding(.top, ExperimentalUITheme.Spacing.xl)
        }
    }
}

// MARK: - Search Bar
struct ExperimentalSearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                .font(.system(size: 16, weight: .semibold))
            
            TextField(placeholder, text: $text)
                .font(ExperimentalUITheme.Typography.body)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                }
            }
        }
        .padding(ExperimentalUITheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                .fill(ExperimentalUITheme.Colors.backgroundSecondary)
        )
    }
}

// MARK: - Featured Section
struct ExperimentalFeaturedSection: View {
    let sources: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.md) {
            Text("Featured")
                .font(ExperimentalUITheme.Typography.title3)
                .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            
            if sources.isEmpty {
                Text("No featured sources available")
                    .font(ExperimentalUITheme.Typography.body)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                    .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: ExperimentalUITheme.Spacing.md) {
                        ForEach(sources) { source in
                            NavigationLink(destination: SourceDetailsView(source: source, viewModel: viewModel)) {
                                ExperimentalFeaturedCard(source: source, viewModel: viewModel)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                }
            }
        }
    }
}

// MARK: - Featured Card
struct ExperimentalFeaturedCard: View {
    let source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                .fill(ExperimentalUITheme.Gradients.primary)
                .frame(width: 300, height: 180)
            
            VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.xs) {
                Text(source.name ?? "Unknown Source")
                    .font(ExperimentalUITheme.Typography.headline)
                    .foregroundStyle(.white)
                
                if let repo = viewModel.sources[source] {
                    Text("\(repo.apps.count) apps available")
                        .font(ExperimentalUITheme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text("Loading...")
                        .font(ExperimentalUITheme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(ExperimentalUITheme.Spacing.md)
        }
        .shadow(
            color: ExperimentalUITheme.Shadow.md.color,
            radius: ExperimentalUITheme.Shadow.md.radius,
            x: ExperimentalUITheme.Shadow.md.x,
            y: ExperimentalUITheme.Shadow.md.y
        )
    }
}

// MARK: - Sources Grid
struct ExperimentalSourcesGrid: View {
    let sources: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    
    let columns = [
        GridItem(.flexible(), spacing: ExperimentalUITheme.Spacing.md),
        GridItem(.flexible(), spacing: ExperimentalUITheme.Spacing.md)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.md) {
            Text("All Sources")
                .font(ExperimentalUITheme.Typography.title3)
                .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            
            if sources.isEmpty {
                Text("No sources available")
                    .font(ExperimentalUITheme.Typography.body)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                    .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            } else {
                LazyVGrid(columns: columns, spacing: ExperimentalUITheme.Spacing.md) {
                    ForEach(sources) { source in
                        NavigationLink(destination: SourceDetailsView(source: source, viewModel: viewModel)) {
                            ExperimentalSourceCard(source: source, viewModel: viewModel)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            }
        }
    }
}

// MARK: - Source Card
struct ExperimentalSourceCard: View {
    let source: AltSource
    @ObservedObject var viewModel: SourcesViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.sm) {
            // Icon placeholder or actual icon
            if let iconURL = source.iconURL {
                AsyncImage(url: iconURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md))
                    case .failure(_), .empty:
                        RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                            .fill(ExperimentalUITheme.Gradients.accent)
                            .frame(height: 100)
                            .overlay(
                                Image(systemName: "app.badge.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                            .fill(ExperimentalUITheme.Gradients.accent)
                            .frame(height: 100)
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                    .fill(ExperimentalUITheme.Gradients.accent)
                    .frame(height: 100)
                    .overlay(
                        Image(systemName: "app.badge.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(source.name ?? "Unknown Source")
                    .font(ExperimentalUITheme.Typography.headline)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                if let repo = viewModel.sources[source] {
                    Text("\(repo.apps.count) apps")
                        .font(ExperimentalUITheme.Typography.caption)
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                } else {
                    Text("Loading...")
                        .font(ExperimentalUITheme.Typography.caption)
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.xs)
        }
        .experimentalCard(padding: ExperimentalUITheme.Spacing.sm)
    }
}
