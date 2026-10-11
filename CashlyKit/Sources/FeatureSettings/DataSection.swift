import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct DataSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.showGuide) private var showGuide

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
                    data.startBackupImport()
                }
                if let showGuide {
                    Button("Importar planilha (CSV)", systemImage: "tablecells.badge.ellipsis") {
                        showGuide(.importSpreadsheet)
                    }
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
                    .tint(.positive)
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
        .sheet(isPresented: $data.isRestoringBackup) { BackupImportScreen().environment(data) }
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
