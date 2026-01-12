// This logic checks to see if the app has any added .dylibs, if it does, it blcoks the navigation making the app unusable.

import Foundation
import SwiftUI

/// Utility to detect .dylib files in the app bundle
class DylibDetector {
    static let shared = DylibDetector()

    private init() {}

    /// Scans the app bundle for any .dylib files
    /// - Returns: Array of detected .dylib file paths
    func scanForDylibs() -> [String] {
        var dylibPaths: [String] = []

        guard let bundlePath = Bundle.main.bundlePath as String? else {
            return dylibPaths
        }

        // Scan main bundle
        dylibPaths.append(contentsOf: scanDirectory(at: bundlePath))

        // Scan Frameworks directory specifically
        let frameworksPath = (bundlePath as NSString).appendingPathComponent("Frameworks")
        if FileManager.default.fileExists(atPath: frameworksPath) {
            dylibPaths.append(contentsOf: scanDirectory(at: frameworksPath))
        }

        return dylibPaths
    }

    /// Recursively scans a directory for .dylib files
    private func scanDirectory(at path: String) -> [String] {
        var dylibPaths: [String] = []
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(atPath: path) else {
            return dylibPaths
        }

        for case let file as String in enumerator {
            if file.hasSuffix(".dylib") {
                let fullPath = (path as NSString).appendingPathComponent(file)
                dylibPaths.append(fullPath)
            }
        }

        return dylibPaths
    }

    /// Checks if any .dylib files exist in the bundle
    /// - Returns: true if .dylib files are detected
    func hasDylibs() -> Bool {
        return !scanForDylibs().isEmpty
    }
}

/// Full-screen unavailable view shown when .dylib files are detected
struct DylibBlockerView: View {
    var body: some View {
        ZStack {
            // Background
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red.opacity(0.2), Color.red.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red, Color.red.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .padding(.top, 60)

                VStack(spacing: 16) {
                    Text("Dynamic Libraries Detected")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text("Sorry but you may not add any .dylib files to this app. Please resign the app without any additional frameworks to proceed.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(4)
                }

                Spacer()

                // Non-dismissible OK button
                Button {
                    // This button intentionally does nothing
                    // User must relaunch without dylibs
                    HapticsManager.shared.error()
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                        Text("OK")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.red.opacity(0.4), radius: 12, x: 0, y: 6)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .interactiveDismissDisabled(true)
    }
}

#Preview {
    DylibBlockerView()
}
