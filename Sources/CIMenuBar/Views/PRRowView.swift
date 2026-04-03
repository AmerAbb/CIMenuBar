import SwiftUI

struct PRRowView: View {
    let prWithStatus: PRWithStatus
    let onRerun: () async -> Bool
    let onUpdateBranch: () async -> Bool
    let onMerge: () async -> Bool
    let onOpenInGitHub: () -> Void

    @State private var rerunState: ActionState = .idle
    @State private var rebaseState: ActionState = .idle
    @State private var mergeState: ActionState = .idle

    enum ActionState {
        case idle, loading, done, failed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                statusDot
                VStack(alignment: .leading, spacing: 2) {
                    Text(prWithStatus.pullRequest.title)
                        .font(.system(.body, weight: .medium))
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(prWithStatus.repoFullName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(prWithStatus.pullRequest.head.ref)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                timingLabel
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onOpenInGitHub)

            if let failedJob = prWithStatus.failedJobName {
                Text("Failed: \(failedJob)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 8) {
                if prWithStatus.latestRun?.conclusion == .failure {
                    actionButton(label: "Re-run failed", state: rerunState) {
                        rerunState = .loading
                        let success = await onRerun()
                        rerunState = success ? .done : .failed
                    }
                }
                if prWithStatus.behindBy > 0 && prWithStatus.allowUpdateBranch {
                    // Behind base branch — update first, then merge after CI re-runs
                    actionButton(label: "Update branch", state: rebaseState) {
                        rebaseState = .loading
                        let success = await onUpdateBranch()
                        rebaseState = success ? .done : .failed
                    }
                } else if prWithStatus.mergeableState == "clean" {
                    actionButton(label: "Merge", state: mergeState) {
                        mergeState = .loading
                        let success = await onMerge()
                        mergeState = success ? .done : .failed
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func actionButton(label: String, state: ActionState, action: @escaping () async -> Void) -> some View {
        Button(action: {
            Task { await action() }
        }) {
            switch state {
            case .idle:
                Text(label)
            case .loading:
                ProgressView()
                    .controlSize(.small)
            case .done:
                Label("Done", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Label("Failed", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .font(.caption)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .disabled(state == .loading || state == .done)
    }

    @ViewBuilder
    private var statusDot: some View {
        let color: Color = {
            guard let run = prWithStatus.latestRun else { return .gray }
            switch (run.status, run.conclusion) {
            case (.completed, .success): return .green
            case (.completed, .failure): return .red
            case (.inProgress, _), (.queued, _): return .yellow
            default: return .gray
            }
        }()

        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }

    @ViewBuilder
    private var timingLabel: some View {
        if let run = prWithStatus.latestRun {
            if run.status == .inProgress {
                if let started = prWithStatus.jobStartedAt {
                    Text(RelativeTimeFormatter.durationString(since: started))
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Text("running...")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } else {
                Text(RelativeTimeFormatter.string(for: run.updatedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
