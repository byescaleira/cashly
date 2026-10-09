import CashlyDomain
import FeatureCore

extension FinanceModel {
    func category(id: String) -> CashlyDomain.Category {
        allCategories.first { $0.id == id }
            ?? CashlyDomain.Category(
                id: id, user: User(id: "", name: "", photo: ""), name: "Categoria indisponível",
                color: "808080", icon: "questionmark")
    }

    func usage(of budget: Budget) -> BudgetUsage {
        BudgetUsage(spent: expensesAmount(for: budget), budgeted: budget.money.doubleValue)
    }
}
