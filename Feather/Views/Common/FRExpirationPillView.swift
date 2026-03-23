import SwiftUI

// MARK: - View
struct FRExpirationPillView: View {
    @EnvironmentObject var themeManager: ThemeManager
	let title: String
	let revoked: Bool
	let expiration: Date.ExpirationInfo?
	
	var body: some View {
		let textLabel = revoked
		? .localized("Revoked")
		: expiration?.formatted ?? title
		
		let textForeground = (expiration == nil)
		? themeManager.accentColor
		: Color(hex: themeManager.resolvedColors.badgeText)
		
		let textBackground = revoked
		? Color.red
		: expiration?.color.opacity(0.85) ?? Color(hex: themeManager.resolvedColors.badgeBackground)
		
		Text(textLabel)
			.lineLimit(0)
			.font(.headline.bold())
			.foregroundStyle(textForeground)
			.padding(.horizontal, 12)
			.padding(.vertical, 6)
			.background(textBackground)
			.clipShape(Capsule())
	}
}

