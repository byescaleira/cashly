import CashlyDomain
import CashlyPresentation
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
    @Environment(CashlySession.self) private var session
    @Environment(MainViewModel.self) private var main
    let route: MainRoute

    @ViewBuilder var body: some View {
        let factory = session.factory.scoped(to: main.user?.id)
        switch route {
        case .addUser(let id):
            AddUserScreen(draft: id.map(UserDraft.edit) ?? .new(), factory: factory)
        case .addCategory(let id):
            AddCategoryScreen(draft: id.map(CategoryDraft.edit) ?? .new(), factory: factory)
        case .addBudget(let id, let categoryID, let date):
            AddBudgetScreen(
                draft: budgetDraft(id: id, categoryID: categoryID, date: date), factory: factory)
        case .addTransaction(let id):
            AddTransactionScreen(draft: id.map(TransactionDraft.edit) ?? .new(), factory: factory)
        case .addTag(let id): AddTagScreen(draft: id.map(TagDraft.edit) ?? .new(), factory: factory)
        case .detailCategory(let id): DetailCategoryScreen(categoryID: id)
        case .budgetConflict(let categoryID, let month):
            BudgetConflictScreen(categoryID: categoryID, month: month)
        }
    }

    private func budgetDraft(id: String?, categoryID: String?, date: Date?) -> BudgetDraft {
        if let id { return .edit(id: id) }
        if let categoryID, let category = main.allCategories.first(where: { $0.id == categoryID }) {
            return .new(category: category, date: date ?? main.filter.startDate)
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
