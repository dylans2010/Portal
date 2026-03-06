import SwiftUI

// MARK: - iOS 17 Symbol Effect Compatibility Modifiers
@available(iOS 17.0, *)
struct BounceEffectModifier<T: Equatable>: ViewModifier {
    let value: T

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.symbolEffect(.bounce, value: value)
        } else {
            content
        }
    }
}

@available(iOS 17.0, *)
struct PulseEffectModifier<T: Equatable>: ViewModifier {
    let value: T

    func body(content: Content) -> some View {
        #if canImport(SwiftUI) && os(iOS)
        if #available(iOS 18.0, *) {
            content.symbolEffect(.pulse, options: .repeating, value: value)
        } else {
            content.symbolEffect(.pulse, value: value)
        }
        #else
        content
        #endif
    }
}

extension View {
    @ViewBuilder
    func pulseEffect() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.pulse, options: .repeating)
        } else if #available(iOS 17.0, *) {
            self.symbolEffect(.pulse)
        } else {
            self
        }
    }

    @ViewBuilder
    func bounceEffect() -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.bounce)
        } else {
            self
        }
    }

    @ViewBuilder
    func bounceEffect<T: Equatable>(_ value: T) -> some View {
        if #available(iOS 17.0, *) {
            self.modifier(BounceEffectModifier(value: value))
        } else {
            self
        }
    }

    @ViewBuilder
    func pulseEffect<T: Equatable>(_ value: T) -> some View {
        if #available(iOS 17.0, *) {
            self.modifier(PulseEffectModifier(value: value))
        } else {
            if let trigger = value as? Bool {
                self
                    .opacity(trigger ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: trigger)
            } else {
                self
            }
        }
    }

    @ViewBuilder
    func ifAvailableiOS17SymbolPulse() -> some View {
        if #available(iOS 17.0, *) {
            self.symbolEffect(.pulse)
        } else {
            self
        }
    }

    @ViewBuilder
    func hideScrollContentBackground() -> some View {
        if #available(iOS 16.0, *) {
            self.scrollContentBackground(.hidden)
        } else {
            self
        }
    }
}
