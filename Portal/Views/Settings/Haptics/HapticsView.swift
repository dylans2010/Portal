import SwiftUI
import NimbleViews

// MARK: - HapticsView
struct HapticsView: View {
    @StateObject private var hapticsManager = HapticsManager.shared
    
    var body: some View {
        Form {
            enableHapticsSection
            
            if hapticsManager.isEnabled {
                intensitySection
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle(.localized("Haptics"))
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var enableHapticsSection: some View {
        Section {
            Toggle(isOn: $hapticsManager.isEnabled) {
                Label(.localized("Enable Haptics"), systemImage: "iphone.radiowaves.left.and.right")
            }
            .onChange(of: hapticsManager.isEnabled) { newValue in
                if newValue {
                    HapticsManager.shared.impact()
                }
            }
        } footer: {
            Text(.localized("Enable haptic feedback throughout the app for actions, errors, and success states."))
        }
    }
    
    private var intensitySection: some View {
        Section {
            ForEach(HapticsManager.HapticIntensity.allCases, id: \.self) { intensity in
                intensityButton(for: intensity)
            }
        } header: {
            Text(.localized("Intensity"))
        } footer: {
            Text(.localized("Choose the intensity of haptic feedback. Tap each option to feel the difference."))
        }
    }
    
    private func intensityButton(for intensity: HapticsManager.HapticIntensity) -> some View {
        Button {
            hapticsManager.intensity = intensity
            HapticsManager.shared.impact()
        } label: {
            HStack(spacing: 12) {
				Image(systemName: iconForIntensity(intensity))
					.foregroundStyle(hapticsManager.intensity == intensity ? Color.accentColor : Color.secondary)
					.font(.body)
					.frame(width: 24)
                Text(intensity.title)
                    .foregroundStyle(.primary)
                Spacer()
                if hapticsManager.intensity == intensity {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
	
	// Helper function to return appropriate icon for each intensity level
	private func iconForIntensity(_ intensity: HapticsManager.HapticIntensity) -> String {
		switch intensity {
		case .slow: return "waveform.path.ecg"
		case .defaultIntensity: return "waveform.path.ecg"
		case .hard: return "waveform.path.ecg.rectangle"
		case .extreme: return "waveform.path.ecg.rectangle"
		}
	}
}
