# CIMenuBar

A macOS menu bar app that shows your GitHub CI/CD status at a glance. See which PRs are passing, failing, or running — and take action without leaving your desktop.

## Features

- Live CI status for your open PRs across multiple repos
- Color-coded menu bar icon (green/yellow/red/gray)
- Click any PR row to open it on GitHub
- **Re-run failed jobs** directly from the menu bar
- **Update branch** when behind base
- **Merge** when all checks pass and branch is up to date
- macOS notifications when checks complete or a rebase is needed
- Auto-refreshes every 60 seconds, shows cached data instantly on open
- Auto-updates via Sparkle

## Setup

### 1. Create a GitHub Personal Access Token

Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens) and create a token with these scopes:

- **`repo`** — read access to your repositories and PRs
- **`actions`** — read access to workflow runs and jobs

### 2. Launch CIMenuBar

On first launch, the app will prompt you to:

1. **Paste your token** — it's stored securely in your macOS Keychain
2. **Pick repos to watch** — select which repositories to monitor

That's it. The menu bar icon will turn green/yellow/red based on your PR statuses.

## Install

### From GitHub Releases

Download the latest `CIMenuBar.zip` from [Releases](https://github.com/AmerAbb/CIMenuBar/releases), unzip, and move `CIMenuBar.app` to your Desktop or Applications folder.

The app checks for updates automatically and can be updated from the menu bar.

### Build from source

Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open CIMenuBar.xcodeproj
```

## Release

Releases are automated via GitHub Actions. To cut a new release:

```bash
fastlane release bump:patch   # 0.1.0 → 0.1.1
fastlane release bump:minor   # 0.1.0 → 0.2.0
fastlane release bump:major   # 0.1.0 → 1.0.0
```

This bumps the version in `project.yml`, commits, tags, and pushes. GitHub Actions builds the app, signs the Sparkle appcast, and publishes the release.
