import SwiftUI

struct GlitchDeveloperModeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var glitchOffset: CGFloat = 0
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Color.red.opacity(0.1).ignoresSafeArea()
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                    .offset(x: glitchOffset)

                Text("YOU AREN'T SUPPOSED TO BE HERE")
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .offset(x: -glitchOffset)

                Text("ILLEGAL ACCESS DETECTED")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .opacity(0.8)

                Button {
                    dismiss()
                } label: {
                    Text("GET ME OUT")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.top, 40)
            }
        }
        .onReceive(timer) { _ in
            if Int.random(in: 0...5) == 0 {
                glitchOffset = CGFloat.random(in: -5...5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    glitchOffset = 0
                }
            }
        }
    }
}
