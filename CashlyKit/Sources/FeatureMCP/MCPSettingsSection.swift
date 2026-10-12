import CashlyDesignSystem
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
            Toggle("Permitir acesso pelo Claude Code", isOn: $mcp.isEnabled)
                .tint(.positive)
            if mcp.isEnabled {
                Toggle("Aceitar conexões da rede local", isOn: $mcp.allowsLocalNetwork)
                    .tint(.positive)
                LabeledContent("Situação", value: status)
                Button {
                    copy(mcp.command)
                    copied = true
                } label: {
                    IconRow(
                        copied ? "Comando copiado" : "Copiar comando de instalação",
                        symbol: copied ? "checkmark" : "doc.on.doc", color: appTint)
                }
                Button {
                    mcp.regenerateToken()
                    copied = false
                } label: {
                    IconRow(
                        "Gerar novo token", symbol: "arrow.triangle.2.circlepath",
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
                        Button("Remover", systemImage: "xmark.circle", role: .destructive) {
                            mcp.revoke(key)
                        }
                        .labelStyle(.iconOnly)
                    }
                }
            } header: {
                Text("Conexões permitidas")
            } footer: {
                Text("Uma conexão removida precisa ser aprovada de novo no próximo acesso.")
            }
        }
    }

    private var footer: String {
        let reach =
            mcp.allowsLocalNetwork
            ? "Computadores da mesma rede alcançam este aparelho em \(mcp.host):\(String(mcp.port))."
            : "Só este aparelho alcança o servidor."
        return
            "Com o Cashly aberto, o Claude Code consulta seus dados e envia transações. \(reach) Toda conexão nova pede sua aprovação aqui, e todo envio passa pela conferência antes de gravar. Um token novo desconecta todos."
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
