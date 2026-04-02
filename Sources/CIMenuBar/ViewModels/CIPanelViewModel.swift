import SwiftUI

struct PRWithStatus: Identifiable {
    let pullRequest: PullRequest
    let latestRun: WorkflowRun?
    let failedJobName: String?
    let jobStartedAt: Date?
    let behindBy: Int
    let mergeableState: String?

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
    @Published var lastRefreshedAt: Date?

    var hasData: Bool { lastRefreshedAt != nil }

    func isStale(threshold: TimeInterval = 30) -> Bool {
        guard let lastRefreshedAt else { return true }
        return Date().timeIntervalSince(lastRefreshedAt) > threshold
    }

    private let keychainService = KeychainService()
    private var previousRunStatuses: [Int: WorkflowRun.RunStatus] = [:]
    private var previousBaseBranchShas: [String: String] = [:]
    private var refreshInProgress = false

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
        guard !refreshInProgress else { return }
        guard let token = try? keychainService.retrieve(forKey: SetupViewModel.tokenKey) else { return }
        refreshInProgress = true
        // Only show the spinner when we have nothing to display yet
        if !hasData {
            isRefreshing = true
        }

        let client = GitHubAPIClient(token: token)
        // Start with previous data so failed repos keep their old PRs
        var prsByRepo: [String: [PRWithStatus]] = [:]
        for pr in myPRs + teamPRs {
            prsByRepo[pr.repoFullName, default: []].append(pr)
        }
        var anyRepoSucceeded = false

        for repo in watchedRepos {
            let repoKey = "\(repo.owner)/\(repo.name)"
            do {
                async let prsTask = client.fetchOpenPRs(owner: repo.owner, repo: repo.name)
                async let runsTask = client.fetchWorkflowRuns(owner: repo.owner, repo: repo.name)
                let (prs, runs) = try await (prsTask, runsTask)

                // Enrich each PR in parallel
                let enrichedPRs: [PRWithStatus] = await withTaskGroup(of: PRWithStatus?.self) { group in
                    for pr in prs {
                        group.addTask {
                            let candidateRuns = runs.filter { run in
                                run.pullRequests.contains { $0.number == pr.number }
                                    || run.headSha == pr.head.sha
                            }
                            let matchingRun = candidateRuns
                                .sorted { lhs, rhs in
                                    let lhsActive = lhs.status == .inProgress || lhs.status == .queued
                                    let rhsActive = rhs.status == .inProgress || rhs.status == .queued
                                    if lhsActive != rhsActive { return lhsActive }
                                    return lhs.createdAt > rhs.createdAt
                                }
                                .first

                            var failedJobName: String?
                            var jobStartedAt: Date?

                            if let runId = matchingRun?.id {
                                let needsJobs = matchingRun?.conclusion == .failure
                                    || matchingRun?.status == .inProgress
                                if needsJobs {
                                    if let jobs = try? await client.fetchJobs(owner: repo.owner, repo: repo.name, runId: runId) {
                                        failedJobName = jobs.first { $0.conclusion == .failure }?.name
                                        jobStartedAt = jobs.compactMap(\.startedAt).min()
                                    }
                                }
                            }

                            async let behindByTask = client.fetchBehindBy(
                                owner: repo.owner, repo: repo.name,
                                base: pr.base.ref, head: pr.head.ref
                            )
                            async let detailTask = client.fetchPRDetail(
                                owner: repo.owner, repo: repo.name,
                                pullNumber: pr.number
                            )

                            let behindBy = (try? await behindByTask) ?? 0
                            let detail = try? await detailTask

                            return PRWithStatus(
                                pullRequest: pr,
                                latestRun: matchingRun,
                                failedJobName: failedJobName,
                                jobStartedAt: jobStartedAt,
                                behindBy: behindBy,
                                mergeableState: detail?.mergeableState
                            )
                        }
                    }

                    var results: [PRWithStatus] = []
                    for await result in group {
                        if let pr = result { results.append(pr) }
                    }
                    return results
                }

                prsByRepo[repoKey] = enrichedPRs
                anyRepoSucceeded = true

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

        // Only update state if at least one repo was fetched successfully;
        // otherwise keep showing the previous data instead of blanking out.
        if anyRepoSucceeded {
            let allPRsWithStatus = prsByRepo.values.flatMap { $0 }
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
            lastRefreshedAt = Date()
        }
        isRefreshing = false
        refreshInProgress = false
    }

    func rerunFailedJobs(for prWithStatus: PRWithStatus) async -> Bool {
        guard let token = try? keychainService.retrieve(forKey: SetupViewModel.tokenKey),
              let run = prWithStatus.latestRun else { return false }

        let parts = prWithStatus.pullRequest.htmlUrl.components(separatedBy: "/")
        guard parts.count >= 5 else { return false }
        let owner = parts[3]
        let repo = parts[4]

        let client = GitHubAPIClient(token: token)
        do {
            try await client.rerunFailedJobs(owner: owner, repo: repo, runId: run.id)
            return true
        } catch {
            return false
        }
    }

    func mergePullRequest(for prWithStatus: PRWithStatus) async -> Bool {
        guard let token = try? keychainService.retrieve(forKey: SetupViewModel.tokenKey) else { return false }

        let parts = prWithStatus.pullRequest.htmlUrl.components(separatedBy: "/")
        guard parts.count >= 5 else { return false }
        let owner = parts[3]
        let repo = parts[4]

        let client = GitHubAPIClient(token: token)
        do {
            try await client.mergePullRequest(owner: owner, repo: repo, pullNumber: prWithStatus.pullRequest.number)
            return true
        } catch {
            return false
        }
    }

    func updateBranch(for prWithStatus: PRWithStatus) async -> Bool {
        guard let token = try? keychainService.retrieve(forKey: SetupViewModel.tokenKey) else { return false }

        let parts = prWithStatus.pullRequest.htmlUrl.components(separatedBy: "/")
        guard parts.count >= 5 else { return false }
        let owner = parts[3]
        let repo = parts[4]

        let client = GitHubAPIClient(token: token)
        do {
            try await client.updateBranch(owner: owner, repo: repo, pullNumber: prWithStatus.pullRequest.number)
            return true
        } catch {
            return false
        }
    }
}
