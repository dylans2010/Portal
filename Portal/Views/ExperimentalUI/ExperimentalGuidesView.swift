//
//  ExperimentalGuidesView.swift
//  Portal
//
//  Experimental UI redesigned Guides view
//

import SwiftUI

struct ExperimentalGuidesView: View {
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
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Guides List
struct ExperimentalGuidesList: View {
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
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.sm) {
            // Category Badge
            HStack {
                Text(categories[index % categories.count])
                    .font(ExperimentalUITheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                    .padding(.horizontal, ExperimentalUITheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(ExperimentalUITheme.Colors.accentPrimary.opacity(0.15))
                    )
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("\(Int.random(in: 3...10)) min")
                        .font(ExperimentalUITheme.Typography.caption)
                }
                .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
            }
            
            // Title & Description
            VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.xs) {
                Text("Guide Title \(index + 1)")
                    .font(ExperimentalUITheme.Typography.headline)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Text("Learn how to effectively use Feather with this comprehensive guide covering all essential features.")
                    .font(ExperimentalUITheme.Typography.callout)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
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
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, ExperimentalUITheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.sm)
                        .fill(ExperimentalUITheme.Gradients.primary)
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
    
    let categories = ["Installation", "Signing", "Troubleshooting", "Tips", "Advanced"]
}
