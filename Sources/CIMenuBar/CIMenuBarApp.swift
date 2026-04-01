import SwiftUI

@main
struct CIMenuBarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent(appState: appState)
        } label: {
            Image(systemName: "circle.fill")
                .foregroundStyle(.gray)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarContent: View {
    @ObservedObject var appState: AppState
    @StateObject private var setupViewModel = SetupViewModel()

    var body: some View {
        Group {
            switch appState.setupStatus {
            case .needsSetup:
                SetupView(viewModel: setupViewModel, appState: appState)
            case .ready:
                Text("CI Panel coming next...")
                    .padding()
                    .frame(width: 350)
            }
        }
        .onAppear {
            appState.checkSetup()
        }
    }
}
