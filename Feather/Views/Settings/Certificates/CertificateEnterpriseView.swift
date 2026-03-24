import SwiftUI

// MARK: - View

struct CertificateEnterpriseView: View {
    @EnvironmentObject var themeManager: AppWideThemeManager
	@Environment(\.dismiss) private var dismiss
	@StateObject private var fetcher = CertificateEnterpriseFetcher.shared
	@State private var certificates: [EnterpriseCertificate] = []
	@State private var isExtracting: Bool = false
	@State private var isInstalling: Bool = false
	@State private var errorMessage: String? = nil
	@State private var importErrorMessage: String? = nil
	@State private var successCertName: String? = nil

	private let extractor = EnterpriseCertExtracter()
	private let expirationFormatter: DateFormatter = {
		let f = DateFormatter()
		f.dateStyle = .medium
		f.timeStyle = .none
		return f
	}()

	var body: some View {
		NavigationStack {
			ZStack {
				Color(UIColor.systemGroupedBackground)
					.ignoresSafeArea()

				Group {
					if fetcher.isFetching || isExtracting {
						loadingView
					} else if let error = errorMessage ?? fetcher.errorMessage {
						errorView(message: error)
					} else if certificates.isEmpty {
						emptyView
					} else {
						certificateScrollView
					}
				}

				if isInstalling {
					installOverlay
				}
			}
			.navigationTitle("Enterprise Certificates")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					if !fetcher.isFetching && !isExtracting {
						Button("Fetch") {
							startPipeline(forceRefresh: true)
						}
					}
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark.circle.fill")
							.font(.title2)
							.foregroundStyle(.secondary)
							.symbolRenderingMode(.hierarchical)
					}
					.buttonStyle(.plain)
				}
			}
			.alert(
				"Import Error",
				isPresented: Binding(
					get: { importErrorMessage != nil },
					set: { if !$0 { importErrorMessage = nil } }
				)
			) {
				Button("OK", role: .cancel) { importErrorMessage = nil }
			} message: {
				if let msg = importErrorMessage {
					Text(msg)
				}
			}
			.alert(
				"Certificate Installed",
				isPresented: Binding(
					get: { successCertName != nil },
					set: { if !$0 { successCertName = nil } }
				)
			) {
				Button("OK") { successCertName = nil; restartApp() }
			} message: {
				if let name = successCertName {
					Text("\(name) was added successfully saved into your device!")
				}
			}
		}
		.onAppear {
			let loaded = EnterpriseCertExtracter.loadExtractedCertificates()
			if !loaded.isEmpty {
				certificates = loaded
			} else {
				startPipeline(forceRefresh: false)
			}
		}
	}

	// MARK: - Certificate scroll view

	private var certificateScrollView: some View {
		ScrollView {
			VStack(spacing: 14) {
				ForEach(certificates) { cert in
					certificateCard(cert)
				}
				footerView
					.padding(.top, 8)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
		}
	}

	// MARK: - Certificate card

	private func certificateCard(_ cert: EnterpriseCertificate) -> some View {
		Button {
			installCertificate(cert)
		} label: {
			HStack(spacing: 16) {
				VStack(alignment: .leading, spacing: 6) {
					Text(cert.certificateName)
						.font(.system(size: 17, weight: .bold))
						.foregroundStyle(.primary)
					if let expDate = cert.expirationDate {
						Text("Expires: \(expirationFormatter.string(from: expDate))")
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
				}

				Spacer()

				Image(systemName: "arrow.down.circle.fill")
					.font(.system(size: 28))
					.foregroundStyle(Color.accentColor)
			}
			.padding(16)
			.background(Color(UIColor.secondarySystemGroupedBackground))
			.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
			.shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
		}
		.buttonStyle(.plain)
	}

	// MARK: - Footer

	private var footerView: some View {
		Group {
			Text("Add the certificate that works for your device. All these certificates are ")
				.foregroundColor(.secondary)
			+ Text("REVOKED")
				.bold()
				.foregroundColor(.red)
			+ Text(" but they still work since that's the method.")
				.foregroundColor(.secondary)
		}
		.font(.footnote)
		.multilineTextAlignment(.center)
		.padding(.horizontal, 8)
	}

	// MARK: - Install overlay

	private var installOverlay: some View {
		ZStack {
			Color.black.opacity(0.35)
				.ignoresSafeArea()
			VStack(spacing: 16) {
				ProgressView()
					.scaleEffect(1.4)
					.tint(.white)
				Text("Installing certificate…")
					.font(.subheadline)
					.foregroundStyle(.white)
			}
			.padding(32)
			.background(.ultraThinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
		}
	}

	// MARK: - Loading

	private var loadingView: some View {
		VStack(spacing: 16) {
			ProgressView()
				.scaleEffect(1.4)
			Text(fetcher.isFetching ? "Fetching Enterprise Certificates" : "Extracting Certificates")
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - Error

	private func errorView(message: String) -> some View {
		VStack(spacing: 20) {
			Image(systemName: "exclamationmark.triangle.fill")
				.font(.system(size: 48))
				.foregroundStyle(.orange)
			Text("Failed to Load Certificates")
				.font(.headline)
			Text(message)
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
			Button {
				startPipeline(forceRefresh: false)
			} label: {
				Text("Retry")
					.font(.headline)
					.foregroundStyle(.white)
					.padding(.horizontal, 32)
					.padding(.vertical, 12)
					.background(Color.accentColor)
					.clipShape(Capsule())
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - Empty

	private var emptyView: some View {
		VStack(spacing: 16) {
			Image(systemName: "building.2.crop.circle")
				.font(.system(size: 48))
				.foregroundStyle(.secondary)
			Text("No Certificates Found")
				.font(.headline)
			Text("No Enterprise certificates were found. Tap Fetch to download certificates.")
				.font(.caption)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}

	// MARK: - Install

	private func installCertificate(_ certificate: EnterpriseCertificate) {
		isInstalling = true
		FR.handleCertificateFiles(
			p12URL: certificate.p12URL,
			provisionURL: certificate.provisionURL,
			p12Password: certificate.password,
			certificateName: certificate.certificateName,
			isDefault: false
		) { error in
			Task { @MainActor in
				isInstalling = false
				if let error = error {
					importErrorMessage = error.localizedDescription
				} else {
					HapticsManager.shared.success()
					successCertName = certificate.certificateName
				}
			}
		}
	}

	// MARK: - App restart

	private func restartApp() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			exit(0)
		}
	}

	// MARK: - Pipeline

	private func startPipeline(forceRefresh: Bool) {
		Task {
			await fetchAndExtract(forceRefresh: forceRefresh)
		}
	}

	@MainActor
	private func fetchAndExtract(forceRefresh: Bool) async {
		errorMessage = nil
		importErrorMessage = nil

		do {
			try await fetcher.fetchEnterpriseCertificates(forceRefresh: forceRefresh)
			isExtracting = true
			_ = try extractor.extractEnterpriseCertificates()
			certificates = EnterpriseCertExtracter.loadExtractedCertificates()
		} catch {
			errorMessage = error.localizedDescription
		}

		isExtracting = false
	}
}

