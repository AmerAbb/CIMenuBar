import SwiftUI

@main
struct CIMenuBarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentPlaceholder(appState: appState)
        } label: {
            Image(systemName: "circle.fill")
                .foregroundStyle(.gray)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct ContentPlaceholder: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack {
            Text("CI Menu Bar")
                .font(.headline)
            Text("Setup coming soon")
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 350)
    }
}
