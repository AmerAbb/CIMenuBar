import SwiftUI

@MainActor
final class SetupViewModel: ObservableObject {
    enum Step {
        case token
        case repos
    }

    @Published var step: Step = .token
    @Published var tokenInput: String = ""
    @Published var usernameResult: String = ""
    @Published var availableRepos: [GitHubRepo] = []
    @Published var selectedRepos: Set<Int> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let keychainService = KeychainService()
    static let tokenKey = "com.ciMenuBar.github.pat"

    var isTokenValid: Bool {
        !tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canProceedFromTokenStep: Bool {
        isTokenValid
    }

    func toggleRepo(_ repo: GitHubRepo) {
        if selectedRepos.contains(repo.id) {
            selectedRepos.remove(repo.id)
        } else {
            selectedRepos.insert(repo.id)
        }
    }

    func validateTokenAndFetchRepos() async {
        isLoading = true
        errorMessage = nil
        let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let client = GitHubAPIClient(token: token)
            usernameResult = try await client.fetchAuthenticatedUser()
            availableRepos = try await client.fetchUserRepos()
            try keychainService.save(token: token, forKey: Self.tokenKey)
            step = .repos
        } catch {
            errorMessage = "Invalid token or network error. Check your PAT and try again."
        }

        isLoading = false
    }

    func completeSetup(appState: AppState) {
        let watchedRepos = availableRepos
            .filter { selectedRepos.contains($0.id) }
            .map { WatchedRepo(owner: $0.ownerName, name: $0.repoName) }

        if let data = try? JSONEncoder().encode(watchedRepos) {
            appState.watchedReposData = data
        }
        appState.githubUsername = usernameResult
        appState.setupStatus = .ready
    }
}
