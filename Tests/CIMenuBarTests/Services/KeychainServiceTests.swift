import Testing
@testable import CIMenuBar

@Suite("KeychainService")
struct KeychainServiceTests {
    let service = KeychainService()

    @Test("Saves and retrieves a token")
    func saveAndRetrieve() throws {
        let key = "com.ciMenuBar.test.saveAndRetrieve"
        try service.delete(forKey: key)
        try service.save(token: "ghp_testtoken123", forKey: key)
        let retrieved = try service.retrieve(forKey: key)
        #expect(retrieved == "ghp_testtoken123")
        try service.delete(forKey: key)
    }

    @Test("Returns nil for missing key")
    func missingKey() throws {
        let result = try service.retrieve(forKey: "com.ciMenuBar.test.nonexistent")
        #expect(result == nil)
    }

    @Test("Overwrites existing token")
    func overwrite() throws {
        let key = "com.ciMenuBar.test.overwrite"
        try service.delete(forKey: key)
        try service.save(token: "old_token", forKey: key)
        try service.save(token: "new_token", forKey: key)
        let retrieved = try service.retrieve(forKey: key)
        #expect(retrieved == "new_token")
        try service.delete(forKey: key)
    }

    @Test("Deletes a token")
    func deleteToken() throws {
        let key = "com.ciMenuBar.test.deleteToken"
        try service.delete(forKey: key)
        try service.save(token: "to_delete", forKey: key)
        try service.delete(forKey: key)
        let result = try service.retrieve(forKey: key)
        #expect(result == nil)
    }
}
