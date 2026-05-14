//
//  CreateTransactionIntent.swift
//  Cashly
//
//  Siri intent that creates a transaction directly from a spoken
//  utterance — no app UI required. The utterance is parsed by the
//  same Apple Intelligence / keyword pipeline used in-app, then
//  persisted via TransactionUseCase. Category is resolved by fuzzy
//  matching against the user's existing categories.
//
//  If any required field is missing the transaction is saved with
//  needsReview = true and Siri tells the user to check the app.
//

import AppIntents
import CashlyDomain
import CashlyResource

struct CreateTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Cashly Transaction"
    static let description = IntentDescription(
        "Create a transaction in Cashly from a spoken description."
    )
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Description")
    var utterance: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let deps = SiriTransactionDependencies.shared else {
            return .result(dialog: "Cashly is not ready. Please open the app first.")
        }

        let draft = await deps.transactionDictation.parse(utterance)

        let categories = (try? await deps.categoryUseCase.getCategories()) ?? []
        let budgets = (try? await deps.budgetUseCase.getBudgets()) ?? []

        let matchedCategory: CashlyDomain.Category? = {
            guard let name = draft.categoryName else { return nil }
            return CashlyFuzzyMatch.bestMatch(
                for: name,
                in: categories,
                key: { $0.name }
            )
        }()

        let category = matchedCategory ?? categories.first
        guard let category else {
            return .result(dialog: "No categories found. Open Cashly and create one first.")
        }

        let amount = draft.amount ?? 0
        let summary = draft.summary ?? utterance
        let kind = draft.kind ?? .expense
        let date = draft.date ?? .now
        let budget = budgets.first(where: { $0.category.id == category.id })
        let needsReview = draft.needsReview || matchedCategory == nil

        try await deps.transactionUseCase.addTransaction(
            id: UUID().uuidString,
            participants: [],
            budget: budget,
            amount: amount,
            date: date.timeIntervalSince1970,
            summary: summary,
            status: .settled,
            splitMode: nil,
            splitValue: nil,
            paymentsPlan: nil,
            kind: kind,
            needsReview: needsReview,
            category: category,
            attachmentPath: nil
        )

        let formattedAmount = CashlyCurrency.format(amount)
        if needsReview {
            return .result(
                dialog: "Registered \(formattedAmount) in \(category.name). Needs review — check in Cashly."
            )
        }
        return .result(
            dialog: "Done! \(formattedAmount) in \(category.name) — \(summary)."
        )
    }
}
