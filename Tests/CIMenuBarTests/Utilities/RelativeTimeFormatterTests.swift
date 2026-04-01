import Testing
import Foundation
@testable import CIMenuBar

@Suite("RelativeTimeFormatter")
struct RelativeTimeFormatterTests {
    @Test("Formats seconds ago")
    func secondsAgo() {
        let date = Date().addingTimeInterval(-30)
        let result = RelativeTimeFormatter.string(for: date)
        #expect(result == "just now")
    }

    @Test("Formats minutes ago")
    func minutesAgo() {
        let date = Date().addingTimeInterval(-720) // 12 minutes
        let result = RelativeTimeFormatter.string(for: date)
        #expect(result == "12m ago")
    }

    @Test("Formats hours ago")
    func hoursAgo() {
        let date = Date().addingTimeInterval(-7200) // 2 hours
        let result = RelativeTimeFormatter.string(for: date)
        #expect(result == "2h ago")
    }

    @Test("Formats running duration")
    func runningDuration() {
        let start = Date().addingTimeInterval(-1380) // 23 minutes ago
        let result = RelativeTimeFormatter.durationString(since: start)
        #expect(result == "running 23m...")
    }
}
