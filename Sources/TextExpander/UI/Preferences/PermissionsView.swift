import SwiftUI

/// Permissions onboarding and diagnostics view for system Accessibility settings.
public struct PermissionsView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: appState.isAccessibilityTrusted ? "checkmark.seal.fill" : "lock.shield")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 54, height: 54)
                .foregroundColor(appState.isAccessibilityTrusted ? .green : .orange)

            Text(appState.isAccessibilityTrusted ? "Accessibility Access Granted" : "Accessibility Permission Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("TextExpander requires macOS Accessibility permissions to monitor key presses globally across apps (Safari, Chrome, Slack, VS Code, Mail, Notes) and automatically substitute your snippets.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Click 'Open System Settings' below.")
                }
                HStack(spacing: 12) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Enable the toggle for **TextExpander** under Privacy & Security -> Accessibility.")
                }
                HStack(spacing: 12) {
                    Image(systemName: "3.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("TextExpander will automatically detect permission and begin expanding triggers.")
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)

            HStack(spacing: 16) {
                Button("Check Status Again") {
                    appState.checkAccessibilityPermission()
                }
                .buttonStyle(.bordered)

                Button("Open System Settings") {
                    AccessibilityPermission.shared.requestPermission()
                    AccessibilityPermission.shared.openSystemAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .padding(24)
    }
}
