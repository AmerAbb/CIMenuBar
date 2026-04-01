import Foundation

enum RelativeTimeFormatter {
    static func string(for date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        let days = hours / 24
        return "\(days)d ago"
    }

    static func durationString(since start: Date) -> String {
        let seconds = Int(-start.timeIntervalSinceNow)
        let minutes = seconds / 60
        if minutes < 1 { return "running <1m..." }
        if minutes < 60 { return "running \(minutes)m..." }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return "running \(hours)h \(remainingMinutes)m..."
    }
}
