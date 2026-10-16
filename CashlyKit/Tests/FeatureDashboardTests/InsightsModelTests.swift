import CashlyData
import CashlyDomain
import FeatureCore
import FeatureDashboard
import Foundation
import Testing

@MainActor
struct InsightsModelTests {
    private let owner = User(id: "owner", name: "Perfil")
    private let friend = User(id: "friend", name: "Amigo")

    private func session() async throws -> SessionModel {
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
            for offset in 0...6 {
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

    @Test func unusualShowsTheThreeBiggestGapsInOrder() async throws {
        let insights = InsightsModel(
            session: try await session(),
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        #expect(insights.unusual.map(\.name) == ["Categoria 3", "Categoria 2", "Categoria 1"])
        #expect(insights.unusual.first?.current == 800)
        #expect(insights.unusual.first?.typical == 100)
    }

    @Test func expectedCategoryHidesAndStaysHiddenForTheProfile() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let session = try await session()
        let insights = InsightsModel(session: session, defaults: defaults)
        await insights.load()
        let first = try #require(insights.unusual.first)
        insights.markExpected(first)
        #expect(insights.unusual.map(\.name) == ["Categoria 2", "Categoria 1", "Categoria 0"])
        let reopened = InsightsModel(session: session, defaults: defaults)
        await reopened.load()
        #expect(!reopened.unusual.contains(first))
        #expect(InsightFeedbackStore(defaults: defaults).feedback(for: friend.id).expected.isEmpty)
    }
}
