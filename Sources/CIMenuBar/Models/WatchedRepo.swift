import Foundation

struct WatchedRepo: Codable, Identifiable, Hashable {
    let owner: String
    let name: String

    var id: String { "\(owner)/\(name)" }
    var fullName: String { "\(owner)/\(name)" }
}
