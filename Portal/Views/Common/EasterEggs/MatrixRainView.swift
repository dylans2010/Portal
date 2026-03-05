import SwiftUI

struct MatrixRainView: View {
    let characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    @State private var columns: [MatrixColumn] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.8)

                HStack(spacing: 4) {
                    ForEach(columns) { column in
                        MatrixColumnView(column: column)
                    }
                }
            }
            .onAppear {
                let columnCount = Int(geometry.size.width / 20)
                columns = (0..<columnCount).map { _ in MatrixColumn() }
            }
        }
        .ignoresSafeArea()
    }
}

struct MatrixColumn: Identifiable {
    let id = UUID()
    var yOffset: CGFloat = CGFloat.random(in: -500...0)
    var speed: CGFloat = CGFloat.random(in: 2...10)
    var characters: [String] = (0..<20).map { _ in "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!.description }
}

struct MatrixColumnView: View {
    @State var column: MatrixColumn
    @State private var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 4) {
            ForEach(0..<column.characters.count, id: \.self) { i in
                Text(column.characters[i])
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(i == column.characters.count - 1 ? .white : .green)
                    .opacity(Double(i) / Double(column.characters.count))
            }
        }
        .offset(y: column.yOffset)
        .onReceive(timer) { _ in
            column.yOffset += column.speed
            if column.yOffset > 1000 {
                column.yOffset = -200
            }
            if Int.random(in: 0...10) == 0 {
                column.characters.removeFirst()
                column.characters.append("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ".randomElement()!.description)
            }
        }
    }
}
