//
//  ExperimentalGuidesView.swift
//  Portal
//
//  Experimental UI redesigned Guides view
//

import SwiftUI

struct ExperimentalGuidesView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    @State private var selectedCategory: GuideCategory = .all
    
    enum GuideCategory: String, CaseIterable {
        case all = "All"
        case installation = "Installation"
        case signing = "Signing"
        case troubleshooting = "Troubleshooting"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ExperimentalUITheme.Spacing.lg) {
                    // Hero Header
                    ExperimentalHeroHeader(
                        title: "Guides",
                        subtitle: "Learn how to use Feather",
                        icon: "book.fill"
                    )
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: ExperimentalUITheme.Spacing.sm) {
                            ForEach(GuideCategory.allCases, id: \.self) { category in
                                ExperimentalFilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                    }
                    
                    // Guides List
                    ExperimentalGuidesList()
                }
                .padding(.bottom, 100)
            }
            .globalTheme()
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Guides List
struct ExperimentalGuidesList: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    var body: some View {
        VStack(spacing: ExperimentalUITheme.Spacing.md) {
            ForEach(0..<5) { index in
                ExperimentalGuideCard(index: index)
            }
        }
        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
    }
}

// MARK: - Guide Card
struct ExperimentalGuideCard: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.sm) {
            // Category Badge
            HStack {
                Text(categories[index % categories.count])
                    .font(ExperimentalUITheme.Typography.caption)
                    .fontWeight(.semibold)
                    .themedText(.badge)
                    .padding(.horizontal, ExperimentalUITheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(hex: themeManager.resolvedColors.badgeBackground))
                    )
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("\(Int.random(in: 3...10)) min")
                        .font(ExperimentalUITheme.Typography.caption)
                }
                .themedText(.secondary)
            }
            
            // Title & Description
            VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.xs) {
                Text("Guide Title \(index + 1)")
                    .font(ExperimentalUITheme.Typography.headline)
                    .themedText(.primary)
                
                Text("Learn how to effectively use Feather with this comprehensive guide covering all essential features.")
                    .font(ExperimentalUITheme.Typography.callout)
                    .themedText(.secondary)
                    .lineLimit(2)
            }
            
            // Read Button
            Button(action: {}) {
                HStack {
                    Text("Read Guide")
                        .font(ExperimentalUITheme.Typography.callout)
                        .fontWeight(.semibold)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color(hex: themeManager.resolvedColors.buttonText))
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExperimentalUITheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.sm)
                        .fill(themeManager.accentColor)
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
    
    let categories = ["Installation", "Signing", "Troubleshooting", "Tips", "Advanced"]
}
