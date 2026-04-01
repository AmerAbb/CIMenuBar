import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendCheckCompleted(prTitle: String, passed: Bool) {
        let content = UNMutableNotificationContent()
        content.title = passed ? "Checks Passed" : "Checks Failed"
        content.body = prTitle
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendRebaseNeeded(prTitle: String, baseBranch: String) {
        let content = UNMutableNotificationContent()
        content.title = "Rebase Needed"
        content.body = "\(prTitle) — \(baseBranch) has new commits"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
