// Created by dylan on 1/4/26

import SwiftUI

// MARK: - Helper for Conditional Label Creation
struct ConditionalLabel: View {
    @EnvironmentObject var themeManager: ThemeManager
	let title: LocalizedStringKey
	let systemImage: String
	@AppStorage("Feather.showIconsInAppearance") private var showIcons: Bool = true
	
	var body: some View {
		if showIcons {
			Label(title, systemImage: systemImage)
		} else {
			Text(title)
		}
	}
}

struct ConditionalLabelString: View {
    @EnvironmentObject var themeManager: ThemeManager
	let title: String
	let systemImage: String
	@AppStorage("Feather.showIconsInAppearance") private var showIcons: Bool = true
	
	var body: some View {
		if showIcons {
			Label(title, systemImage: systemImage)
		} else {
			Text(title)
		}
	}
}

// MARK: - Helper for Conditional Image
struct ConditionalImage: View {
    @EnvironmentObject var themeManager: ThemeManager
	let systemName: String
	@AppStorage("Feather.showIconsInAppearance") private var showIcons: Bool = true
	
	var body: some View {
		if showIcons {
			Image(systemName: systemName)
		} else {
			EmptyView()
		}
	}
}
