import SwiftUI
import Sparkle

@main
struct CIMenuBarApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var ciPanelViewModel = CIPanelViewModel()
    @StateObject private var pollingService = PollingService()
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    init() {
        NotificationService.shared.requestPermission()
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(
                appState: appState,
                ciPanelViewModel: ciPanelViewModel,
                pollingService: pollingService,
                updater: updaterController.updater
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
    @ObservedObject var pollingService: PollingService
    let updater: SPUUpdater
    @StateObject private var setupViewModel = SetupViewModel()

    var body: some View {
        Group {
            switch appState.setupStatus {
            case .needsSetup:
                SetupView(viewModel: setupViewModel, appState: appState)
            case .ready:
                CIPanelView(
                    viewModel: ciPanelViewModel,
                    username: appState.githubUsername,
                    watchedRepos: appState.decodedWatchedRepos,
                    updater: updater
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
