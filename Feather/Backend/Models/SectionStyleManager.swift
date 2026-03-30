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

    func applyGlobalUIKitStyle(themeManager: ThemeManager? = nil) {
        let tm = themeManager ?? ThemeManager.shared
        switch currentStyle {
        case .native:
            UITableView.appearance().backgroundColor = nil
            UITableView.appearance().separatorColor = nil
            UITableViewCell.appearance().backgroundColor = nil
            UITableView.appearance().separatorStyle = .singleLine
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = nil
            UISwitch.appearance().onTintColor = nil
            UISegmentedControl.appearance().selectedSegmentTintColor = nil
            UISegmentedControl.appearance().backgroundColor = nil

        case .colorMatch:
            UITableView.appearance().backgroundColor = tm.appBackgroundUIColor
            UITableView.appearance().separatorColor = tm.separatorUIColor
            UITableView.appearance().separatorStyle = .singleLine
            UITableViewCell.appearance().backgroundColor = tm.cardBackgroundUIColor

            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = tm.headerTextUIColor

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
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                if let sym = symbol {
                    Image(systemName: sym)
                        .font(.caption)
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.headerTextColor
                                : Color(.secondaryLabel)
                        )
                }
                Text(header)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .foregroundStyle(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.headerTextColor
                            : Color(.secondaryLabel)
                    )
            }
            .padding(.horizontal, 4)

            if styleManager.currentStyle == .colorMatch {
                VStack(spacing: 0) {
                    content
                }
                .background(themeManager.cardBackgroundColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeManager.borderColor, lineWidth: 0.5)
                )
            } else {
                content
            }
        }
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
                            : Color.accentColor
                    )
                    .frame(width: 28, height: 28)
                    .background(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.iconTintColor.opacity(0.12)
                            : Color.clear
                    )
                    .cornerRadius(7)

                Text(label)
                    .foregroundStyle(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.primaryTextColor
                            : Color(.label)
                    )
                    .font(.body)

                Spacer()

                if let val = value {
                    Text(val)
                        .foregroundStyle(
                            styleManager.currentStyle == .colorMatch
                                ? themeManager.secondaryTextColor
                                : Color(.secondaryLabel)
                        )
                        .font(.subheadline)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.cardBackgroundColor
                    : Color(.secondarySystemGroupedBackground)
            )
            .overlay(alignment: .bottom) {
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
    @Binding var isOn: Bool
    var isLast: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.iconTintColor : Color.accentColor
                )
                .frame(width: 28, height: 28)
                .background(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.iconTintColor.opacity(0.12) : Color.clear
                )
                .cornerRadius(7)

            Text(label)
                .foregroundStyle(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.primaryTextColor : Color(.label)
                )
                .font(.body)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.switchTintColor : Color.accentColor
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            styleManager.currentStyle == .colorMatch
                ? themeManager.cardBackgroundColor
                : Color(.secondarySystemGroupedBackground)
        )
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.separatorColor : Color(.separator)
                    )
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
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
                        ? themeManager.iconTintColor : Color.accentColor
                )
                .frame(width: 28, height: 28)
                .background(
                    styleManager.currentStyle == .colorMatch
                        ? themeManager.iconTintColor.opacity(0.12) : Color.clear
                )
                .cornerRadius(7)

            Picker(label, selection: $selection) {
                ForEach(options, id: \.value) { opt in
                    Text(opt.label).tag(opt.value)
                }
            }
            .pickerStyle(.segmented)
            .tint(
                styleManager.currentStyle == .colorMatch
                    ? themeManager.accentColor : Color.accentColor
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(
            styleManager.currentStyle == .colorMatch
                ? themeManager.cardBackgroundColor
                : Color(.secondarySystemGroupedBackground)
        )
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(
                        styleManager.currentStyle == .colorMatch
                            ? themeManager.separatorColor : Color(.separator)
                    )
                    .frame(height: 0.5)
                    .padding(.leading, 58)
            }
        }
    }
}
