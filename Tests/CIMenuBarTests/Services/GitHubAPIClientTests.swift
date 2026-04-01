import Testing
import Foundation
@testable import CIMenuBar

@Suite("GitHubAPIClient")
struct GitHubAPIClientTests {
    @Test("Builds correct URL for listing PRs")
    func listPRsURL() {
        let client = GitHubAPIClient(token: "ghp_test123")
        let request = client.buildRequest(
            path: "/repos/osn/android/pulls",
            queryItems: [URLQueryItem(name: "state", value: "open")]
        )

        #expect(request.url?.absoluteString == "https://api.github.com/repos/osn/android/pulls?state=open")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer ghp_test123")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/vnd.github+json")
    }

    @Test("Builds correct URL for workflow runs")
    func workflowRunsURL() {
        let client = GitHubAPIClient(token: "ghp_test123")
        let request = client.buildRequest(
            path: "/repos/osn/android/actions/runs",
            queryItems: [URLQueryItem(name: "per_page", value: "30")]
        )

        #expect(request.url?.absoluteString == "https://api.github.com/repos/osn/android/actions/runs?per_page=30")
    }

    @Test("Builds POST request for re-running failed jobs")
    func rerunFailedJobsRequest() {
        let client = GitHubAPIClient(token: "ghp_test123")
        let request = client.buildRequest(
            path: "/repos/osn/android/actions/runs/98765/rerun-failed-jobs",
            method: "POST"
        )

        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://api.github.com/repos/osn/android/actions/runs/98765/rerun-failed-jobs")
    }
}
