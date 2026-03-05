import SwiftUI

// MARK: - View
struct AppearanceTintColorView: View {
	@AppStorage("Feather.userTintColor") private var selectedColorHex: String = "#0077BE"
	@AppStorage("Feather.userTintColorType") private var colorType: String = "solid"
	@AppStorage("Feather.userTintGradientStart") private var gradientStartHex: String = "#0077BE"
	@AppStorage("Feather.userTintGradientEnd") private var gradientEndHex: String = "#848ef9"
	
	@State private var isCustomSheetPresented = false
	
	private let tintOptions: [(name: String, hex: String)] = [
		("Ocean Blue", 		"#0077BE"),
		("Classic", 		"#848ef9"),
		("Berry",   		"#ff7a83"),
		("Cool Blue", 		"#4161F1"),
		("Fuchsia", 		"#FF00FF"),
		("Protokolle", 		"#4CD964"),
		("Aidoku", 			"#FF2D55"),
		("Clock", 			"#FF9500"),
		("Peculiar", 		"#4860e8"),
		("Very Peculiar", 	"#5394F7"),
		("Pink",			"#e18aab"),
		("Mint Fresh",		"#00E5C3"),
		("Sunset Orange",	"#FF6B35"),
		("Royal Purple",	"#7B2CBF"),
		("Forest Green",	"#2D6A4F"),
		("Ruby Red",		"#D62828"),
		("Golden Hour",		"#FFB703"),
		("Lavender",		"#9D4EDD"),
		("Coral",			"#FF006E"),
		("Teal Dream",		"#06FFF0"),
		("Crimson",			"#DC2F02"),
		("Sky Blue",		"#48CAE4"),
		("Emerald",			"#52B788"),
		("Hot Pink",		"#FF69B4"),
		("Lime Green",		"#32CD32"),
		("Indigo",			"#4B0082"),
		("Turquoise",		"#40E0D0"),
		("Peach",			"#FFDAB9"),
		("Magenta",			"#FF00FF"),
		("Amber",			"#FFBF00"),
		("Rose Gold",		"#B76E79"),
		("Cyan",			"#00FFFF"),
		("Salmon",			"#FA8072"),
		("Violet",			"#8B00FF"),
		("Gold",			"#FFD700"),
		("Bronze",			"#CD7F32"),
		("Silver",			"#C0C0C0"),
		("Navy",			"#001F3F"),
		("Maroon",			"#800000"),
		("Olive",			"#808000"),
		("Aqua",			"#00FFAA"),
		("Cherry",			"#DE3163"),
		("Mint",			"#98FF98"),
		("Plum",			"#DDA0DD"),
		("Tangerine",		"#FFA500"),
		("Seafoam",			"#93E9BE"),
		("Periwinkle",		"#CCCCFF"),
		("Burgundy",		"#800020"),
		("Chartreuse",		"#7FFF00"),
		("Cobalt",			"#0047AB"),
		("Mauve",			"#E0B0FF"),
		("Scarlet",			"#FF2400"),
		("Slate",			"#708090"),
		("Jade",			"#00A86B"),
		("Raspberry",		"#E30B5D"),
		("Steel Blue",		"#4682B4"),
		("Orchid",			"#DA70D6"),
		("Sienna",			"#A0522D"),
		("Cerulean",		"#007BA7"),
		("Mustard",			"#FFDB58"),
		("Pine Green",		"#01796F"),
		("Apricot",			"#FBCEB1"),
		("Lilac",			"#C8A2C8"),
		("Mahogany",		"#C04000"),
		("Powder Blue",		"#B0E0E6"),
		("Vermillion",		"#E34234"),
		("Spring Green",	"#00FF7F"),
		("Blush",			"#DE5D83"),
		("Ochre",			"#CC7722"),
		("Rust",			"#B7410E"),
		("Sage",			"#BCB88A"),
		("Brick Red",		"#CB4154"),
		("Mint Green",		"#98FF98")
	]

	var body: some View {
		Button {
			isCustomSheetPresented = true
		} label: {
			HStack(spacing: 16) {
				ZStack {
					if colorType == "gradient" {
						LinearGradient(
							colors: [SwiftUI.Color(hex: gradientStartHex), SwiftUI.Color(hex: gradientEndHex)],
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
						.frame(width: 32, height: 32)
						.clipShape(Circle())
					} else {
						Circle()
							.fill(SwiftUI.Color(hex: selectedColorHex))
							.frame(width: 32, height: 32)
					}
					Circle()
						.strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
						.frame(width: 32, height: 32)
				}
				.shadow(color: .black.opacity(0.1), radius: 4)
				
				VStack(alignment: .leading, spacing: 2) {
					Text("Theme Color")
						.font(.system(size: 16, weight: .semibold))
						.foregroundStyle(.primary)
					Text(colorName)
						.font(.system(size: 13))
						.foregroundStyle(.secondary)
				}

				Spacer()

				Image(systemName: "chevron.right")
					.font(.system(size: 14, weight: .bold))
					.foregroundStyle(.tertiary)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 14)
			.background(Color.clear)
			.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
			.overlay(
				RoundedRectangle(cornerRadius: 16, style: .continuous)
					.stroke(Color.white.opacity(0.1), lineWidth: 1)
			)
		}
		.buttonStyle(.plain)
		.padding(.horizontal, 16)
		.sheet(isPresented: $isCustomSheetPresented) {
			ThemeColorPickerSheet(
				selectedColorHex: $selectedColorHex,
				colorType: $colorType,
				gradientStartHex: $gradientStartHex,
				gradientEndHex: $gradientEndHex,
				tintOptions: tintOptions
			)
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
		}
	}

	private var colorName: String {
		if colorType == "gradient" {
			return "Gradient"
		}
		return tintOptions.first(where: { $0.hex == selectedColorHex })?.name ?? "Custom"
	}
}

struct ThemeColorPickerSheet: View {
	@Environment(\.dismiss) var dismiss
	@Binding var selectedColorHex: String
	@Binding var colorType: String
	@Binding var gradientStartHex: String
	@Binding var gradientEndHex: String
	let tintOptions: [(name: String, hex: String)]

	@State private var showCustomPicker = false

	var body: some View {
		NavigationView {
			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					Text("Personalize Portal with a custom theme color.")
						.font(.system(size: 14))
						.foregroundStyle(.secondary)
						.padding(.horizontal)

					LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 20) {
						// Advanced button
						VStack(spacing: 8) {
							ZStack {
								Circle()
									.fill(LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
									.frame(width: 50, height: 50)

								Image(systemName: "slider.horizontal.3")
									.font(.system(size: 18, weight: .bold))
									.foregroundStyle(.white)
							}

							Text("Custom")
								.font(.system(size: 11, weight: .medium))
						}
						.onTapGesture {
							showCustomPicker = true
						}

						ForEach(tintOptions, id: \.hex) { option in
							let color = SwiftUI.Color(hex: option.hex)
							VStack(spacing: 8) {
								ZStack {
									Circle()
										.fill(color)
										.frame(width: 50, height: 50)
										.shadow(color: color.opacity(0.3), radius: 5, y: 3)

									if selectedColorHex == option.hex && colorType == "solid" {
										Circle()
											.strokeBorder(.white, lineWidth: 3)
											.frame(width: 50, height: 50)

										Image(systemName: "checkmark")
											.font(.system(size: 14, weight: .bold))
											.foregroundStyle(.white)
									}
								}

								Text(option.name)
									.font(.system(size: 11, weight: .medium))
									.lineLimit(1)
							}
							.onTapGesture {
								withAnimation(.spring()) {
									colorType = "solid"
									selectedColorHex = option.hex
								}
								HapticsManager.shared.softImpact()
							}
						}
					}
					.padding(.horizontal)
				}
				.padding(.vertical)
			}
			.navigationTitle("Theme Colors")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") { dismiss() }
						.fontWeight(.bold)
				}
			}
			.background(Color.clear)
			.sheet(isPresented: $showCustomPicker) {
				CustomColorPickerView(
					colorType: $colorType,
					selectedColorHex: $selectedColorHex,
					gradientStartHex: $gradientStartHex,
					gradientEndHex: $gradientEndHex
				)
			}
		}
	}
}

// MARK: - Custom Color Picker View
struct CustomColorPickerView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var colorType: String
	@Binding var selectedColorHex: String
	@Binding var gradientStartHex: String
	@Binding var gradientEndHex: String

	@State private var solidColor: Color = .accentColor
	@State private var gradientStart: Color = .purple
	@State private var gradientEnd: Color = .blue

	private let gradientPresets: [(name: String, start: String, end: String)] = [
		("Sunset", "#FF6B35", "#F7931E"),
		("Ocean", "#00B4DB", "#0083B0"),
		("Purple Dream", "#B490CA", "#5E4FA2"),
		("Forest", "#2D6A4F", "#52B788"),
		("Fire", "#FF0844", "#FFB199"),
		("Northern Lights", "#00FFA3", "#03E1FF"),
		("Twilight", "#4E54C8", "#8F94FB"),
		("Royal", "#141E30", "#243B55")
	]

	var body: some View {
		NavigationView {
			Form {
				Section {
					Picker("Type", selection: $colorType) {
						Text("Solid").tag("solid")
						Text("Gradient").tag("gradient")
					}
					.pickerStyle(.segmented)
				}

				if colorType == "solid" {
					Section {
						ColorPicker("Pick a color", selection: $solidColor, supportsOpacity: false)
					}
				} else {
					Section(header: Text("Custom Gradient")) {
						ColorPicker("Start", selection: $gradientStart, supportsOpacity: false)
						ColorPicker("End", selection: $gradientEnd, supportsOpacity: false)
					}

					Section(header: Text("Presets")) {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack(spacing: 16) {
								ForEach(gradientPresets, id: \.name) { preset in
									VStack(spacing: 8) {
										Circle()
											.fill(
												LinearGradient(
													colors: [SwiftUI.Color(hex: preset.start), SwiftUI.Color(hex: preset.end)],
													startPoint: .topLeading,
													endPoint: .bottomTrailing
												)
											)
											.frame(width: 54, height: 54)
											.overlay(
												Circle()
													.stroke(
														gradientStartHex == preset.start && gradientEndHex == preset.end
															? Color.accentColor
															: Color.white.opacity(0.2),
														lineWidth: 3
													)
											)
											.onTapGesture {
												gradientStart = SwiftUI.Color(hex: preset.start)
												gradientEnd = SwiftUI.Color(hex: preset.end)
											}

										Text(preset.name)
											.font(.caption2.weight(.medium))
											.foregroundStyle(.secondary)
									}
								}
							}
							.padding(.vertical, 8)
						}
					}
				}

				Section {
					HStack {
						Spacer()
						Circle()
							.fill(
								colorType == "solid"
								? AnyShapeStyle(solidColor)
								: AnyShapeStyle(LinearGradient(colors: [gradientStart, gradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
							)
							.frame(width: 80, height: 80)
							.shadow(radius: 10)
						Spacer()
					}
					.padding()
				}
				.listRowBackground(Color.clear)
			}
            .scrollContentBackground(.hidden)
			.navigationTitle("Advanced Color")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") { dismiss() }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						if colorType == "solid" {
							selectedColorHex = solidColor.toHex() ?? "#0077BE"
						} else {
							gradientStartHex = gradientStart.toHex() ?? "#0077BE"
							gradientEndHex = gradientEnd.toHex() ?? "#848ef9"
						}
						dismiss()
					}
					.fontWeight(.bold)
				}
			}
		}
		.onAppear {
			solidColor = SwiftUI.Color(hex: selectedColorHex)
			gradientStart = SwiftUI.Color(hex: gradientStartHex)
			gradientEnd = SwiftUI.Color(hex: gradientEndHex)
		}
	}
}
