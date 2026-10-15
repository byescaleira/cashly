import CashlyDesignSystem
import FeatureCore
import SwiftUI

struct DataSection: View {
    @Environment(DataModel.self) private var data
    @Environment(SessionModel.self) private var session: SessionModel?

    var body: some View {
        @Bindable var data = data
        Group {
            DataSummarySection()
            DataExportSection()
            ProCurtainSection(.backups) {
                BackupScheduleSection()
                BackupCloudSection()
                SavedBackupsSection()
            } preview: {
                BackupPreview()
            }
            ProCurtainSection(.imports) {
                DataImportSection()
            } preview: {
                ImportPreview()
            }
            EraseSection()
        }
        .disabled(data.isWorking)
        .fileExporter(
            isPresented: $data.isExportingFromPage, document: data.document,
            contentType: data.exportType, defaultFilename: data.fileName,
            onCompletion: data.finishExport
        )
        .sheet(isPresented: $data.isRestoringBackup) { BackupImportScreen().environment(data) }
        .dataAlerts()
        .task(id: session?.user?.id) { await data.load() }
    }
}

private struct DataSummarySection: View {
    @Environment(DataModel.self) private var data

    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                CashlyAnimationView(.backup).frame(maxWidth: 220)
                if let inventory = data.inventory {
                    DataSummary(inventory: inventory)
                } else {
                    ProgressView().frame(minHeight: .rowHeight)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceS)
            .animation(.smooth, value: data.inventory)
        }
    }
}

private struct DataSummary: View {
    @Environment(\.appTint) private var appTint
    let inventory: DataInventory

    var body: some View {
        VStack(spacing: .spaceM) {
            VStack(spacing: .space2XS) {
                Text("Transactions").font(.subheadline).foregroundStyle(.secondary)
                FigureValue(
                    inventory.transactionsValue, numeric: Double(inventory.transactions),
                    color: appTint)
                Text(verbatim: inventory.summaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .combine)
            ViewThatFits {
                HStack(spacing: .spaceS) { chips }
                FlowLayout(spacing: .spaceS) { chips }
            }
        }
    }

    @ViewBuilder private var chips: some View {
        ForEach(inventory.otherKinds, id: \.self) { kind in
            Chip(inventory.chip(kind), color: inventory.count(kind) > 0 ? .companion : .secondary)
        }
    }
}

private struct DataExportSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            Button {
                Task { await data.prepareExport() }
            } label: {
                IconRow(
                    "Backup File (JSON)", detail: "Everything, ready to import into Cashly.",
                    symbol: "doc.badge.arrow.up", color: appTint)
            }
            Button {
                Task { await data.prepareExport(as: .commaSeparatedText) }
            } label: {
                IconRow(
                    "Spreadsheet (CSV)", detail: "Transactions only, for Numbers, Excel or Sheets.",
                    symbol: "tablecells", color: .companion)
            }
        } header: {
            Text("Export").sectionTitle()
        } footer: {
            Text("Exporting is always free. You choose where the file goes.")
        }
    }
}

private struct DataImportSection: View {
    @Environment(DataModel.self) private var data
    @Environment(\.showGuide) private var showGuide
    @Environment(\.featureFlags) private var flags

    var body: some View {
        Section {
            Button {
                data.startBackupImport()
            } label: {
                ImportBackupLabel()
            }
            if let showGuide, flags?.isOn(.spreadsheetImport) != false {
                Button {
                    showGuide(.importSpreadsheet)
                } label: {
                    ImportSpreadsheetLabel()
                }
            }
        } header: {
            Text("Import").sectionTitle()
        }
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

private struct BackupPreview: View {
    var body: some View {
        VStack(spacing: .spaceM) {
            Toggle(isOn: .constant(true)) { AutoBackupLabel() }.tint(.positive)
            Toggle(isOn: .constant(false)) { CloudBackupLabel() }.tint(.positive)
        }
    }
}

private struct ImportPreview: View {
    var body: some View {
        VStack(spacing: .spaceM) {
            ImportBackupLabel()
            ImportSpreadsheetLabel()
        }
    }
}

private struct ImportBackupLabel: View {
    @Environment(\.appTint) private var appTint

    var body: some View {
        IconRow(
            "Import Backup", detail: "See what's new in the file before anything changes.",
            symbol: "square.and.arrow.down", color: appTint)
    }
}

private struct ImportSpreadsheetLabel: View {
    var body: some View {
        IconRow(
            "Import Spreadsheet (CSV)", detail: "Bring transactions from your bank or another app.",
            symbol: "tablecells.badge.ellipsis", color: .companion)
    }
}
