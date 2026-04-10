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
            return "Fully replaces backgrounds, text, icons, separators, toggles, and controls with your theme colors app-wide"
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

    private let defaultsKey = "app.sectionStyle"

    @Published private(set) var currentStyle: SectionStyle {
        didSet {
            UserDefaults.standard.set(currentStyle.rawValue, forKey: defaultsKey)
            applyGlobalUIKitStyle()
            NotificationCenter.default.post(name: .sectionStyleDidChange, object: nil)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "app.sectionStyle")
        currentStyle = SectionStyle(rawValue: saved ?? "") ?? .native
    }

    func setStyle(_ style: SectionStyle) {
        currentStyle = style
    }

    var isReplacingSectionStyles: Bool {
        currentStyle == .colorMatch
    }

    func setReplaceSectionStyles(_ enabled: Bool) {
        setStyle(enabled ? .colorMatch : .native)
    }

    func applyGlobalUIKitStyle(themeManager: ThemeManager? = nil) {
        let tm = themeManager ?? ThemeManager.shared
        switch currentStyle {
        case .native:
            UITableView.appearance().backgroundColor = nil
            UITableView.appearance().separatorColor = nil
            UITableViewCell.appearance().backgroundColor = nil
            UITableView.appearance().separatorStyle = .singleLine
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = nil
            UITableViewHeaderFooterView.appearance().tintColor = nil
            UITableViewHeaderFooterView.appearance().contentView.backgroundColor = nil
            UISwitch.appearance().onTintColor = nil
            UISegmentedControl.appearance().selectedSegmentTintColor = nil
            UISegmentedControl.appearance().backgroundColor = nil

        case .colorMatch:
            UITableView.appearance().backgroundColor = tm.appBackgroundUIColor
            UITableView.appearance().separatorColor = tm.separatorUIColor
            UITableView.appearance().separatorStyle = .singleLine
            UITableViewCell.appearance().backgroundColor = tm.cardBackgroundUIColor

            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = UIColor(tm.sectionHeaderTheme.textColor)
            UITableViewHeaderFooterView.appearance().tintColor = UIColor(tm.sectionHeaderTheme.background)
            UITableViewHeaderFooterView.appearance().contentView.backgroundColor = UIColor(tm.sectionHeaderTheme.background)

            let selView = UIView()
            selView.backgroundColor = tm.cellHighlightUIColor
            UITableViewCell.appearance().selectedBackgroundView = selView

            UISwitch.appearance().onTintColor = tm.switchTintUIColor
            UISwitch.appearance().thumbTintColor = tm.primaryTextUIColor

            UISegmentedControl.appearance().selectedSegmentTintColor = tm.segmentedSelectedUIColor
            UISegmentedControl.appearance().backgroundColor = tm.segmentedBackgroundUIColor
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: tm.primaryTextUIColor], for: .selected)
            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: tm.secondaryTextUIColor], for: .normal)

            UISlider.appearance().minimumTrackTintColor = tm.sliderTintUIColor
            UISlider.appearance().maximumTrackTintColor = tm.separatorUIColor
            UISlider.appearance().thumbTintColor = tm.primaryTextUIColor

            UIProgressView.appearance().progressTintColor = tm.progressTintUIColor
            UIProgressView.appearance().trackTintColor = tm.separatorUIColor

            UITextField.appearance().textColor = tm.primaryTextUIColor
            UITextField.appearance().tintColor = tm.accentUIColor

            UITextView.appearance().backgroundColor = tm.cardBackgroundUIColor
            UITextView.appearance().textColor = tm.primaryTextUIColor
            UITextView.appearance().tintColor = tm.accentUIColor
        }
    }
}

extension Notification.Name {
    static let sectionStyleDidChange = Notification.Name("SectionStyleDidChange")
}

struct ThemedSection<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let header: String
    let symbol: String?
    let content: Content

    init(_ header: String,
         symbol: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.header = header
        self.symbol = symbol
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            HStack(spacing: 6) {
                if let sym = symbol {
                    Image(systemName: sym)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                }
                Text(header)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .textCase(.uppercase)
                    .tracking(1.0)
            }
            .foregroundStyle(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.sectionHeaderTheme.resolvedTextColor(style: styleManager.currentStyle, defaultColor: themeManager.headerTextColor)
                    : Color(.secondaryLabel)
            )
            .padding(.leading, 8)
            .padding(.bottom, 4)
        }
        .listRowBackground(
            styleManager.currentStyle == .colorMatch
                ? themeManager.surface
                : Color(.secondarySystemGroupedBackground)
        )
        .listRowSeparatorTint(
            styleManager.currentStyle == .colorMatch
                ? themeManager.separatorColor
                : Color(.separator)
        )
    }
}

struct ThemedRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    var value: String? = nil
    var showChevron: Bool = true
    var isLast: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.iconTintColor
                            : themeManager.accentColor
                    )
                    .frame(width: 30, height: 30)
                    .background(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.iconTintColor.opacity(0.12)
                            : themeManager.accentColor.opacity(0.1)
                    )
                    .cornerRadius(8)

                Text(label)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.primaryTextColor
                            : Color(.label)
                    )

                Spacer()

                if let val = value {
                    Text(val)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.secondaryTextColor
                                : Color(.secondaryLabel)
                        )
                }

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.secondaryTextColor.opacity(0.5)
                                : Color(.tertiaryLabel)
                        )
                }
            }
            .padding(.vertical, 10)
        }
        .listRowBackground(
            styleManager.currentStyle == .colorMatch
                ? themeManager.surface
                : Color(.secondarySystemGroupedBackground)
        )
        .listRowSeparatorTint(
            styleManager.currentStyle == .colorMatch
                ? themeManager.separatorColor
                : Color(.separator)
        )
    }
}

struct ThemedToggleRow: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    @Binding var isOn: Bool
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.iconTintColor
                        : themeManager.accentColor
                )
                .frame(width: 30, height: 30)
                .background(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.iconTintColor.opacity(0.12)
                        : themeManager.accentColor.opacity(0.1)
                )
                .cornerRadius(8)

            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.primaryTextColor
                        : Color(.label)
                )

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.switchTintColor
                        : themeManager.accentColor
                )
        }
        .padding(.vertical, 8)
        .listRowBackground(
            styleManager.currentStyle == .colorMatch
                ? themeManager.surface
                : Color(.secondarySystemGroupedBackground)
        )
        .listRowSeparatorTint(
            styleManager.currentStyle == .colorMatch
                ? themeManager.separatorColor
                : Color(.separator)
        )
    }
}

struct ThemedPickerRow<SelectionValue: Hashable>: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var styleManager: SectionStyleManager

    let label: String
    let symbol: String
    @Binding var selection: SelectionValue
    let options: [(value: SelectionValue, label: String)]
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.iconTintColor
                        : themeManager.accentColor
                )
                .frame(width: 30, height: 30)
                .background(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.iconTintColor.opacity(0.12)
                        : themeManager.accentColor.opacity(0.1)
                )
                .cornerRadius(8)

            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.primaryTextColor
                        : Color(.label)
                )

            Spacer()

            Picker(label, selection: $selection) {
                ForEach(options, id: \.value) { opt in
                    Text(opt.label).tag(opt.value)
                }
            }
            .pickerStyle(.menu)
            .tint(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.accentColor
                    : themeManager.accentColor
            )
        }
        .padding(.vertical, 8)
        .listRowBackground(
            styleManager.currentStyle == .colorMatch
                ? themeManager.surface
                : Color(.secondarySystemGroupedBackground)
        )
        .listRowSeparatorTint(
            styleManager.currentStyle == .colorMatch
                ? themeManager.separatorColor
                : Color(.separator)
        )
    }
}
