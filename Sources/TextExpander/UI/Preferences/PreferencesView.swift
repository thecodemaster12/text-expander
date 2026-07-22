import SwiftUI

/// Main Preferences Window combining Snippets list/editor, General settings, and Permission status.
public struct PreferencesView: View {
    @ObservedObject var appState: AppState
    @State private var selectedTab: PreferenceTab = .snippets

    public enum PreferenceTab: String, CaseIterable, Identifiable {
        case snippets = "Snippets"
        case general = "General"
        case permissions = "Permissions"

        public var id: String { rawValue }

        public var icon: String {
            switch self {
            case .snippets: return "text.quote"
            case .general: return "gearshape"
            case .permissions: return "shield"
            }
        }
    }

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            // Snippets Tab
            NavigationSplitView {
                SnippetListView(appState: appState)
                    .frame(minWidth: 260, idealWidth: 280)
            } detail: {
                if let selectedID = appState.selectedSnippetID {
                    SnippetDetailView(appState: appState, snippetID: selectedID)
                } else {
                    Text("Select or create a snippet")
                        .foregroundColor(.secondary)
                }
            }
            .tabItem {
                Label(PreferenceTab.snippets.rawValue, systemImage: PreferenceTab.snippets.icon)
            }
            .tag(PreferenceTab.snippets)

            // General Settings Tab
            GeneralSettingsView(appState: appState)
                .tabItem {
                    Label(PreferenceTab.general.rawValue, systemImage: PreferenceTab.general.icon)
                }
                .tag(PreferenceTab.general)

            // Permissions Tab
            PermissionsView(appState: appState)
                .tabItem {
                    Label(PreferenceTab.permissions.rawValue, systemImage: PreferenceTab.permissions.icon)
                }
                .tag(PreferenceTab.permissions)
        }
        .frame(minWidth: 720, minHeight: 480)
    }
}
