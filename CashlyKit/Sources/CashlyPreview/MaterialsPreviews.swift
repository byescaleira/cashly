#if DEBUG
    import CashlyDesignSystem
    import SwiftUI

    private struct CashlyMaterialsPreview: View {
        var body: some View {
            VStack(spacing: .spaceXL) {
                Text("Informação")
                    .font(.headline)
                HStack(spacing: .spaceL) {
                    Text("OUTUBRO")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                        .padding(.spaceM)
                        .contentSurface(tint: .blue.opacity(.opacityTint), in: .capsule)
                    Text("EM ABERTO")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                        .padding(.spaceM)
                        .contentSurface(tint: .orange.opacity(.opacityTint), in: .capsule)
                }
                Text("Controles")
                    .font(.headline)
                SurfaceContainer(spacing: .spaceS) {
                    HStack(spacing: .spaceL) {
                        control("slider.horizontal.3", title: "Opções")
                        control("checkmark", title: "Confirmar")
                        control("trash", title: "Excluir").disabled(true)
                    }
                }
                Button("Salvar") {}
                    .prominentButton()
                    .controlSize(.large)
            }
            .padding(.space2XL)
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
