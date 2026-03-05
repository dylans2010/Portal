import SwiftUI

// MARK: - Toast Notification Manager
/// Manages toast notifications for showing success/error messages
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toast: ToastMessage?
    
    private init() {}
    
    func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toast = ToastMessage(message: message, type: type)
        }
        
        // Auto-dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                if self.toast?.message == message {
                    self.toast = nil
                }
            }
        }
        
        // Log the toast
        switch type {
        case .success:
            AppLogManager.shared.success(message, category: "Toast")
        case .error:
            AppLogManager.shared.error(message, category: "Toast")
        case .warning:
            AppLogManager.shared.warning(message, category: "Toast")
        case .info:
            AppLogManager.shared.info(message, category: "Toast")
        }
    }
    
    func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            toast = nil
        }
    }
}

// MARK: - Toast Message
struct ToastMessage: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
}

enum ToastType {
    case success
    case error
    case warning
    case info
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundStyle(type.color)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(3)
            
            Spacer(minLength: 0)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(type.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 16)
    }
}

// MARK: - Toast Container View Modifier
struct ToastViewModifier: ViewModifier {
    @ObservedObject var toastManager = ToastManager.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let toast = toastManager.toast {
                ToastView(
                    message: toast.message,
                    type: toast.type,
                    onDismiss: {
                        toastManager.dismiss()
                    }
                )
                .padding(.top, 60)
                .transition(AnyTransition.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(999)
            }
        }
    }
}

// MARK: - View Extension
extension View {
    func withToast() -> some View {
        modifier(ToastViewModifier())
    }
}
