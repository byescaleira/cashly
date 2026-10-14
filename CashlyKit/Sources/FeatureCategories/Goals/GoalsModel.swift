import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class GoalsModel {
    public enum Deletion: Identifiable, Equatable {
        case category(CashlyDomain.Category)
        case budget(Budget)

        public var id: String {
            switch self {
            case .category(let category): "category-" + category.id
            case .budget(let budget): "budget-" + budget.id
            }
        }

        var title: String {
            switch self {
            case .category(let category): String(appLocalized: "Delete \(category.name)?")
            case .budget(let budget):
                String(appLocalized: "Delete the \(budget.category.name) budget?")
            }
        }

        var message: String {
            switch self {
            case .category: String(appLocalized: "The category and its budgets will be deleted.")
            case .budget: String(appLocalized: "Only the budget is deleted; the transactions stay.")
            }
        }
    }

    public var deletion: Deletion?
    public var error: CashlyError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let finance: FinanceModel

    public init(session: SessionModel, finance: FinanceModel) {
        self.session = session
        self.finance = finance
    }

    public var overview: BudgetOverview {
        BudgetOverview(
            items: finance.budgets.map {
                BudgetProgress(
                    budget: $0, planned: $0.money.doubleValue,
                    spent: finance.expensesAmount(for: $0))
            },
            totalSpent: finance.expensesAmount, month: session.filter.month)
    }

    public var categories: [CashlyDomain.Category] {
        finance.categories.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public var hasBudgets: Bool { !finance.budgets.isEmpty }

    public var isShowingEmptyBudgets: Bool {
        !hasBudgets && !finance.categories.isEmpty && !finance.isLoading
    }

    public var canCreateBudget: Bool { !finance.categories.isEmpty && !finance.isLoading }

    public var periodTitle: String { session.filter.periodTitle }

    public var newBudgetRoute: Route {
        .addBudget(id: nil, categoryID: nil, date: session.filter.startDate)
    }

    public func budgetRoute(for category: CashlyDomain.Category) -> Route {
        .addBudget(id: nil, categoryID: category.id, date: session.filter.startDate)
    }

    public func caption(for category: CashlyDomain.Category) -> String {
        let planned = finance.budgetsAmount(for: category)
        return planned > 0
            ? String(appLocalized: "\(planned.formatted(.appCurrency)) planned")
            : String(appLocalized: "No budget")
    }

    public var isConfirmingDeletion: Bool {
        get { deletion != nil }
        set { if !newValue { deletion = nil } }
    }

    public func confirmDeletion() async {
        guard let deletion else { return }
        self.deletion = nil
        do {
            switch deletion {
            case .category(let category):
                try await session.repositories.categories.delete(id: category.id)
            case .budget(let budget):
                try await session.repositories.budgets.delete(id: budget.id)
            }
            session.reload()
        } catch {
            self.error = error as? CashlyError ?? .onSave
        }
    }
}
