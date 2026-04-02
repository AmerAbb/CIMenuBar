import Foundation

struct PullRequest: Codable, Identifiable {
    let number: Int
    let title: String
    let htmlUrl: String
    let user: User
    let head: BranchRef
    let base: BranchRef
    let draft: Bool

    var id: Int { number }

    struct User: Codable {
        let login: String
    }

    struct BranchRef: Codable {
        let ref: String
        let sha: String?
    }
}
