import SwiftUI
import NimbleViews

// MARK: - View
struct CertificatesView: View {
	@AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
	@AppStorage("Feather.certificateExperience") private var certificateExperience: String = CertificateExperience.developer.rawValue
	@AppStorage("forceShowGuides") private var forceShowGuides = false
	@AppStorage("feature_passwordChanger") private var passwordChanger = false
	@AppStorage("Feather.showHeaderViews") private var showHeaderViews = true
	
	@State private var _isAddingPresenting = false
	@State private var _isPasswordChangePresenting = false
	@State private var _isSelectedInfoPresenting: CertificatePair?
	@State private var appearAnimation = false

	// MARK: Fetch
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .easeInOut(duration: 0.35)
	) private var _certificates: FetchedResults<CertificatePair>
	
	private var _bindingSelectedCert: Binding<Int>?
	private var _selectedCertBinding: Binding<Int> {
		_bindingSelectedCert ?? $_storedSelectedCert
	}
	
	init(selectedCert: Binding<Int>? = nil) {
		self._bindingSelectedCert = selectedCert
	}
	
	// MARK: Body
	var body: some View {
		ScrollView {
			LazyVStack(spacing: 18) {
				if showHeaderViews {
					CertificatesHeaderView()
						.opacity(appearAnimation ? 1 : 0)
						.offset(y: appearAnimation ? 0 : 20)
				}

				// Certificate Type Picker Card
				certificateTypeCard
					.opacity(appearAnimation ? 1 : 0)
					.offset(y: appearAnimation ? 0 : 20)
				
				ForEach(Array(_certificates.enumerated()), id: \.element.uuid) { index, cert in
					modernCertificateCard(for: cert, at: index)
						.opacity(appearAnimation ? 1 : 0)
						.offset(y: appearAnimation ? 0 : 20)
						.animation(
							.spring(response: 0.5, dampingFraction: 0.8)
							.delay(Double(index + 1) * 0.05),
							value: appearAnimation
						)
				}
			}
			.padding(20)
		}
		.background(Color.clear)
		.navigationTitle(.localized("Certificates"))
		.overlay {
			if _certificates.isEmpty {
				emptyStateView
					.padding(.top, 200)
			}
		}
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				HStack(spacing: 12) {
					if passwordChanger {
						Button {
							_isPasswordChangePresenting = true
						} label: {
							Image(systemName: "lock.rotation")
								.font(.system(size: 20, weight: .medium))
								.foregroundStyle(Color.accentColor)
						}
					}

					Button {
						HapticsManager.shared.softImpact()
						_isAddingPresenting = true
					} label: {
						Image(systemName: "plus.circle.fill")
							.font(.system(size: 22, weight: .medium))
							.foregroundStyle(Color.accentColor)
							.symbolRenderingMode(.hierarchical)
					}
				}
			}
		}
		.sheet(item: $_isSelectedInfoPresenting) { cert in
			CertificatesInfoView(cert: cert)
		}
		.sheet(isPresented: $_isAddingPresenting) {
			CertificatesAddView()
		}
		.sheet(isPresented: $_isPasswordChangePresenting) {
			CertificatePasswordChangeView()
		}
		.onAppear {
			withAnimation {
				appearAnimation = true
			}
			// Initial sync for widgets
			if let cert = Storage.shared.getCertificate(for: _selectedCertBinding.wrappedValue) {
				Storage.shared.updateWidgetData(certName: cert.nickname ?? "Unknown", expiryDate: cert.expiration)
			}
		}
		.onChange(of: _selectedCertBinding.wrappedValue) { index in
			if let cert = Storage.shared.getCertificate(for: index) {
				Storage.shared.updateWidgetData(certName: cert.nickname ?? "Unknown", expiryDate: cert.expiration)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .gestureOpenCertDetails)) { notification in
			if let cert = notification.object as? CertificatePair {
				_isSelectedInfoPresenting = cert
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .gestureExportCertEntitlements)) { notification in
			if let cert = notification.object as? CertificatePair {
				_exportEntitlements(for: cert)
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .gestureSelectCert)) { notification in
			if let cert = notification.object as? CertificatePair {
				if let index = _certificates.firstIndex(where: { $0.uuid == cert.uuid }) {
					withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
						_selectedCertBinding.wrappedValue = index
					}
					HapticsManager.shared.softImpact()
				}
			}
		}
		.onReceive(NotificationCenter.default.publisher(for: .gestureRequireConfirmation)) { notification in
			guard let userInfo = notification.userInfo,
				  let action = userInfo["action"] as? GestureAction,
				  action == .deleteApp,
				  let cert = userInfo["context"] as? CertificatePair else { return }

			Storage.shared.deleteCertificate(for: cert)
			HapticsManager.shared.success()
		}
	}
	
	// MARK: - Certificate Type Card
	private var certificateTypeCard: some View {
		Picker("", selection: $certificateExperience) {
			ForEach(CertificateExperience.allCases, id: \.rawValue) { exp in
				Text(exp.displayName).tag(exp.rawValue)
			}
		}
		.pickerStyle(.segmented)
		.padding(.horizontal, 4)
		.onChange(of: certificateExperience) { newValue in
			if newValue == CertificateExperience.enterprise.rawValue {
				forceShowGuides = true
			}
			HapticsManager.shared.softImpact()
		}
	}
	
	// MARK: - Empty State
	private var emptyStateView: some View {
		VStack(spacing: 20) {
			ZStack {
				Circle()
					.fill(
						LinearGradient(
							colors: [.accentColor.opacity(0.15), .accentColor.opacity(0.05)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
					.frame(width: 100, height: 100)
				
				Image(systemName: "seal.fill")
					.font(.system(size: 40, weight: .medium))
					.foregroundStyle(
						LinearGradient(
							colors: [.accentColor, .accentColor.opacity(0.7)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
			}
			
			VStack(spacing: 8) {
				Text(.localized("No Certificates"))
					.font(.system(size: 20, weight: .bold))
					.foregroundStyle(.primary)
				
				Text(.localized("Get started signing by importing your first certificate."))
					.font(.system(size: 14, weight: .medium))
					.foregroundStyle(.secondary)
					.multilineTextAlignment(.center)
					.padding(.horizontal, 40)
			}
			
			Button {
				HapticsManager.shared.softImpact()
				_isAddingPresenting = true
			} label: {
				HStack(spacing: 8) {
					Image(systemName: "plus.circle.fill")
						.font(.system(size: 16, weight: .semibold))
					Text(.localized("Import Certificate"))
						.font(.system(size: 15, weight: .semibold))
				}
				.foregroundStyle(.white)
				.padding(.horizontal, 24)
				.padding(.vertical, 14)
				.background(
					Capsule()
						.fill(
							LinearGradient(
								colors: [.accentColor, .accentColor.opacity(0.8)],
								startPoint: .leading,
								endPoint: .trailing
							)
						)
				)
				.shadow(color: .accentColor.opacity(0.3), radius: 10, x: 0, y: 5)
			}
		}
	}
	
	// MARK: - Modern Certificate Card
	@ViewBuilder
	private func modernCertificateCard(for cert: CertificatePair, at index: Int) -> some View {
		let isSelected = _selectedCertBinding.wrappedValue == index
		
		Button {
			Task {
				await GestureManager.shared.performAction(for: .singleTap, in: .certificates, context: cert)
			}
			withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
				_selectedCertBinding.wrappedValue = index
			}
			HapticsManager.shared.softImpact()
		} label: {
			HStack(spacing: 0) {
				// Selection indicator
				if isSelected {
					Rectangle()
						.fill(
							LinearGradient(
								colors: [.accentColor, .accentColor.opacity(0.7)],
								startPoint: .top,
								endPoint: .bottom
							)
						)
						.frame(width: 6)
				}
				
				// Content
				CertificatesCellView(cert: cert)
					.padding(.horizontal, 20)
					.padding(.vertical, 18)
			}
			.background {
				if isSelected {
					ZStack {
						Color.accentColor.opacity(0.08)
						.background(Color.clear)

						RoundedRectangle(cornerRadius: 24, style: .continuous)
							.stroke(
								LinearGradient(
									colors: [
										Color.accentColor.opacity(0.5),
										Color.accentColor.opacity(0.2),
										Color.accentColor.opacity(0.05)
									],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 2
							)
					}
				} else {
					Color.clear
						.opacity(0.6)
						.background(Color.clear)
				}
			}
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
			.shadow(
				color: isSelected ? Color.accentColor.opacity(0.25) : Color.black.opacity(0.08),
				radius: isSelected ? 20 : 12,
				x: 0,
				y: isSelected ? 10 : 4
			)
			.overlay(alignment: .topTrailing) {
				if isSelected {
					ZStack {
						Circle()
							.fill(
								LinearGradient(
									colors: [.accentColor, .accentColor.opacity(0.8)],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								)
							)
							.frame(width: 28, height: 28)
						
						Image(systemName: "checkmark")
							.font(.system(size: 12, weight: .bold))
							.foregroundStyle(.white)
					}
					.offset(x: 8, y: -8)
					.shadow(color: .accentColor.opacity(0.4), radius: 8, x: 0, y: 4)
				}
			}
			.scaleEffect(isSelected ? 1.02 : 1.0)
			.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
			.contentShape(Rectangle())
			.onTapGesture(count: 2) {
				Task {
					await GestureManager.shared.performAction(for: .doubleTap, in: .certificates, context: cert)
				}
			}
			.onLongPressGesture {
				Task {
					await GestureManager.shared.performAction(for: .longPress, in: .certificates, context: cert)
				}
			}
			.contextMenu {
				_contextActions(for: cert)
				if cert.isDefault != true {
					Divider()
					_actions(for: cert)
				}
			}
		}

	}
	
	@ViewBuilder
	private func _actions(for cert: CertificatePair) -> some View {
		Button(.localized("Delete"), systemImage: "trash", role: .destructive) {
			Storage.shared.deleteCertificate(for: cert)
		}
	}
	
	private func _exportEntitlements(for cert: CertificatePair) {
		guard let data = Storage.shared.getProvisionFileDecoded(for: cert),
			  let entitlements = data.Entitlements else {
			return
		}
		
		var text = "Certificate: \(cert.nickname ?? "Unknown")\n"
		text += "Entitlements Export\n"
		text += String(repeating: "=", count: 50) + "\n\n"
		
		let sortedKeys = entitlements.keys.sorted()
		for key in sortedKeys {
			if let value = entitlements[key]?.value {
				text += "\(key):\n"
				text += _formatValue(value, indent: 1) + "\n\n"
			}
		}
		
		let tempDir = FileManager.default.temporaryDirectory
		let sanitizedName = (cert.nickname ?? "certificate")
			.replacingOccurrences(of: "/", with: "-")
			.replacingOccurrences(of: "\\", with: "-")
			.replacingOccurrences(of: ":", with: "-")
		let fileName = "\(sanitizedName)_Entitlements.txt"
		let fileURL = tempDir.appendingPathComponent(fileName)
		
		do {
			try text.write(to: fileURL, atomically: true, encoding: .utf8)
			UIActivityViewController.show(activityItems: [fileURL])
		} catch {
			print("Error writing entitlements file: \(error)")
		}
	}
	
	private func _formatValue(_ value: Any, indent: Int) -> String {
		let indentStr = String(repeating: "  ", count: indent)
		
		if let dict = value as? [String: Any] {
			var result = "{\n"
			let sortedKeys = dict.keys.sorted()
			for key in sortedKeys {
				if let dictValue = dict[key] {
					result += "\(indentStr)\(key): \(_formatValue(dictValue, indent: indent + 1))\n"
				}
			}
			result += String(repeating: "  ", count: indent - 1) + "}"
			return result
		} else if let array = value as? [Any] {
			var result = "[\n"
			for (index, item) in array.enumerated() {
				result += "\(indentStr)[\(index)]: \(_formatValue(item, indent: indent + 1))\n"
			}
			result += String(repeating: "  ", count: indent - 1) + "]"
			return result
		} else if let bool = value as? Bool {
			return bool ? "true" : "false"
		} else {
			return String(describing: value)
		}
	}
	
	@ViewBuilder
	private func _contextActions(for cert: CertificatePair) -> some View {
		Button(.localized("View Details"), systemImage: "info.circle") {
			_isSelectedInfoPresenting = cert
		}
		Button(.localized("Export Entitlements"), systemImage: "square.and.arrow.up") {
			_exportEntitlements(for: cert)
		}
		Button(.localized("Copy Password"), systemImage: "doc.on.clipboard") {
			UIPasteboard.general.string = cert.password
			HapticsManager.shared.success()
			ToastManager.shared.show(.localized("Password Copied"), type: .success)
		}
	}
}
