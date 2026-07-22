import SwiftUI

/// Clickable macro helper pill button for quick variable insertion into replacement template.
public struct VariablePillView: View {
    public let title: String
    public let variableTag: String
    public let action: (String) -> Void

    public init(title: String, variableTag: String, action: @escaping (String) -> Void) {
        self.title = title
        self.variableTag = variableTag
        self.action = action
    }

    public var body: some View {
        Button(action: { action(variableTag) }) {
            HStack(spacing: 4) {
                Image(systemName: "curlybraces")
                    .font(.caption2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.12))
            .foregroundColor(.accentColor)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .help("Insert '\(variableTag)' macro")
    }
}
