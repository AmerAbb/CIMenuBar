import SwiftUI
import ServiceManagement

@MainActor
final class AppState: ObservableObject {
    enum SetupStatus {
        case needsSetup
        case ready
    }

    @Published var setupStatus: SetupStatus = .needsSetup

    @AppStorage("githubUsername") var githubUsername: String = ""
    @AppStorage("watchedRepos") var watchedReposData: Data = Data()

    var decodedWatchedRepos: [WatchedRepo] {
        guard !watchedReposData.isEmpty else { return [] }
        return (try? JSONDecoder().decode([WatchedRepo].self, from: watchedReposData)) ?? []
    }

    func checkSetup() {
        if !githubUsername.isEmpty, !watchedReposData.isEmpty {
            setupStatus = .ready
        } else {
            setupStatus = .needsSetup
        }
    }

    var isLaunchAtLoginEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                // Silently fail — user can toggle again
            }
        }
    }
}
