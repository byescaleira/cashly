#if DEBUG
    import CashlyDesignSystem
    import SwiftUI

    private struct CashlyMaterialsPreview: View {
        var body: some View {
            VStack(spacing: 24) {
                Text("Informação")
                    .font(.headline)
                HStack(spacing: 16) {
                    Text("OUTUBRO")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(12)
                        .contentSurface(tint: .blue.opacity(0.2), in: .capsule)
                    Text("EM ABERTO")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(12)
                        .contentSurface(tint: .orange.opacity(0.2), in: .capsule)
                }
                Text("Controles")
                    .font(.headline)
                SurfaceContainer(spacing: 8) {
                    HStack(spacing: 16) {
                        control("slider.horizontal.3", title: "Opções")
                        control("checkmark", title: "Confirmar")
                        control("trash", title: "Excluir").disabled(true)
                    }
                }
                Button("Salvar") {}
                    .prominentButton()
                    .controlSize(.large)
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }

        private func control(_ symbol: String, title: String) -> some View {
            Button {
            } label: {
                Image(systemName: symbol)
                    .font(.headline)
                    .frame(width: 46, height: 46)
                    .surface(in: .circle, interactive: true)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
        }
    }

    #Preview("Materiais — claro") { CashlyMaterialsPreview().preferredColorScheme(.light) }
    #Preview("Materiais — escuro") { CashlyMaterialsPreview().preferredColorScheme(.dark) }
    #Preview("Materiais — controles desativados") {
        CashlyMaterialsPreview().disabled(true)
    }
#endif
