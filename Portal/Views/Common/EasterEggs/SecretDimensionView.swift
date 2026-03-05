import SwiftUI

struct SecretDimensionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Animated background
            ZStack {
                ForEach(0..<10) { i in
                    Circle()
                        .stroke(LinearGradient(colors: [.blue, .purple, .cyan], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                        .frame(width: CGFloat(i * 50), height: CGFloat(i * 50))
                        .rotation3DEffect(.degrees(rotation + Double(i * 10)), axis: (x: 1, y: 1, z: 0))
                        .opacity(0.3)
                }
            }

            VStack(spacing: 30) {
                Text("SECRET DIMENSION")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple, .cyan], startPoint: .leading, endPoint: .trailing)
                    )
                    .shadow(color: .blue.opacity(0.5), radius: 10, x: 0, y: 0)

                VStack(spacing: 15) {
                    SecretInfoRow(label: "STATUS", value: "ENCRYPTED")
                    SecretInfoRow(label: "ACCESS", value: "OMNIPOTENT")
                    SecretInfoRow(label: "LOCATION", value: "UNKNOWN")
                }
                .padding(25)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )

                Button {
                    dismiss()
                } label: {
                    Text("RETURN TO REALITY")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Capsule().fill(Color.blue))
                }
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

struct SecretInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)
        }
    }
}
