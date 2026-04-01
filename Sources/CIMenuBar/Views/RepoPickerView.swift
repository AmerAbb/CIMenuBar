import SwiftUI

struct RepoPickerView: View {
    let repos: [GitHubRepo]
    let selectedRepoIds: Set<Int>
    let onToggle: (GitHubRepo) -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                ForEach(repos) { repo in
                    Button(action: { onToggle(repo) }) {
                        HStack {
                            Image(systemName: selectedRepoIds.contains(repo.id)
                                  ? "checkmark.circle.fill"
                                  : "circle")
                                .foregroundStyle(selectedRepoIds.contains(repo.id) ? .blue : .secondary)
                            Text(repo.fullName)
                                .font(.system(.body, design: .monospaced))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 200)
    }
}
