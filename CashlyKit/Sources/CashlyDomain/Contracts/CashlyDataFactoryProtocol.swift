import Foundation

public protocol CashlyDataFactoryProtocol: Sendable {
    var userID: String? { get }
    func scoped(to userID: String?) -> any CashlyDataFactoryProtocol
    func makeDashboardUseCase() -> any DashboardUseCase
    func makeDataChangeUseCase() -> any DataChangeUseCase
    func makeSnapshotUseCase() -> any SnapshotUseCase
    func makeBudgetUseCase() -> BudgetUseCase
    func makeCategoryUseCase() -> CategoryUseCase
    func makeUserUseCase() -> UserUseCase
    func makeTransactionUseCase() -> TransactionUseCase
    func makeTagUseCase() -> TagUseCase
}
