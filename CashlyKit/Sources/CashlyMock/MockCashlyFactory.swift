import CashlyData
import CashlyDomain
import SwiftData

public struct MockCashlyFactory {
    public let dataFactory: CashlyDataFactory

    public init() throws {
        dataFactory = try .make(inMemory: true)
    }

    public func makeModelContext() -> ModelContext {
        ModelContext(dataFactory.modelContainer)
    }

    public func seed() async throws {
        let users = dataFactory.makeUserUseCase()
        for user in SampleData.users {
            try await users.addUser(id: user.id, name: user.name, photo: user.photo)
        }
        let owner = dataFactory.scoped(to: SampleData.owner.id)
        for category in SampleData.categories {
            try await owner.makeCategoryUseCase().addCategory(
                id: category.id, user: category.user.id, name: category.name,
                color: category.color, icon: category.icon)
        }
        for budget in SampleData.budgets {
            try await owner.makeBudgetUseCase().addBudget(
                id: budget.id, money: budget.money, category: budget.category, month: budget.month,
                summary: budget.summary)
        }
        for tag in SampleData.tags {
            try await owner.makeTagUseCase().addTag(
                id: tag.id, user: tag.user.id, name: tag.name, color: tag.color, icon: tag.icon)
        }
        for transaction in SampleData.transactions {
            try await owner.makeTransactionUseCase().addTransaction(
                id: transaction.id, participants: transaction.participants,
                categoryID: transaction.category.id, kind: transaction.kind,
                money: transaction.money, date: transaction.date, summary: transaction.summary,
                status: transaction.status, splitMode: transaction.splitMode,
                splitValue: transaction.splitValue, paymentsPlan: transaction.paymentsPlan,
                tagIDs: transaction.tagIDs)
        }
    }
}
