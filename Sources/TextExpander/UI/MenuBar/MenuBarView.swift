import SwiftUI

/// Menu Bar status popup menu view for quick control, app state check, and preferences access.
public struct MenuBarView: View {
    @ObservedObject var appState: AppState
    public let openPreferencesAction: () -> Void

    public init(appState: AppState, openPreferencesAction: @escaping () -> Void) {
        self.appState = appState
        self.openPreferencesAction = openPreferencesAction
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                AppStatusIndicator(
                    isTrusted: appState.isAccessibilityTrusted,
                    isGloballyEnabled: appState.isGloballyEnabled
                )
                Spacer()
                Text("\(appState.snippets.filter(\.isEnabled).count) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)

            if !appState.isAccessibilityTrusted {
                Button(action: {
                    AccessibilityPermission.shared.requestPermission()
                    AccessibilityPermission.shared.openSystemAccessibilitySettings()
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Grant Accessibility Access")
                    }
                    .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
            }

            Divider()

            Toggle(isOn: $appState.isGloballyEnabled) {
                Label(appState.isGloballyEnabled ? "Expansion Active" : "Expansion Paused",
                      systemImage: appState.isGloballyEnabled ? "bolt.fill" : "bolt.slash")
            }
            .toggleStyle(.switch)

            if let notice = appState.lastExpansionNotice {
                Text(notice)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }

            Divider()

            Button(action: openPreferencesAction) {
                Label("Manage Snippets & Settings...", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)

            Divider()

            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit TextExpander", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
        .frame(width: 240)
    }
}
