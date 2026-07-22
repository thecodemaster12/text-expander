import SwiftUI

/// Snippet detail view providing comprehensive editing tools, tag management, variable macro helpers, and live resolution preview.
public struct SnippetDetailView: View {
    @ObservedObject var appState: AppState
    let snippetID: UUID

    private let resolver = VariableResolver()

    public init(appState: AppState, snippetID: UUID) {
        self.appState = appState
        self.snippetID = snippetID
    }

    private var snippetBinding: Binding<Snippet>? {
        guard let index = appState.snippets.firstIndex(where: { $0.id == snippetID }) else { return nil }
        return Binding(
            get: { appState.snippets[index] },
            set: { updated in appState.saveSnippet(updated) }
        )
    }

    public var body: some View {
        if let binding = snippetBinding {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header title, delete button & active toggle
                    HStack(spacing: 12) {
                        TextField("Snippet Name", text: binding.label)
                            .font(.title2)
                            .fontWeight(.bold)
                            .textFieldStyle(.plain)

                        Spacer()

                        // Delete button right next to title
                        Button(action: {
                            appState.deleteSnippet(id: snippetID)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                            }
                            .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Delete this snippet")

                        Toggle("Active", isOn: binding.isEnabled)
                            .toggleStyle(.switch)
                    }

                    Divider()

                    // Trigger input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TRIGGER WORD")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack {
                            TextField("e.g. ;email or !addr", text: binding.trigger)
                                .font(.system(.body, design: .monospaced))
                                .textFieldStyle(.roundedBorder)

                            Toggle("Case Sensitive", isOn: binding.isCaseSensitive)
                                .toggleStyle(.checkbox)
                        }
                    }

                    // Replacement text editor
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("REPLACEMENT TEXT")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Supports plain & multiline text")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        TextEditor(text: binding.replacement)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 120)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    }

                    // Dynamic Variable Helpers
                    VStack(alignment: .leading, spacing: 6) {
                        Text("INSERT DYNAMIC MACRO")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            VariablePillView(title: "Date (01-Jan-26)", variableTag: "{{date}}") { macro in
                                binding.replacement.wrappedValue += macro
                            }
                            VariablePillView(title: "Time (12:30 PM)", variableTag: "{{time}}") { macro in
                                binding.replacement.wrappedValue += macro
                            }
                            VariablePillView(title: "Date & Time", variableTag: "{{datetime}}") { macro in
                                binding.replacement.wrappedValue += macro
                            }
                            VariablePillView(title: "Clipboard", variableTag: "{{clipboard}}") { macro in
                                binding.replacement.wrappedValue += macro
                            }
                            VariablePillView(title: "Cursor Position", variableTag: "{{cursor}}") { macro in
                                binding.replacement.wrappedValue += macro
                            }
                        }
                    }

                    // Interactive Tag Management
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TAGS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        TagEditorView(tags: binding.tags)
                    }

                    Divider()

                    // Live Expansion Preview
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LIVE RESOLVED PREVIEW")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        let resolved = resolver.resolve(template: binding.replacement.wrappedValue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resolved.text.isEmpty ? "(empty)" : resolved.text)
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)

                            if let offset = resolved.cursorOffsetFromEnd {
                                Text("Cursor will be positioned \(offset) characters from the end.")
                                    .font(.caption2)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .padding(16)
            }
        } else {
            VStack {
                Text("Select a snippet to edit")
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

/// Interactive Tag Editor allowing addition, removal, and pill display of snippet tags.
private struct TagEditorView: View {
    @Binding var tags: [String]
    @State private var newTagText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing Tag Chips Flow
            if !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags, id: \.self) { tag in
                            HStack(spacing: 4) {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Button(action: {
                                    tags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundColor(.accentColor)
                            .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            // Input to add a new tag
            HStack {
                TextField("Add tag (press Enter)...", text: $newTagText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTag()
                    }
                Button(action: addTag) {
                    Label("Add Tag", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !trimmed.isEmpty else { return }
        if !tags.contains(trimmed) {
            tags.append(trimmed)
        }
        newTagText = ""
    }
}
