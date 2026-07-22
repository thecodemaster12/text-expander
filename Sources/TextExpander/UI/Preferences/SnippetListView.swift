import SwiftUI

/// Sidebar snippet list displaying filtered snippets with quick search, tag selector, and item deletion.
public struct SnippetListView: View {
    @ObservedObject var appState: AppState

    public init(appState: AppState) {
        self.appState = appState
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search triggers or text...", text: $appState.searchText)
                    .textFieldStyle(.plain)
                if !appState.searchText.isEmpty {
                    Button(action: { appState.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(8)

            // Tag Filter Selector with horizontal scrollbar
            if !appState.availableTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 6) {
                        FilterTagChip(
                            title: "All",
                            isSelected: appState.selectedTagFilter == nil,
                            action: { appState.selectedTagFilter = nil }
                        )
                        ForEach(appState.availableTags, id: \.self) { tag in
                            FilterTagChip(
                                title: "#\(tag)",
                                isSelected: appState.selectedTagFilter == tag,
                                action: { appState.selectedTagFilter = tag }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .frame(height: 38)
            }

            Divider()

            // Snippet Rows List
            List(selection: $appState.selectedSnippetID) {
                ForEach(appState.filteredSnippets) { snippet in
                    SnippetRowView(snippet: snippet, appState: appState)
                        .tag(snippet.id)
                }
                .onDelete { indexSet in
                    let itemsToDelete = indexSet.map { appState.filteredSnippets[$0] }
                    for item in itemsToDelete {
                        appState.deleteSnippet(id: item.id)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider()

            // Footer bar with dedicated "Create Snippet" button
            HStack {
                Button(action: {
                    _ = appState.createNewSnippet()
                }) {
                    Label("Create Snippet", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)

                Spacer()

                Text("\(appState.filteredSnippets.count) snippets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
        }
    }
}

private struct SnippetRowView: View {
    let snippet: Snippet
    @ObservedObject var appState: AppState

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { snippet.isEnabled },
                set: { _ in appState.toggleSnippetEnabled(id: snippet.id) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(snippet.trigger)
                        .font(.system(.body, design: .monospaced))
                        .fontWeight(.semibold)

                    // Delete 'x' button right next to the title in the list row
                    Button(action: {
                        appState.deleteSnippet(id: snippet.id)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help("Delete snippet")

                    Spacer()

                    if snippet.usageCount > 0 {
                        Text("\(snippet.usageCount)x")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(4)
                    }
                }

                Text(snippet.replacement.replacingOccurrences(of: "\n", with: " ↵ "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct FilterTagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .fixedSize()
    }
}
