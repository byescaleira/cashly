import SwiftUI

struct EraseSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        Section {
            Button("Apagar todos os dados", systemImage: "trash", role: .destructive) {
                data.isConfirmingErase = true
            }
            .foregroundStyle(Color.red)
            .confirmationDialog(
                "Apagar todos os dados?", isPresented: $data.isConfirmingErase,
                titleVisibility: .visible
            ) {
                Button("Apagar tudo", role: .destructive) { Task { await data.eraseAll() } }
            } message: {
                Text(
                    "Usuários, categorias, tags, orçamentos, transações e modelos de inteligência serão apagados. Com o iCloud ligado, os dados também saem dos seus outros aparelhos. Não é possível desfazer."
                )
            }
        }
    }
}
