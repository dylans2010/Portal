// created by dylan, this is a utility file for getting device information to display on the Device Information (UDID and device identifier)
// from HomeView.swift

import UIKit
import Darwin

extension UIDevice {
    /// Returns the model name instead of identifier
    var humanReadableModelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        switch identifier {
        // iPhone 17
        case "iPhone18,1": return "iPhone 17 Pro"
        case "iPhone18,2": return "iPhone 17 Pro Max"
        case "iPhone18,3": return "iPhone 17"
        case "iPhone18,4": return "iPhone Air"
            
        // iPhone 16
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,5": return "iPhone 16e"

        // iPhone 15
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"

        // iPhone 14
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"

        // iPhone 13
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"

        // iPhone 12
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"

        // iPhone 11
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"

        // iPhone XS / XR
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone11,8": return "iPhone XR"

        // iPhone X / 8
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"

        // iPhone SE
        case "iPhone8,4": return "iPhone SE (1st generation)"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone14,6": return "iPhone SE (3rd generation)"

        // iPads
        case "iPad11,6", "iPad11,7": return "iPad (8th generation)"
        case "iPad12,1", "iPad12,2": return "iPad (9th generation)"
        case "iPad13,18", "iPad13,19": return "iPad (10th generation)"
        case "iPad13,1", "iPad13,2": return "iPad Air (4th generation)"
        case "iPad13,16", "iPad13,17": return "iPad Air (5th generation)"
        case "iPad14,1", "iPad14,2": return "iPad mini (6th generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (3rd generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (5th generation)"
        case "iPad14,3", "iPad14,4": return "iPad Pro 11-inch (4th generation)"
        case "iPad14,5", "iPad14,6": return "iPad Pro 12.9-inch (6th generation)"

        // Simulators
        case "i386", "x86_64", "arm64": return "Simulator (\(identifier))"

        default: return identifier
        }
    }

    func grabUDID() -> String {
        getDeviceIdentifier().id
    }

    struct DeviceIdentifier {
        let id: String
        let isRealUDID: Bool
        var label: String { isRealUDID ? "UDID" : "Device ID" }
    }

    func getDeviceIdentifier() -> DeviceIdentifier {
    
        if let udid = grabUDIDFromProvisioningProfile() {
            return DeviceIdentifier(id: udid, isRealUDID: true)
        }

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let pairingFileURL = documentsURL.appendingPathComponent("pairingFile.plist")
        if FileManager.default.fileExists(atPath: pairingFileURL.path) {
            if let dict = NSDictionary(contentsOf: pairingFileURL) as? [String: Any] {

                let keys = ["UDID", "DeviceUDID", "UniqueDeviceID"]
                for key in keys {
                    if let udid = dict[key] as? String {
                        return DeviceIdentifier(id: udid, isRealUDID: true)
                    }
                }
            }
        }

        let fallbackID = identifierForVendor?.uuidString ?? "Unknown"
        return DeviceIdentifier(id: fallbackID, isRealUDID: false)
    }

    func grabUDIDFromProvisioningProfile() -> String? {
        guard let path = Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            if let xmlStart = data.range(of: Data("<?xml".utf8)),
               let plistEnd = data.range(of: Data("</plist>".utf8)) {
                let xmlData = data.subdata(in: xmlStart.lowerBound..<plistEnd.upperBound)

                if let plist = try PropertyListSerialization.propertyList(from: xmlData, format: nil) as? [String: Any] {
                    if let devices = plist["ProvisionedDevices"] as? [String], !devices.isEmpty {
                        return devices.first
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
