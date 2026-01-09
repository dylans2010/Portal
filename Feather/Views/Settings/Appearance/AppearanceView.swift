import SwiftUI
import NimbleViews
import UIKit

// MARK: - View
// dear god help me
struct AppearanceView: View {
	@AppStorage("Feather.userInterfaceStyle")
	private var _userIntefacerStyle: Int = UIUserInterfaceStyle.unspecified.rawValue
	
	@AppStorage("Feather.storeCellAppearance")
	private var _storeCellAppearance: Int = 0
	private let _storeCellAppearanceMethods: [(name: String, desc: String)] = [
		(.localized("Standard"), .localized("Default style for the app, only includes subtitle.")),
		(.localized("Big Description"), .localized("Adds the localized description of the app."))
	]
	
	@AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck")
	private var _ignoreSolariumLinkedOnCheck: Bool = false
	
	@AppStorage("Feather.showNews")
	private var _showNews: Bool = true
	
	@AppStorage("Feather.showIconsInAppearance")
	private var _showIconsInAppearance: Bool = true
	
	@AppStorage("Feather.useNewAllAppsView")
	private var _useNewAllAppsView: Bool = true
	
	@AppStorage("Feather.greetingsName")
	private var _greetingsName: String = ""
	
	// MARK: Body
    var body: some View {
		NBList(.localized("Appearance")) {
			Section {
				Picker(.localized("Appearance"), selection: $_userIntefacerStyle) {
					ForEach(UIUserInterfaceStyle.allCases.sorted(by: { $0.rawValue < $1.rawValue }), id: \.rawValue) { style in
						if _showIconsInAppearance {
							Label {
								Text(style.label)
							} icon: {
								Image(systemName: style.iconName)
							}
							.tag(style.rawValue)
						} else {
							Text(style.label).tag(style.rawValue)
						}
					}
				}
				.pickerStyle(.segmented)
			} footer: {
				Text(.localized("Choose between Light, Dark, or Automatic appearance mode"))
			}
			
			NBSection(.localized("Theme")) {
				AppearanceTintColorView()
					.listRowInsets(EdgeInsets())
					.listRowBackground(EmptyView())
			} footer: {
				Text(.localized("Select your preferred accent color theme"))
			}
			
			NBSection(.localized("Visual Effects")) {
				Toggle(isOn: $_showIconsInAppearance) {
					if _showIconsInAppearance {
						Label(.localized("Show Icons"), systemImage: "square.grid.2x2.fill")
					} else {
						Text(.localized("Show Icons"))
					}
				}
				
				Toggle(isOn: $_useNewAllAppsView) {
					if _showIconsInAppearance {
						Label(.localized("Use new All Apps View"), systemImage: "square.grid.2x2.fill")
					} else {
						Text(.localized("Use new All Apps View"))
					}
				}
			} footer: {
				Text(.localized("Hiding icons will affect the entire app. Enable the modern yet simple new All Apps view, keep in mind this is buggy when you have too many sources."))
			}
			
			NBSection(.localized("Greetings")) {
				HStack {
					if _showIconsInAppearance {
						Label(.localized("Your Name"), systemImage: "person.fill")
					} else {
						Text(.localized("Your Name"))
					}
					Spacer()
					TextField(.localized("Enter Name"), text: $_greetingsName)
						.multilineTextAlignment(.trailing)
						.textFieldStyle(.plain)
				}
			} footer: {
				Text(.localized("Personalize the Home Screen with a greeting with your name"))
			}
			
			NBSection(.localized("Sources")) {
				Picker(.localized("Store Cell Appearance"), selection: $_storeCellAppearance) {
					ForEach(0..<_storeCellAppearanceMethods.count, id: \.self) { index in
						let method = _storeCellAppearanceMethods[index]
						if _showIconsInAppearance {
							Label {
								NBTitleWithSubtitleView(
									title: method.name,
									subtitle: method.desc
								)
							} icon: {
								Image(systemName: index == 0 ? "list.bullet" : "text.alignleft")
							}
							.tag(index)
						} else {
							NBTitleWithSubtitleView(
								title: method.name,
								subtitle: method.desc
							)
							.tag(index)
						}
					}

				}
				.labelsHidden()
				.pickerStyle(.inline)
				
				Toggle(isOn: $_showNews) {
					if _showIconsInAppearance {
						Label(.localized("Show News"), systemImage: "newspaper.fill")
					} else {
						Text(.localized("Show News"))
					}
				}
			} footer: {
				Text(.localized("When disabled, news from sources will not be displayed in the Sources section."))
			}
			
			NBSection(.localized("Status Bar")) {
				NavigationLink(destination: StatusBarCustomizationView()) {
					ConditionalLabel(title: .localized("Status Bar Customization"), systemImage: "rectangle.inset.topright.filled")
				}
			} footer: {
				Text(.localized("Customize status bar with SF Symbols, text, colors, and more"))
			}
			
			NBSection(.localized("Tab Bar")) {
				NavigationLink(destination: TabBarCustomizationView()) {
					ConditionalLabel(title: .localized("Tab Bar Customization"), systemImage: "square.split.bottomrightquarter")
				}
			} footer: {
				Text(.localized("Show or hide tabs from the tab bar. Settings cannot be hidden."))
			}
			
			if #available(iOS 19.0, *) {
				NBSection(.localized("Experiments")) {
					Toggle(.localized("Enable Liquid Glass"), isOn: $_ignoreSolariumLinkedOnCheck)
				} footer: {
					Text(.localized("This enables Liquid Glass for this app, this requires a restart of the app to take effect."))
				}
			}
		}
		.onChange(of: _userIntefacerStyle) { value in
			if let style = UIUserInterfaceStyle(rawValue: value) {
				UIApplication.topViewController()?.view.window?.overrideUserInterfaceStyle = style
			}
		}
		.onChange(of: _ignoreSolariumLinkedOnCheck) { _ in
			UIApplication.shared.suspendAndReopen()
		}
    }
}
