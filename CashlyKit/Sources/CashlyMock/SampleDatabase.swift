import CashlyData
import CashlyDomain
import Foundation

public enum SampleDatabase {
    public static func make(seeded: Bool = true) async throws -> CashlyDatabase {
        let database = try CashlyDatabase.open(inMemory: true)
        if seeded { try await seed(database) }
        return database
    }

    public static func seed(_ database: CashlyDatabase) async throws {
        let users = database.repositories(for: nil).users
        for user in SampleData.users {
            try await users.save(user)
        }
        let owner = database.repositories(for: SampleData.owner.id)
        for category in SampleData.categories {
            try await owner.categories.save(category)
        }
        for budget in SampleData.budgets {
            try await owner.budgets.save(budget)
        }
        for tag in SampleData.tags {
            try await owner.tags.save(tag)
        }
        for transaction in SampleData.transactions {
            try await owner.transactions.save(transaction)
        }
        try await recordGameEvents(owner)
    }

    public static func seedShowcase(_ database: CashlyDatabase, today: Date = .now) async throws {
        let users = database.repositories(for: nil).users
        for user in SampleData.users {
            try await users.save(user)
        }
        let owner = database.repositories(for: SampleData.owner.id)
        for category in SampleData.showcaseCategories {
            try await owner.categories.save(category)
        }
        for tag in SampleData.tags {
            try await owner.tags.save(tag)
        }
        for budget in SampleData.showcaseBudgets(today: today) {
            try await owner.budgets.save(budget)
        }
        for transaction in SampleData.showcaseTransactions(today: today) {
            try await owner.transactions.save(transaction)
        }
        try await recordGameEvents(owner)
    }

    private static func recordGameEvents(_ owner: Repositories) async throws {
        let known = Set(try await owner.game.events().map(\.id))
        try await owner.game.record(SampleData.gameEvents().filter { !known.contains($0.id) })
    }
}
