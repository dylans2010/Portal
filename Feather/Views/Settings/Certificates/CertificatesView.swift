import SwiftUI
import NimbleViews

// MARK: - View
struct CertificatesView: View {
	@AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
	
	@State private var _isAddingPresenting = false
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
			LazyVStack(spacing: 14) {
				ForEach(Array(_certificates.enumerated()), id: \.element.uuid) { index, cert in
					modernCertificateCard(for: cert, at: index)
						.opacity(appearAnimation ? 1 : 0)
						.offset(y: appearAnimation ? 0 : 20)
						.animation(
							.spring(response: 0.5, dampingFraction: 0.8)
							.delay(Double(index) * 0.05),
							value: appearAnimation
						)
				}
			}
			.padding(16)
		}
		.background(Color(UIColor.systemGroupedBackground))
		.navigationTitle(.localized("Certificates"))
		.overlay {
			if _certificates.isEmpty {
				emptyStateView
			}
		}
		.toolbar {
			if _bindingSelectedCert == nil {
				ToolbarItem(placement: .topBarTrailing) {
					Button {
						_isAddingPresenting = true
					} label: {
						Image(systemName: "plus.circle.fill")
							.font(.system(size: 22, weight: .medium))
							.foregroundStyle(Color.accentColor)
					}
				}
			}
		}
		.sheet(item: $_isSelectedInfoPresenting) { cert in
			CertificatesInfoView(cert: cert)
		}
		.sheet(isPresented: $_isAddingPresenting) {
			CertificatesAddView()
				.presentationDetents([.medium])
		}
		.onAppear {
			withAnimation {
				appearAnimation = true
			}
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
						.frame(width: 4)
				}
				
				// Content
				CertificatesCellView(cert: cert)
					.padding(.horizontal, 16)
					.padding(.vertical, 14)
			}
			.background(
				ZStack {
					// Base background
					RoundedRectangle(cornerRadius: 18, style: .continuous)
						.fill(
							isSelected
								? AnyShapeStyle(
									LinearGradient(
										colors: [
											Color.accentColor.opacity(0.12),
											Color.accentColor.opacity(0.06),
											Color.accentColor.opacity(0.03)
										],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								: AnyShapeStyle(Color(UIColor.secondarySystemGroupedBackground))
						)
					
					// Subtle inner glow for selected
					if isSelected {
						RoundedRectangle(cornerRadius: 18, style: .continuous)
							.stroke(
								LinearGradient(
									colors: [
										Color.accentColor.opacity(0.4),
										Color.accentColor.opacity(0.2),
										Color.accentColor.opacity(0.1)
									],
									startPoint: .topLeading,
									endPoint: .bottomTrailing
								),
								lineWidth: 1.5
							)
					} else {
						RoundedRectangle(cornerRadius: 18, style: .continuous)
							.stroke(Color(UIColor.separator).opacity(0.2), lineWidth: 0.5)
					}
				}
			)
			.clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
			.shadow(
				color: isSelected ? Color.accentColor.opacity(0.2) : Color.black.opacity(0.06),
				radius: isSelected ? 15 : 10,
				x: 0,
				y: isSelected ? 8 : 4
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
							.frame(width: 26, height: 26)
						
						Image(systemName: "checkmark")
							.font(.system(size: 11, weight: .bold))
							.foregroundStyle(.white)
					}
					.offset(x: 6, y: -6)
					.shadow(color: .accentColor.opacity(0.4), radius: 6, x: 0, y: 3)
				}
			}
			.scaleEffect(isSelected ? 1.0 : 0.98)
			.animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
			.contextMenu {
				_contextActions(for: cert)
				if cert.isDefault != true {
					Divider()
					_actions(for: cert)
				}
			}
		}
		.buttonStyle(.plain)
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
		let fileName = "\(sanitizedName)_entitlements.txt"
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
		Button(.localized("Details"), systemImage: "info.circle") {
			_isSelectedInfoPresenting = cert
		}
		Button(.localized("Export Entitlements"), systemImage: "square.and.arrow.up") {
			_exportEntitlements(for: cert)
		}
		Divider()
		Button(.localized("Check Revokage (Beta)"), systemImage: "person.text.rectangle") {
			Storage.shared.revokagedCertificate(for: cert)
		}
	}
}
