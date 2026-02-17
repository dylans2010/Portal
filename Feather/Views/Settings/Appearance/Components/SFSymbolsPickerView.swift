import SwiftUI

// MARK: - Enhanced SF Symbols Picker
struct SFSymbolsPickerView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @Environment(\.dismiss) var dismiss
    @State private var customSymbolName = ""
    @State private var showCustomSymbolInput = false
    @State private var selectedWeight: Font.Weight = .regular
    @State private var selectedSize: CGFloat = 24
    @State private var previewColor: Color = .accentColor
    @State private var showCustomizationPanel = false
    
    // Symbol categories for filtering
    private let categories = [
        "All", "Communication", "Weather", "Objects", "Devices",
        "Gaming", "Health", "Nature", "Transportation", "Human",
        "Symbols", "Arrows", "Math", "Text Formatting"
    ]
    
    // Comprehensive SF Symbols catalog organized by category
    private let symbolsByCategory: [String: [String]] = [
        "Communication": [
            "antenna.radiowaves.left.and.right", "bell", "bell.badge", "bell.circle",
            "bell.circle.fill", "bell.fill", "bell.slash", "bubble.left",
            "bubble.left.fill", "bubble.middle.bottom", "bubble.middle.top", "bubble.right",
            "bubble.right.fill", "dot.radiowaves.left.and.right", "envelope", "envelope.badge.checkmark",
            "envelope.badge.clock", "envelope.badge.minus", "envelope.badge.plus", "envelope.badge.xmark",
            "envelope.circle", "envelope.circle.badge.checkmark", "envelope.circle.badge.clock", "envelope.circle.badge.minus",
            "envelope.circle.badge.plus", "envelope.circle.badge.xmark", "envelope.circle.fill", "envelope.circle.fill.badge.checkmark",
            "envelope.circle.fill.badge.clock", "envelope.circle.fill.badge.minus", "envelope.circle.fill.badge.plus", "envelope.circle.fill.badge.xmark",
            "envelope.circle.fill.circle", "envelope.circle.fill.circle.fill", "envelope.circle.fill.rectangle", "envelope.circle.fill.rectangle.fill",
            "envelope.circle.fill.rtl", "envelope.circle.fill.slash", "envelope.circle.fill.slash.fill", "envelope.circle.fill.square",
            "envelope.circle.fill.square.fill", "envelope.circle.rectangle", "envelope.circle.rectangle.fill", "envelope.circle.rtl",
            "envelope.circle.slash", "envelope.circle.slash.fill", "envelope.circle.square", "envelope.circle.square.fill",
            "envelope.fill", "envelope.fill.badge.checkmark", "envelope.fill.badge.clock", "envelope.fill.badge.minus",
            "envelope.fill.badge.plus", "envelope.fill.badge.xmark", "envelope.fill.circle", "envelope.fill.circle.fill",
            "envelope.fill.rectangle", "envelope.fill.rectangle.fill", "envelope.fill.rtl", "envelope.fill.slash",
            "envelope.fill.slash.fill", "envelope.fill.square", "envelope.fill.square.fill", "envelope.open",
            "envelope.open.badge.checkmark", "envelope.open.badge.minus", "envelope.open.badge.plus", "envelope.open.badge.xmark",
            "envelope.open.circle", "envelope.open.circle.fill", "envelope.open.fill", "envelope.open.rectangle",
            "envelope.open.rectangle.fill", "envelope.open.slash", "envelope.open.slash.fill", "envelope.open.square",
            "envelope.open.square.fill", "envelope.rectangle", "envelope.rectangle.fill", "envelope.rtl",
            "envelope.slash", "envelope.slash.fill", "envelope.square", "envelope.square.fill",
            "message", "message.badge", "message.badge.badge.checkmark", "message.badge.badge.clock",
            "message.badge.badge.minus", "message.badge.badge.plus", "message.badge.badge.xmark", "message.badge.checkmark",
            "message.badge.circle", "message.badge.circle.fill", "message.badge.clock", "message.badge.fill",
            "message.badge.fill.rtl", "message.badge.filled.fill", "message.badge.filled.fill.badge.checkmark", "message.badge.filled.fill.badge.clock",
            "message.badge.filled.fill.badge.minus", "message.badge.filled.fill.badge.plus", "message.badge.filled.fill.badge.xmark", "message.badge.filled.fill.circle",
            "message.badge.filled.fill.circle.fill", "message.badge.filled.fill.rectangle", "message.badge.filled.fill.rectangle.fill", "message.badge.filled.fill.rtl",
            "message.badge.filled.fill.slash", "message.badge.filled.fill.slash.fill", "message.badge.filled.fill.square", "message.badge.filled.fill.square.fill",
            "message.badge.minus", "message.badge.plus", "message.badge.rectangle", "message.badge.rectangle.fill",
            "message.badge.rtl", "message.badge.slash", "message.badge.slash.fill", "message.badge.square",
            "message.badge.square.fill", "message.badge.xmark", "message.circle", "message.circle.badge.checkmark",
            "message.circle.badge.clock", "message.circle.badge.minus", "message.circle.badge.plus", "message.circle.badge.xmark",
            "message.circle.fill", "message.circle.fill.badge.checkmark", "message.circle.fill.badge.clock", "message.circle.fill.badge.minus",
            "message.circle.fill.badge.plus", "message.circle.fill.badge.xmark", "message.circle.fill.circle", "message.circle.fill.circle.fill",
            "message.circle.fill.rectangle", "message.circle.fill.rectangle.fill", "message.circle.fill.rtl", "message.circle.fill.slash",
            "message.circle.fill.slash.fill", "message.circle.fill.square", "message.circle.fill.square.fill", "message.circle.rectangle",
            "message.circle.rectangle.fill", "message.circle.rtl", "message.circle.slash", "message.circle.slash.fill",
            "message.circle.square", "message.circle.square.fill", "message.fill", "message.fill.badge.checkmark",
            "message.fill.badge.clock", "message.fill.badge.minus", "message.fill.badge.plus", "message.fill.badge.xmark",
            "message.fill.circle", "message.fill.circle.fill", "message.fill.rectangle", "message.fill.rectangle.fill",
            "message.fill.rtl", "message.fill.slash", "message.fill.slash.fill", "message.fill.square",
            "message.fill.square.fill", "message.rectangle", "message.rectangle.fill", "message.rtl",
            "message.slash", "message.slash.fill", "message.square", "message.square.fill",
            "mic", "mic.badge.plus", "mic.circle", "mic.circle.fill",
            "mic.fill", "mic.slash", "phone", "phone.arrow.down.left",
            "phone.arrow.up.right", "phone.circle", "phone.circle.fill", "phone.fill",
            "speaker", "speaker.fill", "speaker.slash", "speaker.wave.1",
            "speaker.wave.2", "speaker.wave.3", "video", "video.badge.checkmark",
            "video.badge.plus", "video.circle", "video.circle.fill", "video.fill",
            "waveform", "wifi", "wifi.exclamationmark", "wifi.slash"
        ],
        "Weather": [
            "cloud", "cloud.bolt", "cloud.fill", "cloud.fog",
            "cloud.heavyrain", "cloud.moon", "cloud.moon.fill", "cloud.rain",
            "cloud.rain.fill", "cloud.snow", "cloud.sun", "cloud.sun.fill",
            "drop", "drop.circle", "drop.circle.fill", "drop.fill",
            "drop.triangle", "drop.triangle.fill", "flame", "flame.circle",
            "flame.circle.fill", "flame.fill", "humidity", "humidity.fill",
            "hurricane", "moon", "moon.badge.checkmark", "moon.badge.clock",
            "moon.badge.minus", "moon.badge.plus", "moon.badge.xmark", "moon.circle",
            "moon.circle.badge.checkmark", "moon.circle.badge.clock", "moon.circle.badge.minus", "moon.circle.badge.plus",
            "moon.circle.badge.xmark", "moon.circle.fill", "moon.circle.fill.badge.checkmark", "moon.circle.fill.badge.clock",
            "moon.circle.fill.badge.minus", "moon.circle.fill.badge.plus", "moon.circle.fill.badge.xmark", "moon.circle.fill.circle",
            "moon.circle.fill.circle.fill", "moon.circle.fill.rectangle", "moon.circle.fill.rectangle.fill", "moon.circle.fill.rtl",
            "moon.circle.fill.slash", "moon.circle.fill.slash.fill", "moon.circle.fill.square", "moon.circle.fill.square.fill",
            "moon.circle.rectangle", "moon.circle.rectangle.fill", "moon.circle.rtl", "moon.circle.slash",
            "moon.circle.slash.fill", "moon.circle.square", "moon.circle.square.fill", "moon.fill",
            "moon.fill.badge.checkmark", "moon.fill.badge.clock", "moon.fill.badge.minus", "moon.fill.badge.plus",
            "moon.fill.badge.xmark", "moon.fill.circle", "moon.fill.circle.fill", "moon.fill.rectangle",
            "moon.fill.rectangle.fill", "moon.fill.rtl", "moon.fill.slash", "moon.fill.slash.fill",
            "moon.fill.square", "moon.fill.square.fill", "moon.rectangle", "moon.rectangle.fill",
            "moon.rtl", "moon.slash", "moon.slash.fill", "moon.square",
            "moon.square.fill", "moon.stars", "moon.stars.badge.checkmark", "moon.stars.badge.minus",
            "moon.stars.badge.plus", "moon.stars.badge.xmark", "moon.stars.circle", "moon.stars.circle.fill",
            "moon.stars.fill", "moon.stars.rectangle", "moon.stars.rectangle.fill", "moon.stars.slash",
            "moon.stars.slash.fill", "moon.stars.square", "moon.stars.square.fill", "snowflake",
            "sun.dust", "sun.dust.badge.checkmark", "sun.dust.badge.clock", "sun.dust.badge.minus",
            "sun.dust.badge.plus", "sun.dust.badge.xmark", "sun.dust.circle", "sun.dust.circle.fill",
            "sun.dust.fill", "sun.dust.fill.rtl", "sun.dust.rectangle", "sun.dust.rectangle.fill",
            "sun.dust.rtl", "sun.dust.slash", "sun.dust.slash.fill", "sun.dust.square",
            "sun.dust.square.fill", "sun.haze", "sun.haze.badge.checkmark", "sun.haze.badge.clock",
            "sun.haze.badge.minus", "sun.haze.badge.plus", "sun.haze.badge.xmark", "sun.haze.circle",
            "sun.haze.circle.fill", "sun.haze.fill", "sun.haze.fill.rtl", "sun.haze.rectangle",
            "sun.haze.rectangle.fill", "sun.haze.rtl", "sun.haze.slash", "sun.haze.slash.fill",
            "sun.haze.square", "sun.haze.square.fill", "sun.max", "sun.max.badge.checkmark",
            "sun.max.badge.clock", "sun.max.badge.minus", "sun.max.badge.plus", "sun.max.badge.xmark",
            "sun.max.circle", "sun.max.circle.fill", "sun.max.fill", "sun.max.fill.badge.checkmark",
            "sun.max.fill.badge.clock", "sun.max.fill.badge.minus", "sun.max.fill.badge.plus", "sun.max.fill.badge.xmark",
            "sun.max.fill.circle", "sun.max.fill.circle.fill", "sun.max.fill.rectangle", "sun.max.fill.rectangle.fill",
            "sun.max.fill.rtl", "sun.max.fill.slash", "sun.max.fill.slash.fill", "sun.max.fill.square",
            "sun.max.fill.square.fill", "sun.max.rectangle", "sun.max.rectangle.fill", "sun.max.rtl",
            "sun.max.slash", "sun.max.slash.fill", "sun.max.square", "sun.max.square.fill",
            "sun.min", "sun.min.badge.checkmark", "sun.min.badge.clock", "sun.min.badge.minus",
            "sun.min.badge.plus", "sun.min.badge.xmark", "sun.min.circle", "sun.min.circle.fill",
            "sun.min.fill", "sun.min.fill.badge.checkmark", "sun.min.fill.badge.clock", "sun.min.fill.badge.minus",
            "sun.min.fill.badge.plus", "sun.min.fill.badge.xmark", "sun.min.fill.circle", "sun.min.fill.circle.fill",
            "sun.min.fill.rectangle", "sun.min.fill.rectangle.fill", "sun.min.fill.rtl", "sun.min.fill.slash",
            "sun.min.fill.slash.fill", "sun.min.fill.square", "sun.min.fill.square.fill", "sun.min.rectangle",
            "sun.min.rectangle.fill", "sun.min.rtl", "sun.min.slash", "sun.min.slash.fill",
            "sun.min.square", "sun.min.square.fill", "thermometer.high", "thermometer.low",
            "thermometer.medium", "thermometer.snowflake", "thermometer.sun", "thermometer.sun.fill",
            "tornado", "tropicalstorm", "wind", "wind.snow"
        ],
        "Objects": [
            "1.magnifyingglass", "arrow.up.left.and.down.right.magnifyingglass", "bolt", "bolt.badge.a",
            "bolt.circle", "bolt.fill", "bolt.shield", "bolt.square",
            "book", "bookmark", "bookmark.circle", "bookmark.fill",
            "bookmark.slash", "bookmark.square", "briefcase", "briefcase.fill",
            "checkerboard.shield", "doc", "doc.badge.plus", "doc.fill",
            "doc.on.clipboard", "doc.on.doc", "doc.text", "eye",
            "eye.circle", "eye.fill", "eye.slash", "eyebrow",
            "eyes", "flag", "flag.badge.ellipsis", "flag.circle",
            "flag.fill", "flag.slash", "flag.square", "folder",
            "folder.badge.minus", "folder.badge.plus", "folder.fill", "heart",
            "heart.badge.checkmark", "heart.badge.clock", "heart.badge.minus", "heart.badge.plus",
            "heart.badge.xmark", "heart.circle", "heart.circle.badge.plus", "heart.circle.fill",
            "heart.circle.rectangle", "heart.circle.rectangle.fill", "heart.circle.slash", "heart.circle.slash.fill",
            "heart.circle.square", "heart.circle.square.fill", "heart.fill", "heart.fill.badge.checkmark",
            "heart.fill.badge.clock", "heart.fill.badge.minus", "heart.fill.badge.plus", "heart.fill.badge.xmark",
            "heart.fill.circle", "heart.fill.circle.fill", "heart.fill.rectangle", "heart.fill.rectangle.fill",
            "heart.fill.rtl", "heart.fill.slash", "heart.fill.slash.fill", "heart.fill.square",
            "heart.fill.square.fill", "heart.rectangle", "heart.rectangle.fill", "heart.rtl",
            "heart.slash", "heart.slash.fill", "heart.square", "heart.square.fill",
            "heart.text.square", "key", "key.fill", "key.icloud",
            "link", "link.badge.plus", "link.circle", "lock",
            "lock.fill", "lock.open", "magnifyingglass", "magnifyingglass.circle",
            "minus.magnifyingglass", "paperclip", "paperclip.circle", "paperplane",
            "paperplane.circle", "paperplane.fill", "personalhotspot", "plus.magnifyingglass",
            "shield", "shield.fill", "shield.lefthalf.filled", "shield.righthalf.filled",
            "shield.slash", "star", "star.badge.checkmark", "star.badge.clock",
            "star.badge.minus", "star.badge.plus", "star.badge.xmark", "star.circle",
            "star.circle.badge.checkmark", "star.circle.badge.clock", "star.circle.badge.minus", "star.circle.badge.plus",
            "star.circle.badge.xmark", "star.circle.fill", "star.circle.fill.rtl", "star.circle.rectangle",
            "star.circle.rectangle.fill", "star.circle.rtl", "star.circle.slash", "star.circle.slash.fill",
            "star.circle.square", "star.circle.square.fill", "star.fill", "star.fill.badge.checkmark",
            "star.fill.badge.clock", "star.fill.badge.minus", "star.fill.badge.plus", "star.fill.badge.xmark",
            "star.fill.circle", "star.fill.circle.fill", "star.fill.rectangle", "star.fill.rectangle.fill",
            "star.fill.rtl", "star.fill.slash", "star.fill.slash.fill", "star.fill.square",
            "star.fill.square.fill", "star.leadinghalf.filled", "star.leadinghalf.filled.badge.checkmark", "star.leadinghalf.filled.badge.clock",
            "star.leadinghalf.filled.badge.minus", "star.leadinghalf.filled.badge.plus", "star.leadinghalf.filled.badge.xmark", "star.leadinghalf.filled.circle",
            "star.leadinghalf.filled.circle.fill", "star.leadinghalf.filled.fill", "star.leadinghalf.filled.fill.rtl", "star.leadinghalf.filled.rectangle",
            "star.leadinghalf.filled.rectangle.fill", "star.leadinghalf.filled.rtl", "star.leadinghalf.filled.slash", "star.leadinghalf.filled.slash.fill",
            "star.leadinghalf.filled.square", "star.leadinghalf.filled.square.fill", "star.rectangle", "star.rectangle.fill",
            "star.rtl", "star.slash", "star.slash.badge.checkmark", "star.slash.badge.clock",
            "star.slash.badge.minus", "star.slash.badge.plus", "star.slash.badge.xmark", "star.slash.circle",
            "star.slash.circle.fill", "star.slash.fill", "star.slash.fill.rtl", "star.slash.rectangle",
            "star.slash.rectangle.fill", "star.slash.rtl", "star.slash.slash", "star.slash.slash.fill",
            "star.slash.square", "star.slash.square.fill", "star.square", "star.square.badge.checkmark",
            "star.square.badge.clock", "star.square.badge.minus", "star.square.badge.plus", "star.square.badge.xmark",
            "star.square.circle", "star.square.circle.fill", "star.square.fill", "star.square.fill.rtl",
            "star.square.rectangle", "star.square.rectangle.fill", "star.square.rtl", "star.square.slash",
            "star.square.slash.fill", "star.square.square", "star.square.square.fill", "tag",
            "tag.circle", "tag.fill", "tag.slash", "tag.square",
            "tags", "trash", "trash.fill", "trash.slash"
        ],
        "Devices": [
            "4k.tv", "airpod.left", "airpod.right", "airpods",
            "airpods.max", "airpodspro", "applewatch", "applewatch.watchface",
            "battery.100", "cable.connector", "camera", "computermouse",
            "desktopcomputer", "display", "display.2", "externaldrive",
            "externaldrive.fill", "faxmachine", "headphones", "headphones.circle",
            "homepod", "internaldrive", "ipad", "ipad.badge.checkmark",
            "ipad.badge.clock", "ipad.badge.minus", "ipad.badge.plus", "ipad.badge.xmark",
            "ipad.checkmark", "ipad.checkmark.badge.checkmark", "ipad.checkmark.badge.minus", "ipad.checkmark.badge.plus",
            "ipad.checkmark.circle", "ipad.checkmark.circle.fill", "ipad.checkmark.fill", "ipad.checkmark.rectangle",
            "ipad.checkmark.rectangle.fill", "ipad.checkmark.slash", "ipad.checkmark.slash.fill", "ipad.checkmark.square",
            "ipad.checkmark.square.fill", "ipad.circle", "ipad.circle.fill", "ipad.fill",
            "ipad.fill.rtl", "ipad.homebutton", "ipad.homebutton.badge.checkmark", "ipad.homebutton.badge.clock",
            "ipad.homebutton.badge.minus", "ipad.homebutton.badge.plus", "ipad.homebutton.badge.xmark", "ipad.homebutton.circle",
            "ipad.homebutton.circle.fill", "ipad.homebutton.fill", "ipad.homebutton.fill.rtl", "ipad.homebutton.rectangle",
            "ipad.homebutton.rectangle.fill", "ipad.homebutton.rtl", "ipad.homebutton.slash", "ipad.homebutton.slash.fill",
            "ipad.homebutton.square", "ipad.homebutton.square.fill", "ipad.landscape", "ipad.landscape.badge.checkmark",
            "ipad.landscape.badge.clock", "ipad.landscape.badge.minus", "ipad.landscape.badge.plus", "ipad.landscape.badge.xmark",
            "ipad.landscape.circle", "ipad.landscape.circle.fill", "ipad.landscape.fill", "ipad.landscape.fill.rtl",
            "ipad.landscape.rectangle", "ipad.landscape.rectangle.fill", "ipad.landscape.rtl", "ipad.landscape.slash",
            "ipad.landscape.slash.fill", "ipad.landscape.square", "ipad.landscape.square.fill", "ipad.rectangle",
            "ipad.rectangle.fill", "ipad.rtl", "ipad.slash", "ipad.slash.fill",
            "ipad.square", "ipad.square.fill", "iphone", "iphone.badge.checkmark",
            "iphone.badge.clock", "iphone.badge.minus", "iphone.badge.plus", "iphone.badge.xmark",
            "iphone.circle", "iphone.circle.badge.checkmark", "iphone.circle.badge.clock", "iphone.circle.badge.minus",
            "iphone.circle.badge.plus", "iphone.circle.badge.xmark", "iphone.circle.fill", "iphone.circle.fill.rtl",
            "iphone.circle.rectangle", "iphone.circle.rectangle.fill", "iphone.circle.rtl", "iphone.circle.slash",
            "iphone.circle.slash.fill", "iphone.circle.square", "iphone.circle.square.fill", "iphone.fill",
            "iphone.fill.rtl", "iphone.homebutton", "iphone.homebutton.badge.checkmark", "iphone.homebutton.badge.clock",
            "iphone.homebutton.badge.minus", "iphone.homebutton.badge.plus", "iphone.homebutton.badge.xmark", "iphone.homebutton.circle",
            "iphone.homebutton.circle.fill", "iphone.homebutton.fill", "iphone.homebutton.fill.rtl", "iphone.homebutton.rectangle",
            "iphone.homebutton.rectangle.fill", "iphone.homebutton.rtl", "iphone.homebutton.slash", "iphone.homebutton.slash.fill",
            "iphone.homebutton.square", "iphone.homebutton.square.fill", "iphone.landscape", "iphone.landscape.badge.checkmark",
            "iphone.landscape.badge.clock", "iphone.landscape.badge.minus", "iphone.landscape.badge.plus", "iphone.landscape.badge.xmark",
            "iphone.landscape.circle", "iphone.landscape.circle.fill", "iphone.landscape.fill", "iphone.landscape.fill.rtl",
            "iphone.landscape.rectangle", "iphone.landscape.rectangle.fill", "iphone.landscape.rtl", "iphone.landscape.slash",
            "iphone.landscape.slash.fill", "iphone.landscape.square", "iphone.landscape.square.fill", "iphone.radiowaves.left.and.right",
            "iphone.radiowaves.left.and.right.badge.checkmark", "iphone.radiowaves.left.and.right.badge.clock", "iphone.radiowaves.left.and.right.badge.minus", "iphone.radiowaves.left.and.right.badge.plus",
            "iphone.radiowaves.left.and.right.badge.xmark", "iphone.radiowaves.left.and.right.circle", "iphone.radiowaves.left.and.right.circle.fill", "iphone.radiowaves.left.and.right.fill",
            "iphone.radiowaves.left.and.right.fill.rtl", "iphone.radiowaves.left.and.right.rectangle", "iphone.radiowaves.left.and.right.rectangle.fill", "iphone.radiowaves.left.and.right.rtl",
            "iphone.radiowaves.left.and.right.slash", "iphone.radiowaves.left.and.right.slash.fill", "iphone.radiowaves.left.and.right.square", "iphone.radiowaves.left.and.right.square.fill",
            "iphone.rectangle", "iphone.rectangle.fill", "iphone.rtl", "iphone.slash",
            "iphone.slash.fill", "iphone.smartcase", "iphone.smartcase.badge.checkmark", "iphone.smartcase.badge.clock",
            "iphone.smartcase.badge.minus", "iphone.smartcase.badge.plus", "iphone.smartcase.badge.xmark", "iphone.smartcase.circle",
            "iphone.smartcase.circle.fill", "iphone.smartcase.fill", "iphone.smartcase.fill.rtl", "iphone.smartcase.rectangle",
            "iphone.smartcase.rectangle.fill", "iphone.smartcase.rtl", "iphone.smartcase.slash", "iphone.smartcase.slash.fill",
            "iphone.smartcase.square", "iphone.smartcase.square.fill", "iphone.square", "iphone.square.fill",
            "keyboard", "keyboard.macwindow", "laptopcomputer", "macmini",
            "macpro.gen1", "mouse", "opticaldisc", "pc",
            "printer", "printer.fill", "scanner", "scanner.fill",
            "server.rack", "tv", "tv.circle", "tv.fill"
        ],
        "Gaming": [
            "baseball", "basketball", "checkerboard", "crown",
            "crown.badge.checkmark", "crown.badge.clock", "crown.badge.minus", "crown.badge.plus",
            "crown.badge.xmark", "crown.circle", "crown.circle.fill", "crown.fill",
            "crown.rectangle", "crown.rectangle.fill", "crown.rtl", "crown.slash",
            "crown.slash.fill", "crown.square", "crown.square.fill", "dice",
            "dice.badge.checkmark", "dice.badge.clock", "dice.badge.minus", "dice.badge.plus",
            "dice.badge.xmark", "dice.circle", "dice.circle.fill", "dice.fill",
            "dice.fill.badge.checkmark", "dice.fill.badge.clock", "dice.fill.badge.minus", "dice.fill.badge.plus",
            "dice.fill.badge.xmark", "dice.fill.circle", "dice.fill.circle.fill", "dice.fill.rectangle",
            "dice.fill.rectangle.fill", "dice.fill.rtl", "dice.fill.slash", "dice.fill.slash.fill",
            "dice.fill.square", "dice.fill.square.fill", "dice.rectangle", "dice.rectangle.fill",
            "dice.rtl", "dice.slash", "dice.slash.fill", "dice.square",
            "dice.square.fill", "football", "gamecontroller", "gamecontroller.badge.checkmark",
            "gamecontroller.badge.clock", "gamecontroller.badge.minus", "gamecontroller.badge.plus", "gamecontroller.badge.xmark",
            "gamecontroller.circle", "gamecontroller.circle.fill", "gamecontroller.fill", "gamecontroller.fill.badge.checkmark",
            "gamecontroller.fill.badge.clock", "gamecontroller.fill.badge.minus", "gamecontroller.fill.badge.plus", "gamecontroller.fill.badge.xmark",
            "gamecontroller.fill.circle", "gamecontroller.fill.circle.fill", "gamecontroller.fill.rectangle", "gamecontroller.fill.rectangle.fill",
            "gamecontroller.fill.rtl", "gamecontroller.fill.slash", "gamecontroller.fill.slash.fill", "gamecontroller.fill.square",
            "gamecontroller.fill.square.fill", "gamecontroller.rectangle", "gamecontroller.rectangle.fill", "gamecontroller.rtl",
            "gamecontroller.slash", "gamecontroller.slash.fill", "gamecontroller.square", "gamecontroller.square.fill",
            "gift", "gift.fill", "medal", "medal.badge.checkmark",
            "medal.badge.clock", "medal.badge.minus", "medal.badge.plus", "medal.badge.xmark",
            "medal.circle", "medal.circle.fill", "medal.fill", "medal.fill.badge.checkmark",
            "medal.fill.badge.clock", "medal.fill.badge.minus", "medal.fill.badge.plus", "medal.fill.badge.xmark",
            "medal.fill.circle", "medal.fill.circle.fill", "medal.fill.rectangle", "medal.fill.rectangle.fill",
            "medal.fill.rtl", "medal.fill.slash", "medal.fill.slash.fill", "medal.fill.square",
            "medal.fill.square.fill", "medal.rectangle", "medal.rectangle.fill", "medal.rtl",
            "medal.slash", "medal.slash.fill", "medal.square", "medal.square.fill",
            "puzzlepiece", "puzzlepiece.badge.checkmark", "puzzlepiece.badge.clock", "puzzlepiece.badge.minus",
            "puzzlepiece.badge.plus", "puzzlepiece.badge.xmark", "puzzlepiece.circle", "puzzlepiece.circle.fill",
            "puzzlepiece.fill", "puzzlepiece.fill.badge.checkmark", "puzzlepiece.fill.badge.clock", "puzzlepiece.fill.badge.minus",
            "puzzlepiece.fill.badge.plus", "puzzlepiece.fill.badge.xmark", "puzzlepiece.fill.circle", "puzzlepiece.fill.circle.fill",
            "puzzlepiece.fill.rectangle", "puzzlepiece.fill.rectangle.fill", "puzzlepiece.fill.rtl", "puzzlepiece.fill.slash",
            "puzzlepiece.fill.slash.fill", "puzzlepiece.fill.square", "puzzlepiece.fill.square.fill", "puzzlepiece.rectangle",
            "puzzlepiece.rectangle.fill", "puzzlepiece.rtl", "puzzlepiece.slash", "puzzlepiece.slash.fill",
            "puzzlepiece.square", "puzzlepiece.square.fill", "racket", "skis",
            "snowboard", "soccerball", "sparkles", "sportscourt",
            "surfboard", "target", "target.badge.checkmark", "target.badge.clock",
            "target.badge.minus", "target.badge.plus", "target.badge.xmark", "target.circle",
            "target.circle.fill", "target.fill", "target.fill.rtl", "target.rectangle",
            "target.rectangle.fill", "target.rtl", "target.slash", "target.slash.fill",
            "target.square", "target.square.fill", "tennisball", "trophy",
            "trophy.badge.checkmark", "trophy.badge.clock", "trophy.badge.minus", "trophy.badge.plus",
            "trophy.badge.xmark", "trophy.circle", "trophy.circle.fill", "trophy.fill",
            "trophy.fill.badge.checkmark", "trophy.fill.badge.clock", "trophy.fill.badge.minus", "trophy.fill.badge.plus",
            "trophy.fill.badge.xmark", "trophy.fill.circle", "trophy.fill.circle.fill", "trophy.fill.rectangle",
            "trophy.fill.rectangle.fill", "trophy.fill.rtl", "trophy.fill.slash", "trophy.fill.slash.fill",
            "trophy.fill.square", "trophy.fill.square.fill", "trophy.rectangle", "trophy.rectangle.fill",
            "trophy.rtl", "trophy.slash", "trophy.slash.fill", "trophy.square",
            "trophy.square.fill", "volleyball", "wand.and.rays", "wand.and.stars"
        ],
        "Health": [
            "allergens", "bandage", "bandage.badge.checkmark", "bandage.badge.clock",
            "bandage.badge.minus", "bandage.badge.plus", "bandage.badge.xmark", "bandage.circle",
            "bandage.circle.fill", "bandage.fill", "bandage.fill.badge.checkmark", "bandage.fill.badge.clock",
            "bandage.fill.badge.minus", "bandage.fill.badge.plus", "bandage.fill.badge.xmark", "bandage.fill.circle",
            "bandage.fill.circle.fill", "bandage.fill.rectangle", "bandage.fill.rectangle.fill", "bandage.fill.rtl",
            "bandage.fill.slash", "bandage.fill.slash.fill", "bandage.fill.square", "bandage.fill.square.fill",
            "bandage.rectangle", "bandage.rectangle.fill", "bandage.rtl", "bandage.slash",
            "bandage.slash.fill", "bandage.square", "bandage.square.fill", "bolt.heart",
            "bolt.heart.badge.checkmark", "bolt.heart.badge.clock", "bolt.heart.badge.minus", "bolt.heart.badge.plus",
            "bolt.heart.badge.xmark", "bolt.heart.circle", "bolt.heart.circle.fill", "bolt.heart.fill",
            "bolt.heart.fill.rtl", "bolt.heart.rectangle", "bolt.heart.rectangle.fill", "bolt.heart.rtl",
            "bolt.heart.slash", "bolt.heart.slash.fill", "bolt.heart.square", "bolt.heart.square.fill",
            "brain", "brain.head.profile", "cross", "cross.badge.checkmark",
            "cross.badge.clock", "cross.badge.minus", "cross.badge.plus", "cross.badge.xmark",
            "cross.circle", "cross.circle.badge.checkmark", "cross.circle.badge.clock", "cross.circle.badge.minus",
            "cross.circle.badge.plus", "cross.circle.badge.xmark", "cross.circle.fill", "cross.circle.fill.rtl",
            "cross.circle.rectangle", "cross.circle.rectangle.fill", "cross.circle.rtl", "cross.circle.slash",
            "cross.circle.slash.fill", "cross.circle.square", "cross.circle.square.fill", "cross.fill",
            "cross.fill.badge.checkmark", "cross.fill.badge.clock", "cross.fill.badge.minus", "cross.fill.badge.plus",
            "cross.fill.badge.xmark", "cross.fill.circle", "cross.fill.circle.fill", "cross.fill.rectangle",
            "cross.fill.rectangle.fill", "cross.fill.rtl", "cross.fill.slash", "cross.fill.slash.fill",
            "cross.fill.square", "cross.fill.square.fill", "cross.rectangle", "cross.rectangle.fill",
            "cross.rtl", "cross.slash", "cross.slash.fill", "cross.square",
            "cross.square.fill", "facemask", "facemask.fill", "hand.raised",
            "hand.raised.fill", "heart.fill", "heart.fill.badge.checkmark", "heart.fill.badge.clock",
            "heart.fill.badge.minus", "heart.fill.badge.plus", "heart.fill.badge.xmark", "heart.fill.circle",
            "heart.fill.circle.fill", "heart.fill.rectangle", "heart.fill.rectangle.fill", "heart.fill.rtl",
            "heart.fill.slash", "heart.fill.slash.fill", "heart.fill.square", "heart.fill.square.fill",
            "heart.text.square", "heart.text.square.badge.checkmark", "heart.text.square.badge.clock", "heart.text.square.badge.minus",
            "heart.text.square.badge.plus", "heart.text.square.badge.xmark", "heart.text.square.circle", "heart.text.square.circle.fill",
            "heart.text.square.fill", "heart.text.square.fill.rtl", "heart.text.square.rectangle", "heart.text.square.rectangle.fill",
            "heart.text.square.rtl", "heart.text.square.slash", "heart.text.square.slash.fill", "heart.text.square.square",
            "heart.text.square.square.fill", "ivfluid.bag", "lungs", "lungs.fill",
            "medical.thermometer", "microbe", "pill", "pill.badge.checkmark",
            "pill.badge.clock", "pill.badge.minus", "pill.badge.plus", "pill.badge.xmark",
            "pill.circle", "pill.circle.fill", "pill.fill", "pill.fill.badge.checkmark",
            "pill.fill.badge.clock", "pill.fill.badge.minus", "pill.fill.badge.plus", "pill.fill.badge.xmark",
            "pill.fill.circle", "pill.fill.circle.fill", "pill.fill.rectangle", "pill.fill.rectangle.fill",
            "pill.fill.rtl", "pill.fill.slash", "pill.fill.slash.fill", "pill.fill.square",
            "pill.fill.square.fill", "pill.rectangle", "pill.rectangle.fill", "pill.rtl",
            "pill.slash", "pill.slash.fill", "pill.square", "pill.square.fill",
            "pills", "pills.badge.checkmark", "pills.badge.clock", "pills.badge.minus",
            "pills.badge.plus", "pills.badge.xmark", "pills.circle", "pills.circle.fill",
            "pills.fill", "pills.fill.badge.checkmark", "pills.fill.badge.clock", "pills.fill.badge.minus",
            "pills.fill.badge.plus", "pills.fill.badge.xmark", "pills.fill.circle", "pills.fill.circle.fill",
            "pills.fill.rectangle", "pills.fill.rectangle.fill", "pills.fill.rtl", "pills.fill.slash",
            "pills.fill.slash.fill", "pills.fill.square", "pills.fill.square.fill", "pills.rectangle",
            "pills.rectangle.fill", "pills.rtl", "pills.slash", "pills.slash.fill",
            "pills.square", "pills.square.fill", "staroflife", "stethoscope",
            "syringe", "syringe.fill", "testtube", "testtube.2"
        ],
        "Nature": [
            "allergens", "ant", "ant.fill", "bird",
            "bird.fill", "bug", "camera.macro", "fish",
            "flame", "globe", "globe.americas", "globe.americas.badge.checkmark",
            "globe.americas.badge.clock", "globe.americas.badge.minus", "globe.americas.badge.plus", "globe.americas.badge.xmark",
            "globe.americas.circle", "globe.americas.circle.fill", "globe.americas.fill", "globe.americas.fill.rtl",
            "globe.americas.rectangle", "globe.americas.rectangle.fill", "globe.americas.rtl", "globe.americas.slash",
            "globe.americas.slash.fill", "globe.americas.square", "globe.americas.square.fill", "globe.asia.australia",
            "globe.asia.australia.badge.checkmark", "globe.asia.australia.badge.clock", "globe.asia.australia.badge.minus", "globe.asia.australia.badge.plus",
            "globe.asia.australia.badge.xmark", "globe.asia.australia.circle", "globe.asia.australia.circle.fill", "globe.asia.australia.fill",
            "globe.asia.australia.fill.rtl", "globe.asia.australia.rectangle", "globe.asia.australia.rectangle.fill", "globe.asia.australia.rtl",
            "globe.asia.australia.slash", "globe.asia.australia.slash.fill", "globe.asia.australia.square", "globe.asia.australia.square.fill",
            "globe.badge.checkmark", "globe.badge.clock", "globe.badge.minus", "globe.badge.plus",
            "globe.badge.xmark", "globe.circle", "globe.circle.fill", "globe.europe.africa",
            "globe.europe.africa.badge.checkmark", "globe.europe.africa.badge.clock", "globe.europe.africa.badge.minus", "globe.europe.africa.badge.plus",
            "globe.europe.africa.badge.xmark", "globe.europe.africa.circle", "globe.europe.africa.circle.fill", "globe.europe.africa.fill",
            "globe.europe.africa.fill.rtl", "globe.europe.africa.rectangle", "globe.europe.africa.rectangle.fill", "globe.europe.africa.rtl",
            "globe.europe.africa.slash", "globe.europe.africa.slash.fill", "globe.europe.africa.square", "globe.europe.africa.square.fill",
            "globe.fill", "globe.fill.rtl", "globe.rectangle", "globe.rectangle.fill",
            "globe.rtl", "globe.slash", "globe.slash.fill", "globe.square",
            "globe.square.fill", "hare", "hare.fill", "ladybug",
            "leaf", "leaf.arrow.triangle.circlepath", "leaf.arrow.triangle.circlepath.badge.checkmark", "leaf.arrow.triangle.circlepath.badge.clock",
            "leaf.arrow.triangle.circlepath.badge.minus", "leaf.arrow.triangle.circlepath.badge.plus", "leaf.arrow.triangle.circlepath.badge.xmark", "leaf.arrow.triangle.circlepath.circle",
            "leaf.arrow.triangle.circlepath.circle.fill", "leaf.arrow.triangle.circlepath.fill", "leaf.arrow.triangle.circlepath.fill.rtl", "leaf.arrow.triangle.circlepath.rectangle",
            "leaf.arrow.triangle.circlepath.rectangle.fill", "leaf.arrow.triangle.circlepath.rtl", "leaf.arrow.triangle.circlepath.slash", "leaf.arrow.triangle.circlepath.slash.fill",
            "leaf.arrow.triangle.circlepath.square", "leaf.arrow.triangle.circlepath.square.fill", "leaf.badge.checkmark", "leaf.badge.clock",
            "leaf.badge.minus", "leaf.badge.plus", "leaf.badge.xmark", "leaf.circle",
            "leaf.circle.fill", "leaf.fill", "leaf.fill.badge.checkmark", "leaf.fill.badge.clock",
            "leaf.fill.badge.minus", "leaf.fill.badge.plus", "leaf.fill.badge.xmark", "leaf.fill.circle",
            "leaf.fill.circle.fill", "leaf.fill.rectangle", "leaf.fill.rectangle.fill", "leaf.fill.rtl",
            "leaf.fill.slash", "leaf.fill.slash.fill", "leaf.fill.square", "leaf.fill.square.fill",
            "leaf.rectangle", "leaf.rectangle.fill", "leaf.rtl", "leaf.slash",
            "leaf.slash.fill", "leaf.square", "leaf.square.fill", "lizard",
            "moon.stars", "moon.stars.fill", "mountain.2", "mountain.2.badge.checkmark",
            "mountain.2.badge.clock", "mountain.2.badge.minus", "mountain.2.badge.plus", "mountain.2.badge.xmark",
            "mountain.2.circle", "mountain.2.circle.fill", "mountain.2.fill", "mountain.2.fill.badge.checkmark",
            "mountain.2.fill.badge.clock", "mountain.2.fill.badge.minus", "mountain.2.fill.badge.plus", "mountain.2.fill.badge.xmark",
            "mountain.2.fill.circle", "mountain.2.fill.circle.fill", "mountain.2.fill.rectangle", "mountain.2.fill.rectangle.fill",
            "mountain.2.fill.rtl", "mountain.2.fill.slash", "mountain.2.fill.slash.fill", "mountain.2.fill.square",
            "mountain.2.fill.square.fill", "mountain.2.rectangle", "mountain.2.rectangle.fill", "mountain.2.rtl",
            "mountain.2.slash", "mountain.2.slash.fill", "mountain.2.square", "mountain.2.square.fill",
            "pawprint", "pawprint.fill", "sparkles", "sunrise",
            "sunrise.fill", "sunset", "sunset.fill", "tortoise",
            "tortoise.fill", "tree", "tree.badge.checkmark", "tree.badge.clock",
            "tree.badge.minus", "tree.badge.plus", "tree.badge.xmark", "tree.circle",
            "tree.circle.fill", "tree.fill", "tree.fill.badge.checkmark", "tree.fill.badge.clock",
            "tree.fill.badge.minus", "tree.fill.badge.plus", "tree.fill.badge.xmark", "tree.fill.circle",
            "tree.fill.circle.fill", "tree.fill.rectangle", "tree.fill.rectangle.fill", "tree.fill.rtl",
            "tree.fill.slash", "tree.fill.slash.fill", "tree.fill.square", "tree.fill.square.fill",
            "tree.rectangle", "tree.rectangle.fill", "tree.rtl", "tree.slash",
            "tree.slash.fill", "tree.square", "tree.square.fill", "water.waves"
        ],
        "Transportation": [
            "airplane", "airplane.badge.checkmark", "airplane.badge.clock", "airplane.badge.minus",
            "airplane.badge.plus", "airplane.badge.xmark", "airplane.circle", "airplane.circle.fill",
            "airplane.fill", "airplane.fill.rtl", "airplane.rectangle", "airplane.rectangle.fill",
            "airplane.rtl", "airplane.slash", "airplane.slash.fill", "airplane.square",
            "airplane.square.fill", "bicycle", "bicycle.badge.checkmark", "bicycle.badge.clock",
            "bicycle.badge.minus", "bicycle.badge.plus", "bicycle.badge.xmark", "bicycle.circle",
            "bicycle.circle.badge.checkmark", "bicycle.circle.badge.clock", "bicycle.circle.badge.minus", "bicycle.circle.badge.plus",
            "bicycle.circle.badge.xmark", "bicycle.circle.fill", "bicycle.circle.fill.rtl", "bicycle.circle.rectangle",
            "bicycle.circle.rectangle.fill", "bicycle.circle.rtl", "bicycle.circle.slash", "bicycle.circle.slash.fill",
            "bicycle.circle.square", "bicycle.circle.square.fill", "bicycle.fill", "bicycle.fill.rtl",
            "bicycle.rectangle", "bicycle.rectangle.fill", "bicycle.rtl", "bicycle.slash",
            "bicycle.slash.fill", "bicycle.square", "bicycle.square.fill", "bus",
            "bus.badge.checkmark", "bus.badge.clock", "bus.badge.minus", "bus.badge.plus",
            "bus.badge.xmark", "bus.circle", "bus.circle.fill", "bus.fill",
            "bus.fill.badge.checkmark", "bus.fill.badge.clock", "bus.fill.badge.minus", "bus.fill.badge.plus",
            "bus.fill.badge.xmark", "bus.fill.circle", "bus.fill.circle.fill", "bus.fill.rectangle",
            "bus.fill.rectangle.fill", "bus.fill.rtl", "bus.fill.slash", "bus.fill.slash.fill",
            "bus.fill.square", "bus.fill.square.fill", "bus.rectangle", "bus.rectangle.fill",
            "bus.rtl", "bus.slash", "bus.slash.fill", "bus.square",
            "bus.square.fill", "car", "car.2", "car.2.badge.checkmark",
            "car.2.badge.clock", "car.2.badge.minus", "car.2.badge.plus", "car.2.badge.xmark",
            "car.2.circle", "car.2.circle.fill", "car.2.fill", "car.2.fill.rtl",
            "car.2.rectangle", "car.2.rectangle.fill", "car.2.rtl", "car.2.slash",
            "car.2.slash.fill", "car.2.square", "car.2.square.fill", "car.badge.checkmark",
            "car.badge.clock", "car.badge.minus", "car.badge.plus", "car.badge.xmark",
            "car.circle", "car.circle.badge.checkmark", "car.circle.badge.clock", "car.circle.badge.minus",
            "car.circle.badge.plus", "car.circle.badge.xmark", "car.circle.fill", "car.circle.fill.rtl",
            "car.circle.rectangle", "car.circle.rectangle.fill", "car.circle.rtl", "car.circle.slash",
            "car.circle.slash.fill", "car.circle.square", "car.circle.square.fill", "car.fill",
            "car.fill.badge.checkmark", "car.fill.badge.clock", "car.fill.badge.minus", "car.fill.badge.plus",
            "car.fill.badge.xmark", "car.fill.circle", "car.fill.circle.fill", "car.fill.rectangle",
            "car.fill.rectangle.fill", "car.fill.rtl", "car.fill.slash", "car.fill.slash.fill",
            "car.fill.square", "car.fill.square.fill", "car.rectangle", "car.rectangle.fill",
            "car.rtl", "car.side", "car.side.badge.checkmark", "car.side.badge.clock",
            "car.side.badge.minus", "car.side.badge.plus", "car.side.badge.xmark", "car.side.circle",
            "car.side.circle.fill", "car.side.fill", "car.side.fill.rtl", "car.side.rectangle",
            "car.side.rectangle.fill", "car.side.rtl", "car.side.slash", "car.side.slash.fill",
            "car.side.square", "car.side.square.fill", "car.slash", "car.slash.fill",
            "car.square", "car.square.fill", "ferry", "ferry.fill",
            "fuelpump", "fuelpump.fill", "parkingsign.circle", "road.lanes",
            "rocket", "rocket.fill", "sailboat", "sailboat.fill",
            "scooter", "steeringwheel", "tractor", "train.side.front.car",
            "tram", "tram.badge.checkmark", "tram.badge.clock", "tram.badge.minus",
            "tram.badge.plus", "tram.badge.xmark", "tram.circle", "tram.circle.fill",
            "tram.fill", "tram.fill.badge.checkmark", "tram.fill.badge.clock", "tram.fill.badge.minus",
            "tram.fill.badge.plus", "tram.fill.badge.xmark", "tram.fill.circle", "tram.fill.circle.fill",
            "tram.fill.rectangle", "tram.fill.rectangle.fill", "tram.fill.rtl", "tram.fill.slash",
            "tram.fill.slash.fill", "tram.fill.square", "tram.fill.square.fill", "tram.rectangle",
            "tram.rectangle.fill", "tram.rtl", "tram.slash", "tram.slash.fill",
            "tram.square", "tram.square.fill", "truck.box", "truck.box.fill"
        ],
        "Human": [
            "brain.head.profile", "ear", "ear.fill", "eye",
            "eye.fill", "facemask", "figure.arms.open", "figure.run",
            "figure.run.badge.checkmark", "figure.run.badge.minus", "figure.run.badge.plus", "figure.run.badge.xmark",
            "figure.run.circle", "figure.run.circle.fill", "figure.run.fill", "figure.run.rectangle",
            "figure.run.rectangle.fill", "figure.run.slash", "figure.run.slash.fill", "figure.run.square",
            "figure.run.square.fill", "figure.stand", "figure.stand.badge.checkmark", "figure.stand.badge.clock",
            "figure.stand.badge.minus", "figure.stand.badge.plus", "figure.stand.badge.xmark", "figure.stand.circle",
            "figure.stand.circle.fill", "figure.stand.fill", "figure.stand.fill.rtl", "figure.stand.rectangle",
            "figure.stand.rectangle.fill", "figure.stand.rtl", "figure.stand.slash", "figure.stand.slash.fill",
            "figure.stand.square", "figure.stand.square.fill", "figure.walk", "figure.walk.badge.checkmark",
            "figure.walk.badge.clock", "figure.walk.badge.minus", "figure.walk.badge.plus", "figure.walk.badge.xmark",
            "figure.walk.circle", "figure.walk.circle.fill", "figure.walk.fill", "figure.walk.fill.rtl",
            "figure.walk.rectangle", "figure.walk.rectangle.fill", "figure.walk.rtl", "figure.walk.slash",
            "figure.walk.slash.fill", "figure.walk.square", "figure.walk.square.fill", "figure.wave",
            "hand.raised", "hand.raised.fill", "hand.thumbsdown", "hand.thumbsdown.fill",
            "hand.thumbsup", "hand.thumbsup.fill", "hand.wave", "hand.wave.fill",
            "hands.clap", "hands.clap.fill", "person", "person.2",
            "person.2.badge.checkmark", "person.2.badge.clock", "person.2.badge.minus", "person.2.badge.plus",
            "person.2.badge.xmark", "person.2.circle", "person.2.circle.fill", "person.2.fill",
            "person.2.fill.badge.checkmark", "person.2.fill.badge.clock", "person.2.fill.badge.minus", "person.2.fill.badge.plus",
            "person.2.fill.badge.xmark", "person.2.fill.circle", "person.2.fill.circle.fill", "person.2.fill.rectangle",
            "person.2.fill.rectangle.fill", "person.2.fill.rtl", "person.2.fill.slash", "person.2.fill.slash.fill",
            "person.2.fill.square", "person.2.fill.square.fill", "person.2.rectangle", "person.2.rectangle.fill",
            "person.2.rtl", "person.2.slash", "person.2.slash.fill", "person.2.square",
            "person.2.square.fill", "person.3", "person.3.badge.checkmark", "person.3.badge.clock",
            "person.3.badge.minus", "person.3.badge.plus", "person.3.badge.xmark", "person.3.circle",
            "person.3.circle.fill", "person.3.fill", "person.3.fill.badge.checkmark", "person.3.fill.badge.clock",
            "person.3.fill.badge.minus", "person.3.fill.badge.plus", "person.3.fill.badge.xmark", "person.3.fill.circle",
            "person.3.fill.circle.fill", "person.3.fill.rectangle", "person.3.fill.rectangle.fill", "person.3.fill.rtl",
            "person.3.fill.slash", "person.3.fill.slash.fill", "person.3.fill.square", "person.3.fill.square.fill",
            "person.3.rectangle", "person.3.rectangle.fill", "person.3.rtl", "person.3.slash",
            "person.3.slash.fill", "person.3.square", "person.3.square.fill", "person.badge.checkmark",
            "person.badge.clock", "person.badge.minus", "person.badge.plus", "person.badge.plus.badge.checkmark",
            "person.badge.plus.badge.clock", "person.badge.plus.badge.minus", "person.badge.plus.badge.plus", "person.badge.plus.badge.xmark",
            "person.badge.plus.circle", "person.badge.plus.circle.fill", "person.badge.plus.fill", "person.badge.plus.fill.rtl",
            "person.badge.plus.rectangle", "person.badge.plus.rectangle.fill", "person.badge.plus.rtl", "person.badge.plus.slash",
            "person.badge.plus.slash.fill", "person.badge.plus.square", "person.badge.plus.square.fill", "person.badge.xmark",
            "person.circle", "person.circle.badge.checkmark", "person.circle.badge.clock", "person.circle.badge.minus",
            "person.circle.badge.plus", "person.circle.badge.xmark", "person.circle.fill", "person.circle.fill.rtl",
            "person.circle.rectangle", "person.circle.rectangle.fill", "person.circle.rtl", "person.circle.slash",
            "person.circle.slash.fill", "person.circle.square", "person.circle.square.fill", "person.crop.circle",
            "person.crop.circle.badge.checkmark", "person.crop.circle.badge.clock", "person.crop.circle.badge.minus", "person.crop.circle.badge.plus",
            "person.crop.circle.badge.xmark", "person.crop.circle.fill", "person.crop.circle.fill.rtl", "person.crop.circle.rectangle",
            "person.crop.circle.rectangle.fill", "person.crop.circle.rtl", "person.crop.circle.slash", "person.crop.circle.slash.fill",
            "person.crop.circle.square", "person.crop.circle.square.fill", "person.fill", "person.fill.badge.checkmark",
            "person.fill.badge.clock", "person.fill.badge.minus", "person.fill.badge.plus", "person.fill.badge.xmark",
            "person.fill.circle", "person.fill.circle.fill", "person.fill.rectangle", "person.fill.rectangle.fill",
            "person.fill.rtl", "person.fill.slash", "person.fill.slash.fill", "person.fill.square",
            "person.fill.square.fill", "person.rectangle", "person.rectangle.fill", "person.rtl",
            "person.slash", "person.slash.fill", "person.square", "person.square.fill"
        ],
        "Symbols": [
            "app", "app.badge", "app.badge.fill", "app.fill",
            "capsule", "capsule.fill", "circle", "circle.badge.checkmark",
            "circle.badge.clock", "circle.badge.minus", "circle.badge.plus", "circle.badge.xmark",
            "circle.circle", "circle.circle.fill", "circle.dashed", "circle.fill",
            "circle.fill.badge.checkmark", "circle.fill.badge.clock", "circle.fill.badge.minus", "circle.fill.badge.plus",
            "circle.fill.badge.xmark", "circle.fill.circle", "circle.fill.circle.fill", "circle.fill.rectangle",
            "circle.fill.rectangle.fill", "circle.fill.rtl", "circle.fill.slash", "circle.fill.slash.fill",
            "circle.fill.square", "circle.fill.square.fill", "circle.grid.2x1", "circle.grid.2x1.badge.checkmark",
            "circle.grid.2x1.badge.clock", "circle.grid.2x1.badge.minus", "circle.grid.2x1.badge.plus", "circle.grid.2x1.badge.xmark",
            "circle.grid.2x1.circle", "circle.grid.2x1.circle.fill", "circle.grid.2x1.fill", "circle.grid.2x1.fill.rtl",
            "circle.grid.2x1.rectangle", "circle.grid.2x1.rectangle.fill", "circle.grid.2x1.rtl", "circle.grid.2x1.slash",
            "circle.grid.2x1.slash.fill", "circle.grid.2x1.square", "circle.grid.2x1.square.fill", "circle.grid.3x3",
            "circle.grid.3x3.badge.checkmark", "circle.grid.3x3.badge.clock", "circle.grid.3x3.badge.minus", "circle.grid.3x3.badge.plus",
            "circle.grid.3x3.badge.xmark", "circle.grid.3x3.circle", "circle.grid.3x3.circle.fill", "circle.grid.3x3.fill",
            "circle.grid.3x3.fill.rtl", "circle.grid.3x3.rectangle", "circle.grid.3x3.rectangle.fill", "circle.grid.3x3.rtl",
            "circle.grid.3x3.slash", "circle.grid.3x3.slash.fill", "circle.grid.3x3.square", "circle.grid.3x3.square.fill",
            "circle.inset.filled", "circle.inset.filled.badge.checkmark", "circle.inset.filled.badge.clock", "circle.inset.filled.badge.minus",
            "circle.inset.filled.badge.plus", "circle.inset.filled.badge.xmark", "circle.inset.filled.circle", "circle.inset.filled.circle.fill",
            "circle.inset.filled.fill", "circle.inset.filled.fill.rtl", "circle.inset.filled.rectangle", "circle.inset.filled.rectangle.fill",
            "circle.inset.filled.rtl", "circle.inset.filled.slash", "circle.inset.filled.slash.fill", "circle.inset.filled.square",
            "circle.inset.filled.square.fill", "circle.rectangle", "circle.rectangle.fill", "circle.rtl",
            "circle.slash", "circle.slash.fill", "circle.square", "circle.square.fill",
            "diamond", "diamond.fill", "hexagon", "hexagon.fill",
            "octagon", "octagon.fill", "oval", "oval.fill",
            "pentagon", "pentagon.fill", "rectangle", "rectangle.fill",
            "rhombus", "rhombus.fill", "seal", "seal.fill",
            "shield", "square", "square.badge.checkmark", "square.badge.clock",
            "square.badge.minus", "square.badge.plus", "square.badge.xmark", "square.circle",
            "square.circle.fill", "square.dashed", "square.fill", "square.fill.badge.checkmark",
            "square.fill.badge.clock", "square.fill.badge.minus", "square.fill.badge.plus", "square.fill.badge.xmark",
            "square.fill.circle", "square.fill.circle.fill", "square.fill.rectangle", "square.fill.rectangle.fill",
            "square.fill.rtl", "square.fill.slash", "square.fill.slash.fill", "square.fill.square",
            "square.fill.square.fill", "square.grid.2x2", "square.grid.2x2.badge.checkmark", "square.grid.2x2.badge.clock",
            "square.grid.2x2.badge.minus", "square.grid.2x2.badge.plus", "square.grid.2x2.badge.xmark", "square.grid.2x2.circle",
            "square.grid.2x2.circle.fill", "square.grid.2x2.fill", "square.grid.2x2.fill.rtl", "square.grid.2x2.rectangle",
            "square.grid.2x2.rectangle.fill", "square.grid.2x2.rtl", "square.grid.2x2.slash", "square.grid.2x2.slash.fill",
            "square.grid.2x2.square", "square.grid.2x2.square.fill", "square.grid.3x3", "square.grid.3x3.badge.checkmark",
            "square.grid.3x3.badge.clock", "square.grid.3x3.badge.minus", "square.grid.3x3.badge.plus", "square.grid.3x3.badge.xmark",
            "square.grid.3x3.circle", "square.grid.3x3.circle.fill", "square.grid.3x3.fill", "square.grid.3x3.fill.rtl",
            "square.grid.3x3.rectangle", "square.grid.3x3.rectangle.fill", "square.grid.3x3.rtl", "square.grid.3x3.slash",
            "square.grid.3x3.slash.fill", "square.grid.3x3.square", "square.grid.3x3.square.fill", "square.rectangle",
            "square.rectangle.fill", "square.rtl", "square.slash", "square.slash.fill",
            "square.square", "square.square.fill", "triangle", "triangle.badge.checkmark",
            "triangle.badge.clock", "triangle.badge.minus", "triangle.badge.plus", "triangle.badge.xmark",
            "triangle.circle", "triangle.circle.fill", "triangle.fill", "triangle.fill.badge.checkmark",
            "triangle.fill.badge.clock", "triangle.fill.badge.minus", "triangle.fill.badge.plus", "triangle.fill.badge.xmark",
            "triangle.fill.circle", "triangle.fill.circle.fill", "triangle.fill.rectangle", "triangle.fill.rectangle.fill",
            "triangle.fill.rtl", "triangle.fill.slash", "triangle.fill.slash.fill", "triangle.fill.square",
            "triangle.fill.square.fill", "triangle.rectangle", "triangle.rectangle.fill", "triangle.rtl",
            "triangle.slash", "triangle.slash.fill", "triangle.square", "triangle.square.fill"
        ],
        "Arrows": [
            "arrow.clockwise", "arrow.clockwise.badge.checkmark", "arrow.clockwise.badge.clock", "arrow.clockwise.badge.minus",
            "arrow.clockwise.badge.plus", "arrow.clockwise.badge.xmark", "arrow.clockwise.circle", "arrow.clockwise.circle.badge.checkmark",
            "arrow.clockwise.circle.badge.clock", "arrow.clockwise.circle.badge.minus", "arrow.clockwise.circle.badge.plus", "arrow.clockwise.circle.badge.xmark",
            "arrow.clockwise.circle.fill", "arrow.clockwise.circle.fill.rtl", "arrow.clockwise.circle.rectangle", "arrow.clockwise.circle.rectangle.fill",
            "arrow.clockwise.circle.rtl", "arrow.clockwise.circle.slash", "arrow.clockwise.circle.slash.fill", "arrow.clockwise.circle.square",
            "arrow.clockwise.circle.square.fill", "arrow.clockwise.fill", "arrow.clockwise.fill.rtl", "arrow.clockwise.rectangle",
            "arrow.clockwise.rectangle.fill", "arrow.clockwise.rtl", "arrow.clockwise.slash", "arrow.clockwise.slash.fill",
            "arrow.clockwise.square", "arrow.clockwise.square.fill", "arrow.counterclockwise", "arrow.counterclockwise.badge.checkmark",
            "arrow.counterclockwise.badge.clock", "arrow.counterclockwise.badge.minus", "arrow.counterclockwise.badge.plus", "arrow.counterclockwise.badge.xmark",
            "arrow.counterclockwise.circle", "arrow.counterclockwise.circle.badge.checkmark", "arrow.counterclockwise.circle.badge.clock", "arrow.counterclockwise.circle.badge.minus",
            "arrow.counterclockwise.circle.badge.plus", "arrow.counterclockwise.circle.badge.xmark", "arrow.counterclockwise.circle.fill", "arrow.counterclockwise.circle.fill.rtl",
            "arrow.counterclockwise.circle.rectangle", "arrow.counterclockwise.circle.rectangle.fill", "arrow.counterclockwise.circle.rtl", "arrow.counterclockwise.circle.slash",
            "arrow.counterclockwise.circle.slash.fill", "arrow.counterclockwise.circle.square", "arrow.counterclockwise.circle.square.fill", "arrow.counterclockwise.fill",
            "arrow.counterclockwise.fill.rtl", "arrow.counterclockwise.rectangle", "arrow.counterclockwise.rectangle.fill", "arrow.counterclockwise.rtl",
            "arrow.counterclockwise.slash", "arrow.counterclockwise.slash.fill", "arrow.counterclockwise.square", "arrow.counterclockwise.square.fill",
            "arrow.down", "arrow.down.badge.checkmark", "arrow.down.badge.clock", "arrow.down.badge.minus",
            "arrow.down.badge.plus", "arrow.down.badge.xmark", "arrow.down.circle", "arrow.down.circle.badge.checkmark",
            "arrow.down.circle.badge.clock", "arrow.down.circle.badge.minus", "arrow.down.circle.badge.plus", "arrow.down.circle.badge.xmark",
            "arrow.down.circle.fill", "arrow.down.circle.fill.rtl", "arrow.down.circle.rectangle", "arrow.down.circle.rectangle.fill",
            "arrow.down.circle.rtl", "arrow.down.circle.slash", "arrow.down.circle.slash.fill", "arrow.down.circle.square",
            "arrow.down.circle.square.fill", "arrow.down.fill", "arrow.down.fill.rtl", "arrow.down.rectangle",
            "arrow.down.rectangle.fill", "arrow.down.rtl", "arrow.down.slash", "arrow.down.slash.fill",
            "arrow.down.square", "arrow.down.square.fill", "arrow.down.to.line", "arrow.left",
            "arrow.left.arrow.right", "arrow.left.badge.checkmark", "arrow.left.badge.clock", "arrow.left.badge.minus",
            "arrow.left.badge.plus", "arrow.left.badge.xmark", "arrow.left.circle", "arrow.left.circle.badge.checkmark",
            "arrow.left.circle.badge.clock", "arrow.left.circle.badge.minus", "arrow.left.circle.badge.plus", "arrow.left.circle.badge.xmark",
            "arrow.left.circle.fill", "arrow.left.circle.fill.rtl", "arrow.left.circle.rectangle", "arrow.left.circle.rectangle.fill",
            "arrow.left.circle.rtl", "arrow.left.circle.slash", "arrow.left.circle.slash.fill", "arrow.left.circle.square",
            "arrow.left.circle.square.fill", "arrow.left.fill", "arrow.left.fill.rtl", "arrow.left.rectangle",
            "arrow.left.rectangle.fill", "arrow.left.rtl", "arrow.left.slash", "arrow.left.slash.fill",
            "arrow.left.square", "arrow.left.square.fill", "arrow.right", "arrow.right.badge.checkmark",
            "arrow.right.badge.clock", "arrow.right.badge.minus", "arrow.right.badge.plus", "arrow.right.badge.xmark",
            "arrow.right.circle", "arrow.right.circle.badge.checkmark", "arrow.right.circle.badge.clock", "arrow.right.circle.badge.minus",
            "arrow.right.circle.badge.plus", "arrow.right.circle.badge.xmark", "arrow.right.circle.fill", "arrow.right.circle.fill.rtl",
            "arrow.right.circle.rectangle", "arrow.right.circle.rectangle.fill", "arrow.right.circle.rtl", "arrow.right.circle.slash",
            "arrow.right.circle.slash.fill", "arrow.right.circle.square", "arrow.right.circle.square.fill", "arrow.right.fill",
            "arrow.right.fill.rtl", "arrow.right.rectangle", "arrow.right.rectangle.fill", "arrow.right.rtl",
            "arrow.right.slash", "arrow.right.slash.fill", "arrow.right.square", "arrow.right.square.fill",
            "arrow.triangle.2.circlepath", "arrow.turn.up.right", "arrow.up", "arrow.up.arrow.down",
            "arrow.up.arrow.down.circle", "arrow.up.arrow.down.circle.fill", "arrow.up.arrow.down.fill", "arrow.up.arrow.down.rectangle",
            "arrow.up.arrow.down.rectangle.fill", "arrow.up.arrow.down.slash", "arrow.up.arrow.down.square", "arrow.up.arrow.down.square.fill",
            "arrow.up.badge.checkmark", "arrow.up.badge.clock", "arrow.up.badge.minus", "arrow.up.badge.plus",
            "arrow.up.badge.xmark", "arrow.up.circle", "arrow.up.circle.badge.checkmark", "arrow.up.circle.badge.clock",
            "arrow.up.circle.badge.minus", "arrow.up.circle.badge.plus", "arrow.up.circle.badge.xmark", "arrow.up.circle.fill",
            "arrow.up.circle.fill.rtl", "arrow.up.circle.rectangle", "arrow.up.circle.rectangle.fill", "arrow.up.circle.rtl",
            "arrow.up.circle.slash", "arrow.up.circle.slash.fill", "arrow.up.circle.square", "arrow.up.circle.square.fill",
            "arrow.up.fill", "arrow.up.fill.rtl", "arrow.up.rectangle", "arrow.up.rectangle.fill",
            "arrow.up.rtl", "arrow.up.slash", "arrow.up.slash.fill", "arrow.up.square",
            "arrow.up.square.fill", "arrow.up.to.line", "chevron.down", "chevron.down.circle",
            "chevron.left", "chevron.right", "chevron.up", "chevron.up.circle"
        ],
        "Math": [
            "divide", "divide.badge.checkmark", "divide.badge.clock", "divide.badge.minus",
            "divide.badge.plus", "divide.badge.xmark", "divide.circle", "divide.circle.badge.checkmark",
            "divide.circle.badge.clock", "divide.circle.badge.minus", "divide.circle.badge.plus", "divide.circle.badge.xmark",
            "divide.circle.fill", "divide.circle.fill.rtl", "divide.circle.rectangle", "divide.circle.rectangle.fill",
            "divide.circle.rtl", "divide.circle.slash", "divide.circle.slash.fill", "divide.circle.square",
            "divide.circle.square.fill", "divide.fill", "divide.fill.rtl", "divide.rectangle",
            "divide.rectangle.fill", "divide.rtl", "divide.slash", "divide.slash.fill",
            "divide.square", "divide.square.badge.checkmark", "divide.square.badge.clock", "divide.square.badge.minus",
            "divide.square.badge.plus", "divide.square.badge.xmark", "divide.square.circle", "divide.square.circle.fill",
            "divide.square.fill", "divide.square.fill.rtl", "divide.square.rectangle", "divide.square.rectangle.fill",
            "divide.square.rtl", "divide.square.slash", "divide.square.slash.fill", "divide.square.square",
            "divide.square.square.fill", "equal", "equal.circle", "equal.circle.fill",
            "equal.fill", "equal.rectangle", "equal.rectangle.fill", "equal.slash",
            "equal.square", "equal.square.fill", "function", "greaterthan",
            "infinity", "lessthan", "minus", "minus.badge.checkmark",
            "minus.badge.clock", "minus.badge.minus", "minus.badge.plus", "minus.badge.xmark",
            "minus.circle", "minus.circle.badge.checkmark", "minus.circle.badge.clock", "minus.circle.badge.minus",
            "minus.circle.badge.plus", "minus.circle.badge.xmark", "minus.circle.fill", "minus.circle.fill.rtl",
            "minus.circle.rectangle", "minus.circle.rectangle.fill", "minus.circle.rtl", "minus.circle.slash",
            "minus.circle.slash.fill", "minus.circle.square", "minus.circle.square.fill", "minus.fill",
            "minus.fill.rtl", "minus.rectangle", "minus.rectangle.fill", "minus.rtl",
            "minus.slash", "minus.slash.fill", "minus.square", "minus.square.badge.checkmark",
            "minus.square.badge.clock", "minus.square.badge.minus", "minus.square.badge.plus", "minus.square.badge.xmark",
            "minus.square.circle", "minus.square.circle.fill", "minus.square.fill", "minus.square.fill.rtl",
            "minus.square.rectangle", "minus.square.rectangle.fill", "minus.square.rtl", "minus.square.slash",
            "minus.square.slash.fill", "minus.square.square", "minus.square.square.fill", "multiply",
            "multiply.badge.checkmark", "multiply.badge.clock", "multiply.badge.minus", "multiply.badge.plus",
            "multiply.badge.xmark", "multiply.circle", "multiply.circle.badge.checkmark", "multiply.circle.badge.clock",
            "multiply.circle.badge.minus", "multiply.circle.badge.plus", "multiply.circle.badge.xmark", "multiply.circle.fill",
            "multiply.circle.fill.rtl", "multiply.circle.rectangle", "multiply.circle.rectangle.fill", "multiply.circle.rtl",
            "multiply.circle.slash", "multiply.circle.slash.fill", "multiply.circle.square", "multiply.circle.square.fill",
            "multiply.fill", "multiply.fill.rtl", "multiply.rectangle", "multiply.rectangle.fill",
            "multiply.rtl", "multiply.slash", "multiply.slash.fill", "multiply.square",
            "multiply.square.badge.checkmark", "multiply.square.badge.clock", "multiply.square.badge.minus", "multiply.square.badge.plus",
            "multiply.square.badge.xmark", "multiply.square.circle", "multiply.square.circle.fill", "multiply.square.fill",
            "multiply.square.fill.rtl", "multiply.square.rectangle", "multiply.square.rectangle.fill", "multiply.square.rtl",
            "multiply.square.slash", "multiply.square.slash.fill", "multiply.square.square", "multiply.square.square.fill",
            "number", "percent", "plus", "plus.badge.checkmark",
            "plus.badge.clock", "plus.badge.minus", "plus.badge.plus", "plus.badge.xmark",
            "plus.circle", "plus.circle.badge.checkmark", "plus.circle.badge.clock", "plus.circle.badge.minus",
            "plus.circle.badge.plus", "plus.circle.badge.xmark", "plus.circle.fill", "plus.circle.fill.rtl",
            "plus.circle.rectangle", "plus.circle.rectangle.fill", "plus.circle.rtl", "plus.circle.slash",
            "plus.circle.slash.fill", "plus.circle.square", "plus.circle.square.fill", "plus.fill",
            "plus.fill.rtl", "plus.rectangle", "plus.rectangle.fill", "plus.rtl",
            "plus.slash", "plus.slash.fill", "plus.square", "plus.square.badge.checkmark",
            "plus.square.badge.clock", "plus.square.badge.minus", "plus.square.badge.plus", "plus.square.badge.xmark",
            "plus.square.circle", "plus.square.circle.fill", "plus.square.fill", "plus.square.fill.rtl",
            "plus.square.rectangle", "plus.square.rectangle.fill", "plus.square.rtl", "plus.square.slash",
            "plus.square.slash.fill", "plus.square.square", "plus.square.square.fill", "plusminus",
            "plusminus.circle", "sum", "textformat.123", "x.squareroot"
        ],
        "Text Formatting": [
            "123", "abc", "bold", "bold.badge.checkmark",
            "bold.badge.clock", "bold.badge.minus", "bold.badge.plus", "bold.badge.xmark",
            "bold.circle", "bold.circle.fill", "bold.fill", "bold.fill.rtl",
            "bold.rectangle", "bold.rectangle.fill", "bold.rtl", "bold.slash",
            "bold.slash.fill", "bold.square", "bold.square.fill", "character",
            "character.badge.checkmark", "character.badge.clock", "character.badge.minus", "character.badge.plus",
            "character.badge.xmark", "character.circle", "character.circle.fill", "character.fill",
            "character.fill.rtl", "character.rectangle", "character.rectangle.fill", "character.rtl",
            "character.slash", "character.slash.fill", "character.square", "character.square.fill",
            "character.textbox", "character.textbox.badge.checkmark", "character.textbox.badge.clock", "character.textbox.badge.minus",
            "character.textbox.badge.plus", "character.textbox.badge.xmark", "character.textbox.circle", "character.textbox.circle.fill",
            "character.textbox.fill", "character.textbox.fill.rtl", "character.textbox.rectangle", "character.textbox.rectangle.fill",
            "character.textbox.rtl", "character.textbox.slash", "character.textbox.slash.fill", "character.textbox.square",
            "character.textbox.square.fill", "italic", "italic.badge.checkmark", "italic.badge.clock",
            "italic.badge.minus", "italic.badge.plus", "italic.badge.xmark", "italic.circle",
            "italic.circle.fill", "italic.fill", "italic.fill.rtl", "italic.rectangle",
            "italic.rectangle.fill", "italic.rtl", "italic.slash", "italic.slash.fill",
            "italic.square", "italic.square.fill", "list.bullet", "list.number",
            "strikethrough", "strikethrough.badge.checkmark", "strikethrough.badge.clock", "strikethrough.badge.minus",
            "strikethrough.badge.plus", "strikethrough.badge.xmark", "strikethrough.circle", "strikethrough.circle.fill",
            "strikethrough.fill", "strikethrough.fill.rtl", "strikethrough.rectangle", "strikethrough.rectangle.fill",
            "strikethrough.rtl", "strikethrough.slash", "strikethrough.slash.fill", "strikethrough.square",
            "strikethrough.square.fill", "text.aligncenter", "text.alignleft", "text.alignright",
            "text.badge.checkmark", "text.badge.plus", "text.badge.xmark", "text.justify",
            "text.quote", "text.red redaction", "textformat", "textformat.123",
            "textformat.123.badge.checkmark", "textformat.123.badge.clock", "textformat.123.badge.minus", "textformat.123.badge.plus",
            "textformat.123.badge.xmark", "textformat.123.circle", "textformat.123.circle.fill", "textformat.123.fill",
            "textformat.123.fill.rtl", "textformat.123.rectangle", "textformat.123.rectangle.fill", "textformat.123.rtl",
            "textformat.123.slash", "textformat.123.slash.fill", "textformat.123.square", "textformat.123.square.fill",
            "textformat.abc", "textformat.abc.badge.checkmark", "textformat.abc.badge.clock", "textformat.abc.badge.minus",
            "textformat.abc.badge.plus", "textformat.abc.badge.xmark", "textformat.abc.circle", "textformat.abc.circle.fill",
            "textformat.abc.fill", "textformat.abc.fill.rtl", "textformat.abc.rectangle", "textformat.abc.rectangle.fill",
            "textformat.abc.rtl", "textformat.abc.slash", "textformat.abc.slash.fill", "textformat.abc.square",
            "textformat.abc.square.fill", "textformat.alt", "textformat.alt.badge.checkmark", "textformat.alt.badge.clock",
            "textformat.alt.badge.minus", "textformat.alt.badge.plus", "textformat.alt.badge.xmark", "textformat.alt.circle",
            "textformat.alt.circle.fill", "textformat.alt.fill", "textformat.alt.fill.rtl", "textformat.alt.rectangle",
            "textformat.alt.rectangle.fill", "textformat.alt.rtl", "textformat.alt.slash", "textformat.alt.slash.fill",
            "textformat.alt.square", "textformat.alt.square.fill", "textformat.badge.checkmark", "textformat.badge.clock",
            "textformat.badge.minus", "textformat.badge.plus", "textformat.badge.xmark", "textformat.circle",
            "textformat.circle.fill", "textformat.fill", "textformat.fill.rtl", "textformat.rectangle",
            "textformat.rectangle.fill", "textformat.rtl", "textformat.size", "textformat.size.badge.checkmark",
            "textformat.size.badge.clock", "textformat.size.badge.minus", "textformat.size.badge.plus", "textformat.size.badge.xmark",
            "textformat.size.circle", "textformat.size.circle.fill", "textformat.size.fill", "textformat.size.fill.rtl",
            "textformat.size.rectangle", "textformat.size.rectangle.fill", "textformat.size.rtl", "textformat.size.slash",
            "textformat.size.slash.fill", "textformat.size.square", "textformat.size.square.fill", "textformat.slash",
            "textformat.slash.fill", "textformat.square", "textformat.square.fill", "underline",
            "underline.badge.checkmark", "underline.badge.clock", "underline.badge.minus", "underline.badge.plus",
            "underline.badge.xmark", "underline.circle", "underline.circle.fill", "underline.fill",
            "underline.fill.rtl", "underline.rectangle", "underline.rectangle.fill", "underline.rtl",
            "underline.slash", "underline.slash.fill", "underline.square", "underline.square.fill"
        ],
        ]
    
    var filteredSymbols: [String] {
        var symbols: [String] = []
        
        if viewModel.selectedCategory == "All" {
            symbols = symbolsByCategory.values.flatMap { $0 }
        } else {
            symbols = symbolsByCategory[viewModel.selectedCategory] ?? []
        }
        
        if !viewModel.searchText.isEmpty {
            // Search in all symbols, not just the current category
            let allSymbols = symbolsByCategory.values.flatMap { $0 }
            symbols = allSymbols.filter { 
                $0.lowercased().contains(viewModel.searchText.lowercased()) 
            }
        }
        
        return Array(Set(symbols)).sorted()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced Search Bar with Custom Symbol Input
                searchSection
                
                // Category Picker
                categoryPicker
                
                // Quick Access Tabs
                quickAccessTabs
                
                // Symbol Grid
                ScrollView {
                    if viewModel.selectedCategory == "Recents" && !viewModel.recentSymbols.isEmpty {
                        symbolGrid(for: viewModel.recentSymbols)
                    } else if viewModel.selectedCategory == "Favorites" && !viewModel.favoriteSymbols.isEmpty {
                        symbolGrid(for: viewModel.favoriteSymbols)
                    } else if filteredSymbols.isEmpty && !viewModel.searchText.isEmpty {
                        noResultsView
                    } else {
                        symbolGrid(for: filteredSymbols)
                    }
                }
                
                // Customization Panel
                if showCustomizationPanel {
                    customizationPanel
                }
            }
            .navigationTitle("SF Symbols")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showCustomizationPanel.toggle()
                        }
                    } label: {
                        Image(systemName: showCustomizationPanel ? "slider.horizontal.3" : "slider.horizontal.3")
                            .foregroundColor(showCustomizationPanel ? .accentColor : .primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Search Section
    private var searchSection: some View {
        VStack(spacing: 12) {
            // Main Search Bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("Search SF Symbols", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            
            // Custom Symbol Input
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                
                TextField("Search Any SF Symbol", text: $customSymbolName)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                if !customSymbolName.isEmpty {
                    Button {
                        tryCustomSymbol()
                    } label: {
                        Text("Try")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.accentColor))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedCategory = category
                            HapticsManager.shared.softImpact()
                        }
                    } label: {
                        Text(category)
                            .font(.subheadline.weight(viewModel.selectedCategory == category ? .semibold : .regular))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedCategory == category ? 
                                          Color.accentColor : 
                                          Color(UIColor.tertiarySystemGroupedBackground))
                            )
                            .foregroundStyle(viewModel.selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Quick Access Tabs
    @ViewBuilder
    private var quickAccessTabs: some View {
        if !viewModel.recentSymbols.isEmpty || !viewModel.favoriteSymbols.isEmpty {
            HStack(spacing: 0) {
                if !viewModel.recentSymbols.isEmpty {
                    quickAccessTab(title: "Recents", icon: "clock.fill", category: "Recents")
                }
                
                if !viewModel.favoriteSymbols.isEmpty {
                    quickAccessTab(title: "Favorites", icon: "heart.fill", category: "Favorites")
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    private func quickAccessTab(title: String, icon: String, category: String) -> some View {
        Button {
            withAnimation {
                viewModel.selectedCategory = category
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline)
            }
            .foregroundColor(viewModel.selectedCategory == category ? .accentColor : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Rectangle()
                    .fill(viewModel.selectedCategory == category ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(viewModel.selectedCategory == category ? Color.accentColor : Color.clear)
                    .frame(height: 2)
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Symbols Found")
                .font(.headline)
            
            Text("Try a different search term or enter the exact SF Symbol name above")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    customSymbolName = viewModel.searchText
                    tryCustomSymbol()
                } label: {
                    Label("Try as custom symbol", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
    }
    
    // MARK: - Customization Panel
    private var customizationPanel: some View {
        VStack(spacing: 16) {
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("CUSTOMIZATION")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                
                // Preview
                HStack {
                    Text("Preview")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: viewModel.sfSymbol)
                        .font(.system(size: selectedSize, weight: selectedWeight))
                        .foregroundStyle(previewColor)
                        .frame(width: 50, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(UIColor.tertiarySystemGroupedBackground))
                        )
                }
                
                // Size Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Size")
                            .font(.subheadline)
                        Spacer()
                        Text("\(Int(selectedSize)) pt")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $selectedSize, in: 12...48, step: 2)
                        .tint(.accentColor)
                }
                
                // Weight Picker
                HStack {
                    Text("Weight")
                        .font(.subheadline)
                    Spacer()
                    Picker("", selection: $selectedWeight) {
                        Text("Light").tag(Font.Weight.light)
                        Text("Regular").tag(Font.Weight.regular)
                        Text("Medium").tag(Font.Weight.medium)
                        Text("Semibold").tag(Font.Weight.semibold)
                        Text("Bold").tag(Font.Weight.bold)
                    }
                    .pickerStyle(.menu)
                }
                
                // Color Picker
                HStack {
                    Text("Color")
                        .font(.subheadline)
                    Spacer()
                    ColorPicker("", selection: $previewColor)
                        .labelsHidden()
                }
                
                // Apply Button
                Button {
                    applyCustomization()
                } label: {
                    Text("Apply Customization")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
    }
    
    // MARK: - Symbol Grid
    @ViewBuilder
    private func symbolGrid(for symbols: [String]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 75))], spacing: 16) {
            ForEach(symbols, id: \.self) { symbol in
                symbolCell(symbol: symbol)
            }
        }
        .padding(16)
    }
    
    @ViewBuilder
    private func symbolCell(symbol: String) -> some View {
        let isSelected = viewModel.sfSymbol == symbol
        
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectSymbol(symbol)
                        HapticsManager.shared.softImpact()
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: symbol)
                            .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? Color(hex: viewModel.colorHex) : .secondary)
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color(UIColor.tertiarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                        
                        Text(formatSymbolName(symbol))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(.plain)
                
                // Favorite button
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.toggleFavorite(symbol)
                        HapticsManager.shared.softImpact()
                    }
                } label: {
                    Image(systemName: viewModel.isFavorite(symbol) ? "heart.fill" : "heart")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(viewModel.isFavorite(symbol) ? .red : .secondary)
                        .padding(5)
                        .background(Circle().fill(.ultraThinMaterial))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
            }
        }
    }
    
    // MARK: - Helper Functions
    private func formatSymbolName(_ name: String) -> String {
        let parts = name.split(separator: ".")
        if let first = parts.first {
            return String(first).capitalized
        }
        return name
    }
    
    private func tryCustomSymbol() {
        guard !customSymbolName.isEmpty else { return }
        
        // Check if the symbol exists by trying to create an image
        let testImage = UIImage(systemName: customSymbolName)
        if testImage != nil {
            viewModel.selectSymbol(customSymbolName)
            customSymbolName = ""
            HapticsManager.shared.success()
        } else {
            HapticsManager.shared.error()
        }
    }
    
    private func applyCustomization() {
        viewModel.iconSize = selectedSize
        viewModel.colorHex = previewColor.toHex() ?? "#007AFF"
        
        switch selectedWeight {
        case .ultraLight: viewModel.iconWeight = "ultralight"
        case .thin: viewModel.iconWeight = "thin"
        case .light: viewModel.iconWeight = "light"
        case .regular: viewModel.iconWeight = "regular"
        case .medium: viewModel.iconWeight = "medium"
        case .semibold: viewModel.iconWeight = "semibold"
        case .bold: viewModel.iconWeight = "bold"
        case .heavy: viewModel.iconWeight = "heavy"
        case .black: viewModel.iconWeight = "black"
        default: viewModel.iconWeight = "regular"
        }
        
        HapticsManager.shared.success()
        withAnimation {
            showCustomizationPanel = false
        }
    }
}
