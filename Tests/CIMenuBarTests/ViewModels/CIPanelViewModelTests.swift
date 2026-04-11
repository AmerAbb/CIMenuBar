import Testing
import Foundation
@testable import CIMenuBar

@Suite("CIPanelViewModel")
struct CIPanelViewModelTests {
    @Test("Classifies PRs into mine vs team")
    @MainActor
    func classifiesPRs() {
        let myPR = PRWithStatus(
            pullRequest: makePR(number: 1, author: "amerabb"),
            latestRun: nil,
            failedJobName: nil,
            jobStartedAt: nil,
            behindBy: 0,
            mergeableState: nil,
            allowUpdateBranch: true
        )
        let teamPR = PRWithStatus(
            pullRequest: makePR(number: 2, author: "teammate"),
            latestRun: nil,
            failedJobName: nil,
            jobStartedAt: nil,
            behindBy: 0,
            mergeableState: nil,
            allowUpdateBranch: true
        )

        let result = CIPanelViewModel.classify(
            prsWithStatus: [myPR, teamPR],
            username: "amerabb"
        )

        #expect(result.mine.count == 1)
        #expect(result.mine.first?.pullRequest.number == 1)
        #expect(result.team.count == 1)
        #expect(result.team.first?.pullRequest.number == 2)
    }

    @Test("Computes aggregate status - all green")
    @MainActor
    func aggregateGreen() {
        let run = makeRun(status: .completed, conclusion: .success)
        let pr = PRWithStatus(
            pullRequest: makePR(number: 1, author: "amerabb"),
            latestRun: run,
            failedJobName: nil,
            jobStartedAt: nil,
            behindBy: 0,
            mergeableState: nil,
            allowUpdateBranch: true
        )

        let status = CIPanelViewModel.aggregateStatus(for: [pr])
        #expect(status == .allPassing)
    }

    @Test("Computes aggregate status - one failing")
    @MainActor
    func aggregateFailing() {
        let passingRun = makeRun(status: .completed, conclusion: .success)
        let failingRun = makeRun(status: .completed, conclusion: .failure)
        let prs = [
            PRWithStatus(pullRequest: makePR(number: 1, author: "me"), latestRun: passingRun, failedJobName: nil, jobStartedAt: nil, behindBy: 0, mergeableState: "clean", allowUpdateBranch: true),
            PRWithStatus(pullRequest: makePR(number: 2, author: "me"), latestRun: failingRun, failedJobName: "Unit Tests", jobStartedAt: nil, behindBy: 0, mergeableState: "blocked", allowUpdateBranch: true),
        ]

        let status = CIPanelViewModel.aggregateStatus(for: prs)
        #expect(status == .hasFailing)
    }

    @Test("Computes aggregate status - running")
    @MainActor
    func aggregateRunning() {
        let run = makeRun(status: .inProgress, conclusion: nil)
        let prs = [
            PRWithStatus(pullRequest: makePR(number: 1, author: "me"), latestRun: run, failedJobName: nil, jobStartedAt: nil, behindBy: 0, mergeableState: nil, allowUpdateBranch: true),
        ]

        let status = CIPanelViewModel.aggregateStatus(for: prs)
        #expect(status == .running)
    }

    @Test("Computes aggregate status - no PRs")
    @MainActor
    func aggregateNoPRs() {
        let status = CIPanelViewModel.aggregateStatus(for: [])
        #expect(status == .noPRs)
    }

    // MARK: - Helpers

    private func makePR(number: Int, author: String) -> PullRequest {
        PullRequest(
            number: number,
            title: "PR #\(number)",
            htmlUrl: "https://github.com/org/repo/pull/\(number)",
            user: PullRequest.User(login: author),
            head: PullRequest.BranchRef(ref: "feature-\(number)", sha: nil),
            base: PullRequest.BranchRef(ref: "main", sha: nil),
            draft: false,
            body: nil
        )
    }

    private func makeRun(status: WorkflowRun.RunStatus, conclusion: WorkflowRun.RunConclusion?) -> WorkflowRun {
        WorkflowRun(
            id: Int.random(in: 1...99999),
            status: status,
            conclusion: conclusion,
            htmlUrl: "https://github.com/org/repo/actions/runs/1",
            createdAt: Date(),
            updatedAt: Date(),
            headSha: "abc123",
            pullRequests: [WorkflowRun.PRReference(number: 1)]
        )
    }
}
