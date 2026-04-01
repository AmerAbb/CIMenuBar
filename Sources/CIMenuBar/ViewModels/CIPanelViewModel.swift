import SwiftUI

struct PRWithStatus: Identifiable {
    let pullRequest: PullRequest
    let latestRun: WorkflowRun?
    let failedJobName: String?

    var id: Int { pullRequest.number }

    var repoFullName: String {
        let parts = pullRequest.htmlUrl.components(separatedBy: "/")
        guard parts.count >= 5 else { return "" }
        return "\(parts[3])/\(parts[4])"
    }
}

struct ClassifiedPRs {
    let mine: [PRWithStatus]
    let team: [PRWithStatus]
}

enum AggregateStatus: Equatable {
    case noPRs
    case allPassing
    case running
    case hasFailing
}

@MainActor
final class CIPanelViewModel: ObservableObject {
    @Published var myPRs: [PRWithStatus] = []
    @Published var teamPRs: [PRWithStatus] = []
    @Published var aggregateMenuBarStatus: AggregateStatus = .noPRs
    @Published var isRefreshing = false

    private let keychainService = KeychainService()
    private var previousRunStatuses: [Int: WorkflowRun.RunStatus] = [:]
    private var previousBaseBranchShas: [String: String] = [:]

    static func classify(
        prsWithStatus: [PRWithStatus],
        username: String
    ) -> ClassifiedPRs {
        let mine = prsWithStatus.filter { $0.pullRequest.user.login == username }
        let team = prsWithStatus.filter { $0.pullRequest.user.login != username }
        return ClassifiedPRs(mine: mine, team: team)
    }

    static func aggregateStatus(for prs: [PRWithStatus]) -> AggregateStatus {
        if prs.isEmpty { return .noPRs }

        let hasFailure = prs.contains { pr in
            pr.latestRun?.conclusion == .failure
        }
        if hasFailure { return .hasFailing }

        let hasRunning = prs.contains { pr in
            guard let run = pr.latestRun else { return false }
            return run.status == .inProgress || run.status == .queued
        }
        if hasRunning { return .running }

        return .allPassing
    }

    func refresh(username: String, watchedRepos: [WatchedRepo]) async {
        guard let token = try? keychainService.retrieve(forKey: SetupViewModel.tokenKey) else { return }
        isRefreshing = true

        let client = GitHubAPIClient(token: token)
        var allPRsWithStatus: [PRWithStatus] = []

        for repo in watchedRepos {
            do {
                let prs = try await client.fetchOpenPRs(owner: repo.owner, repo: repo.name)
                let runs = try await client.fetchWorkflowRuns(owner: repo.owner, repo: repo.name)

                for pr in prs {
                    let matchingRun = runs
                        .filter { run in run.pullRequests.contains { $0.number == pr.number } }
                        .sorted { $0.createdAt > $1.createdAt }
                        .first

                    var failedJobName: String?
                    if matchingRun?.conclusion == .failure, let runId = matchingRun?.id {
                        let jobs = try await client.fetchJobs(owner: repo.owner, repo: repo.name, runId: runId)
                        failedJobName = jobs.first { $0.conclusion == .failure }?.name
                    }

                    allPRsWithStatus.append(PRWithStatus(
                        pullRequest: pr,
                        latestRun: matchingRun,
                        failedJobName: failedJobName
                    ))
                }

                // Check for base branch changes (rebase alerts)
                let myRepoPRs = prs.filter { $0.user.login == username }
                let baseBranches = Set(myRepoPRs.map { $0.base.ref })
                for baseBranch in baseBranches {
                    let key = "\(repo.owner)/\(repo.name)/\(baseBranch)"
                    if let currentSha = try? await client.fetchBranchSha(owner: repo.owner, repo: repo.name, branch: baseBranch) {
                        if let previousSha = previousBaseBranchShas[key], previousSha != currentSha {
                            let affectedPR = myRepoPRs.first { $0.base.ref == baseBranch }
                            NotificationService.shared.sendRebaseNeeded(
                                prTitle: affectedPR?.title ?? "Your PR",
                                baseBranch: baseBranch
                            )
                        }
                        previousBaseBranchShas[key] = currentSha
                    }
                }
            } catch {
                continue
            }
        }

        let classified = Self.classify(prsWithStatus: allPRsWithStatus, username: username)
        myPRs = classified.mine
        teamPRs = classified.team
        aggregateMenuBarStatus = Self.aggregateStatus(for: classified.mine)

        // Send notifications for status changes on my PRs
        for pr in classified.mine {
            guard let run = pr.latestRun else { continue }
            let previousStatus = previousRunStatuses[pr.pullRequest.number]

            if previousStatus == .inProgress && run.status == .completed {
                let passed = run.conclusion == .success
                NotificationService.shared.sendCheckCompleted(
                    prTitle: pr.pullRequest.title,
                    passed: passed
                )
            }
            previousRunStatuses[pr.pullRequest.number] = run.status
        }
        isRefreshing = false
    }

    func rerunFailedJobs(for prWithStatus: PRWithStatus) async {
        guard let token = try? keychainService.retrieve(forKey: SetupViewModel.tokenKey),
              let run = prWithStatus.latestRun else { return }

        let parts = prWithStatus.pullRequest.htmlUrl.components(separatedBy: "/")
        guard parts.count >= 5 else { return }
        let owner = parts[3]
        let repo = parts[4]

        let client = GitHubAPIClient(token: token)
        try? await client.rerunFailedJobs(owner: owner, repo: repo, runId: run.id)
    }
}
