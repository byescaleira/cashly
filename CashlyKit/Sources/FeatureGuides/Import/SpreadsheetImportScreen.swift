import CashlyDesignSystem
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
            title: "Monte sua planilha",
            message: "Uma linha por transação. Data, Descrição e Valor são obrigatórias."
        ) {
            SpreadsheetExample()
        } content: {
            GuideValueList([
                GuideValue("Data", value: "05/10/2026"),
                GuideValue("Descrição", value: "Supermercado"),
                GuideValue("Valor", value: "1.234,56"),
                GuideValue("Categoria", value: "Opcional, criada se faltar"),
                GuideValue("Tipo e Situação", value: "Saída · Paga"),
                GuideValue("Parcelas e Tags", value: "3 · Viagem"),
            ])
            ShareLink(item: TemplateFile.url) {
                Label("Baixar modelo", systemImage: "arrow.down.doc")
                    .font(.buttonLabel)
            }
        }
    }
}

private struct FileStep: View {
    var body: some View {
        GuidePage(
            title: "Escolha o arquivo",
            message:
                "Salve a planilha como CSV, separada por ponto e vírgula ou vírgula, e escolha o arquivo no app Arquivos. A planilha exportada pelo Cashly também funciona."
        ) {
            ExampleFile("extrato-outubro.csv", detail: "Separado por ponto e vírgula", kind: "CSV")
        }
    }
}

private struct ReviewStep: View {
    @Environment(SpreadsheetImportModel.self) private var model

    var body: some View {
        let preview = model.preview
        let issues = preview?.issues ?? []
        GuidePage(title: "Confira os dados", message: "\(model.fileName)") {
            if let rows = preview?.rows.prefix(3), !rows.isEmpty {
                GuideExample {
                    ForEach(rows, id: \.self) { row in
                        ExampleRow(
                            row.summary,
                            detail:
                                "\(row.category) · \(row.date.formatted(date: .abbreviated, time: .omitted))",
                            value: row.money.doubleValue.formatted(.appCurrency),
                            valueColor: row.kind == .income ? .positive : .primary)
                    }
                }
            }
        } content: {
            if let preview {
                GuideValueList([
                    GuideValue("Transações prontas", value: preview.rows.count.formatted()),
                    GuideValue(
                        "Entradas", value: preview.income.doubleValue.formatted(.appCurrency),
                        color: .positive),
                    GuideValue(
                        "Saídas", value: preview.expenses.doubleValue.formatted(.appCurrency),
                        color: .negative),
                ])
            }
            if !model.newCategories.isEmpty || !model.newTags.isEmpty || !issues.isEmpty {
                GuideFeatureList {
                    if !model.newCategories.isEmpty {
                        GuideFeature(
                            title: "Categorias novas",
                            detail: model.newCategories.joined(separator: ", "))
                    }
                    if !model.newTags.isEmpty {
                        GuideFeature(
                            title: "Tags novas",
                            detail: model.newTags.joined(separator: ", "))
                    }
                    if !issues.isEmpty {
                        GuideFeature(
                            title: issues.count == 1
                                ? "1 linha fica de fora" : "\(issues.count) linhas ficam de fora",
                            detail: issues.prefix(3).map { "Linha \($0.line): \($0.message)" }
                                .joined(separator: "\n"),
                            color: .warning)
                    }
                }
            }
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
            ExampleDone(value: model.imported.formatted(), detail: "transações importadas")
        }
    }
}

private struct SpreadsheetExample: View {
    private let rows: [(String, String, String)] = [
        ("05/10", "Mercado", "312,40"), ("06/10", "Corrida", "24,90"),
        ("07/10", "Salário", "6.500,00"),
    ]

    var body: some View {
        GuideExample {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Data")
                    Text("Descrição")
                    Text("Valor").gridColumnAlignment(.trailing)
                }
                .font(.chipLabel)
                .foregroundStyle(Color.retroTeal)
                Divider()
                ForEach(rows, id: \.0) { date, summary, value in
                    GridRow {
                        Text(date).foregroundStyle(.secondary)
                        Text(summary)
                        Text(value).fontWeight(.semibold)
                    }
                    .font(.subheadline.monospacedDigit())
                }
            }
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
