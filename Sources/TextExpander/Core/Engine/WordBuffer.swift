import Foundation

/// High-performance character buffer tracking recent keystrokes to detect typed trigger words.
public struct WordBuffer: Sendable {
    private var buffer: [Character] = []
    private let capacity: Int
    private var isEscapedNext: Bool = false

    /// Creates a WordBuffer with maximum sliding capacity (default 64 characters).
    public init(capacity: Int = 64) {
        self.capacity = max(1, capacity)
    }

    /// Appends a character to the ring buffer sliding window.
    public mutating func append(_ character: Character) {
        // If previous character was backslash escape, skip triggering for this char
        if character == "\\" {
            isEscapedNext = true
            buffer.append(character)
            trimIfNeeded()
            return
        }

        if isEscapedNext {
            isEscapedNext = false
        }

        buffer.append(character)
        trimIfNeeded()
    }

    /// Handles Backspace key press by removing the last character.
    public mutating func deleteLast() {
        if !buffer.isEmpty {
            buffer.removeLast()
        }
        isEscapedNext = false
    }

    /// Resets the buffer to empty state.
    public mutating func clear() {
        buffer.removeAll(keepingCapacity: true)
        isEscapedNext = false
    }

    /// Current buffered content string.
    public var currentString: String {
        String(buffer)
    }

    /// Checks if the current buffer ends with a specific trigger string.
    /// Returns true only if trigger matches and is NOT preceded by an active escape `\`.
    public func matchesTrigger(_ trigger: String, caseSensitive: Bool = false) -> Bool {
        guard !trigger.isEmpty, trigger.count <= buffer.count else { return false }

        let targetBuffer = caseSensitive ? buffer : buffer.map { Character($0.lowercased()) }
        let targetTrigger = caseSensitive ? Array(trigger) : Array(trigger.lowercased())

        let bufferSuffix = targetBuffer.suffix(targetTrigger.count)
        guard Array(bufferSuffix) == targetTrigger else { return false }

        // Check if there is a backslash right before the match
        let matchStartIndex = buffer.count - targetTrigger.count
        if matchStartIndex > 0 && buffer[matchStartIndex - 1] == "\\" {
            return false // Escaped trigger!
        }

        return true
    }

    /// Checks if buffer ends with any registered triggers from an in-memory collection.
    /// Returns the matched snippet and exact trigger length if found.
    public func findMatchingTrigger(in snippets: [String: Snippet]) -> (snippet: Snippet, matchedTrigger: String)? {
        guard !buffer.isEmpty else { return nil }

        // Iterate through all active triggers to match against buffer suffix
        for (_, snippet) in snippets {
            guard snippet.isEnabled else { continue }
            if matchesTrigger(snippet.trigger, caseSensitive: snippet.isCaseSensitive) {
                return (snippet, snippet.trigger)
            }
        }
        return nil
    }

    private mutating func trimIfNeeded() {
        if buffer.count > capacity {
            buffer.removeFirst(buffer.count - capacity)
        }
    }
}
