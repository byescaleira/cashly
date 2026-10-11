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
            primary: GuideAction("Permitir") { mcp.answer(request.id, allow: true) },
            secondary: GuideAction("Recusar") { mcp.answer(request.id, allow: false) }
        ) {
            GuidePage(
                title: "Conectar o Claude Code?",
                message:
                    "\(request.client.name) \(request.client.version) em \(request.client.address) quer ler seus dados do Cashly e enviar transações. Cada envio ainda passa pela sua conferência."
            ) {
                GuideExample {
                    ExampleRow(
                        request.client.name, detail: request.client.address,
                        value: request.client.version)
                    HStack(spacing: 6) {
                        ExampleChip("Ler dados", color: .retroTeal)
                        ExampleChip("Enviar transações", color: .retroOrange)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .onDisappear { mcp.answer(request.id, allow: false) }
    }
}
