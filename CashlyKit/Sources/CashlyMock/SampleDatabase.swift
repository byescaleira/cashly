import CashlyData
import CashlyDomain

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
        let known = Set(try await owner.game.events().map(\.id))
        try await owner.game.record(SampleData.gameEvents().filter { !known.contains($0.id) })
    }
}
