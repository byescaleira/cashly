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
            case .columns: ColumnsStep()
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
        case .format: GuideAction("Continue") { model.step = .columns }
        case .columns: GuideAction("Continue") { model.step = .file }
        case .file: GuideAction("Choose File") { model.isPickingFile = true }
        case .review:
            GuideAction(
                "Import \(model.preview?.rows.count ?? 0) Transactions", isEnabled: model.canImport
            ) {
                Task { await model.importRows() }
            }
        case .done: GuideAction("Done") { dismiss() }
        }
    }

    private var secondary: GuideAction? {
        switch model.step {
        case .format, .columns: GuideAction("Not Now") { dismiss() }
        case .review:
            model.isExternal
                ? GuideAction("Decline") { dismiss() }
                : GuideAction("Choose Another File") { model.isPickingFile = true }
        case .file, .done: nil
        }
    }
}

private struct FormatStep: View {
    var body: some View {
        GuidePage(
            title: "Build Your Spreadsheet",
            message:
                "One row per transaction. \(SpreadsheetTerm.date.title), \(SpreadsheetTerm.summary.title) and \(SpreadsheetTerm.amount.title) are required."
        ) {
            CashlyAnimationView(.table)
        } content: {
            GuideValueList([
                GuideValue(SpreadsheetTerm.date.title, value: "05/10/2026"),
                GuideValue(
                    SpreadsheetTerm.summary.title, value: String(appLocalized: "Supermarket")),
                GuideValue(SpreadsheetTerm.amount.title, value: SpreadsheetTerm.amount(123_456)),
            ])
        }
    }
}

private struct ColumnsStep: View {
    var body: some View {
        GuidePage(
            title: "Optional Columns",
            message: "Add these columns when you have the information. Empty cells are fine."
        ) {
            CashlyAnimationView(.history)
        } content: {
            GuideValueList([
                GuideValue(
                    SpreadsheetTerm.category.title,
                    value: String(appLocalized: "Optional, created if missing")),
                GuideValue(
                    String(appLocalized: "Type and Status"),
                    value: SpreadsheetTerm.expense.title + " · " + SpreadsheetTerm.paid.title),
                GuideValue(
                    String(appLocalized: "Installments and Tags"),
                    value: "3 · " + String(appLocalized: "Trip")),
            ])
            ShareLink(item: TemplateFile.url) {
                Label("Download Template", systemImage: "arrow.down.doc")
                    .font(.buttonLabel)
            }
        }
    }
}

private struct FileStep: View {
    var body: some View {
        GuidePage(
            title: "Choose the File",
            message:
                "Save the spreadsheet as CSV, separated by semicolons or commas, and choose the file in the Files app. The spreadsheet exported by Cashly works too."
        ) {
            CashlyAnimationView(.file)
        }
    }
}

private struct ReviewStep: View {
    @Environment(SpreadsheetImportModel.self) private var model

    var body: some View {
        let preview = model.preview
        let issues = preview?.issues ?? []
        GuidePage(title: "Review the Data", message: "\(model.fileName)") {
            CashlyAnimationView(.table)
        } content: {
            if let preview {
                GuideValueList([
                    GuideValue(
                        String(appLocalized: "Transactions ready"),
                        value: preview.rows.count.formatted(.number.locale(.app))),
                    GuideValue(
                        String(appLocalized: "Money in"),
                        value: preview.income.doubleValue.formatted(.appCurrency),
                        color: .positive),
                    GuideValue(
                        String(appLocalized: "Money out"),
                        value: preview.expenses.doubleValue.formatted(.appCurrency),
                        color: .negative),
                ])
            }
            if !model.newCategories.isEmpty || !model.newTags.isEmpty || !issues.isEmpty {
                GuideFeatureList {
                    if !model.newCategories.isEmpty {
                        GuideFeature(
                            title: String(appLocalized: "New categories"),
                            detail: model.newCategories.joined(separator: ", "))
                    }
                    if !model.newTags.isEmpty {
                        GuideFeature(
                            title: String(appLocalized: "New tags"),
                            detail: model.newTags.joined(separator: ", "))
                    }
                    if !issues.isEmpty {
                        GuideFeature(
                            title: String(appLocalized: "\(issues.count) rows left out"),
                            detail: issues.prefix(3).map {
                                String(appLocalized: "Row \($0.line): \($0.message)")
                            }
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
            title: "Import Complete",
            message: "\(model.imported) transactions were added to Cashly."
        ) {
            CashlyAnimationView(.done)
        }
    }
}

private enum TemplateFile {
    static var url: URL {
        let url = FileManager.default.temporaryDirectory.appending(
            path: String(appLocalized: "cashly-template") + ".csv")
        try? Data(SpreadsheetParser.template.utf8).write(to: url, options: .atomic)
        return url
    }
}
