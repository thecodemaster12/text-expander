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
    public init() {}

    /// Resolves all variable placeholders inside a snippet replacement string.
    /// - Parameters:
    ///   - template: The replacement template containing optional macro tags.
    ///   - context: Environment context (date, clipboard contents).
    /// - Returns: Resolution result containing processed text and target cursor position offset.
    public func resolve(template: String, context: ExpansionContext = ExpansionContext()) -> VariableResolutionResult {
        var processed = template

        // 1. Resolve {{datetime}} and {{datetime:FORMAT}} (default: "dd-MMM-yy hh:mm a" -> e.g. "01-Jan-26 12:30 PM")
        let datetimeRegex = try? NSRegularExpression(pattern: #"\{\{datetime(?::([^}]+))?\}\}"#, options: [])
        if let matches = datetimeRegex?.matches(in: processed, options: [], range: NSRange(location: 0, length: processed.utf16.count)).reversed() {
            for match in matches {
                let fullRange = Range(match.range, in: processed)!
                var formatString = "dd-MMM-yy hh:mm a"
                if match.numberOfRanges > 1, let formatRange = Range(match.range(at: 1), in: processed) {
                    formatString = String(processed[formatRange])
                }
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = formatString
                let formattedValue = formatter.string(from: context.date)
                processed.replaceSubrange(fullRange, with: formattedValue)
            }
        }

        // 2. Resolve {{date}} and {{date:FORMAT}} (default: "dd-MMM-yy" -> e.g. "01-Jan-26")
        let dateRegex = try? NSRegularExpression(pattern: #"\{\{date(?::([^}]+))?\}\}"#, options: [])
        if let matches = dateRegex?.matches(in: processed, options: [], range: NSRange(location: 0, length: processed.utf16.count)).reversed() {
            for match in matches {
                let fullRange = Range(match.range, in: processed)!
                var formatString = "dd-MMM-yy"
                if match.numberOfRanges > 1, let formatRange = Range(match.range(at: 1), in: processed) {
                    formatString = String(processed[formatRange])
                }
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = formatString
                let formattedDate = formatter.string(from: context.date)
                processed.replaceSubrange(fullRange, with: formattedDate)
            }
        }

        // 3. Resolve {{time}} and {{time:FORMAT}} (default: "hh:mm a" -> e.g. "12:30 PM")
        let timeRegex = try? NSRegularExpression(pattern: #"\{\{time(?::([^}]+))?\}\}"#, options: [])
        if let matches = timeRegex?.matches(in: processed, options: [], range: NSRange(location: 0, length: processed.utf16.count)).reversed() {
            for match in matches {
                let fullRange = Range(match.range, in: processed)!
                var formatString = "hh:mm a"
                if match.numberOfRanges > 1, let formatRange = Range(match.range(at: 1), in: processed) {
                    formatString = String(processed[formatRange])
                }
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = formatString
                let formattedTime = formatter.string(from: context.date)
                processed.replaceSubrange(fullRange, with: formattedTime)
            }
        }

        // 4. Resolve {{clipboard}}
        let clipboardText = context.clipboardText ?? NSPasteboard.general.string(forType: .string) ?? ""
        processed = processed.replacingOccurrences(of: "{{clipboard}}", with: clipboardText)

        // 5. Resolve {{cursor}} position indicator
        var cursorOffset: Int? = nil
        if let cursorRange = processed.range(of: "{{cursor}}") {
            let offsetFromEnd = processed.distance(from: cursorRange.upperBound, to: processed.endIndex)
            cursorOffset = offsetFromEnd
            processed.removeSubrange(cursorRange)
        }

        return VariableResolutionResult(text: processed, cursorOffsetFromEnd: cursorOffset)
    }
}
