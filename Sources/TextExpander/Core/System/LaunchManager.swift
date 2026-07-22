import Foundation
import ServiceManagement

/// Launch at login manager utilizing macOS SMAppService API.
@MainActor
public final class LaunchManager: ObservableObject {
    public static let shared = LaunchManager()

    @Published public private(set) var isEnabledAtLogin: Bool = false

    private init() {
        checkStatus()
    }

    /// Checks the current launch at login service status.
    public func checkStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            DispatchQueue.main.async {
                self.isEnabledAtLogin = (status == .enabled)
            }
        }
    }

    /// Toggles launch at login state.
    public func setLaunchAtLogin(_ enable: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                checkStatus()
            } catch {
                print("[TextExpander] Failed to set launch at login: \(error)")
            }
        }
    }
}
