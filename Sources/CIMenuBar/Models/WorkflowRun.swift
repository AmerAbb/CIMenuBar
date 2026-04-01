import Foundation

struct WorkflowRun: Codable, Identifiable {
    let id: Int
    let status: RunStatus
    let conclusion: RunConclusion?
    let htmlUrl: String
    let createdAt: Date
    let updatedAt: Date
    let headSha: String
    let pullRequests: [PRReference]

    struct PRReference: Codable {
        let number: Int
    }

    enum RunStatus: String, Codable {
        case queued, inProgress = "in_progress", completed, waiting
    }

    enum RunConclusion: String, Codable {
        case success, failure, cancelled, skipped, timedOut = "timed_out"
    }
}

struct WorkflowJob: Codable, Identifiable {
    let id: Int
    let name: String
    let status: WorkflowRun.RunStatus
    let conclusion: WorkflowRun.RunConclusion?
    let startedAt: Date?
    let completedAt: Date?
}

struct JobsResponse: Codable {
    let jobs: [WorkflowJob]
}

struct WorkflowRunsResponse: Codable {
    let workflowRuns: [WorkflowRun]
}
