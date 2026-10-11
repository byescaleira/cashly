import CashlyDesignSystem
import SwiftUI

#if canImport(UIKit)
    import UIKit
#else
    import AppKit
#endif

public struct MCPSettingsSection: View {
    @Environment(MCPModel.self) private var mcp
    @State private var copied = false

    public init() {}

    public var body: some View {
        @Bindable var mcp = mcp
        Section {
            Toggle("Permitir acesso pelo Claude Code", isOn: $mcp.isEnabled)
                .tint(.positive)
            if mcp.isEnabled {
                LabeledContent("Situação", value: status)
                Button(
                    copied ? "Comando copiado" : "Copiar comando de instalação",
                    systemImage: copied ? "checkmark" : "doc.on.doc"
                ) {
                    copy(mcp.command)
                    copied = true
                }
                Button("Gerar novo token", systemImage: "arrow.triangle.2.circlepath") {
                    mcp.regenerateToken()
                    copied = false
                }
            }
        } header: {
            Text("Claude Code")
        } footer: {
            Text(
                "Com o app aberto, o Claude Code lê seus dados e envia transações pelo endereço 127.0.0.1:\(String(mcp.port)). Toda importação passa pela tela de conferência antes de gravar. Cole o comando copiado no Terminal; um token novo desconecta quem usava o anterior."
            )
        }
    }

    private var status: String {
        switch mcp.state {
        case .off: "Desligado"
        case .starting: "Iniciando"
        case .ready: "Pronto"
        case .failed(let message): "Erro: \(message)"
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
