import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct DataSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags
    @Environment(\.appTint) private var appTint

    var body: some View {
        @Bindable var data = data
        Group {
            Section {
                Button {
                    Task { await data.prepareExport() }
                } label: {
                    IconRow("Exportar backup", symbol: "square.and.arrow.up", color: appTint)
                }
                Button {
                    Task { await data.prepareExport(as: .commaSeparatedText) }
                } label: {
                    IconRow("Exportar planilha (CSV)", symbol: "tablecells", color: .companion)
                }
                Button {
                    data.startBackupImport()
                } label: {
                    IconRow("Importar backup", symbol: "square.and.arrow.down", color: appTint)
                }
                if let showGuide, flags?.isOn(.spreadsheetImport) != false {
                    Button {
                        showGuide(.importSpreadsheet)
                    } label: {
                        IconRow(
                            "Importar planilha (CSV)", symbol: "tablecells.badge.ellipsis",
                            color: .companion)
                    }
                }
                if data.isWorking { ProgressView() }
            } header: {
                Text("Exportar e importar")
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
