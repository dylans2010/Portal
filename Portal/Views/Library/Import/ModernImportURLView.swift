import SwiftUI
import NimbleViews

// MARK: - ModernImportURLView
struct ModernImportURLView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@AppStorage("Feather.useGradients") private var _useGradients: Bool = true
	@AppStorage("Feather.recentImportURLs") private var recentURLsData: Data = Data()
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
	@State private var errorMessage: String?
	@State private var showError = false
	@State private var isImporting = false
	@State private var recentURLs: [String] = []
    var onImport: (URL) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerIconView
                        
                        titleSection
                        
                        urlInputField

                        recentURLsSection

                        Spacer(minLength: 40)

                        actionButtons
                    }
                    .frame(maxWidth: .infinity)
                }
                .navigationBarHidden(true)
            }
        }
        .onAppear {
			loadRecentURLs()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backgroundView: some View {
        Color.clear
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var headerIconView: some View {
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
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(.localized("Import IPA From URL"))
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(.localized("Enter the URL of the IPA file you want to install."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    @ViewBuilder
    private var urlInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 18))

                TextField(.localized("https://example.com/test.ipa"), text: $urlText)
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

                // Paste button
                if !urlText.isEmpty {
                    Button {
                        urlText = ""
                        HapticsManager.shared.softImpact()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 18))
                    }
                } else {
                    Button {
                        if let clipboardString = UIPasteboard.general.string, !clipboardString.isEmpty {
                            urlText = clipboardString
                            HapticsManager.shared.softImpact()
                        }
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                            .foregroundStyle(Color.accentColor)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.clear)
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
                .transition(AnyTransition.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: horizontalSizeClass == .regular ? 500 : .infinity)
    }

    @ViewBuilder
    private var recentURLsSection: some View {
        if !recentURLs.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 14))
                    Text(.localized("Recents"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        recentURLs.removeAll()
                        saveRecentURLs()
                        HapticsManager.shared.softImpact()
                    } label: {
                        Text(.localized("Clear"))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }

                VStack(spacing: 8) {
                    ForEach(Array(recentURLs.prefix(3)), id: \.self) { urlString in
                        Button {
                            urlText = urlString
                            HapticsManager.shared.softImpact()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "link")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.system(size: 14))

                                Text(urlString)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Image(systemName: "arrow.up.left")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 12))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.clear)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
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
                            .fill(Color.clear)
                    )
            }
            .contentShape(Rectangle())
            .disabled(isImporting)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
    
    private func loadRecentURLs() {
		if let urls = try? JSONDecoder().decode([String].self, from: recentURLsData) {
			recentURLs = urls
		}
	}
	
	private func saveRecentURLs() {
		if let data = try? JSONEncoder().encode(recentURLs) {
			recentURLsData = data
		}
	}
	
	private func addToRecentURLs(_ urlString: String) {
		// Remove if already exists
		recentURLs.removeAll { $0 == urlString }
		// Add to front
		recentURLs.insert(urlString, at: 0)
		// Keep only last 5
		if recentURLs.count > 5 {
			recentURLs = Array(recentURLs.prefix(5))
		}
		saveRecentURLs()
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
				showErrorWithAnimation(.localized("Please Enter A URL"))
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
				showErrorWithAnimation(.localized("Invalid URL - Missing Host"))
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
			addToRecentURLs(url.absoluteString)
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
