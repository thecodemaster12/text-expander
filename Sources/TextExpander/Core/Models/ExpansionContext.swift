import Foundation

/// Contextual data available during dynamic variable expansion.
public struct ExpansionContext: Sendable {
    public let date: Date
    public let clipboardText: String?

    public init(date: Date = Date(), clipboardText: String? = nil) {
        self.date = date
        self.clipboardText = clipboardText
    }
}
