import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import FeatureGuides
import FeatureMCP
import FeatureSettings
import SwiftUI

public struct MCPSettingsSlot: View {
    @Environment(MCPModel.self) private var mcp: MCPModel?
    @Environment(\.featureFlags) private var flags
    @Environment(\.pro) private var pro

    public init() {}

    public var body: some View {
        if let mcp, flags?.isOn(.mcpServer) != false {
            ClaudeCodeTipView(isConnected: mcp.isEnabled)
            SettingsRow(
                "Claude Code", symbol: "terminal", color: RetroColor.terracotta.color,
                value: pro.lockedValue ?? mcp.overviewValue
            ) {
                SettingsPage("Claude Code") {
                    ProOnly {
                        MCPSettingsSection()
                    }
                    ProShowcaseSection(.claudeCode)
                }
                .environment(mcp)
            }
        }
    }
}

struct MCPImportPresenter: ViewModifier {
    @Environment(MCPModel.self) private var mcp: MCPModel?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.pro) private var pro
    @State private var shown: MCPModel.Prompt?
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .sheet(item: $shown, onDismiss: dismissed) { prompt in
                if let mcp {
                    switch prompt {
                    case .connection(let request):
                        ConnectionApprovalScreen(request: request).environment(mcp)
                    case .importing(let request):
                        ExternalImportScreen(preview: request.preview, source: request.source) {
                            mcp.finish(request.id, imported: $0)
                        }
                    }
                }
            }
            .onChange(of: mcp?.prompt?.id, initial: true) { present() }
            .onChange(of: pro.isPro, initial: true) { mcp?.isPro = $1 }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active: mcp?.resume()
                #if os(iOS)
                    case .background: mcp?.suspend()
                #endif
                default: break
                }
            }
    }

    private func dismissed() {
        isVisible = false
        Task { present() }
    }

    private func present() {
        guard let mcp else { return }
        if isVisible {
            if let visible = shown, !mcp.isOutstanding(visible) { shown = nil }
            return
        }
        guard let prompt = mcp.prompt else { return }
        shown = prompt
        isVisible = true
    }
}
