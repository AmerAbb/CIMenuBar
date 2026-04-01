import Foundation

@MainActor
final class PollingService: ObservableObject {
    private var timer: Timer?
    private var onPoll: (() async -> Void)?

    func start(interval: TimeInterval = 60, action: @escaping () async -> Void) {
        onPoll = action
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.onPoll?()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
