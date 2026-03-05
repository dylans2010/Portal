//
//  ExperimentalUITheme.swift
// Portal
//
//  Created for Experimental UI Feature
//

import SwiftUI

// MARK: - Experimental UI Theme
/// Design system for the experimental UI redesign
struct ExperimentalUITheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary gradient colors
        static let gradientStart = Color(hex: "#6366F1") // Indigo
        static let gradientEnd = Color(hex: "#8B5CF6")   // Purple
        
        // Accent colors
        static let accentPrimary = Color(hex: "#8B5CF6")
        static let accentSecondary = Color(hex: "#06B6D4") // Cyan
        
        // Background colors
        static let backgroundPrimary = Color.clear
        static let backgroundSecondary = Color.clear
        static let backgroundTertiary = Color.clear
        
        // Card colors
        static let cardBackground = Color.clear
        static let cardBorder = Color.gray.opacity(0.2)
        
        // Text colors
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        static let textTertiary = Color(.tertiaryLabel)
    }
    
    // MARK: - Gradients
    struct Gradients {
        static let primary = LinearGradient(
            gradient: Gradient(colors: [Colors.gradientStart, Colors.gradientEnd]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accent = LinearGradient(
            gradient: Gradient(colors: [Colors.accentPrimary, Colors.accentSecondary]),
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let subtle = LinearGradient(
            gradient: Gradient(colors: [
                Colors.gradientStart.opacity(0.1),
                Colors.gradientEnd.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let sm: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = 
            (.black.opacity(0.1), 2, 0, 1)
        static let md: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = 
            (.black.opacity(0.15), 4, 0, 2)
        static let lg: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) = 
            (.black.opacity(0.2), 8, 0, 4)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
        static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
        static let title2 = Font.system(size: 22, weight: .bold, design: .rounded)
        static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 17, weight: .regular, design: .rounded)
        static let callout = Font.system(size: 16, weight: .regular, design: .rounded)
        static let subheadline = Font.system(size: 15, weight: .regular, design: .rounded)
        static let footnote = Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
    }
}

// MARK: - Experimental UI Card Modifier
struct ExperimentalCardModifier: ViewModifier {
    var padding: CGFloat = ExperimentalUITheme.Spacing.md
    var cornerRadius: CGFloat = ExperimentalUITheme.CornerRadius.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(ExperimentalUITheme.Colors.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: ExperimentalUITheme.Shadow.md.color,
                radius: ExperimentalUITheme.Shadow.md.radius,
                x: ExperimentalUITheme.Shadow.md.x,
                y: ExperimentalUITheme.Shadow.md.y
            )
    }
}

extension View {
    func experimentalCard(padding: CGFloat = ExperimentalUITheme.Spacing.md, 
                         cornerRadius: CGFloat = ExperimentalUITheme.CornerRadius.lg) -> some View {
        modifier(ExperimentalCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Experimental UI Gradient Background Modifier
struct ExperimentalGradientBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            ExperimentalUITheme.Gradients.subtle
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    func experimentalGradientBackground() -> some View {
        modifier(ExperimentalGradientBackground())
    }
}
