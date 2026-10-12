import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct DataSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags
    @Environment(\.appTint) private var appTint
    @Environment(\.pro) private var pro

    var body: some View {
        @Bindable var data = data
        Group {
            Section {
                Button {
                    Task { await data.prepareExport() }
                } label: {
                    IconRow("Export Backup", symbol: "square.and.arrow.up", color: appTint)
                }
                Button {
                    Task { await data.prepareExport(as: .commaSeparatedText) }
                } label: {
                    IconRow("Export Spreadsheet (CSV)", symbol: "tablecells", color: .companion)
                }
                Button {
                    pro.perform { data.startBackupImport() }
                } label: {
                    IconRow("Import Backup", symbol: "square.and.arrow.down", color: appTint)
                }
                if let showGuide, flags?.isOn(.spreadsheetImport) != false {
                    Button {
                        pro.perform { showGuide(.importSpreadsheet) }
                    } label: {
                        IconRow(
                            "Import Spreadsheet (CSV)", symbol: "tablecells.badge.ellipsis",
                            color: .companion)
                    }
                }
                if data.isWorking { ProgressView() }
            } header: {
                Text("Export and Import")
            } footer: {
                Text(
                    "A backup is a file with users, categories, tags, budgets and transactions. Importing adds the file's records to the ones already on this device. The spreadsheet has transactions only."
                )
            }
            BackupScheduleSection()
            BackupCloudSection()
            SavedBackupsSection()
            EraseSection()
        }
        .disabled(data.isWorking)
        .fileExporter(
            isPresented: $data.isExporting, document: data.document,
            contentType: data.exportType, defaultFilename: data.fileName,
            onCompletion: data.finishExport
        )
        .sheet(isPresented: $data.isRestoringBackup) { BackupImportScreen().environment(data) }
        .dataAlerts()
        .task { await data.loadBackups() }
    }
}

struct DataAlerts: ViewModifier {
    @Environment(DataModel.self) private var data

    func body(content: Content) -> some View {
        @Bindable var data = data
        content
            .alert("Data", isPresented: $data.isShowingMessage) {
            } message: {
                Text(data.message ?? "")
            }
            .alert("Couldn't complete", isPresented: $data.isShowingError) {
            } message: {
                Text(data.error?.localizedDescription ?? "")
            }
    }
}

extension View {
    func dataAlerts() -> some View {
        modifier(DataAlerts())
    }
}
