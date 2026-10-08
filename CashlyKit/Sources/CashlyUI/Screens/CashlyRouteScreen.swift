import CashlyDomain
import CashlyPresentation
import FeatureCore
import SwiftUI

struct CashlySectionScreen: View {
    let section: CashlySection

    @ViewBuilder var body: some View {
        switch section {
        case .intelligence: IntelligenceScreen()
        case .category: CategoryScreen()
        case .home: HomeScreen()
        case .transaction: TransactionScreen()
        }
    }
}

struct CashlyRouteScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(FinanceModel.self) private var finance
    let route: MainRoute

    @ViewBuilder var body: some View {
        let repositories = session.repositories
        switch route {
        case .addUser(let id):
            ModelHost(
                UserEditorModel(draft: id.map(UserDraft.edit) ?? .new(), users: repositories.users)
            ) { AddUserScreen() }
        case .addCategory(let id):
            ModelHost(
                CategoryEditorModel(
                    draft: id.map(CategoryDraft.edit) ?? .new(), repositories: repositories)
            ) { AddCategoryScreen() }
        case .addBudget(let id, let categoryID, let date):
            ModelHost(
                BudgetEditorModel(
                    draft: budgetDraft(id: id, categoryID: categoryID, date: date),
                    repositories: repositories)
            ) { AddBudgetScreen() }
        case .addTransaction(let id):
            ModelHost(
                TransactionEditorModel(
                    draft: id.map(TransactionDraft.edit) ?? .new(), repositories: repositories)
            ) { AddTransactionScreen() }
        case .addTag(let id):
            ModelHost(
                TagEditorModel(draft: id.map(TagDraft.edit) ?? .new(), repositories: repositories)
            ) { AddTagScreen() }
        case .detailCategory(let id): DetailCategoryScreen(categoryID: id)
        case .budgetConflict(let categoryID, let month):
            BudgetConflictScreen(categoryID: categoryID, month: month)
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

struct CashlySheetScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CashlyNavigation.self) private var navigation
    let destination: CashlyNavigation.SheetDestination

    var body: some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.sheetPath) {
            CashlyRouteScreen(route: destination.route)
                .navigationDestination(for: MainRoute.self) { CashlyRouteScreen(route: $0) }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
        .environment(\.navigationSection, destination.section)
        .presentationDetents([.large])
    }
}
