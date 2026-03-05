
import SwiftUI
import NimbleViews
import IDeviceSwift

struct JITAppSelectionView: View, InstallationProxyAppsDelegate {

    @Environment(\.dismiss) private var dismiss
    let onSelect: (String) -> Void

    @State private var apps: [AppInfo] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var errorMessage: String?

    private let proxy = InstallationAppProxy()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if apps.isEmpty && errorMessage != nil {
                    errorView
                } else {
                    appList
                }
            }
            .navigationTitle(String.localized("Select App"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String.localized("Cancel")) { dismiss() }
                }
            }
            .searchable(text: $searchText, prompt: String.localized("Search Apps"))
        }
        .onAppear {
            proxy.delegate = self
            Task { await loadApps() }
        }
    }


    private var appList: some View {
        List(filteredApps) { app in
            Button {
                if let bundleID = app.CFBundleIdentifier {
                    onSelect(bundleID)
                    dismiss()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "app.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.CFBundleName ?? app.CFBundleIdentifier ?? "Unknown")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                        if let bundleID = app.CFBundleIdentifier {
                            Text(bundleID)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 2)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(String.localized("Loading Apps..."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text(errorMessage ?? String.localized("Failed to load apps"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(String.localized("Try Again")) {
                Task { await loadApps() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Filtering

    private var filteredApps: [AppInfo] {
        guard !searchText.isEmpty else { return apps }
        return apps.filter { app in
            let name = app.CFBundleName ?? ""
            let bundleID = app.CFBundleIdentifier ?? ""
            return name.localizedCaseInsensitiveContains(searchText) ||
                   bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func loadApps() async {
        isLoading = true
        errorMessage = nil
        do {
            try await proxy.listApps()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateApplications(with apps: [AppInfo]) {
        DispatchQueue.main.async {
            self.apps = apps.sorted { ($0.CFBundleName ?? "") < ($1.CFBundleName ?? "") }
        }
    }
}
