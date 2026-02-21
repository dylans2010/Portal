import SwiftUI
import NimbleViews

struct ColorCustomizationView: View {
    @EnvironmentObject private var backgroundManager: ColorBackgroundManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                colorPickerRow(
                    title: "Main Color",
                    color: $backgroundManager.baseColor,
                    icon: "paintpalette.fill"
                )
            } header: {
                Text("Main Color")
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Main Color")
        .navigationBarTitleDisplayMode(.inline)
        .hideScrollContentBackground()
    }

    private func colorPickerRow(title: String, color: Binding<Color>, icon: String) -> some View {
        ColorPicker(selection: color, supportsOpacity: false) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.wrappedValue.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(color.wrappedValue)
                }
                Text(title)
                    .font(.body)

                Spacer()

                Circle()
                    .fill(color.wrappedValue)
                    .frame(width: 20, height: 20)
                    .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
            }
        }
    }
}
