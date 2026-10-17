import CashlyDomain
import FeatureBudgets
import FeatureCategories
import FeatureConverter
import FeatureCore
import FeatureJourney
import FeatureTags
import FeatureTransactions
import FeatureUsers
import SwiftUI

struct RouteScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    @Environment(\.exchangeRates) private var rates
    let route: Route

    @ViewBuilder var body: some View {
        let repositories = session.repositories
        switch route {
        case .addUser(let id):
            ModelHost(
                UserEditorModel(draft: id.map(UserDraft.edit) ?? .new(), users: repositories.users)
            ) { UserEditorScreen() }
        case .addCategory(let id):
            ModelHost(
                CategoryEditorModel(
                    draft: id.map(CategoryDraft.edit) ?? .new(), repositories: repositories)
            ) { CategoryEditorScreen() }
        case .addBudget(let id, let categoryID, let date, let amount):
            ModelHost(
                BudgetEditorModel(
                    draft: budgetDraft(id: id, categoryID: categoryID, date: date, amount: amount),
                    repositories: repositories)
            ) { BudgetEditorScreen() }
        case .addTransaction(let id):
            ModelHost(
                TransactionEditorModel(
                    draft: id.map(TransactionDraft.edit) ?? .new(), repositories: repositories,
                    rates: rates)
            ) { TransactionEditorScreen() }
        case .classifyCapture(let capture):
            ModelHost(
                TransactionEditorModel(
                    draft: .new(
                        capture: capture,
                        category: finance.allCategories.first {
                            $0.id == capture.suggestedCategoryID
                        }),
                    repositories: repositories, capture: capture, rates: rates)
            ) { TransactionEditorScreen() }
        case .addTag(let id):
            ModelHost(
                TagEditorModel(draft: id.map(TagDraft.edit) ?? .new(), repositories: repositories)
            ) { TagEditorScreen() }
        case .budgets:
            ModelHost(GoalsModel(session: session, finance: finance)) { BudgetsScreen() }
        case .shop: ShopScreen()
        case .converter:
            ModelHost(ConverterModel(rates: rates)) { ConverterScreen() }
        case .budgetConflict(let categoryID, let month):
            ModelHost(
                BudgetConflictModel(finance: finance, categoryID: categoryID, month: month)
            ) { BudgetConflictScreen() }
        }
    }

    private func budgetDraft(id: String?, categoryID: String?, date: Date?, amount: Double?)
        -> BudgetDraft
    {
        if let id { return .edit(id: id) }
        if let categoryID,
            let category = finance.allCategories.first(where: { $0.id == categoryID })
        {
            return .new(
                category: category, date: date ?? session.filter.startDate, amount: amount ?? 0)
        }
        return .new(date: date ?? session.filter.startDate)
    }
}
