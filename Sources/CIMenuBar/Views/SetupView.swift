import SwiftUI

struct SetupView: View {
    @ObservedObject var viewModel: SetupViewModel
    @ObservedObject var appState: AppState

    var body: some View {
        VStack(spacing: 16) {
            Text("CI Menu Bar Setup")
                .font(.headline)

            switch viewModel.step {
            case .token:
                tokenStep
            case .repos:
                repoStep
            }
        }
        .padding()
        .frame(width: 350)
    }

    private var tokenStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paste your GitHub Personal Access Token.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Needs **repo** and **actions** scopes.")
                .font(.caption)
                .foregroundStyle(.secondary)

            SecureField("ghp_...", text: $viewModel.tokenInput)
                .textFieldStyle(.roundedBorder)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button(action: {
                Task { await viewModel.validateTokenAndFetchRepos() }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text("Connect")
                }
            }
            .disabled(!viewModel.canProceedFromTokenStep || viewModel.isLoading)
        }
    }

    private var repoStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome, **\(viewModel.usernameResult)**!")
                .font(.subheadline)
            Text("Pick the repos you want to watch:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RepoPickerView(
                repos: viewModel.availableRepos,
                selectedRepoIds: viewModel.selectedRepos,
                onToggle: { viewModel.toggleRepo($0) }
            )

            Button("Done") {
                viewModel.completeSetup(appState: appState)
            }
            .disabled(viewModel.selectedRepos.isEmpty)
        }
    }
}
