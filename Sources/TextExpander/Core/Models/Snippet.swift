import Foundation

/// Represents a single text expansion snippet with trigger, replacement, metadata, and state options.
public struct Snippet: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public var trigger: String
    public var replacement: String
    public var label: String
    public var isEnabled: Bool
    public var isCaseSensitive: Bool
    public var tags: [String]
    public var dateCreated: Date
    public var dateModified: Date
    public var usageCount: Int

    public init(
        id: UUID = UUID(),
        trigger: String,
        replacement: String,
        label: String = "",
        isEnabled: Bool = true,
        isCaseSensitive: Bool = false,
        tags: [String] = [],
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        usageCount: Int = 0
    ) {
        self.id = id
        self.trigger = trigger
        self.replacement = replacement
        self.label = label.isEmpty ? trigger : label
        self.isEnabled = isEnabled
        self.isCaseSensitive = isCaseSensitive
        self.tags = tags
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.usageCount = usageCount
    }

    /// Normalized lookup key based on case-sensitivity configuration.
    public var lookupKey: String {
        isCaseSensitive ? trigger : trigger.lowercased()
    }
}
