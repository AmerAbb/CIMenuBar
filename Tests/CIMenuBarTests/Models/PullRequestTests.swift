import Testing
import Foundation
@testable import CIMenuBar

@Suite("PullRequest Model")
struct PullRequestTests {
    @Test("Decodes from GitHub API JSON")
    func decodesFromJSON() throws {
        let json = """
        {
            "number": 1387,
            "title": "Adapt timeslot details screen layout for tablet landscape",
            "html_url": "https://github.com/org/repo/pull/1387",
            "user": {
                "login": "amerabb"
            },
            "head": {
                "ref": "feature/tablet-landscape"
            },
            "base": {
                "ref": "main"
            },
            "draft": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let pullRequest = try decoder.decode(PullRequest.self, from: json)

        #expect(pullRequest.number == 1387)
        #expect(pullRequest.title == "Adapt timeslot details screen layout for tablet landscape")
        #expect(pullRequest.user.login == "amerabb")
        #expect(pullRequest.head.ref == "feature/tablet-landscape")
        #expect(pullRequest.base.ref == "main")
        #expect(pullRequest.draft == false)
    }

    @Test("Decodes body field from GitHub API JSON")
    func decodesBody() throws {
        let json = """
        {
            "number": 42,
            "title": "Add feature",
            "html_url": "https://github.com/org/repo/pull/42",
            "user": { "login": "amerabb" },
            "head": { "ref": "feature-branch" },
            "base": { "ref": "main" },
            "draft": false,
            "body": "Fixes the layout\\n\\nhttps://app.asana.com/0/0/1213945434968148"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let pr = try decoder.decode(PullRequest.self, from: json)

        #expect(pr.body == "Fixes the layout\n\nhttps://app.asana.com/0/0/1213945434968148")
    }

    @Test("Decodes PR with nil body")
    func decodesNilBody() throws {
        let json = """
        {
            "number": 42,
            "title": "Add feature",
            "html_url": "https://github.com/org/repo/pull/42",
            "user": { "login": "amerabb" },
            "head": { "ref": "feature-branch" },
            "base": { "ref": "main" },
            "draft": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let pr = try decoder.decode(PullRequest.self, from: json)

        #expect(pr.body == nil)
    }
}
