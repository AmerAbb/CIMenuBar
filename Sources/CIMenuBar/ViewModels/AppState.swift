import SwiftUI

@MainActor
final class AppState: ObservableObject {
    enum SetupStatus {
        case needsSetup
        case ready
    }

    @Published var setupStatus: SetupStatus = .needsSetup

    @AppStorage("githubUsername") var githubUsername: String = ""
    @AppStorage("watchedRepos") var watchedReposData: Data = Data()

    func checkSetup() {
        if !githubUsername.isEmpty, !watchedReposData.isEmpty {
            setupStatus = .ready
        } else {
            setupStatus = .needsSetup
        }
    }
}
