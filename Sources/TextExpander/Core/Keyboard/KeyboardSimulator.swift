import Foundation
import AppKit
import CoreGraphics

/// Low-level keyboard event simulator for trigger deletion and text expansion injection.
public final class KeyboardSimulator: Sendable {
    public init() {}

    /// Performs text replacement by deleting trigger count characters and typing/pasting replacement text.
    /// - Parameters:
    ///   - triggerLength: Number of characters in trigger to erase with backspaces.
    ///   - replacement: Expanded string to insert.
    ///   - cursorOffsetFromEnd: Optional number of left-arrow steps to position cursor.
    public func performExpansion(triggerLength: Int, replacement: String, cursorOffsetFromEnd: Int? = nil) {
        guard triggerLength > 0 else { return }

        // Step 1: Send backspaces to delete trigger
        sendBackspaces(count: triggerLength)

        // Give system slight pause to process backspaces
        usleep(10_000) // 10ms

        // Step 2: Inject replacement text
        // Use clipboard + Cmd+V for multiline or long replacements for instant performance
        if replacement.contains("\n") || replacement.count > 20 {
            pasteText(replacement)
        } else {
            typeText(replacement)
        }

        // Step 3: Position cursor if offset specified
        if let offset = cursorOffsetFromEnd, offset > 0 {
            usleep(15_000) // 15ms
            sendLeftArrows(count: offset)
        }
    }

    /// Simulates pressing the Backspace key `count` times.
    public func sendBackspaces(count: Int) {
        let backspaceKeyCode: CGKeyCode = 0x33 // kVK_Delete
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<count {
            postKeyEvent(keyCode: backspaceKeyCode, keyDown: true, source: source)
            postKeyEvent(keyCode: backspaceKeyCode, keyDown: false, source: source)
            usleep(2_000) // 2ms per key press
        }
    }

    /// Simulates Left Arrow key presses to position cursor.
    public func sendLeftArrows(count: Int) {
        let leftArrowKeyCode: CGKeyCode = 0x7B // kVK_LeftArrow
        let source = CGEventSource(stateID: .hidSystemState)
        for _ in 0..<count {
            postKeyEvent(keyCode: leftArrowKeyCode, keyDown: true, source: source)
            postKeyEvent(keyCode: leftArrowKeyCode, keyDown: false, source: source)
            usleep(2_000)
        }
    }

    /// Types plain text by generating Unicode key events.
    private func typeText(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)
        for char in text.utf16 {
            var charCode = char
            if let eventDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true) {
                eventDown.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charCode)
                eventDown.post(tap: .cghidEventTap)
            }
            if let eventUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) {
                eventUp.keyboardSetUnicodeString(stringLength: 1, unicodeString: &charCode)
                eventUp.post(tap: .cghidEventTap)
            }
            usleep(1_500)
        }
    }

    /// Inserts text via Pasteboard clipboard injection and simulated Cmd+V.
    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let ourChangeCount = pasteboard.changeCount

        // Simulate Command + V keypress
        let vKeyCode: CGKeyCode = 0x09 // kVK_ANSI_V
        let source = CGEventSource(stateID: .hidSystemState)

        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }

        // Restore previous pasteboard contents asynchronously after short delay, but only if
        // nothing else (e.g. the user copying something new) has touched the pasteboard since
        // we set our replacement text — otherwise we'd clobber their newer clipboard content.
        if let previous = previousContent {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                guard NSPasteboard.general.changeCount == ourChangeCount else { return }
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(previous, forType: .string)
            }
        }
    }

    private func postKeyEvent(keyCode: CGKeyCode, keyDown: Bool, source: CGEventSource? = nil) {
        let source = source ?? CGEventSource(stateID: .hidSystemState)
        if let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown) {
            event.post(tap: .cghidEventTap)
        }
    }
}
