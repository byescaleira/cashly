import CashlyDesignSystem
import CashlyDomain
import SwiftUI

#if canImport(UIKit)
    import UIKit
#else
    import AppKit
#endif

public struct MCPSettingsSection: View {
    @Environment(MCPModel.self) private var mcp
    @Environment(\.appTint) private var appTint
    @State private var copied = false

    public init() {}

    public var body: some View {
        @Bindable var mcp = mcp
        Section {
            Toggle("Allow Access from Claude Code", isOn: $mcp.isEnabled)
                .tint(.positive)
            if mcp.isEnabled {
                Toggle("Accept Local Network Connections", isOn: $mcp.allowsLocalNetwork)
                    .tint(.positive)
                LabeledContent("Status", value: status)
                Button {
                    copy(mcp.command)
                    copied = true
                } label: {
                    IconRow(
                        copied ? "Command Copied" : "Copy Install Command",
                        symbol: copied ? "checkmark" : "doc.on.doc", color: appTint)
                }
                Button {
                    mcp.regenerateToken()
                    copied = false
                } label: {
                    IconRow(
                        "Generate New Token", symbol: "arrow.triangle.2.circlepath",
                        color: .companion)
                }
            }
        } header: {
            Text("Claude Code")
        } footer: {
            Text(footer)
        }
        if mcp.isEnabled, !mcp.trusted.isEmpty {
            Section {
                ForEach(mcp.trusted, id: \.self) { key in
                    LabeledContent(key) {
                        Button("Remove", systemImage: "xmark.circle", role: .destructive) {
                            mcp.revoke(key)
                        }
                        .labelStyle(.iconOnly)
                    }
                }
            } header: {
                Text("Allowed Connections")
            } footer: {
                Text("A removed connection needs to be approved again the next time it connects.")
            }
        }
    }

    private var footer: String {
        let reach =
            mcp.allowsLocalNetwork
            ? String(
                appLocalized:
                    "Computers on the same network reach this device at \(mcp.host):\(String(mcp.port))."
            )
            : String(appLocalized: "Only this device can reach the server.")
        return
            String(
                appLocalized:
                    "While Cashly is open, Claude Code reads your data and sends transactions. \(reach) Every new connection asks for your approval here, and every submission is reviewed before it's saved. A new token disconnects everyone."
            )
    }

    private var status: String {
        switch mcp.state {
        case .off: String(appLocalized: "Off")
        case .starting: String(appLocalized: "Starting")
        case .ready: String(appLocalized: "Ready")
        case .failed(let message): String(appLocalized: "Error: \(message)")
        }
    }

    private func copy(_ text: String) {
        #if canImport(UIKit)
            UIPasteboard.general.string = text
        #else
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}
