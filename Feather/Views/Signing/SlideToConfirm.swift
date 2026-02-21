import SwiftUI

struct SlideToConfirm: View {
    var onComplete: () -> Void

    @State private var offset: CGFloat = 0
    private let maxWidth: CGFloat = 280

    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(.systemGray6))
                .frame(width: maxWidth, height: 60)
                .overlay(
                    Text("Slide to Confirm")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                )

            HStack {
                ZStack {
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: 60 + offset, height: 50)

                    HStack {
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.trailing, 15)
                    }
                    .frame(width: 60 + offset)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 && value.translation.width <= maxWidth - 70 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if offset > maxWidth - 100 {
                                withAnimation(.spring()) {
                                    offset = maxWidth - 70
                                }
                                HapticsManager.shared.success()
                                onComplete()
                                // Reset after delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    withAnimation {
                                        offset = 0
                                    }
                                }
                            } else {
                                withAnimation(.spring()) {
                                    offset = 0
                                }
                            }
                        }
                )

                Spacer()
            }
            .padding(.horizontal, 5)
            .frame(width: maxWidth)
        }
    }
}
