//
//  ExperimentalLibraryView.swift
//  Portal
//
//  Experimental UI redesigned Library view
//

import SwiftUI

struct ExperimentalLibraryView: View {
    @EnvironmentObject var themeManager: ThemeManager
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
            .globalTheme()
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Filter Chip
struct ExperimentalFilterChip: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(ExperimentalUITheme.Typography.callout)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : Color(hex: themeManager.resolvedColors.primaryText))
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                .padding(.vertical, ExperimentalUITheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(themeManager.accentColor) :
                              AnyShapeStyle(Color(hex: themeManager.resolvedColors.cardBackground)))
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
    @EnvironmentObject var themeManager: ThemeManager
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
    @EnvironmentObject var themeManager: ThemeManager
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
                    .themedText(.primary)
                
                Text("Version 1.\(index).0")
                    .font(ExperimentalUITheme.Typography.caption)
                    .themedText(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(themeManager.accentColor)
                    Text("Signed")
                        .font(ExperimentalUITheme.Typography.caption)
                        .themedText(.secondary)
                }
            }
            
            Spacer()
            
            // Action Button
            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .themedText(.secondary)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(hex: themeManager.resolvedColors.cardBackground))
                    )
            }
        }
        .padding(ExperimentalUITheme.Spacing.md)
        .themedCard()
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                .shadow(
                    color: ExperimentalUITheme.Shadow.sm.color,
                    radius: ExperimentalUITheme.Shadow.sm.radius,
                    x: ExperimentalUITheme.Shadow.sm.x,
                    y: ExperimentalUITheme.Shadow.sm.y
                )
        )
    }
}
