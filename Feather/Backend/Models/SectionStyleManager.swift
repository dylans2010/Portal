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
            return "Uses system default SwiftUI styling"
        case .colorMatch:
            return "Fully replaces all styling with your theme colors"
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
    private let maxRefreshDepth = 64
    private var isApplyingStyle = false

    @Published private(set) var currentStyle: SectionStyle {
        didSet {
            UserDefaults.standard.set(currentStyle.rawValue, forKey: key)
            applyGlobalUIKitStyle()
            NotificationCenter.default.post(name: .sectionStyleDidChange, object: nil)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: key)
        let restoredStyle = SectionStyle(rawValue: saved ?? "") ?? .native
        currentStyle = restoredStyle

        // Repair corrupted persisted values so subsequent launches stay in a valid state.
        if saved != nil, restoredStyle.rawValue != saved {
            UserDefaults.standard.set(restoredStyle.rawValue, forKey: key)
        }

        DispatchQueue.main.async { [weak self] in
            self?.applyGlobalUIKitStyle()
        }
    }

    func setStyle(_ style: SectionStyle) {
        guard style != currentStyle else { return }
        currentStyle = style
    }

    func applyGlobalUIKitStyle() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.applyGlobalUIKitStyle()
            }
            return
        }

        // Prevent re-entrant styling passes (for example while UIKit is already applying appearance).
        guard !isApplyingStyle else { return }
        isApplyingStyle = true
        defer { isApplyingStyle = false }

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

        // Refresh currently live windows only; avoid forcing UIKit work during scene startup.
        let style = currentStyle
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .filter { !$0.isHidden }
            .forEach { [weak self] window in
                self?.refreshViewHierarchy(window, style: style, tm: tm, depth: 0)
            }
    }

    private func refreshViewHierarchy(_ view: UIView, style: SectionStyle, tm: ThemeManager, depth: Int) {
        guard depth <= maxRefreshDepth else { return }

        autoreleasepool {
            if let tv = view as? UITableView {
                tv.backgroundColor = style == .colorMatch ? tm.appBackgroundUIColor : nil
                tv.separatorColor = style == .colorMatch ? tm.separatorUIColor : nil
                // Safer than reloadData during startup/layout transitions.
                tv.setNeedsLayout()
                tv.layoutIfNeeded()
            }
            if let cell = view as? UITableViewCell {
                cell.backgroundColor = style == .colorMatch ? tm.cardBackgroundUIColor : nil
                if style == .colorMatch {
                    let selView = UIView()
                    selView.backgroundColor = tm.cellHighlightUIColor
                    cell.selectedBackgroundView = selView
                } else {
                    cell.selectedBackgroundView = nil
                }
            }
            if let sw = view as? UISwitch {
                sw.onTintColor = style == .colorMatch ? tm.switchTintUIColor : nil
            }
            if let seg = view as? UISegmentedControl {
                seg.selectedSegmentTintColor = style == .colorMatch ? tm.segmentedSelectedUIColor : nil
                seg.backgroundColor = style == .colorMatch ? tm.segmentedBackgroundUIColor : nil
            }

            for subview in view.subviews {
                refreshViewHierarchy(subview, style: style, tm: tm, depth: depth + 1)
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

            HStack(spacing: 0) {
                if showBackButton, let backAction {
                    Button(action: backAction) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(themeManager.primaryTextColor)
                            .frame(width: 36, height: 36)
                            .background(themeManager.cardBackgroundColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                } else if showBackButton {
                    Color.clear.frame(width: 36, height: 36)
                }

                Spacer()

                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                if let trailing = trailingContent {
                    trailing.frame(width: 36, height: 36)
                } else {
                    Color.clear.frame(width: showBackButton ? 36 : 0, height: 36)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
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
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            if styleManager.currentStyle == .colorMatch {
                FeatherNavigationBar(
                    title: title,
                    showBackButton: showBackButton,
                    backAction: showBackButton ? { dismiss() } : nil,
                    trailingContent: trailingContent
                )
                .environmentObject(themeManager)
                .environmentObject(styleManager)
            }

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(themeManager.appBackgroundColor.ignoresSafeArea())
        .toolbar(styleManager.currentStyle == .colorMatch ? .hidden : .visible, for: .navigationBar)
        .navigationTitle(styleManager.currentStyle == .native ? title : "")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(styleManager.currentStyle == .colorMatch)
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
            HStack(spacing: 5) {
                if let sym = symbol {
                    Image(systemName: sym)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.headerTextColor : Color(.secondaryLabel))
                }
                Text(styleManager.currentStyle == .colorMatch ? header.uppercased() : header)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .tracking(styleManager.currentStyle == .colorMatch ? 0.8 : 0)
                    .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.headerTextColor : Color(.secondaryLabel))
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 2)

            VStack(spacing: 0) {
                content
            }
            .background(styleManager.currentStyle == .colorMatch ? themeManager.cardBackgroundColor : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: styleManager.currentStyle == .colorMatch ? 16 : 10))
            .overlay(
                RoundedRectangle(cornerRadius: styleManager.currentStyle == .colorMatch ? 16 : 10)
                    .stroke(styleManager.currentStyle == .colorMatch ? themeManager.borderColor : Color.clear, lineWidth: 0.5)
            )

            if let footer {
                Text(footer)
                    .font(.caption)
                    .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.secondaryTextColor : Color(.secondaryLabel))
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
                            .fill(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor.opacity(0.15) : Color(.systemFill))
                            .frame(width: 30, height: 30)
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor : Color.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.body)
                            .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.primaryTextColor : Color(.label))
                        if let subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.secondaryTextColor : Color(.secondaryLabel))
                        }
                    }

                    Spacer()

                    if let value {
                        Text(value)
                            .font(.subheadline)
                            .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.secondaryTextColor : Color(.secondaryLabel))
                    }

                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.secondaryTextColor : Color(.tertiaryLabel))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(styleManager.currentStyle == .colorMatch ? themeManager.cardBackgroundColor : Color(.secondarySystemGroupedBackground))
                .contentShape(Rectangle())

                if !isLast {
                    Rectangle()
                        .fill(styleManager.currentStyle == .colorMatch ? themeManager.separatorColor : Color(.separator))
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
                        .fill(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor.opacity(0.15) : Color(.systemFill))
                        .frame(width: 30, height: 30)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor : Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.body)
                        .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.primaryTextColor : Color(.label))
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.secondaryTextColor : Color(.secondaryLabel))
                    }
                }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(styleManager.currentStyle == .colorMatch ? themeManager.switchTintColor : Color.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(styleManager.currentStyle == .colorMatch ? themeManager.cardBackgroundColor : Color(.secondarySystemGroupedBackground))

            if !isLast {
                Rectangle()
                    .fill(styleManager.currentStyle == .colorMatch ? themeManager.separatorColor : Color(.separator))
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
                        .fill(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor.opacity(0.15) : Color(.systemFill))
                        .frame(width: 30, height: 30)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor : Color.accentColor)
                }

                Picker(label, selection: $selection) {
                    ForEach(options, id: \.value) { opt in
                        Text(opt.label).tag(opt.value)
                    }
                }
                .pickerStyle(.segmented)
                .tint(themeManager.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(styleManager.currentStyle == .colorMatch ? themeManager.cardBackgroundColor : Color(.secondarySystemGroupedBackground))

            if !isLast {
                Rectangle()
                    .fill(styleManager.currentStyle == .colorMatch ? themeManager.separatorColor : Color(.separator))
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
                        .fill(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor.opacity(0.15) : Color(.systemFill))
                        .frame(width: 30, height: 30)
                    Image(systemName: symbol)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor : Color.accentColor)
                }

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.primaryTextColor : Color(.label))
                    .tint(themeManager.accentColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(styleManager.currentStyle == .colorMatch ? themeManager.cardBackgroundColor : Color(.secondarySystemGroupedBackground))

            if !isLast {
                Rectangle()
                    .fill(styleManager.currentStyle == .colorMatch ? themeManager.separatorColor : Color(.separator))
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }
}

struct ThemedButtonRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    enum RowButtonStyle { case normal, destructive, accent }

    let label: String
    let symbol: String
    var style: RowButtonStyle = .normal
    var isLast: Bool = false
    let action: () -> Void

    private var labelColor: Color {
        switch style {
        case .normal:
            return styleManager.currentStyle == .colorMatch ? themeManager.primaryTextColor : Color(.label)
        case .destructive:
            return themeManager.destructiveColor
        case .accent:
            return themeManager.accentColor
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(labelColor.opacity(styleManager.currentStyle == .colorMatch ? 0.15 : 0.1))
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
                .background(styleManager.currentStyle == .colorMatch ? themeManager.cardBackgroundColor : Color(.secondarySystemGroupedBackground))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !isLast {
                Rectangle()
                    .fill(styleManager.currentStyle == .colorMatch ? themeManager.separatorColor : Color(.separator))
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
                if let symbol {
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor.opacity(0.15) : Color(.systemFill))
                            .frame(width: 30, height: 30)
                        Image(systemName: symbol)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.iconTintColor : Color.accentColor)
                    }
                }

                Text(label)
                    .font(.body)
                    .foregroundStyle(styleManager.currentStyle == .colorMatch ? themeManager.primaryTextColor : Color(.label))

                Spacer()

                Text(value)
                    .font(monospaced ? .caption.monospaced() : .subheadline)
                    .foregroundStyle(valueColor ?? (styleManager.currentStyle == .colorMatch ? themeManager.secondaryTextColor : Color(.secondaryLabel)))
                    .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(styleManager.currentStyle == .colorMatch ? themeManager.cardBackgroundColor : Color(.secondarySystemGroupedBackground))

            if !isLast {
                Rectangle()
                    .fill(styleManager.currentStyle == .colorMatch ? themeManager.separatorColor : Color(.separator))
                    .frame(height: 0.5)
                    .padding(.leading, symbol != nil ? 58 : 16)
            }
        }
    }
}

struct ThemedFilledButton: View {
    @EnvironmentObject var themeManager: ThemeManager

    let label: String
    let symbol: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                Text(label).fontWeight(.semibold)
            }
            .foregroundStyle(themeManager.buttonTextColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(isDestructive ? themeManager.destructiveColor : themeManager.buttonBackgroundColor)
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
