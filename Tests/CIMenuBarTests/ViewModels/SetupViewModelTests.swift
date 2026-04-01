import Testing
import Foundation
@testable import CIMenuBar

@Suite("SetupViewModel")
struct SetupViewModelTests {
    @Test("Validates PAT is not empty")
    @MainActor
    func validatesPAT() {
        let viewModel = SetupViewModel()
        viewModel.tokenInput = ""
        #expect(viewModel.isTokenValid == false)

        viewModel.tokenInput = "ghp_abc123"
        #expect(viewModel.isTokenValid == true)
    }

    @Test("Can proceed only when token is valid")
    @MainActor
    func canProceed() {
        let viewModel = SetupViewModel()
        viewModel.tokenInput = ""
        #expect(viewModel.canProceedFromTokenStep == false)

        viewModel.tokenInput = "ghp_valid"
        #expect(viewModel.canProceedFromTokenStep == true)
    }

    @Test("Tracks selected repos")
    @MainActor
    func tracksSelectedRepos() {
        let viewModel = SetupViewModel()
        let repo = GitHubRepo(
            id: 1,
            fullName: "osn/android",
            owner: GitHubRepo.Owner(login: "osn")
        )
        viewModel.toggleRepo(repo)
        #expect(viewModel.selectedRepos.count == 1)

        viewModel.toggleRepo(repo)
        #expect(viewModel.selectedRepos.count == 0)
    }
}
