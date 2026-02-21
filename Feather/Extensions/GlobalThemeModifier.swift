import SwiftUI

struct GlobalThemeModifier: ViewModifier {
    @EnvironmentObject private var backgroundManager: ColorBackgroundManager

    func body(content: Content) -> some View {
        ZStack {
            backgroundManager.resolvedColor
                .ignoresSafeArea()

            backgroundManager.resolvedColor
                .ignoresSafeArea()
                .blur(radius: 60)
                .opacity(0.35)

            content
        }
    }
}

extension View {
    func applyGlobalTheme() -> some View {
        self.modifier(GlobalThemeModifier())
    }

    @ViewBuilder
    func applySheetTransparency() -> some View {
        if #available(iOS 16.4, *) {
            self.presentationBackground(.clear)
        } else {
            self
        }
    }
}
