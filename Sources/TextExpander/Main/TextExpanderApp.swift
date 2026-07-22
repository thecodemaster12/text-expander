import SwiftUI

@main
struct TextExpanderApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.openWindow) private var openWindow

    init() {
        // Run as lightweight menu bar application
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        // Menu Bar extra dropdown interface
        MenuBarExtra("TextExpander", systemImage: appState.isGloballyEnabled ? "bolt.fill" : "bolt.slash") {
            MenuBarView(appState: appState) {
                openPreferencesWindow()
            }
        }
        .menuBarExtraStyle(.window)

        // Main Preferences Window
        Window("TextExpander Preferences", id: "preferences") {
            PreferencesView(appState: appState)
                .onAppear {
                    NSApp.activate(ignoringOtherApps: true)
                }
        }
        .windowResizability(.contentSize)
    }

    private func openPreferencesWindow() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "preferences")
        NSApp.activate(ignoringOtherApps: true)
    }
}
