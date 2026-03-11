import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "swift")
                .imageScale(.large)
                .foregroundStyle(.orange)
            Text("SwiftCode demo")
                .font(.title)
                .bold()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}