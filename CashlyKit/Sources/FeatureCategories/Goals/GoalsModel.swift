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
            case .category(let category): "Apagar \(category.name)?"
            case .budget(let budget): "Apagar orçamento de \(budget.category.name)?"
            }
        }

        var message: String {
            switch self {
            case .category: "A categoria e os orçamentos dela serão apagados."
            case .budget: "Só o orçamento é apagado; as transações continuam."
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

    public func caption(for category: CashlyDomain.Category) -> String {
        let planned = finance.budgetsAmount(for: category)
        return planned > 0 ? "Orçamento de \(planned.formatted(.appCurrency))" : "Sem orçamento"
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
