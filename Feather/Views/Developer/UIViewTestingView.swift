import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct UIViewTestingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedView: UIViewType = .offlineView
    @State private var showDismissButton: Bool = true

    enum UIViewType: String, CaseIterable {
        case offlineView = "Offline View"
    }

    var body: some View {
        ZStack {
            // Main content - the selected view
            Group {
                switch selectedView {
                case .offlineView:
                    // Create a custom dismissible version of OfflineView
                    OfflineViewWithDismiss(showDismissButton: $showDismissButton, onDismiss: {
                        dismiss()
                    })
                }
            }

            // Overlay controls
            VStack {
                HStack {
                    // Dropdown picker
                    Menu {
                        ForEach(UIViewType.allCases, id: \.self) { viewType in
                            Button(viewType.rawValue) {
                                selectedView = viewType
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedView.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.clear.opacity(0.95))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }

                    Spacer()

                    // Dismiss button (only when opened from debug mode)
                    if showDismissButton {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}
