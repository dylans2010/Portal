import SwiftUI
import NimbleViews

// MARK: - View
struct SigningOptionsView: View {
    @Binding var options: Options
    var temporaryOptions: Options?
    @State private var accentColor: Color = .accentColor
    @State private var showPPQInfo = false
    @State private var floatingAnimation = false
    @AppStorage("Feather.certificateExperience") private var certificateExperience: String = "Developer"
    
    // Check if any certificate has PPQCheck
    private var hasCertificateWithPPQCheck: Bool {
        let certificates = Storage.shared.getAllCertificates()
        return certificates.contains { $0.ppQCheck }
    }
    
    // Check if Enterprise certificate type is selected
    private var isEnterpriseCertificate: Bool {
        certificateExperience == "Enterprise"
    }
    
    // PPQ Protection should be forced ON if Enterprise OR if any cert has PPQCheck
    private var isPPQProtectionForced: Bool {
        isEnterpriseCertificate || hasCertificateWithPPQCheck
    }
    
    // MARK: Body
    var body: some View {
        ZStack {
            // Modern animated background
            modernBackground

            ScrollView {
                VStack(spacing: 24) {
                    if temporaryOptions == nil {
                        // Protection Section
                        modernSection(title: "Protection", icon: "shield.lefthalf.filled", color: .blue) {
                            modernToggle(
                                title: "PPQ Protection",
                                subtitle: isPPQProtectionForced ? "Required for your certificate." : "Append random string to Bundle IDs to avoid Apple flagging this certificate.",
                                icon: "shield.checkered",
                                color: .blue,
                                isOn: Binding(
                                    get: { isPPQProtectionForced ? true : options.ppqProtection },
                                    set: { newValue in
                                        if !isPPQProtectionForced || newValue {
                                            options.ppqProtection = newValue
                                            if newValue { options.dynamicProtection = false }
                                        }
                                    }
                                ),
                                disabled: isPPQProtectionForced
                            )

                            Divider().padding(.leading, 56)

                            modernToggle(
                                title: "Dynamic Protection",
                                subtitle: "Only apply random strings to apps matching those in the App Store.",
                                icon: "wand.and.stars",
                                color: .indigo,
                                isOn: Binding(
                                    get: { options.dynamicProtection },
                                    set: { newValue in
                                        options.dynamicProtection = newValue
                                        if newValue {
                                            if isPPQProtectionForced {
                                                options.dynamicProtection = false
                                            } else {
                                                options.ppqProtection = false
                                            }
                                        }
                                    }
                                ),
                                disabled: isPPQProtectionForced
                            )

                            Divider().padding(.leading, 56)

                            Button {
                                HapticsManager.shared.impact()
                                showPPQInfo = true
                            } label: {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.accentColor.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Color.accentColor)
                                    }
                                    Text("What is PPQ?")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.quaternary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // General Section
                    modernSection(title: "General", icon: "gearshape.2.fill", color: .gray) {
                        modernPicker(
                            title: "Appearance",
                            icon: "paintpalette.fill",
                            color: .pink,
                            selection: $options.appAppearance,
                            values: Options.AppAppearance.allCases
                        )

                        Divider().padding(.leading, 56)

                        modernPicker(
                            title: "Minimum Requirement",
                            icon: "ruler.fill",
                            color: .indigo,
                            selection: $options.minimumAppRequirement,
                            values: Options.MinimumAppRequirement.allCases
                        )
                    }

                    // Signing Section
                    modernSection(title: "Signing", icon: "signature", color: .purple) {
                        modernPicker(
                            title: "Signing Type",
                            icon: "pencil.and.scribble",
                            color: .purple,
                            selection: $options.signingOption,
                            values: Options.SigningOption.allCases
                        )
                    }

                    // App Features Section
                    modernSection(title: "App Features", icon: "sparkles", color: .yellow) {
                        modernToggle(title: "File Sharing", subtitle: "Enable Document Sharing.", icon: "folder.fill.badge.person.crop", color: .blue, isOn: $options.fileSharing)
                        Divider().padding(.leading, 56)
                        modernToggle(title: "iTunes File Sharing", subtitle: "Access Via iTunes/Finder.", icon: "music.note.list", color: .pink, isOn: $options.itunesFileSharing)
                        Divider().padding(.leading, 56)
                        modernToggle(title: "ProMotion", subtitle: "120Hz Display Support.", icon: "gauge.with.dots.needle.67percent", color: .green, isOn: $options.proMotion)
                        Divider().padding(.leading, 56)
                        modernToggle(title: "Game Mode", subtitle: "Turn on Gaming Mode (iOS 18+).", icon: "gamecontroller.fill", color: .purple, isOn: $options.gameMode)
                        Divider().padding(.leading, 56)
                        modernToggle(title: "iPad Fullscreen", subtitle: "Full Screen On iPad.", icon: "ipad.landscape", color: .orange, isOn: $options.ipadFullscreen)
                    }

                    // Removal Section
                    modernSection(title: "Removal", icon: "trash.slash.fill", color: .red) {
                        modernToggle(title: "Remove URL Scheme", subtitle: "Strip URL Handlers.", icon: "link.badge.minus", color: .red, isOn: $options.removeURLScheme)
                        Divider().padding(.leading, 56)
                        modernToggle(title: "Remove Provisioning", subtitle: "Exclude .mobileprovision.", icon: "doc.badge.minus", color: .orange, isOn: $options.removeProvisioning)
                    }

                    // Localization Section
                    modernSection(title: "Localization", icon: "globe.badge.chevron.backward", color: .green) {
                        modernToggle(title: "Force Localize", subtitle: "Override Localized Titles.", icon: "character.bubble.fill", color: .green, isOn: $options.changeLanguageFilesForCustomDisplayName)
                    }

                    // Post Signing Section
                    modernSection(title: "Post Signing", icon: "clock.arrow.circlepath", color: .orange) {
                        modernToggle(title: "Install After Signing", subtitle: "Auto Install When Done.", icon: "arrow.down.circle.fill", color: .green, isOn: $options.post_installAppAfterSigned)
                        Divider().padding(.leading, 56)
                        modernToggle(title: "Delete After Signing", subtitle: "Remove Original File.", icon: "trash.fill", color: .red, isOn: $options.post_deleteAppAfterSigned)
                    }

                    // Experiments Section
                    modernSection(title: "Experiments", icon: "flask.fill", color: .purple, isBeta: true) {
                        modernToggle(title: "Replace Substrate", subtitle: "Use ElleKit Instead.", icon: "arrow.triangle.2.circlepath.circle.fill", color: .cyan, isOn: $options.experiment_replaceSubstrateWithEllekit)
                        Divider().padding(.leading, 56)
                        modernToggle(title: "Liquid Glass", subtitle: "Use iOS 26 Redesign Support.", icon: "sparkles.rectangle.stack.fill", color: .purple, isOn: $options.experiment_supportLiquidGlass)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 40)
            }
        }
        .alert("What is PPQ?", isPresented: $showPPQInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("PPQ is a check Apple has added to certificates. If you have this check on the certificate, change your Bundle IDs when signing apps to avoid Apple revoking your certificates.")
        }
        .onAppear {
            if isPPQProtectionForced && !options.ppqProtection {
                options.ppqProtection = true
            }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                floatingAnimation = true
            }
        }
    }

    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: floatingAnimation ? -20 : 20, y: floatingAnimation ? -30 : 30)
                    .position(x: geo.size.width * 0.9, y: geo.size.height * 0.1)

                Circle()
                    .fill(Color.purple.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: floatingAnimation ? 30 : -30, y: floatingAnimation ? 20 : -20)
                    .position(x: geo.size.width * 0.1, y: geo.size.height * 0.8)
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func modernSection<Content: View>(title: String, icon: String, color: Color, isBeta: Bool = false, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                if isBeta {
                    Text("BETA")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(color))
                }

                Spacer()
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.black.opacity(0.03), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
    }

    @ViewBuilder
    private func modernToggle(title: String, subtitle: String? = nil, icon: String, color: Color, isOn: Binding<Bool>, disabled: Bool = false) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .disabled(disabled)
                .tint(accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func modernPicker<T: Hashable & LocalizedDescribable>(title: String, icon: String, color: Color, selection: Binding<T>, values: [T]) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            Picker("", selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(value.localizedDescription).tag(value)
                }
            }
            .labelsHidden()
            .tint(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // Keep the static picker for compatibility
    @ViewBuilder
    static func picker<SelectionValue: Hashable, T: Hashable & LocalizedDescribable>(
        _ title: String,
        systemImage: String,
        selection: Binding<SelectionValue>,
        values: [T]
    ) -> some View {
        Picker(selection: selection) {
            ForEach(values, id: \.self) { value in
                Text(value.localizedDescription)
            }
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
}
