import CashlyData
import CashlyDomain
import SwiftData

public struct MockCashlyFactory {
    public let dataFactory: CashlyDataFactory
    public init() throws { dataFactory = try .make(inMemory: true) }
    public func makeModelContext() -> ModelContext { ModelContext(dataFactory.modelContainer) }
    public func seed() async throws {
        let users = dataFactory.makeUserUseCase()
        for user in User.mocks {
            try await users.addUser(id: user.id, name: user.name, photo: user.photo)
        }
        for category in CashlyDomain.Category.mocks {
            try await dataFactory.scoped(to: category.user.id).makeCategoryUseCase().addCategory(
                id: category.id, user: category.user.id, name: category.name, color: category.color,
                icon: category.icon)
        }
        for budget in Budget.mocks {
            try await dataFactory.scoped(to: budget.user.id).makeBudgetUseCase().addBudget(
                id: budget.id, amount: budget.amount, category: budget.category, date: budget.date,
                summary: budget.summary)
        }
        for tag in Tag.mocks {
            try await dataFactory.scoped(to: tag.user.id).makeTagUseCase().addTag(
                id: tag.id, user: tag.user.id, name: tag.name, color: tag.color, icon: tag.icon)
        }
        for transaction in CashlyDomain.Transaction.mocks {
            try await dataFactory.scoped(to: transaction.ownerID).makeTransactionUseCase()
                .addTransaction(
                    id: transaction.id, participants: transaction.participants,
                    categoryID: transaction.category.id, kind: transaction.kind,
                    money: transaction.money,
                    date: transaction.date,
                    summary: transaction.summary,
                    status: transaction.status, splitMode: transaction.splitMode,
                    splitValue: transaction.splitValue, paymentsPlan: transaction.paymentsPlan,
                    tagIDs: transaction.tagIDs)
        }
    }
}
