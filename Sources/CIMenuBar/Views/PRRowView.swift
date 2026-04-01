import SwiftUI

struct PRRowView: View {
    let prWithStatus: PRWithStatus
    let onRerun: () -> Void
    let onOpenInGitHub: () -> Void

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

            if let failedJob = prWithStatus.failedJobName {
                Text("Failed: \(failedJob)")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack(spacing: 8) {
                if prWithStatus.latestRun?.conclusion == .failure {
                    Button("Re-run failed", action: onRerun)
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                Button("Open in GitHub", action: onOpenInGitHub)
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.vertical, 6)
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
                Text(RelativeTimeFormatter.durationString(since: run.createdAt))
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text(RelativeTimeFormatter.string(for: run.updatedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
