import SwiftUI

struct DoubleTapToSign: View {
    var onComplete: () -> Void

    @State private var isAnimating = false

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 12) {
                Image(systemName: "signature")
                    .font(.system(size: 20, weight: .bold))
                Text("Double Tap to Sign")
                    .font(.system(size: 17, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.accentColor)
                    .shadow(color: Color.accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(isAnimating ? 0.95 : 1.0)
        }
        .onTapGesture(count: 2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isAnimating = true
            }
            HapticsManager.shared.success()
            onComplete()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    isAnimating = false
                }
            }
        }
        .buttonStyle(.plain)
    }
}
