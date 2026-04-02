import Foundation

final class GitHubAPIClient {
    private let token: String
    private let baseURL = "https://api.github.com"
    private let session: URLSession
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(token: String, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    func buildRequest(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem]? = nil
    ) -> URLRequest {
        var components = URLComponents(string: baseURL + path)!
        components.queryItems = queryItems
        var request = URLRequest(url: components.url!)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        return request
    }

    func fetchOpenPRs(owner: String, repo: String) async throws -> [PullRequest] {
        let request = buildRequest(
            path: "/repos/\(owner)/\(repo)/pulls",
            queryItems: [URLQueryItem(name: "state", value: "open")]
        )
        let (data, _) = try await session.data(for: request)
        return try decoder.decode([PullRequest].self, from: data)
    }

    func fetchWorkflowRuns(owner: String, repo: String) async throws -> [WorkflowRun] {
        let request = buildRequest(
            path: "/repos/\(owner)/\(repo)/actions/runs",
            queryItems: [URLQueryItem(name: "per_page", value: "30")]
        )
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(WorkflowRunsResponse.self, from: data).workflowRuns
    }

    func fetchJobs(owner: String, repo: String, runId: Int) async throws -> [WorkflowJob] {
        let request = buildRequest(
            path: "/repos/\(owner)/\(repo)/actions/runs/\(runId)/jobs"
        )
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(JobsResponse.self, from: data).jobs
    }

    func rerunFailedJobs(owner: String, repo: String, runId: Int) async throws {
        let request = buildRequest(
            path: "/repos/\(owner)/\(repo)/actions/runs/\(runId)/rerun-failed-jobs",
            method: "POST"
        )
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubAPIError.rerunFailed
        }
    }

    func fetchUserRepos() async throws -> [GitHubRepo] {
        let request = buildRequest(
            path: "/user/repos",
            queryItems: [
                URLQueryItem(name: "per_page", value: "100"),
                URLQueryItem(name: "sort", value: "updated"),
            ]
        )
        let (data, _) = try await session.data(for: request)
        return try decoder.decode([GitHubRepo].self, from: data)
    }

    func fetchAuthenticatedUser() async throws -> String {
        let request = buildRequest(path: "/user")
        let (data, _) = try await session.data(for: request)
        let user = try decoder.decode(PullRequest.User.self, from: data)
        return user.login
    }

    func updateBranch(owner: String, repo: String, pullNumber: Int) async throws {
        var request = buildRequest(
            path: "/repos/\(owner)/\(repo)/pulls/\(pullNumber)/update-branch",
            method: "PUT"
        )
        let body = ["update_method": "rebase"]
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubAPIError.updateBranchFailed
        }
    }

    func fetchBranchSha(owner: String, repo: String, branch: String) async throws -> String {
        let request = buildRequest(path: "/repos/\(owner)/\(repo)/git/ref/heads/\(branch)")
        let (data, _) = try await session.data(for: request)
        let ref = try decoder.decode(GitRef.self, from: data)
        return ref.object.sha
    }

    func fetchPRDetail(owner: String, repo: String, pullNumber: Int) async throws -> PRDetail {
        let request = buildRequest(path: "/repos/\(owner)/\(repo)/pulls/\(pullNumber)")
        let (data, _) = try await session.data(for: request)
        return try decoder.decode(PRDetail.self, from: data)
    }

    func mergePullRequest(owner: String, repo: String, pullNumber: Int) async throws {
        let request = buildRequest(
            path: "/repos/\(owner)/\(repo)/pulls/\(pullNumber)/merge",
            method: "PUT"
        )
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GitHubAPIError.mergeFailed
        }
    }

    func fetchBehindBy(owner: String, repo: String, base: String, head: String) async throws -> Int {
        let request = buildRequest(path: "/repos/\(owner)/\(repo)/compare/\(base)...\(head)")
        let (data, _) = try await session.data(for: request)
        let comparison = try decoder.decode(CompareResponse.self, from: data)
        return comparison.behindBy
    }
}

enum GitHubAPIError: Error {
    case rerunFailed
    case updateBranchFailed
    case mergeFailed
}

struct GitRef: Codable {
    let object: RefObject

    struct RefObject: Codable {
        let sha: String
    }
}

struct CompareResponse: Codable {
    let behindBy: Int
}

struct PRDetail: Codable {
    let mergeable: Bool?
    let mergeableState: String?
}

struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let fullName: String
    let owner: Owner

    struct Owner: Codable {
        let login: String
    }

    var repoName: String {
        fullName.components(separatedBy: "/").last ?? fullName
    }

    var ownerName: String {
        owner.login
    }
}
