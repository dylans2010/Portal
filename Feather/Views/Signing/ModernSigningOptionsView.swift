import SwiftUI
import NimbleViews

struct ModernSigningOptionsView: View {
    @Binding var options: Options
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                modernBackground

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        VStack(spacing: 24) {
                            // General Settings
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(title: "General", icon: "gearshape.fill")
                                VStack(spacing: 0) {
                                    optionPicker(title: "Appearance", icon: "paintpalette.fill", color: .pink, selection: $options.appAppearance, values: Options.AppAppearance.allCases)
                                    Divider().padding(.leading, 52)
                                    optionPicker(title: "Minimum OS", icon: "iphone", color: .blue, selection: $options.minimumAppRequirement, values: Options.MinimumAppRequirement.allCases)
                                }
                                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.clear.opacity(0.4)))
                            }

                            // Protection Settings
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(title: "Protection", icon: "shield.fill")
                                VStack(spacing: 0) {
                                    optionToggle(title: "PPQ Protection", subtitle: "Basic anti-revocation protection.", icon: "shield.checkered", color: .blue, isOn: $options.ppqProtection)
                                    Divider().padding(.leading, 52)
                                    optionToggle(title: "Dynamic Protection", subtitle: "Advanced protection for App Store apps.", icon: "wand.and.stars", color: .indigo, isOn: $options.dynamicProtection)
                                }
                                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.clear.opacity(0.4)))
                            }

                            // Features
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(title: "App Features", icon: "sparkles")
                                VStack(spacing: 0) {
                                    optionToggle(title: "File Sharing", icon: "folder.fill.badge.person.crop", color: .green, isOn: $options.fileSharing)
                                    Divider().padding(.leading, 52)
                                    optionToggle(title: "ProMotion", icon: "gauge.with.dots.needle.67percent", color: .orange, isOn: $options.proMotion)
                                    Divider().padding(.leading, 52)
                                    optionToggle(title: "Game Mode", icon: "gamecontroller.fill", color: .purple, isOn: $options.gameMode)
                                }
                                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.clear.opacity(0.4)))
                            }

                            // Post Signing
                            VStack(alignment: .leading, spacing: 12) {
                                sectionHeader(title: "Post Signing", icon: "arrow.right.circle.fill")
                                VStack(spacing: 0) {
                                    optionToggle(title: "Install After Signed", icon: "arrow.down.app.fill", color: .green, isOn: $options.post_installAppAfterSigned)
                                    Divider().padding(.leading, 52)
                                    optionToggle(title: "Delete After Signed", icon: "trash.fill", color: .red, isOn: $options.post_deleteAppAfterSigned)
                                }
                                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.clear.opacity(0.4)))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Signing Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    @ViewBuilder
    private var modernBackground: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            LinearGradient(colors: [Color.accentColor.opacity(0.05), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: 40))
                .foregroundStyle(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.top, 20)

            Text("Customize Your Experience")
                .font(.headline)
            Text("These settings apply to this app specifically.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary)
            Text(title.uppercased()).font(.system(size: 10, weight: .bold)).foregroundStyle(.secondary).tracking(0.5)
        }.padding(.leading, 4)
    }

    @ViewBuilder
    private func optionToggle(title: String, subtitle: String? = nil, icon: String, color: Color, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary)
                if let subtitle = subtitle { Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary) }
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(Color.accentColor)
        }.padding(.horizontal, 14).padding(.vertical, 12)
    }

    @ViewBuilder
    private func optionPicker<T: Hashable & LocalizedDescribable>(title: String, icon: String, color: Color, selection: Binding<T>, values: [T]) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(color.opacity(0.12)).frame(width: 36, height: 36)
                Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(color)
            }
            Text(title).font(.system(size: 15, weight: .medium)).foregroundStyle(.primary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(values, id: \.self) { value in
                    Text(value.localizedDescription).tag(value)
                }
            }
            .labelsHidden()
            .tint(.secondary)
        }.padding(.horizontal, 14).padding(.vertical, 10)
    }
}
