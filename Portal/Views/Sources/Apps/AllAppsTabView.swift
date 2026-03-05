import SwiftUI
import AltSourceKit

struct AllAppsTabView: View {
    @AppStorage("Feather.useNewAllAppsView") private var useNewAllAppsView: Bool = true
    @StateObject private var viewModel = SourcesViewModel.shared

    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.order, ascending: true)]
    ) private var sources: FetchedResults<AltSource>

    var body: some View {
        NavigationStack {
            Group {
                if useNewAllAppsView {
                    AllAppsView(isTab: true, object: Array(sources), viewModel: viewModel)
                } else {
                    VStack(spacing: 20) {
                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 100, height: 100)

                            Image(systemName: "rectangle.stack.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.accentColor)
                        }

                        VStack(spacing: 12) {
                            Text("New Apps View Required")
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)

                            Text("In order so you can see the apps here, enable the New Apps View on Settings, Appearance, turn it on, and restart Portal.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.clear)
                }
            }
        }
        .task(id: Array(sources)) {
            await viewModel.fetchSources(Array(sources))
        }
    }
}
