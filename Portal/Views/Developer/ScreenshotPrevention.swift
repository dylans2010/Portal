import SwiftUI

struct ScreenshotPreventingView<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        _ScreenshotPreventingView(content: content)
    }
}

private struct _ScreenshotPreventingView<Content: View>: UIViewRepresentable {
    let content: Content

    func makeUIView(context: Context) -> UIView {
        let textField = UITextField()
        textField.isSecureTextEntry = true

        let hostingController = UIHostingController(rootView: content)
        hostingController.view.backgroundColor = .clear

        // Find the canvas/container view that actually hides content
        // In iOS 13+ this is usually a private subview of the textfield
        if let canvas = textField.subviews.first(where: { type(of: $0).description().contains("Canvas") }) {
            canvas.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: canvas.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: canvas.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: canvas.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: canvas.bottomAnchor)
            ])
        } else {
            // Fallback for different iOS versions/TextField internal changes
            textField.addSubview(hostingController.view)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hostingController.view.leadingAnchor.constraint(equalTo: textField.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
                hostingController.view.topAnchor.constraint(equalTo: textField.topAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: textField.bottomAnchor)
            ])
        }

        textField.isUserInteractionEnabled = true
        return textField
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ScreenshotPreventionView: View {
    @Environment(\.dismiss) private var dismiss
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "eye.slash.fill")
                .font(.system(size: 80))
                .foregroundStyle(.orange.gradient)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text("What are you doing?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("You cannot screenshot anything on Developer Mode to maintain this information private.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                if let onDismiss = onDismiss {
                    onDismiss()
                } else {
                    dismiss()
                }
            } label: {
                Text("I Understand")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemBackground))
    }
}

#Preview {
    ScreenshotPreventionView()
}
