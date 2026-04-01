import SwiftUI

struct CIPanelView: View {
    @ObservedObject var viewModel: CIPanelViewModel
    let username: String
    let watchedRepos: [WatchedRepo]

    @State private var isTeamExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    myPRsSection
                    if !viewModel.teamPRs.isEmpty {
                        Divider().padding(.vertical, 4)
                        teamPRsSection
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 400)
            Divider()
            footer
        }
        .frame(width: 380)
        .task {
            await viewModel.refresh(username: username, watchedRepos: watchedRepos)
        }
    }

    private var header: some View {
        HStack {
            Text("CI Status")
                .font(.headline)
            Spacer()
            Button(action: {
                Task { await viewModel.refresh(username: username, watchedRepos: watchedRepos) }
            }) {
                if viewModel.isRefreshing {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var myPRsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("My PRs")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.myPRs.isEmpty {
                Text("No open PRs")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.myPRs) { prWithStatus in
                    PRRowView(
                        prWithStatus: prWithStatus,
                        onRerun: {
                            Task { await viewModel.rerunFailedJobs(for: prWithStatus) }
                        },
                        onOpenInGitHub: {
                            if let url = URL(string: prWithStatus.pullRequest.htmlUrl) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                    )
                    Divider()
                }
            }
        }
    }

    private var teamPRsSection: some View {
        DisclosureGroup("Team PRs (\(viewModel.teamPRs.count))", isExpanded: $isTeamExpanded) {
            ForEach(viewModel.teamPRs) { prWithStatus in
                PRRowView(
                    prWithStatus: prWithStatus,
                    onRerun: {
                        Task { await viewModel.rerunFailedJobs(for: prWithStatus) }
                    },
                    onOpenInGitHub: {
                        if let url = URL(string: prWithStatus.pullRequest.htmlUrl) {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
                Divider()
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var footer: some View {
        HStack {
            Text("Watching \(watchedRepos.count) repos")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.caption)
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
