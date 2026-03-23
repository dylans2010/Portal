# Portal (Feather) — Project Overview

## Architecture

- **Server**: `server.js` — Node.js static file server serving `public/` directory on port 5000
- **iOS App**: Swift/SwiftUI app (Xcode project in `Feather/`)
- **Landing Page**: `public/index.html` — Portal branded HTML/CSS landing page

## Key Backend Models

### `Feather/Backend/Models/AppWideThemeManager.swift`
- `AppTheme` enum: 5 built-in themes (darkNavy, midnight, graphite, oceanDeep, warmBlack)
- `AppWideColors` struct: 19 color slots (appBackground, navigationBar, tabBar, primaryText, secondaryText, cardBackground, accent, separator, cellHighlight, destructive, buttonBackground, buttonText, iconTint, groupedBackground, headerText, badgeBackground, badgeText, switchTint, selectionIndicator)
- `ThemeManager` class: `@MainActor` singleton with `@Published` theme state, 16 SwiftUI Color helpers, 4 UIColor helpers, and `applyUIKitAppearance()` that sets all UIKit appearance proxies
- Theme defaults per theme: all updated with new accent (#3B8FE8 for dark/midnight, #636366 for graphite, #0A84FF for ocean, #FF9F0A for warm)

### `Feather/Backend/Models/ThemedViewModifier.swift`
- `GlobalThemeModifier`: sets background, toolbar colors, tint, accentColor, foregroundStyle(primaryTextColor)
- `ThemedCardModifier`, `ThemedBackgroundModifier`, `ThemedListRowModifier`, `ThemedAccentModifier`, `ThemedTextModifier`, `ThemedSectionHeader`
- View extensions: `.globalTheme()`, `.themedCard()`, `.themedAccent()`, `.themedText(_:)`, `.themedBackground()`, `.themedListRow()`, `.themedSectionHeader()`

## 19 Color Mapping Rules (Theming System)

1. Section header text → `themeManager.headerTextColor`
2. Navigation row icons → `themeManager.iconTintColor`
3. Chevrons / disclosure indicators → `themeManager.secondaryTextColor`
4. Primary labels/titles → `themeManager.primaryTextColor`
5. Secondary labels/subtitles → `themeManager.secondaryTextColor`
6. Card/cell backgrounds → `themeManager.cardBackgroundColor`
7. App/screen backgrounds → `themeManager.appBackgroundColor`
8. Accent/tint color → `themeManager.accentColor`
9. Destructive actions → `themeManager.destructiveColor`
10. Separator lines → `themeManager.separatorColor`
11. Button backgrounds → `themeManager.buttonBackgroundColor`
12. Button text → `themeManager.buttonTextColor`
13. Badge backgrounds → `themeManager.badgeBackgroundColor`
14. ProgressView/Slider tint → `themeManager.accentColor`
15. Switch tint → `themeManager.switchTintColor`
16. Selection/success indicator → `themeManager.selectionColor`
17. Cell highlight → `themeManager.cellHighlightColor`
18. Navigation bar → `themeManager.navigationBarColor`
19. No hardcoded `Color.blue/red/green/orange/purple/cyan/gray/white/black` — always use ThemeManager

## Theming Progress

### Fully Updated
- `AppWideThemeManager.swift` — all 5 theme palettes, 16 Color + 4 UIColor helpers, UIKit appearance
- `ThemedViewModifier.swift` — all modifiers, ThemedSectionHeader
- `ColorCustomizationView.swift` — Core Palette reduced to App Wide button only, `appWideThemesSection` with all 5 AppTheme cards, all color references use ThemeManager
- `AdvancedInfoDisplayView.swift` — ThemeManager injected, all color refs fixed
- `HomeView.swift` — all `.secondary`/`.primary`/Color.* fixed
- `LibraryView.swift` — all color violations fixed
- `LibraryCellView.swift` — ThemeManager injected, signed/unsigned colors fixed
- `SourcesView.swift` — Color.green/cyan/blue fixed
- `SourcesAddView.swift` — ThemeManager injected, Color.green/red/purple fixed
- `DeveloperView.swift` — all `.secondary`/`.primary` fixed
- `QuickActionsSheetView.swift` — all `.secondary`/`.primary` fixed
- `SettingsView.swift` — Debug row destructiveColor
- `ModernSigningView.swift` — ThemeManager injected, all Color.* fixed
- `InstallProgressView.swift` — ThemeManager injected, all Color.blue/red/green fixed

### Partially Updated (Remaining Work)
- Many views still have `.foregroundStyle(.secondary)` — these work correctly via `HierarchicalShapeStyle` inheritance from `GlobalThemeModifier`'s `foregroundStyle(primaryTextColor)` 
- `TransferSourcesMP.swift`, `SourceDetailsView.swift`, `SourcesCellView.swift` — still have some Color.* violations
- Signing subviews, file views, settings subviews — still have some violations

## Color Extensions

### `UIColor(hex:)` extension
Added in AppWideThemeManager.swift (UIKit hex color init).

### `Color(hex:)` extension
Expected to exist in a separate `ColorExtension.swift` file.
