import CashlyDomain
import FeatureCore
import Observation

@MainActor @Observable
public final class BudgetConflictModel {
    public private(set) var conflict: BudgetConflict?
    public private(set) var isLoading = true
    public private(set) var isSaving = false
    public var error: CashlyError?
    @ObservationIgnored private let finance: FinanceModel
    @ObservationIgnored private let categoryID: String
    @ObservationIgnored private let month: YearMonth

    public init(finance: FinanceModel, categoryID: String, month: YearMonth) {
        self.finance = finance
        self.categoryID = categoryID
        self.month = month
    }

    public var isLocked: Bool { isLoading || isSaving }

    public func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            conflict = try await finance.budgetConflict(categoryID: categoryID, month: month)
        } catch {
            self.error = error as? CashlyError ?? .onFetch
        }
    }

    public func keep(_ budget: Budget) async -> Bool {
        isSaving = true
        defer { isSaving = false }
        do {
            try await finance.resolveBudgetConflict(keeping: budget.id)
            return true
        } catch {
            self.error = error as? CashlyError ?? .onSave
            return false
        }
    }
}
