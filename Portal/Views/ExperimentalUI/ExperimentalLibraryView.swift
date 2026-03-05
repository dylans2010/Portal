//
//  ExperimentalLibraryView.swift
//  Portal
//
//  Experimental UI redesigned Library view
//

import SwiftUI

struct ExperimentalLibraryView: View {
    @State private var selectedFilter: LibraryFilter = .all
    
    enum LibraryFilter: String, CaseIterable {
        case all = "All"
        case signed = "Signed"
        case imported = "Imported"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ExperimentalUITheme.Spacing.lg) {
                    // Hero Header
                    ExperimentalHeroHeader(
                        title: "Library",
                        subtitle: "Your installed apps",
                        icon: "square.grid.2x2"
                    )
                    
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ExperimentalUITheme.Spacing.sm) {
                            ForEach(LibraryFilter.allCases, id: \.self) { filter in
                                ExperimentalFilterChip(
                                    title: filter.rawValue,
                                    isSelected: selectedFilter == filter
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                    }
                    
                    // Apps List
                    ExperimentalLibraryAppsGrid()
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Filter Chip
struct ExperimentalFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ExperimentalUITheme.Typography.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : ExperimentalUITheme.Colors.textPrimary)
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                .padding(.vertical, ExperimentalUITheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? ExperimentalUITheme.Gradients.primary : 
                              LinearGradient(gradient: Gradient(colors: [ExperimentalUITheme.Colors.backgroundSecondary]), 
                                           startPoint: .leading, endPoint: .trailing))
                )
                .shadow(
                    color: isSelected ? ExperimentalUITheme.Shadow.sm.color : .clear,
                    radius: isSelected ? ExperimentalUITheme.Shadow.sm.radius : 0,
                    x: ExperimentalUITheme.Shadow.sm.x,
                    y: ExperimentalUITheme.Shadow.sm.y
                )
        }
    }
}

// MARK: - Library Apps Grid
struct ExperimentalLibraryAppsGrid: View {
    var body: some View {
        VStack(spacing: ExperimentalUITheme.Spacing.md) {
            ForEach(0..<4) { index in
                ExperimentalLibraryAppRow(index: index)
            }
        }
        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
    }
}

// MARK: - Library App Row
struct ExperimentalLibraryAppRow: View {
    let index: Int
    
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.md) {
            // App Icon
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                .fill(ExperimentalUITheme.Gradients.accent)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "app.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                )
            
            // App Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Application \(index + 1)")
                    .font(ExperimentalUITheme.Typography.headline)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Text("Version 1.\(index).0")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                    Text("Signed")
                        .font(ExperimentalUITheme.Typography.caption)
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Action Button
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(ExperimentalUITheme.Colors.backgroundSecondary)
                    )
            }
        }
        .padding(ExperimentalUITheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                .fill(ExperimentalUITheme.Colors.cardBackground)
                .shadow(
                    color: ExperimentalUITheme.Shadow.sm.color,
                    radius: ExperimentalUITheme.Shadow.sm.radius,
                    x: ExperimentalUITheme.Shadow.sm.x,
                    y: ExperimentalUITheme.Shadow.sm.y
                )
        )
    }
}
