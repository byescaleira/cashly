import CashlyData
import CashlyDomain
import FeatureCore
import Foundation

@MainActor
enum InsightsFixture {
    static func session(owner: User, friend: User) async throws -> SessionModel {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: nil).users.save(friend)
        let repositories = database.repositories(for: owner.id)
        let month = YearMonth(.now)
        for index in 0..<4 {
            let category = Category(
                id: "c\(index)", user: owner, name: "Categoria \(index)", color: "0099FF",
                icon: "cart")
            try await repositories.categories.save(category)
            for offset in 0...7 {
                let cents: Int64 = offset == 0 ? 50_000 + Int64(index) * 10_000 : 10_000
                try await repositories.transactions.save(
                    Transaction(
                        id: "t\(index)-\(offset)", participants: [], category: category,
                        money: Money(minorUnits: cents),
                        date: month.adding(months: -offset).startDate, summary: "Compra",
                        status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
            }
        }
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        return session
    }
}
