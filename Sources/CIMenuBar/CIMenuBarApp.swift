import SwiftUI

@main
struct CIMenuBarApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var ciPanelViewModel = CIPanelViewModel()

    init() {
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(
                appState: appState,
                ciPanelViewModel: ciPanelViewModel
            )
        } label: {
            Image(systemName: "circle.fill")
                .foregroundStyle(menuBarColor)
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarColor: Color {
        switch ciPanelViewModel.aggregateMenuBarStatus {
        case .noPRs: return .gray
        case .allPassing: return .green
        case .running: return .yellow
        case .hasFailing: return .red
        }
    }
}

private struct MenuBarContent: View {
    @ObservedObject var appState: AppState
    @ObservedObject var ciPanelViewModel: CIPanelViewModel
    @StateObject private var setupViewModel = SetupViewModel()
    @StateObject private var pollingService = PollingService()

    var body: some View {
        Group {
            switch appState.setupStatus {
            case .needsSetup:
                SetupView(viewModel: setupViewModel, appState: appState)
            case .ready:
                CIPanelView(
                    viewModel: ciPanelViewModel,
                    username: appState.githubUsername,
                    watchedRepos: appState.decodedWatchedRepos
                )
            }
        }
        .onAppear {
            appState.checkSetup()
        }
        .onChange(of: appState.setupStatus) { newStatus in
            if newStatus == .ready {
                startPolling()
            }
        }
    }

    private func startPolling() {
        pollingService.start { [ciPanelViewModel, appState] in
            await ciPanelViewModel.refresh(
                username: appState.githubUsername,
                watchedRepos: appState.decodedWatchedRepos
            )
        }
    }
}
