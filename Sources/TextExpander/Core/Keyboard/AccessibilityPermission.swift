import Foundation
import AppKit

/// System Accessibility Permissions manager checking and prompting for macOS Accessibility trusted status.
public final class AccessibilityPermission: Sendable {
    public static let shared = AccessibilityPermission()

    private init() {}

    /// Checks if app currently has trusted accessibility privileges.
    public var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts system permissions dialog if not already granted.
    public func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    /// Opens macOS System Settings Privacy & Security -> Accessibility page directly.
    @MainActor
    public func openSystemAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
