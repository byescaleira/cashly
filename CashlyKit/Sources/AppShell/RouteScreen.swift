import CashlyDomain
import FeatureBudgets
import FeatureCategories
import FeatureCore
import FeatureTags
import FeatureTransactions
import FeatureUsers
import SwiftUI

struct RouteScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
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
        case .addBudget(let id, let categoryID, let date):
            ModelHost(
                BudgetEditorModel(
                    draft: budgetDraft(id: id, categoryID: categoryID, date: date),
                    repositories: repositories)
            ) { BudgetEditorScreen() }
        case .addTransaction(let id):
            ModelHost(
                TransactionEditorModel(
                    draft: id.map(TransactionDraft.edit) ?? .new(), repositories: repositories)
            ) { TransactionEditorScreen() }
        case .addTag(let id):
            ModelHost(
                TagEditorModel(draft: id.map(TagDraft.edit) ?? .new(), repositories: repositories)
            ) { TagEditorScreen() }
        case .budgets:
            ModelHost(GoalsModel(session: session, finance: finance)) { BudgetsScreen() }
        case .budgetConflict(let categoryID, let month):
            ModelHost(
                BudgetConflictModel(finance: finance, categoryID: categoryID, month: month)
            ) { BudgetConflictScreen() }
        }
    }

    private func budgetDraft(id: String?, categoryID: String?, date: Date?) -> BudgetDraft {
        if let id { return .edit(id: id) }
        if let categoryID,
            let category = finance.allCategories.first(where: { $0.id == categoryID })
        {
            return .new(category: category, date: date ?? session.filter.startDate)
        }
        return .new()
    }
}
