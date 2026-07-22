import SwiftUI
import AppKit

/// General preferences tab managing launch at login, backup/restore, JSON import/export, and app status.
public struct GeneralSettingsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var launchManager = LaunchManager.shared
    @State private var backupStatusMessage: String?

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        Form {
            Section("General Settings") {
                Toggle("Launch TextExpander automatically at login", isOn: Binding(
                    get: { launchManager.isEnabledAtLogin },
                    set: { launchManager.setLaunchAtLogin($0) }
                ))

                Toggle("Global Text Expansion Enabled", isOn: $appState.isGloballyEnabled)
            }

            Section("Data & Backup Operations") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Backup Snippets")
                            .fontWeight(.medium)
                        Text("Save a timestamped backup copy to App Support")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Create Backup") {
                        do {
                            let url = try appState.createBackup()
                            backupStatusMessage = "Created backup at \(url.lastPathComponent)"
                        } catch {
                            backupStatusMessage = "Backup failed: \(error.localizedDescription)"
                        }
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Export Snippets to JSON")
                            .fontWeight(.medium)
                        Text("Save all snippets to a file for backup or sharing")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Export JSON...") {
                        exportSnippetsFileDialog()
                    }
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text("Import Snippets from JSON")
                            .fontWeight(.medium)
                        Text("Merge or replace snippets from a JSON file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Import JSON...") {
                        importSnippetsFileDialog()
                    }
                }

                if let message = backupStatusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            Section("Statistics & System") {
                LabeledContent("Total Snippets", value: "\(appState.snippets.count)")
                LabeledContent("Active Enabled Snippets", value: "\(appState.snippets.filter(\.isEnabled).count)")
                LabeledContent("Total Expansion Count", value: "\(appState.snippets.reduce(0) { $0 + $1.usageCount })")
            }
        }
        .formStyle(.grouped)
        .padding(12)
    }

    private func exportSnippetsFileDialog() {
        let panel = NSSavePanel()
        panel.title = "Export Snippets"
        panel.nameFieldStringValue = "snippets_export.json"
        panel.allowedContentTypes = [.json]

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try appState.exportJSONData()
                try data.write(to: url)
                backupStatusMessage = "Exported snippets to \(url.lastPathComponent)"
            } catch {
                backupStatusMessage = "Export failed: \(error.localizedDescription)"
            }
        }
    }

    private func importSnippetsFileDialog() {
        let panel = NSOpenPanel()
        panel.title = "Import Snippets"
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                try appState.importJSONData(data)
                backupStatusMessage = "Successfully imported snippets from \(url.lastPathComponent)"
            } catch {
                backupStatusMessage = "Import failed: \(error.localizedDescription)"
            }
        }
    }
}
