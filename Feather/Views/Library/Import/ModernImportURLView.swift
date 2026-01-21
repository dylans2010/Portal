import SwiftUI
import NimbleViews

// MARK: - ModernImportURLView
struct ModernImportURLView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
	@State private var errorMessage: String?
	@State private var showError = false
	@State private var isImporting = false
    var onImport: (URL) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
				if _useGradients {
					LinearGradient(
						colors: [
							Color.accentColor.opacity(0.15),
							Color.accentColor.opacity(0.08),
							Color.clear
						],
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					)
					.ignoresSafeArea()
				} else {
					Color(uiColor: .systemGroupedBackground)
						.ignoresSafeArea()
				}
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
								_useGradients ?
                                    LinearGradient(
                                        colors: [
                                            Color.accentColor.opacity(0.25),
                                            Color.accentColor.opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
								:
								LinearGradient(
									colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.2)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
                                )
                                .frame(width: 90, height: 90)
							.shadow(color: Color.accentColor.opacity(_useGradients ? 0.3 : 0.1), radius: 15, x: 0, y: 5)
                            
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(
								_useGradients ?
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
								:
								LinearGradient(
									colors: [Color.accentColor, Color.accentColor],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
                                )
                        }
                        .padding(.top, 30)
                        
                        VStack(spacing: 8) {
                            Text(.localized("Import IPA from URL"))
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            
                            Text(.localized("Enter the URL of the IPA file you want to install"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        // URL Input Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 18))
                                
                                TextField(.localized("Enter IPA Link Here"), text: $urlText)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                                    .keyboardType(.URL)
                                .focused($isTextFieldFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    handleImport()
                                }
								.onChange(of: urlText) { _ in
									withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
										errorMessage = nil
										showError = false
									}
								}
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(
									showError ? Color.red : (isTextFieldFocused ? Color.accentColor : Color.clear),
									lineWidth: showError ? 2 : (isTextFieldFocused ? 2 : 0)
								)
								.animation(.spring(response: 0.3, dampingFraction: 0.7), value: showError)
								.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isTextFieldFocused)
                        )
						
						if showError, let errorMessage = errorMessage {
							HStack(spacing: 6) {
								Image(systemName: "exclamationmark.triangle.fill")
									.font(.caption)
								Text(errorMessage)
									.font(.caption)
							}
							.foregroundStyle(.red)
							.transition(.asymmetric(
								insertion: .scale.combined(with: .opacity),
								removal: .opacity
							))
						}
                    }
                    .padding(.horizontal, 24)
                    .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            handleImport()
                        } label: {
                            HStack {
								if isImporting {
									ProgressView()
										.progressViewStyle(CircularProgressViewStyle(tint: .white))
										.scaleEffect(0.8)
								} else {
									Image(systemName: "arrow.down.circle.fill")
										.font(.system(size: 18))
									Text(.localized("Import"))
										.font(.headline)
								}
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                            .padding(.vertical, 16)
                            .background(
								_useGradients ?
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
								:
								LinearGradient(
									colors: [Color.accentColor, Color.accentColor],
									startPoint: .leading,
									endPoint: .trailing
								)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
							.shadow(color: Color.accentColor.opacity(_useGradients ? 0.3 : 0.2), radius: 10, x: 0, y: 5)
                        }
                        .contentShape(Rectangle())
                        .disabled(urlText.isEmpty || isImporting)
                        .opacity(urlText.isEmpty || isImporting ? 0.5 : 1.0)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text(.localized("Cancel"))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: horizontalSizeClass == .regular ? 400 : .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                )
                        }
                        .contentShape(Rectangle())
						.disabled(isImporting)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                }
                .navigationBarHidden(true)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func handleImport() {
		// Clear any previous errors
		withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
			errorMessage = nil
			showError = false
		}
		
		isImporting = true
		
		// Simulate slight delay for better UX
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			// Check if empty
			guard !urlText.isEmpty else {
				showErrorWithAnimation(.localized("Please enter a URL"))
				return
			}
			
			// Trim whitespace and normalize the URL
			var urlString = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
			
			// Auto-add https:// if no scheme is provided
			if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
				urlString = "https://" + urlString
			}
			
			// Check if valid URL format
			guard let url = URL(string: urlString) else {
				showErrorWithAnimation(.localized("Invalid URL Format"))
				return
			}
			
			// Check if it has a scheme (http/https)
			guard let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) else {
				showErrorWithAnimation(.localized("URL must start with http:// or https://"))
				return
			}
			
			// Check if it has a host
			guard let host = url.host, !host.isEmpty else {
				showErrorWithAnimation(.localized("Invalid URL - missing host"))
				return
			}
			
			// Check if it ends with .ipa or .tipa (warn but allow other extensions)
			let pathExtension = url.pathExtension.lowercased()
			let isValidExtension = pathExtension == "ipa" || pathExtension == "tipa"
			
			// If extension is not .ipa or .tipa, still allow but the server should respond with proper content type
			if !isValidExtension && !pathExtension.isEmpty {
				// Allow downloads that might redirect to IPA files or have query parameters
				// The server's Content-Disposition header or actual file type will determine validity
				AppLogManager.shared.info("URL may not be a direct IPA link, attempting download anyway: \(url.absoluteString)", category: "Import")
			}
			
			HapticsManager.shared.impact()
			onImport(url)
			dismiss()
		}
    }
	
	private func showErrorWithAnimation(_ message: String) {
		isImporting = false
		errorMessage = message
		withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
			showError = true
		}
		HapticsManager.shared.error()
	}
}
