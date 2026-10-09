import CashlyData
import CashlyMock

struct SampleReport {
    let users: Int
    let transactions: Int

    var lines: [String] { ["PREVIEW users=\(users) transactions=\(transactions)"] }

    @MainActor static func measure() async throws -> SampleReport {
        let database = try await SampleDatabase.make()
        let users = try await database.repositories(for: nil).users.users()
        var count = 0
        for user in users {
            count += try await database.repositories(for: user.id).dashboard
                .load(query: .init()).totalTransactionCount
        }
        return SampleReport(users: users.count, transactions: count)
    }
}
