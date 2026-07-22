import Foundation
import AppKit

/// Result of expanding dynamic variables within a snippet replacement string.
public struct VariableResolutionResult: Sendable, Equatable {
    /// The final expanded text string.
    public let text: String
    /// Number of steps from the end of the text to place the cursor if {{cursor}} marker was present.
    public let cursorOffsetFromEnd: Int?
}

/// Dynamic variable expander resolving macros like {{date}}, {{time}}, {{datetime}}, {{clipboard}}, and {{cursor}}.
public final class VariableResolver: Sendable {
    // Compiled once and reused: these patterns are immutable and NSRegularExpression is safe
    // for concurrent matching, so sharing them across resolve() calls (and threads) is safe.
    // Every expansion used to pay for recompiling all three patterns even when the template
    // contained none of these macros.
    private static let datetimeRegex = try! NSRegularExpression(pattern: #"\{\{datetime(?::([^}]+))?\}\}"#)
    private static let dateRegex = try! NSRegularExpression(pattern: #"\{\{date(?::([^}]+))?\}\}"#)
    private static let timeRegex = try! NSRegularExpression(pattern: #"\{\{time(?::([^}]+))?\}\}"#)

    public init() {}

    /// Resolves all variable placeholders inside a snippet replacement string.
    /// - Parameters:
    ///   - template: The replacement template containing optional macro tags.
    ///   - context: Environment context (date, clipboard contents).
    /// - Returns: Resolution result containing processed text and target cursor position offset.
    public func resolve(template: String, context: ExpansionContext = ExpansionContext()) -> VariableResolutionResult {
        var processed = template

        // 1. Resolve {{datetime}} and {{datetime:FORMAT}} (default: "dd-MMM-yy hh:mm a" -> e.g. "01-Jan-26 12:30 PM")
        if processed.contains("{{datetime") {
            processed = Self.applyDateMacro(Self.datetimeRegex, to: processed, defaultFormat: "dd-MMM-yy hh:mm a", date: context.date)
        }

        // 2. Resolve {{date}} and {{date:FORMAT}} (default: "dd-MMM-yy" -> e.g. "01-Jan-26")
        if processed.contains("{{date") {
            processed = Self.applyDateMacro(Self.dateRegex, to: processed, defaultFormat: "dd-MMM-yy", date: context.date)
        }

        // 3. Resolve {{time}} and {{time:FORMAT}} (default: "hh:mm a" -> e.g. "12:30 PM")
        if processed.contains("{{time") {
            processed = Self.applyDateMacro(Self.timeRegex, to: processed, defaultFormat: "hh:mm a", date: context.date)
        }

        // 4. Resolve {{clipboard}} (only touch the pasteboard if the template actually needs it)
        if processed.contains("{{clipboard}}") {
            let clipboardText = context.clipboardText ?? NSPasteboard.general.string(forType: .string) ?? ""
            processed = processed.replacingOccurrences(of: "{{clipboard}}", with: clipboardText)
        }

        // 5. Resolve {{cursor}} position indicator
        var cursorOffset: Int? = nil
        if let cursorRange = processed.range(of: "{{cursor}}") {
            let offsetFromEnd = processed.distance(from: cursorRange.upperBound, to: processed.endIndex)
            cursorOffset = offsetFromEnd
            processed.removeSubrange(cursorRange)
        }

        return VariableResolutionResult(text: processed, cursorOffsetFromEnd: cursorOffset)
    }

    private static func applyDateMacro(_ regex: NSRegularExpression, to text: String, defaultFormat: String, date: Date) -> String {
        var processed = text
        let matches = regex.matches(in: processed, options: [], range: NSRange(location: 0, length: processed.utf16.count)).reversed()
        for match in matches {
            let fullRange = Range(match.range, in: processed)!
            var formatString = defaultFormat
            if match.numberOfRanges > 1, let formatRange = Range(match.range(at: 1), in: processed) {
                formatString = String(processed[formatRange])
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = formatString
            let formattedValue = formatter.string(from: date)
            processed.replaceSubrange(fullRange, with: formattedValue)
        }
        return processed
    }
}
