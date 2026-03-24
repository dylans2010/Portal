import SwiftUI
import UIKit

enum SectionStyle: String, CaseIterable, Identifiable, Codable {
    case native
    case colorMatch

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .native: return "Native"
        case .colorMatch: return "Color Match"
        }
    }

    var description: String {
        switch self {
        case .native:
            return "Use default iOS appearance styling"
        case .colorMatch:
            return "Apply app-wide color matched styling for every supported control"
        }
    }

    var sfSymbol: String {
        switch self {
        case .native: return "square.on.square"
        case .colorMatch: return "paintpalette.fill"
        }
    }
}

@MainActor
final class SectionStyleManager: ObservableObject {
    static let shared = SectionStyleManager()
    private let key = "app.sectionStyle"

    @Published private(set) var currentStyle: SectionStyle {
        didSet {
            UserDefaults.standard.set(currentStyle.rawValue, forKey: key)
            applyGlobalUIKitStyle()
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .sectionStyleDidChange, object: nil)
            }
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: key)
        currentStyle = SectionStyle(rawValue: saved ?? "") ?? .native
        DispatchQueue.main.async { [self] in
            self.applyGlobalUIKitStyle()
        }
    }

    func setStyle(_ style: SectionStyle) {
        guard style != currentStyle else { return }
        currentStyle = style
    }

    func applyGlobalUIKitStyle() {
        let tm = ThemeManager.shared
        switch currentStyle {
        case .native:
            UITableView.appearance().backgroundColor = nil
            UITableView.appearance().separatorColor = nil
            UITableViewCell.appearance().backgroundColor = nil
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = nil
            UISwitch.appearance().onTintColor = nil
            UISwitch.appearance().thumbTintColor = nil
            UISegmentedControl.appearance().selectedSegmentTintColor = nil
            UISegmentedControl.appearance().backgroundColor = nil
            UISegmentedControl.appearance().setTitleTextAttributes(nil, for: .selected)
            UISegmentedControl.appearance().setTitleTextAttributes(nil, for: .normal)
            UISlider.appearance().minimumTrackTintColor = nil
            UISlider.appearance().thumbTintColor = nil
            UIProgressView.appearance().progressTintColor = nil
            UIProgressView.appearance().trackTintColor = nil
            UITextField.appearance().textColor = nil
            UITextField.appearance().tintColor = nil

        case .colorMatch:
            UITableView.appearance().backgroundColor = tm.appBackgroundUIColor
            UITableView.appearance().separatorColor = tm.separatorUIColor
            UITableViewCell.appearance().backgroundColor = tm.cardBackgroundUIColor
            let sel = UIView()
            sel.backgroundColor = tm.cellHighlightUIColor
            UITableViewCell.appearance().selectedBackgroundView = sel
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = tm.headerTextUIColor
            UISwitch.appearance().onTintColor = tm.switchTintUIColor
            UISwitch.appearance().thumbTintColor = tm.primaryTextUIColor
            UISegmentedControl.appearance().selectedSegmentTintColor = tm.segmentedSelectedUIColor
            UISegmentedControl.appearance().backgroundColor = tm.segmentedBackgroundUIColor
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: tm.primaryTextUIColor], for: .selected)
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: tm.secondaryTextUIColor], for: .normal)
            UISlider.appearance().minimumTrackTintColor = tm.sliderTintUIColor
            UISlider.appearance().thumbTintColor = tm.primaryTextUIColor
            UIProgressView.appearance().progressTintColor = tm.progressTintUIColor
            UIProgressView.appearance().trackTintColor = tm.separatorUIColor
            UITextField.appearance().textColor = tm.primaryTextUIColor
            UITextField.appearance().tintColor = tm.accentUIColor
        }

        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .forEach { window in
                    func refresh(_ view: UIView) {
                        if let tv = view as? UITableView {
                            tv.backgroundColor = self.currentStyle == .colorMatch ? tm.appBackgroundUIColor : nil
                            tv.separatorColor = self.currentStyle == .colorMatch ? tm.separatorUIColor : nil
                            tv.reloadData()
                        }
                        if let cell = view as? UITableViewCell {
                            cell.backgroundColor = self.currentStyle == .colorMatch ? tm.cardBackgroundUIColor : nil
                        }
                        if let sw = view as? UISwitch {
                            sw.onTintColor = self.currentStyle == .colorMatch ? tm.switchTintUIColor : nil
                        }
                        if let seg = view as? UISegmentedControl {
                            seg.selectedSegmentTintColor = self.currentStyle == .colorMatch ? tm.segmentedSelectedUIColor : nil
                            seg.backgroundColor = self.currentStyle == .colorMatch ? tm.segmentedBackgroundUIColor : nil
                        }
                        view.subviews.forEach { refresh($0) }
                    }
                    refresh(window)
                }
        }
    }
}

extension Notification.Name {
    static let sectionStyleDidChange = Notification.Name("SectionStyleDidChange")
}

struct FeatherNavigationBar: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let title: String
    var showBackButton: Bool = true
    var backAction: (() -> Void)? = nil
    var trailingContent: AnyView? = nil

    var body: some View {
        ZStack {
            themeManager.navigationBarColor
                .ignoresSafeArea(edges: .top)

            HStack(spacing: 12) {
                if showBackButton, let back = backAction {
                    Button(action: back) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(themeManager.primaryTextColor)
                        }
                        .frame(width: 36, height: 36)
                        .background(themeManager.cardBackgroundColor)
                        .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)

                Spacer()

                if let trailing = trailingContent {
                    trailing
                        .frame(width: 36, height: 36)
                } else {
                    Color.clear
                        .frame(width: showBackButton ? 36 : 0, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 56)
    }
}

struct FeatherScreen<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager
    @Environment(\.dismiss) private var dismiss

    let title: String
    var showBackButton: Bool = true
    var trailingContent: AnyView? = nil
    let content: Content

    init(
        title: String,
        showBackButton: Bool = true,
        trailingContent: AnyView? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.trailingContent = trailingContent
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            if styleManager.currentStyle == .colorMatch {
                FeatherNavigationBar(
                    title: title,
                    showBackButton: showBackButton,
                    backAction: showBackButton ? { dismiss() } : nil,
                    trailingContent: trailingContent
                )
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(themeManager.appBackgroundColor.ignoresSafeArea())
        .navigationBarHidden(styleManager.currentStyle == .colorMatch)
        .navigationTitle(styleManager.currentStyle == .native ? title : "")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(themeManager.navigationBarColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: .sectionStyleDidChange)) { _ in }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AppWideThemeDidChange"))) { _ in }
    }
}

struct ThemedSection<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let header: String
    var symbol: String? = nil
    var footer: String? = nil
    @ViewBuilder let content: Content

    init(_ header: String, symbol: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.symbol = symbol
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if styleManager.currentStyle == .colorMatch {
                HStack(spacing: 5) {
                    if let sym = symbol {
                        Image(systemName: sym)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(themeManager.headerTextColor)
                    }
                    Text(header.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .tracking(0.8)
                        .foregroundStyle(themeManager.headerTextColor)
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 2)
            } else {
                Text(header)
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))
                    .padding(.horizontal, 6)
                    .padding(.bottom, 2)
            }

            VStack(spacing: 0) {
                content
            }
            .background(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.cardBackgroundColor
                    : Color(.secondarySystemGroupedBackground)
            )
            .clipShape(RoundedRectangle(cornerRadius: styleManager.currentStyle == .colorMatch ? 16 : 10))
            .overlay(
                RoundedRectangle(cornerRadius: styleManager.currentStyle == .colorMatch ? 16 : 10)
                    .stroke(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.borderColor
                            : Color.clear,
                        lineWidth: 0.5
                    )
            )

            if let foot = footer {
                Text(foot)
                    .font(.caption)
                    .foregroundStyle(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.secondaryTextColor
                            : Color(.secondaryLabel)
                    )
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
            }
        }
    }
}

struct ThemedRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    var subtitle: String? = nil
    var value: String? = nil
    var showChevron: Bool = true
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.iconTintColor.opacity(0.15)
                                    : Color(.systemFill)
                            )
                            .frame(width: 30, height: 30)
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.iconTintColor
                                    : Color.accentColor
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.body)
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.primaryTextColor
                                    : Color(.label)
                            )
                        if let sub = subtitle {
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(
                                    styleManager.currentStyle == .colorMatch
                                        ? themeManager.secondaryTextColor
                                        : Color(.secondaryLabel)
                                )
                        }
                    }

                    Spacer()

                    if let val = value {
                        Text(val)
                            .font(.subheadline)
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.secondaryTextColor
                                    : Color(.secondaryLabel)
                            )
                    }

                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.secondaryTextColor
                                    : Color(.tertiaryLabel)
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.cardBackgroundColor
                        : Color(.secondarySystemGroupedBackground)
                )
                .contentShape(Rectangle())

                if !isLast {
                    Rectangle()
                        .fill(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.separatorColor
                                : Color(.separator)
                        )
                        .frame(height: 0.5)
                        .padding(.leading, 58)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct ThemedToggleRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.iconTintColor.opacity(0.15)
                                : Color(.systemFill)
                        )
                        .frame(width: 30, height: 30)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.iconTintColor
                                : Color.accentColor
                        )
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.body)
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.primaryTextColor
                                : Color(.label)
                        )
                    if let sub = subtitle {
                        Text(sub)
                            .font(.caption)
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.secondaryTextColor
                                    : Color(.secondaryLabel)
                            )
                    }
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.switchTintColor
                            : Color.accentColor
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.cardBackgroundColor
                    : Color(.secondarySystemGroupedBackground)
            )

            if !isLast {
                Rectangle()
                    .fill(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.separatorColor
                            : Color(.separator)
                    )
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }
}

struct ThemedPickerRow<T: Hashable>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    @Binding var selection: T
    let options: [(value: T, label: String)]
    var isLast: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.iconTintColor.opacity(0.15)
                                : Color(.systemFill)
                        )
                        .frame(width: 30, height: 30)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.iconTintColor
                                : Color.accentColor
                        )
                }

                Picker(label, selection: $selection) {
                    ForEach(options, id: \.value) { opt in
                        Text(opt.label).tag(opt.value)
                    }
                }
                .pickerStyle(.segmented)
                .tint(themeManager.accentColor)
                .background(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.segmentedBackgroundColor
                        : Color.clear
                )
                .cornerRadius(8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.cardBackgroundColor
                    : Color(.secondarySystemGroupedBackground)
            )

            if !isLast {
                Rectangle()
                    .fill(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.separatorColor
                            : Color(.separator)
                    )
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }
}

struct ThemedTextFieldRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    let placeholder: String
    @Binding var text: String
    var isLast: Bool = false
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.iconTintColor.opacity(0.15)
                                : Color(.systemFill)
                        )
                        .frame(width: 30, height: 30)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.iconTintColor
                                : Color.accentColor
                        )
                }

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .foregroundStyle(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.primaryTextColor
                            : Color(.label)
                    )
                    .tint(themeManager.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.cardBackgroundColor
                    : Color(.secondarySystemGroupedBackground)
            )

            if !isLast {
                Rectangle()
                    .fill(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.separatorColor
                            : Color(.separator)
                    )
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }
}

struct ThemedButtonRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    enum ButtonRowStyle { case normal, destructive, accent }

    let label: String
    let symbol: String
    var style: ButtonRowStyle = .normal
    var isLast: Bool = false
    let action: () -> Void

    private var labelColor: Color {
        switch style {
        case .normal: return styleManager.currentStyle == .colorMatch ? themeManager.primaryTextColor : Color(.label)
        case .destructive: return themeManager.destructiveColor
        case .accent: return themeManager.accentColor
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(
                                styleManager.currentStyle == .colorMatch
                                    ? labelColor.opacity(0.15)
                                    : Color(.systemFill)
                            )
                            .frame(width: 30, height: 30)
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(labelColor)
                    }
                    Text(label)
                        .font(.body)
                        .foregroundStyle(labelColor)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.cardBackgroundColor
                        : Color(.secondarySystemGroupedBackground)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isLast {
                Rectangle()
                    .fill(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.separatorColor
                            : Color(.separator)
                    )
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }
}

struct ThemedInfoRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let value: String
    var symbol: String? = nil
    var valueColor: Color? = nil
    var isLast: Bool = false
    var monospaced: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                if let sym = symbol {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.iconTintColor.opacity(0.15)
                                    : Color(.systemFill)
                            )
                            .frame(width: 30, height: 30)
                        Image(systemName: sym)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(
                                styleManager.currentStyle == .colorMatch
                                    ? themeManager.iconTintColor
                                    : Color.accentColor
                            )
                    }
                }
                Text(label)
                    .font(.body)
                    .foregroundStyle(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.primaryTextColor
                            : Color(.label)
                    )
                Spacer()
                Text(value)
                    .font(monospaced ? .caption.monospaced() : .subheadline)
                    .foregroundStyle(
                        valueColor ?? (styleManager.currentStyle == .colorMatch
                            ? themeManager.secondaryTextColor
                            : Color(.secondaryLabel))
                    )
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.cardBackgroundColor
                    : Color(.secondarySystemGroupedBackground)
            )

            if !isLast {
                Rectangle()
                    .fill(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.separatorColor
                            : Color(.separator)
                    )
                    .frame(height: 0.5)
                    .padding(.leading, symbol != nil ? 58 : 16)
            }
        }
    }
}

struct ThemedFilledButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    var isDestructive: Bool = false
    let action: () -> Void

    var bgColor: Color {
        isDestructive ? themeManager.destructiveColor : themeManager.buttonBackgroundColor
    }

    var fgColor: Color { themeManager.buttonTextColor }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(label)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(fgColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

struct ThemedScreenContent<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .background(themeManager.appBackgroundColor.ignoresSafeArea())
        .scrollContentBackground(.hidden)
        .onReceive(NotificationCenter.default.publisher(for: .sectionStyleDidChange)) { _ in }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("AppWideThemeDidChange"))) { _ in }
    }
}
