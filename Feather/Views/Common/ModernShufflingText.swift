import SwiftUI

struct ModernShufflingText: View {
    let text: String
    @State private var displayText: String = ""
    @State private var timer: Timer?

    private let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"

    var body: some View {
        Text(displayText)
            .onAppear {
                displayText = text
            }
            .onChange(of: text) { newValue in
                shuffleTo(newValue)
            }
    }

    private func shuffleTo(_ target: String) {
        let duration: Double = 0.5
        let steps = 15
        let interval = duration / Double(steps)

        timer?.invalidate()

        var currentStep = 0
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            currentStep += 1

            if currentStep >= steps {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    displayText = target
                }
                timer.invalidate()
            } else {
                // Scramble
                let length = target.count
                let scrambled = String((0..<length).map { _ in
                    characters.randomElement()!
                })
                displayText = scrambled
            }
        }
    }
}
