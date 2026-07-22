import SwiftUI

/// App status indicator badge displaying Active, Paused, or Accessibility Permission Warning status.
public struct AppStatusIndicator: View {
    public let isTrusted: Bool
    public let isGloballyEnabled: Bool

    public init(isTrusted: Bool, isGloballyEnabled: Bool) {
        self.isTrusted = isTrusted
        self.isGloballyEnabled = isGloballyEnabled
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusTitle)
                .font(.callout)
                .fontWeight(.medium)
        }
    }

    private var statusColor: Color {
        if !isTrusted {
            return .red
        } else if !isGloballyEnabled {
            return .orange
        } else {
            return .green
        }
    }

    private var statusTitle: String {
        if !isTrusted {
            return "Needs Accessibility Permission"
        } else if !isGloballyEnabled {
            return "Expansion Paused"
        } else {
            return "Expansion Active"
        }
    }
}
