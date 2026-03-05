import Foundation

struct CapabilityInfo: Identifiable, Equatable {
    var id: String { key }
    let key: String
    let name: String
    let icon: String
}

enum CapabilityMapper {
    static func getInfo(for key: String) -> CapabilityInfo {
        switch key.lowercased() {
        case "armv7":
            return CapabilityInfo(key: key, name: "ARMv7", icon: "cpu")
        case "armv7s":
            return CapabilityInfo(key: key, name: "ARMv7s", icon: "cpu")
        case "arm64":
            return CapabilityInfo(key: key, name: "ARM64", icon: "cpu.fill")
        case "arm64e":
            return CapabilityInfo(key: key, name: "ARM64e", icon: "cpu.fill")
        case "gps":
            return CapabilityInfo(key: key, name: "GPS", icon: "location.fill")
        case "location-services":
            return CapabilityInfo(key: key, name: "Location Services", icon: "location")
        case "magnetic-compass":
            return CapabilityInfo(key: key, name: "Magnetometer", icon: "safari")
        case "magnetometer":
            return CapabilityInfo(key: key, name: "Magnetometer", icon: "safari")
        case "accelerometer":
            return CapabilityInfo(key: key, name: "Accelerometer", icon: "gyroscope")
        case "gyroscope":
            return CapabilityInfo(key: key, name: "Gyroscope", icon: "gyroscope")
        case "wifi":
            return CapabilityInfo(key: key, name: "Wi-Fi", icon: "wifi")
        case "front-facing-camera":
            return CapabilityInfo(key: key, name: "Front Camera", icon: "camera")
        case "front-camera":
            return CapabilityInfo(key: key, name: "Front Camera", icon: "camera")
        case "rear-facing-camera":
            return CapabilityInfo(key: key, name: "Rear Camera", icon: "camera.fill")
        case "video-camera":
            return CapabilityInfo(key: key, name: "Video Camera", icon: "video")
        case "autofocus-camera":
            return CapabilityInfo(key: key, name: "Autofocus", icon: "camera.viewfinder")
        case "auto-focus-camera":
            return CapabilityInfo(key: key, name: "Autofocus", icon: "camera.viewfinder")
        case "still-camera":
            return CapabilityInfo(key: key, name: "Still Camera", icon: "photo")
        case "camera-flash":
            return CapabilityInfo(key: key, name: "Camera Flash", icon: "bolt.fill")
        case "camera":
            return CapabilityInfo(key: key, name: "Camera", icon: "camera.fill")
        case "telephony":
            return CapabilityInfo(key: key, name: "Telephony", icon: "phone.fill")
        case "sms":
            return CapabilityInfo(key: key, name: "SMS", icon: "message.fill")
        case "bluetooth-le":
            return CapabilityInfo(key: key, name: "Bluetooth LE", icon: "bolt.bluetooth.fill")
        case "nfc":
            return CapabilityInfo(key: key, name: "NFC", icon: "wave.3.right")
        case "nfc-tag-reading":
            return CapabilityInfo(key: key, name: "NFC Tag Reading", icon: "wave.3.right")
        case "gamekit":
            return CapabilityInfo(key: key, name: "GameKit", icon: "gamecontroller")
        case "microphone":
            return CapabilityInfo(key: key, name: "Microphone", icon: "mic.fill")
        case "healthkit":
            return CapabilityInfo(key: key, name: "HealthKit", icon: "heart.fill")
        case "homekit":
            return CapabilityInfo(key: key, name: "HomeKit", icon: "house.fill")
        case "metal":
            return CapabilityInfo(key: key, name: "Metal", icon: "sparkles")
        case "arkit":
            return CapabilityInfo(key: key, name: "ARKit", icon: "arkit")
        case "peer-to-peer":
            return CapabilityInfo(key: key, name: "Peer-to-Peer", icon: "personalhotspot")
        case "inter-app-audio":
            return CapabilityInfo(key: key, name: "Inter-App Audio", icon: "waveform")
        case "opengles-1":
            return CapabilityInfo(key: key, name: "OpenGL ES 1.1", icon: "square.stack.3d.down.right")
        case "opengles-2":
            return CapabilityInfo(key: key, name: "OpenGL ES 2.0", icon: "square.stack.3d.down.right.fill")
        case "opengles-3":
            return CapabilityInfo(key: key, name: "OpenGL ES 3.0", icon: "square.stack.3d.up.fill")
        case "iphone-performance-gaming-tier":
            return CapabilityInfo(key: key, name: "Gaming Tier", icon: "speedometer")
        case "iphone-ipad-minimum-performance-a12":
            return CapabilityInfo(key: key, name: "A12 Performance", icon: "cpu.fill")
        case "ipad-minimum-performance-m1":
            return CapabilityInfo(key: key, name: "M1 Performance", icon: "cpu.fill")
        case "apple-pay":
            return CapabilityInfo(key: key, name: "Apple Pay", icon: "creditcard.fill")
        case "carplay":
            return CapabilityInfo(key: key, name: "CarPlay", icon: "car.fill")
        case "classkit":
            return CapabilityInfo(key: key, name: "ClassKit", icon: "book.fill")
        case "coreml":
            return CapabilityInfo(key: key, name: "CoreML", icon: "brain.head.profile")
        case "siri":
            return CapabilityInfo(key: key, name: "Siri", icon: "waveform.circle.fill")
        case "wallet":
            return CapabilityInfo(key: key, name: "Wallet", icon: "wallet.pass.fill")
        case "network-extensions":
            return CapabilityInfo(key: key, name: "Network Extensions", icon: "network")
        case "personal-vpn":
            return CapabilityInfo(key: key, name: "Personal VPN", icon: "lock.shield.fill")
        case "data-protection":
            return CapabilityInfo(key: key, name: "Data Protection", icon: "lock.fill")
        case "background-modes":
            return CapabilityInfo(key: key, name: "Background Modes", icon: "clock.arrow.circlepath")
        case "associated-domains":
            return CapabilityInfo(key: key, name: "Associated Domains", icon: "link")
        case "app-groups":
            return CapabilityInfo(key: key, name: "App Groups", icon: "person.2.fill")
        case "icloud":
            return CapabilityInfo(key: key, name: "iCloud", icon: "cloud.fill")
        case "in-app-purchase":
            return CapabilityInfo(key: key, name: "In-App Purchase", icon: "cart.fill")
        case "maps":
            return CapabilityInfo(key: key, name: "Maps", icon: "map.fill")
        case "haptics":
            return CapabilityInfo(key: key, name: "Haptics", icon: "waveform")
        case "lidar":
            return CapabilityInfo(key: key, name: "LiDAR", icon: "viewfinder.circle.fill")
        case "true-depth-camera":
            return CapabilityInfo(key: key, name: "TrueDepth Camera", icon: "faceid")
        case "biometrics":
            return CapabilityInfo(key: key, name: "Biometrics", icon: "faceid")
        case "faceid":
            return CapabilityInfo(key: key, name: "FaceID", icon: "faceid")
        case "touchid":
            return CapabilityInfo(key: key, name: "TouchID", icon: "touchid")
        case "graphics-validation":
            return CapabilityInfo(key: key, name: "Graphics Validation", icon: "checkmark.shield.fill")
        case "camera-intrinsic-matrix":
            return CapabilityInfo(key: key, name: "Camera Matrix", icon: "grid.circle")
        case "video-conferencing":
            return CapabilityInfo(key: key, name: "Video Conferencing", icon: "video.fill")
        case "on-demand-resources":
            return CapabilityInfo(key: key, name: "On-Demand Resources", icon: "arrow.down.circle.fill")
        case "tv-services":
            return CapabilityInfo(key: key, name: "TV Services", icon: "tv.fill")
        case "game-controllers":
            return CapabilityInfo(key: key, name: "Game Controllers", icon: "gamecontroller.fill")
        case "extended-virtual-addressing":
            return CapabilityInfo(key: key, name: "Memory Addressing", icon: "memorychip")
        case "family-controls":
            return CapabilityInfo(key: key, name: "Family Controls", icon: "person.2.circle.fill")
        default:
            return CapabilityInfo(key: key, name: key, icon: "questionmark.circle")
        }
    }
}
