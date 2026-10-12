import CashlyDesignSystem
import CashlyDomain
import CashlyMCP
import FeatureCore
import SwiftUI

public struct ConnectionApprovalScreen: View {
    @Environment(MCPModel.self) private var mcp
    private let request: MCPModel.ConnectionRequest

    public init(request: MCPModel.ConnectionRequest) {
        self.request = request
    }

    public var body: some View {
        GuideSheet(
            index: 0, count: 1,
            primary: GuideAction("Allow") { mcp.answer(request.id, allow: true) },
            secondary: GuideAction("Decline") { mcp.answer(request.id, allow: false) }
        ) {
            GuidePage(
                title: "Connect Claude Code?",
                message:
                    "\(request.client.name) \(request.client.version) at \(request.client.address) wants to read your Cashly data and send transactions. You still review every submission."
            ) {
                CashlyAnimationView(.connect)
            } content: {
                GuideFeatureList {
                    GuideFeature(
                        title: request.client.name,
                        detail: request.client.address + " · "
                            + String(appLocalized: "version \(request.client.version)"))
                    GuideFeature(
                        title: String(appLocalized: "Read Data"), color: .retroTeal)
                    GuideFeature(
                        title: String(appLocalized: "Send Transactions"), color: .retroOrange)
                }
            }
        }
        .interactiveDismissDisabled()
        .onDisappear { mcp.answer(request.id, allow: false) }
    }
}
