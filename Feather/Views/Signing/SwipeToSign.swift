import SwiftUI

struct SwipeToSign: View {
    var onComplete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isCompleted = false
    private let maxWidth: CGFloat = 280

    var body: some View {
        ZStack {
            // Background
            Capsule()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: maxWidth, height: 60)

            Text("Swipe to Sign")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .opacity(Double(1 - (offset / 200)))

            // Slider
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 50, height: 50)

                    Image(systemName: "chevron.right.2")
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .bold))
                }
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width > 0 && value.translation.width <= maxWidth - 60 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            if offset > maxWidth - 100 {
                                withAnimation(.spring()) {
                                    offset = maxWidth - 60
                                    isCompleted = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    onComplete()
                                    // Reset after a delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        withAnimation {
                                            offset = 0
                                            isCompleted = false
                                        }
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
