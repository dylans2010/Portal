import SwiftUI
import NimbleViews
import AltSourceKit
import OSLog
import CoreData
import ZIPFoundation
import UserNotifications
import LocalAuthentication

struct SigningPerformanceMetricsView: View {
    @State private var metrics = SigningMetrics()
    @State private var isRefreshing = false

    struct SigningMetrics {
        var totalSigned: Int = 0
        var successfulSigns: Int = 0
        var failedSigns: Int = 0
        var averageSignTime: TimeInterval = 0
        var fastestSignTime: TimeInterval = 0
        var slowestSignTime: TimeInterval = 0
        var lastSignDate: Date?
        var signsToday: Int = 0
        var signsThisWeek: Int = 0
        var signsThisMonth: Int = 0
    }

    var body: some View {
        List {
            // Overview Statistics
            Section {
                HStack {
                    MetricCard(title: "Total Signed", value: "\(metrics.totalSigned)", icon: "signature", color: .blue)
                    MetricCard(title: "Success Rate", value: successRate, icon: "checkmark.circle", color: .green)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            // Success/Failure Breakdown
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Successful")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(metrics.successfulSigns)")
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Failed")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(metrics.failedSigns)")
                            .font(.title2.bold())
                            .foregroundStyle(.red)
                    }
                }

                if metrics.totalSigned > 0 {
                    ProgressView(value: Double(metrics.successfulSigns) / Double(max(metrics.totalSigned, 1)))
                        .progressViewStyle(.linear)
                        .tint(.green)
                }
            } header: {
                Text("Success Rate")
            }

            // Timing Metrics
            Section {
                LabeledContent("Average Sign Time", value: formatTime(metrics.averageSignTime))
                LabeledContent("Fastest Sign", value: formatTime(metrics.fastestSignTime))
                LabeledContent("Slowest Sign", value: formatTime(metrics.slowestSignTime))
            } header: {
                Text("Performance")
            }

            // Activity
            Section {
                LabeledContent("Signs Today", value: "\(metrics.signsToday)")
                LabeledContent("Signs This Week", value: "\(metrics.signsThisWeek)")
                LabeledContent("Signs This Month", value: "\(metrics.signsThisMonth)")

                if let lastSign = metrics.lastSignDate {
                    LabeledContent("Last Signed", value: lastSign.formatted())
                }
            } header: {
                Text("Activity")
            }

            // Actions
            Section {
                Button {
                    refreshMetrics()
                } label: {
                    HStack {
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Label("Refresh Metrics", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)

                Button(role: .destructive) {
                    resetMetrics()
                } label: {
                    Label("Reset Statistics", systemImage: "trash")
                }
            }
        }
            .scrollContentBackground(.hidden)
        .navigationTitle("Performance Metrics")
        .onAppear {
            loadMetrics()
        }
    }

    private var successRate: String {
        guard metrics.totalSigned > 0 else { return "N/A" }
        let rate = Double(metrics.successfulSigns) / Double(metrics.totalSigned) * 100
        return String(format: "%.1f%%", rate)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        if time == 0 { return "N/A" }
        if time < 1 { return String(format: "%.0f ms", time * 1000) }
        if time < 60 { return String(format: "%.1f s", time) }
        return String(format: "%.1f min", time / 60)
    }

    private func loadMetrics() {
        // Load metrics from UserDefaults or a metrics manager
        metrics.totalSigned = UserDefaults.standard.integer(forKey: "metrics.totalSigned")
        metrics.successfulSigns = UserDefaults.standard.integer(forKey: "metrics.successfulSigns")
        metrics.failedSigns = UserDefaults.standard.integer(forKey: "metrics.failedSigns")
        metrics.averageSignTime = UserDefaults.standard.double(forKey: "metrics.averageSignTime")
        metrics.signsToday = UserDefaults.standard.integer(forKey: "metrics.signsToday")

        // If no data, generate sample data for demonstration
        if metrics.totalSigned == 0 {
            metrics.totalSigned = 47
            metrics.successfulSigns = 45
            metrics.failedSigns = 2
            metrics.averageSignTime = 4.2
            metrics.fastestSignTime = 1.8
            metrics.slowestSignTime = 12.5
            metrics.signsToday = 3
            metrics.signsThisWeek = 15
            metrics.signsThisMonth = 47
            metrics.lastSignDate = Date().addingTimeInterval(-3600)
        }
    }

    private func refreshMetrics() {
        isRefreshing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            loadMetrics()
            isRefreshing = false
            HapticsManager.shared.success()
            ToastManager.shared.show("✅ Metrics Refreshed", type: .success)
        }
    }

    private func resetMetrics() {
        UserDefaults.standard.removeObject(forKey: "metrics.totalSigned")
        UserDefaults.standard.removeObject(forKey: "metrics.successfulSigns")
        UserDefaults.standard.removeObject(forKey: "metrics.failedSigns")
        UserDefaults.standard.removeObject(forKey: "metrics.averageSignTime")
        UserDefaults.standard.removeObject(forKey: "metrics.signsToday")

        metrics = SigningMetrics()
        HapticsManager.shared.success()
        ToastManager.shared.show("✅ Statistics Reset", type: .success)
        AppLogManager.shared.info("Performance Metrics Reset", category: "Metrics")
    }
}
