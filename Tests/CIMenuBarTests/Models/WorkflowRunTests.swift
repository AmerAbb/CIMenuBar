import Testing
import Foundation
@testable import CIMenuBar

@Suite("WorkflowRun Model")
struct WorkflowRunTests {
    @Test("Decodes workflow run from GitHub API JSON")
    func decodesRunFromJSON() throws {
        let json = """
        {
            "id": 98765,
            "status": "completed",
            "conclusion": "failure",
            "html_url": "https://github.com/org/repo/actions/runs/98765",
            "created_at": "2026-04-01T10:00:00Z",
            "updated_at": "2026-04-01T10:35:00Z",
            "head_sha": "abc123",
            "pull_requests": [
                { "number": 1387 }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let run = try decoder.decode(WorkflowRun.self, from: json)

        #expect(run.id == 98765)
        #expect(run.status == .completed)
        #expect(run.conclusion == .failure)
        #expect(run.pullRequests.first?.number == 1387)
    }

    @Test("Decodes job from GitHub API JSON")
    func decodesJobFromJSON() throws {
        let json = """
        {
            "id": 111,
            "name": "Unit Tests / test-debug",
            "status": "completed",
            "conclusion": "failure",
            "started_at": "2026-04-01T10:00:00Z",
            "completed_at": "2026-04-01T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        let job = try decoder.decode(WorkflowJob.self, from: json)

        #expect(job.name == "Unit Tests / test-debug")
        #expect(job.conclusion == .failure)
    }
}
