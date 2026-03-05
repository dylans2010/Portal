import SwiftUI

struct KeyboardDirectionPicker: View {
    @Binding var direction: Double
    var color: Color = .blue

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                    .frame(width: 100, height: 100)

                // Degree markings
                ForEach(0..<8) { i in
                    Rectangle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 2, height: 8)
                        .offset(y: -46)
                        .rotationEffect(.degrees(Double(i) * 45))
                }

                // Knob
                Circle()
                    .fill(color)
                    .frame(width: 24, height: 24)
                    .shadow(radius: 2)
                    .offset(y: -40)
                    .rotationEffect(.degrees(direction))

                Text("\(Int(direction))°")
                    .font(.caption.monospacedDigit())
                    .fontWeight(.bold)
            }
            .frame(width: 120, height: 120)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let vector = CGVector(dx: value.location.x - 60, dy: value.location.y - 60)
                        let angle = atan2(vector.dy, vector.dx)
                        var degrees = angle * 180 / .pi + 90
                        if degrees < 0 { degrees += 360 }
                        direction = degrees
                    }
            )
        }
    }
}
