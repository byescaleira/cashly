extension BudgetConflict {
    public static func detect(in budgets: [Budget]) -> [BudgetConflict] {
        Dictionary(grouping: budgets.filter(\.isConflicted)) {
            PeriodKey(categoryID: $0.category.id, month: $0.month)
        }
        .map { key, values in
            BudgetConflict(
                categoryID: key.categoryID, month: key.month,
                budgets: values.sorted { $0.id < $1.id })
        }
        .sorted { $0.id < $1.id }
    }

    private struct PeriodKey: Hashable {
        let categoryID: String
        let month: YearMonth
    }
}
