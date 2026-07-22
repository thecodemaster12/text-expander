import Foundation
import AppKit
import CoreGraphics

/// Low-overhead global CGEventTap manager monitoring system-wide keystrokes with zero idle CPU cost.
public final class EventTapManager: @unchecked Sendable {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var wordBuffer = WordBuffer(capacity: 64)
    
    public var onExpansionTriggered: ((Snippet, VariableResolutionResult) -> Void)?
    public var onBufferUpdated: ((String) -> Void)?
    
    private let snippetEngine: SnippetEngine
    private let simulator: KeyboardSimulator

    public init(snippetEngine: SnippetEngine, simulator: KeyboardSimulator = KeyboardSimulator()) {
        self.snippetEngine = snippetEngine
        self.simulator = simulator
    }

    /// Starts global event tap monitoring.
    public func start() {
        guard eventTap == nil else { return }
        guard AccessibilityPermission.shared.isTrusted else {
            print("[TextExpander] Accessibility permission not granted.")
            return
        }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: selfPointer
        ) else {
            print("[TextExpander] Failed to create CGEventTap")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        print("[TextExpander] Global Keyboard CGEventTap successfully started.")
    }

    /// Stops event tap monitoring.
    public func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
            print("[TextExpander] Global Keyboard CGEventTap stopped.")
        }
    }

    /// Internal handler for incoming keyboard event.
    fileprivate func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
                print("[TextExpander] Re-enabled CGEventTap after timeout.")
            }
            return Unmanaged.passUnretained(event)
        }

        guard type == .keyDown else {
            return Unmanaged.passUnretained(event)
        }

        let flags = event.flags

        // Ignore hotkeys with Cmd or Ctrl held down
        if flags.contains(.maskCommand) || flags.contains(.maskControl) {
            wordBuffer.clear()
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Escape Key (0x35) resets buffer
        if keyCode == 0x35 {
            wordBuffer.clear()
            onBufferUpdated?(wordBuffer.currentString)
            return Unmanaged.passUnretained(event)
        }

        // Backspace Key (0x33)
        if keyCode == 0x33 {
            wordBuffer.deleteLast()
            onBufferUpdated?(wordBuffer.currentString)
            return Unmanaged.passUnretained(event)
        }

        // Extract typed unicode character
        var unicharBuffer = [UniChar](repeating: 0, count: 4)
        var actualLength = 0
        event.keyboardGetUnicodeString(maxStringLength: 4, actualStringLength: &actualLength, unicodeString: &unicharBuffer)

        if actualLength > 0 {
            let typedString = String(utf16CodeUnits: unicharBuffer, count: actualLength)
            for char in typedString {
                wordBuffer.append(char)
            }
            onBufferUpdated?(wordBuffer.currentString)

            // Asynchronously evaluate buffer against snippet engine
            let currentBuffer = wordBuffer
            Task {
                if let (snippet, resolution) = await snippetEngine.evaluateBuffer(currentBuffer) {
                    await MainActor.run {
                        self.wordBuffer.clear()
                        self.onBufferUpdated?("")
                        self.simulator.performExpansion(
                            triggerLength: snippet.trigger.count,
                            replacement: resolution.text,
                            cursorOffsetFromEnd: resolution.cursorOffsetFromEnd
                        )
                        self.onExpansionTriggered?(snippet, resolution)
                    }
                }
            }
        }

        return Unmanaged.passUnretained(event)
    }
}

/// C Callback for CGEventTap
private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon = refcon else {
        return Unmanaged.passUnretained(event)
    }
    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
    return manager.handleEvent(proxy: proxy, type: type, event: event)
}
