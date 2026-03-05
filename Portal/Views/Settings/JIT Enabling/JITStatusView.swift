

import SwiftUI
import NimbleViews


struct JITStatusView: View {

    @ObservedObject var manager: JITManager

    var body: some View {
        VStack(spacing: 0) {
            stepRow(
                icon: "doc.badge.gearshape",
                title: String.localized("Pairing File"),
                subtitle: String.localized("Device pairing record loaded"),
                stepState: stepState(for: .validatingPairing)
            )
            Divider().padding(.leading, 56)

            stepRow(
                icon: "network",
                title: String.localized("VPN Tunnel"),
                subtitle: String.localized("Loopback VPN active"),
                stepState: stepState(for: .checkingVPN)
            )
            Divider().padding(.leading, 56)

            stepRow(
                icon: "lock.shield",
                title: String.localized("Lockdown Session"),
                subtitle: String.localized("Authenticated device connection"),
                stepState: stepState(for: .connectingLockdown)
            )
            Divider().padding(.leading, 56)

            stepRow(
                icon: "ant.circle",
                title: String.localized("Debugserver"),
                subtitle: String.localized("Attach and resume process"),
                stepState: stepState(for: .connectingDebugServer)
            )
            Divider().padding(.leading, 56)

            stepRow(
                icon: "bolt.circle.fill",
                title: String.localized("JIT Enabled"),
                subtitle: String.localized("Just-In-Time compilation active"),
                stepState: stepState(for: .jitEnabled)
            )
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private enum StepState {
        case waiting, inProgress, completed, failed
    }

    private func stepState(for step: JITState) -> StepState {
        let orderedSteps: [JITState] = [
            .validatingPairing,
            .checkingVPN,
            .connectingLockdown,
            .connectingDebugServer,
            .jitEnabled
        ]

        if case .failed = manager.state { return .failed }

        guard let stepIndex = orderedSteps.firstIndex(of: step) else { return .waiting }

        if manager.state == step { return .inProgress }
        if manager.state == .jitEnabled { return .completed }

        guard let currentIndex = orderedSteps.firstIndex(of: manager.state) else {
            return stepIndex == 0 ? .waiting : .waiting
        }

        if stepIndex < currentIndex { return .completed }
        if stepIndex == currentIndex { return .inProgress }
        return .waiting
    }


    @ViewBuilder
    private func stepRow(icon: String, title: String, subtitle: String, stepState: StepState) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor(for: stepState))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            statusIndicator(for: stepState)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func statusIndicator(for state: StepState) -> some View {
        switch state {
        case .waiting:
            Image(systemName: "circle")
                .font(.system(size: 18))
                .foregroundStyle(.tertiary)
        case .inProgress:
            ProgressView()
                .scaleEffect(0.8)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(.red)
        }
    }

    private func iconColor(for state: StepState) -> Color {
        switch state {
        case .waiting:    return .secondary
        case .inProgress: return .accentColor
        case .completed:  return .green
        case .failed:     return .red
        }
    }
}
