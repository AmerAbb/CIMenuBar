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
            allowUpdateBranch: true,
            asanaURL: nil
        )
        let teamPR = PRWithStatus(
            pullRequest: makePR(number: 2, author: "teammate"),
            latestRun: nil,
            failedJobName: nil,
            jobStartedAt: nil,
            behindBy: 0,
            mergeableState: nil,
            allowUpdateBranch: true,
            asanaURL: nil
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
            allowUpdateBranch: true,
            asanaURL: nil
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
            PRWithStatus(pullRequest: makePR(number: 1, author: "me"), latestRun: passingRun, failedJobName: nil, jobStartedAt: nil, behindBy: 0, mergeableState: "clean", allowUpdateBranch: true, asanaURL: nil),
            PRWithStatus(pullRequest: makePR(number: 2, author: "me"), latestRun: failingRun, failedJobName: "Unit Tests", jobStartedAt: nil, behindBy: 0, mergeableState: "blocked", allowUpdateBranch: true, asanaURL: nil),
        ]

        let status = CIPanelViewModel.aggregateStatus(for: prs)
        #expect(status == .hasFailing)
    }

    @Test("Computes aggregate status - running")
    @MainActor
    func aggregateRunning() {
        let run = makeRun(status: .inProgress, conclusion: nil)
        let prs = [
            PRWithStatus(pullRequest: makePR(number: 1, author: "me"), latestRun: run, failedJobName: nil, jobStartedAt: nil, behindBy: 0, mergeableState: nil, allowUpdateBranch: true, asanaURL: nil),
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

    @Test("Extracts Asana URL from PR body")
    @MainActor
    func extractsAsanaURL() {
        let body = """
        Fixes the layout

        To see the specific tasks where the Asana app for GitHub is being used, see below:
        https://app.asana.com/0/0/1213945434968148
        """
        let url = PRWithStatus.extractAsanaURL(from: body)
        #expect(url == "https://app.asana.com/0/0/1213945434968148")
    }

    @Test("Returns nil when no Asana URL in body")
    @MainActor
    func noAsanaURL() {
        let url = PRWithStatus.extractAsanaURL(from: "Just a normal PR description")
        #expect(url == nil)
    }

    @Test("Returns nil when body is nil")
    @MainActor
    func nilBody() {
        let url = PRWithStatus.extractAsanaURL(from: nil)
        #expect(url == nil)
    }

    @Test("Extracts first Asana URL when multiple present")
    @MainActor
    func multipleAsanaURLs() {
        let body = """
        https://app.asana.com/0/0/111111
        https://app.asana.com/0/0/222222
        """
        let url = PRWithStatus.extractAsanaURL(from: body)
        #expect(url == "https://app.asana.com/0/0/111111")
    }

    @Test("Extracts Asana URL with project ID")
    @MainActor
    func asanaURLWithProjectID() {
        let body = "Task: https://app.asana.com/0/123456789/987654321"
        let url = PRWithStatus.extractAsanaURL(from: body)
        #expect(url == "https://app.asana.com/0/123456789/987654321")
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
