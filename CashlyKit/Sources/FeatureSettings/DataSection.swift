import SwiftUI

struct DataSection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        @Bindable var data = data
        Group {
            Section {
                Button("Exportar backup", systemImage: "square.and.arrow.up") {
                    Task { await data.prepareExport() }
                }
                Button("Exportar planilha (CSV)", systemImage: "tablecells") {
                    Task { await data.prepareExport(as: .commaSeparatedText) }
                }
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
                if data.isWorking { ProgressView() }
            } header: {
                Text("Dados")
            } footer: {
                Text(
                    "O backup é um arquivo com usuários, categorias, tags, orçamentos e transações. Importar adiciona os registros do arquivo aos que já estão no aparelho. A planilha traz só as transações."
                )
            }
            Section {
                Toggle("Backup automático", isOn: $data.autoBackupToggle)
            } footer: {
                Text(data.autoBackupFooter)
            }
            EraseSection()
        }
        .disabled(data.isWorking)
        .fileExporter(
            isPresented: $data.isExporting, document: data.document,
            contentType: data.exportType, defaultFilename: data.fileName,
            onCompletion: data.finishExport
        )
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
