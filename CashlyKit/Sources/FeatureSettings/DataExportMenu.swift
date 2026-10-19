import CashlyDesignSystem
import SwiftUI

public struct DataExportMenu: View {
    @Environment(DataModel.self) private var data

    public init() {}

    public var body: some View {
        @Bindable var data = data
        Menu {
            Button("Backup File (JSON)", systemImage: "doc.badge.arrow.up") {
                Task { await data.prepareExport() }
            }
            Button("Spreadsheet (CSV)", systemImage: "tablecells") {
                Task { await data.prepareExport(as: .commaSeparatedText) }
            }
        } label: {
            Text("Export Data")
        }
        .font(.buttonLabel)
        .buttonStyle(.borderless)
        .menuIndicator(.hidden)
        .disabled(data.isWorking)
        .fileExporter(
            isPresented: $data.isExportingFromPage, document: data.document,
            contentType: data.exportType, defaultFilename: data.fileName,
            onCompletion: { result in Task { await data.finishExport(result) } }
        )
        .dataAlerts()
    }
}
