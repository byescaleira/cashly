import CashlyDomain
import FeatureCore
import SwiftUI

struct SpreadsheetImportScreen: View {
    @Environment(SpreadsheetImportModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var model = model
        GuideSheet(
            index: model.step.rawValue, count: SpreadsheetImportModel.Step.allCases.count,
            isWorking: model.isWorking, back: back, primary: primary, secondary: secondary
        ) {
            switch model.step {
            case .format: FormatStep()
            case .file: FileStep()
            case .review: ReviewStep()
            case .done: DoneStep()
            }
        }
        .fileImporter(
            isPresented: $model.isPickingFile,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text]
        ) { result in
            Task { await model.read(result) }
        }
        .errorAlert($model.error)
    }

    private var back: (() -> Void)? {
        guard model.canGoBack else { return nil }
        return { model.back() }
    }

    private var primary: GuideAction {
        switch model.step {
        case .format: GuideAction("Continuar") { model.step = .file }
        case .file: GuideAction("Escolher arquivo") { model.isPickingFile = true }
        case .review:
            GuideAction(
                "Importar \(model.preview?.rows.count ?? 0) transações", isEnabled: model.canImport
            ) {
                Task { await model.importRows() }
            }
        case .done: GuideAction("Concluir") { dismiss() }
        }
    }

    private var secondary: GuideAction? {
        switch model.step {
        case .format: GuideAction("Agora não") { dismiss() }
        case .review:
            model.isExternal
                ? GuideAction("Recusar") { dismiss() }
                : GuideAction("Escolher outro arquivo") { model.isPickingFile = true }
        case .file, .done: nil
        }
    }
}

private struct FormatStep: View {
    var body: some View {
        GuidePage(
            .illustrationSpreadsheet, title: "Monte sua planilha",
            message:
                "Uma linha por transação. Data, Descrição e Valor são obrigatórias; o resto é opcional."
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ColumnRow(name: "Data", detail: "2026-10-05 ou 05/10/2026")
                ColumnRow(name: "Descrição", detail: "Supermercado")
                ColumnRow(name: "Valor", detail: "1.234,56")
                ColumnRow(name: "Categoria", detail: "Criada se não existir")
                ColumnRow(name: "Tipo", detail: "Entrada ou Saída")
                ColumnRow(name: "Situação", detail: "Paga, A pagar ou A receber")
                ColumnRow(name: "Parcelas e Tags", detail: "3 · Viagem, Casa")
            }
            .padding(16)
            .background(.subtleFill, in: .rect(cornerRadius: 20))
            ShareLink(item: TemplateFile.url) {
                Label("Baixar modelo", systemImage: "arrow.down.doc")
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

private struct ColumnRow: View {
    let name: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(name).font(.subheadline.weight(.bold))
            Spacer(minLength: 12)
            Text(detail).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(
                .trailing)
        }
    }
}

private struct FileStep: View {
    var body: some View {
        GuidePage(
            .illustrationSearch, title: "Escolha o arquivo",
            message:
                "Salve a planilha como CSV, separada por ponto e vírgula ou vírgula, e escolha o arquivo no app Arquivos. A planilha exportada pelo Cashly também funciona."
        )
    }
}

private struct ReviewStep: View {
    @Environment(SpreadsheetImportModel.self) private var model

    var body: some View {
        let preview = model.preview
        let valid = preview?.rows.count ?? 0
        let issues = preview?.issues ?? []
        GuidePage(.illustrationReview, title: "Confira os dados", message: "\(model.fileName)") {
            VStack(alignment: .leading, spacing: 10) {
                SummaryRow(
                    symbol: "checkmark.circle.fill", color: .positive,
                    text: "\(valid) transações prontas")
                if let preview, valid > 0 {
                    SummaryRow(
                        symbol: "arrow.down.circle.fill", color: .positive,
                        text: "Entradas: \(preview.income.doubleValue.formatted(.appCurrency))")
                    SummaryRow(
                        symbol: "arrow.up.circle.fill", color: .negative,
                        text: "Saídas: \(preview.expenses.doubleValue.formatted(.appCurrency))")
                }
                if !model.newCategories.isEmpty {
                    SummaryRow(
                        symbol: "folder.badge.plus", color: .info,
                        text: "Novas categorias: \(model.newCategories.joined(separator: ", "))")
                }
                if !model.newTags.isEmpty {
                    SummaryRow(
                        symbol: "tag.fill", color: .info,
                        text: "Novas tags: \(model.newTags.joined(separator: ", "))")
                }
                ForEach(issues.prefix(3)) { issue in
                    SummaryRow(
                        symbol: "xmark.circle.fill", color: .negative,
                        text: "Linha \(issue.line): \(issue.message)")
                }
                if issues.count > 3 {
                    SummaryRow(
                        symbol: "ellipsis.circle.fill", color: .negative,
                        text: "Mais \(issues.count - 3) linhas com problema ficarão de fora.")
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.subtleFill, in: .rect(cornerRadius: 20))
        }
    }
}

private struct SummaryRow: View {
    let symbol: String
    let color: Color
    let text: String

    var body: some View {
        Label {
            Text(text).font(.subheadline)
        } icon: {
            Image(systemName: symbol).foregroundStyle(color)
        }
    }
}

private struct DoneStep: View {
    @Environment(SpreadsheetImportModel.self) private var model

    var body: some View {
        GuidePage(
            title: "Importação concluída",
            message: "\(model.imported) transações foram adicionadas ao Cashly."
        ) {
            GuideSymbol("checkmark.circle.fill")
        }
    }
}

private enum TemplateFile {
    static var url: URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "modelo-cashly.csv")
        try? Data(SpreadsheetParser.template.utf8).write(to: url, options: .atomic)
        return url
    }
}
