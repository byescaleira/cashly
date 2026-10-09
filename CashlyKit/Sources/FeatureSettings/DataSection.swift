import SwiftUI

struct DataSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        Section {
            Button("Exportar backup", systemImage: "square.and.arrow.up") {
                Task { await data.prepareExport() }
            }
            .fileExporter(
                isPresented: $data.isExporting, document: data.document,
                contentType: .json, defaultFilename: data.fileName, onCompletion: data.finishExport)
            Button("Importar backup", systemImage: "square.and.arrow.down") {
                data.isImporting = true
            }
            .confirmationDialog(
                "Importar backup?", isPresented: $data.isConfirmingRestore,
                titleVisibility: .visible, presenting: data.pendingRestore
            ) { backup in
                Button("Importar") { Task { await data.restore(backup) } }
            } message: { backup in
                Text(data.description(of: backup))
            }
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
            if data.isWorking { ProgressView() }
        } header: {
            Text("Dados")
        } footer: {
            Text(
                "O backup é um arquivo com usuários, categorias, tags, orçamentos e transações. Importar adiciona os registros do arquivo aos que já estão no aparelho."
            )
        }
        .disabled(data.isWorking)
        .fileImporter(
            isPresented: $data.isImporting, allowedContentTypes: [.json], onCompletion: data.read
        )
        .alert("Dados", isPresented: $data.isShowingMessage) {
        } message: {
            Text(data.message ?? "")
        }
        .alert("Não foi possível concluir", isPresented: $data.isShowingError) {
        } message: {
            Text(data.error?.localizedDescription ?? "")
        }
    }
}
