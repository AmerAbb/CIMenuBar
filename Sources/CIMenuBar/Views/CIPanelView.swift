import SwiftUI
import Sparkle

struct CIPanelView: View {
    @ObservedObject var viewModel: CIPanelViewModel
    let username: String
    let watchedRepos: [WatchedRepo]
    let updater: SPUUpdater

    @State private var isTeamExpanded = false
    @State private var selectedRepo: String? // nil = All
    @StateObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel

    init(viewModel: CIPanelViewModel, username: String, watchedRepos: [WatchedRepo], updater: SPUUpdater) {
        self.viewModel = viewModel
        self.username = username
        self.watchedRepos = watchedRepos
        self.updater = updater
        self._checkForUpdatesViewModel = StateObject(wrappedValue: CheckForUpdatesViewModel(updater: updater))
    }

    private var filteredMyPRs: [PRWithStatus] {
        guard let repo = selectedRepo else { return viewModel.myPRs }
        return viewModel.myPRs.filter { $0.repoFullName == repo }
    }

    private var filteredTeamPRs: [PRWithStatus] {
        guard let repo = selectedRepo else { return viewModel.teamPRs }
        return viewModel.teamPRs.filter { $0.repoFullName == repo }
    }

    private var allRepoNames: [String] {
        let all = (viewModel.myPRs + viewModel.teamPRs).map(\.repoFullName)
        return Array(Set(all)).sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            if !viewModel.hasData {
                VStack {
                    Spacer()
                    ProgressView("Loading CI status…")
                        .frame(maxWidth: .infinity)
                    Spacer()
                }
                .frame(height: 120)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        myPRsSection
                        if !filteredTeamPRs.isEmpty {
                            Divider().padding(.vertical, 4)
                            teamPRsSection
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 400)
            }
            Divider()
            footer
        }
        .frame(width: 380)
        .task {
            guard viewModel.isStale() else { return }
            await viewModel.refresh(username: username, watchedRepos: watchedRepos)
        }
    }

    private var header: some View {
        HStack {
            Menu {
                Button {
                    selectedRepo = nil
                } label: {
                    if selectedRepo == nil {
                        Label("All Repos", systemImage: "checkmark")
                    } else {
                        Text("All Repos")
                    }
                }
                Divider()
                ForEach(allRepoNames, id: \.self) { repo in
                    Button {
                        selectedRepo = repo
                    } label: {
                        if selectedRepo == repo {
                            Label(repo, systemImage: "checkmark")
                        } else {
                            Text(repo)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedRepo ?? "All Repos")
                        .font(.headline)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
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

            if filteredMyPRs.isEmpty {
                Text("No open PRs")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else if selectedRepo != nil {
                // Filtered to one repo — flat list
                prList(filteredMyPRs)
            } else {
                // All repos — grouped
                groupedPRList(filteredMyPRs)
            }
        }
    }

    private var teamPRsSection: some View {
        DisclosureGroup("Team PRs (\(filteredTeamPRs.count))", isExpanded: $isTeamExpanded) {
            if selectedRepo != nil {
                prList(filteredTeamPRs)
            } else {
                groupedPRList(filteredTeamPRs)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func groupedPRList(_ prs: [PRWithStatus]) -> some View {
        let grouped = Dictionary(grouping: prs, by: \.repoFullName)
        return ForEach(grouped.keys.sorted(), id: \.self) { repo in
            Text(repo)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
            ForEach(grouped[repo]!) { prWithStatus in
                prRow(prWithStatus)
                Divider()
            }
        }
    }

    private func prList(_ prs: [PRWithStatus]) -> some View {
        ForEach(prs) { prWithStatus in
            prRow(prWithStatus)
            Divider()
        }
    }

    private func prRow(_ prWithStatus: PRWithStatus) -> some View {
        PRRowView(
            prWithStatus: prWithStatus,
            onRerun: {
                await viewModel.rerunFailedJobs(for: prWithStatus)
            },
            onUpdateBranch: {
                await viewModel.updateBranch(for: prWithStatus)
            },
            onMerge: {
                await viewModel.mergePullRequest(for: prWithStatus)
            },
            onOpenInGitHub: {
                if let url = URL(string: prWithStatus.pullRequest.htmlUrl) {
                    NSWorkspace.shared.open(url)
                }
            }
        )
    }

    private var footer: some View {
        HStack {
            if let lastRefreshed = viewModel.lastRefreshedAt {
                Text("Updated \(RelativeTimeFormatter.string(for: lastRefreshed))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                Text("Watching \(watchedRepos.count) repos")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button(action: { updater.checkForUpdates() }) {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderless)
            .help("Check for Updates")
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
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
