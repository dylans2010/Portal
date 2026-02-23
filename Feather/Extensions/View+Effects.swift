import SwiftUI

// MARK: - iOS 18 Symbol Effect Compatibility Modifiers

/// A modifier that applies a bounce symbol effect on iOS 18+ when a value changes.
struct BounceEffectModifier<T: Equatable>: ViewModifier {
    let value: T

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.symbolEffect(.bounce, value: value)
        } else {
            content
        }
    }
}

/// A modifier that applies a pulse symbol effect on iOS 18+ when a value changes.
struct PulseEffectModifier<T: Equatable>: ViewModifier {
    let value: T

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.symbolEffect(.pulse, options: .repeating, value: value)
        } else {
            if let trigger = value as? Bool {
                content
                    .opacity(trigger ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: trigger)
            } else {
                content
            }
        }
    }
}

/// A modifier that applies a one-time bounce symbol effect on iOS 18+.
@available(iOS 18.0, *)
struct BounceOnceModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.symbolEffect(.bounce, options: .nonRepeating)
    }
}

/// A modifier that applies an appear symbol effect on iOS 18+.
struct AppearEffectModifier: ViewModifier {
    let when: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.symbolEffect(.appear, value: when)
        } else if #available(iOS 17.0, *) {
            content.symbolEffect(.appear)
        } else {
            content
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a repeating pulse symbol effect on iOS 18+.
    @ViewBuilder
    func pulseEffect() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.pulse, options: .repeating)
        } else {
            self
        }
    }

    /// Applies a repeating bounce symbol effect on iOS 18+.
    @ViewBuilder
    func bounceEffect() -> some View {
        if #available(iOS 18.0, *) {
            self.symbolEffect(.bounce, options: .repeating)
        } else {
            self
        }
    }

    /// Applies a bounce symbol effect on iOS 18+ when the provided value changes.
    func bounceEffect<T: Equatable>(_ value: T) -> some View {
        self.modifier(BounceEffectModifier(value: value))
    }

    /// Applies a pulse symbol effect on iOS 18+ when the provided value changes.
    func pulseEffect<T: Equatable>(_ value: T) -> some View {
        self.modifier(PulseEffectModifier(value: value))
    }

    /// Applies a one-time bounce symbol effect on iOS 18+.
    @ViewBuilder
    func bounceEffectOnce() -> some View {
        if #available(iOS 18.0, *) {
            self.modifier(BounceOnceModifier())
        } else {
            self
        }
    }

    /// Applies an appear symbol effect on iOS 18+ when the provided condition is met.
    @ViewBuilder
    func appearEffect(when: Bool) -> some View {
        if #available(iOS 18.0, *) {
            self.modifier(AppearEffectModifier(when: when))
        } else {
            self
        }
    }

    /// Applies a pulse symbol effect on iOS 18+.
    @ViewBuilder
    func ifAvailableiOS18SymbolPulse() -> some View {
        if #available(iOS 18, *) {
            self.symbolEffect(.pulse)
        } else {
            self
        }
    }
}
