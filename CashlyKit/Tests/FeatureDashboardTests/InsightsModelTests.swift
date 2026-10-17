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

    @Test func changesLeaveOutCategoriesAlreadyOutOfTheOrdinary() async throws {
        let insights = InsightsModel(
            session: try await session(),
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        let unusual = Set(insights.unusual.map(\.name))
        #expect(insights.changes.map(\.name) == ["Categoria 0"])
        #expect(insights.changes.allSatisfy { !unusual.contains($0.name) })
        let change = try #require(insights.changes.first)
        #expect(change.isUp)
        #expect(change.isFrequency == false)
        #expect(change.difference == 400)
    }

    @Test func expectedCategoryDoesNotMoveToWhatChanged() async throws {
        let insights = InsightsModel(
            session: try await session(),
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        insights.markExpected(try #require(insights.unusual.first))
        #expect(insights.changes.isEmpty)
    }

    @Test func merchantsComeFromRepeatedDescriptions() async throws {
        let insights = InsightsModel(
            session: try await session(),
            defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        let merchant = try #require(insights.merchants.first)
        #expect(merchant.name == "Compra")
        #expect(merchant.count >= 8)
    }

    @Test func keptRecurringChargeLeavesForGood() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let session = try await session()
        let category = Category(
            id: "fun", user: owner, name: "Lazer", color: "0099FF", icon: "star")
        try await session.repositories.categories.save(category)
        for offset in 0...4 {
            for (name, cents) in [("Netflix", 3_990), ("Spotify", 2_190)] {
                try await session.repositories.transactions.save(
                    Transaction(
                        id: "\(name)-\(offset)", participants: [], category: category,
                        money: Money(minorUnits: Int64(cents)),
                        date: YearMonth(.now).adding(months: -offset).startDate,
                        summary: name, status: .settled, splitMode: nil, splitValue: nil,
                        paymentsPlan: nil))
            }
        }
        let insights = InsightsModel(session: session, defaults: defaults)
        await insights.load()
        let netflix = try #require(insights.recurrences?.items.first { $0.name == "Netflix" })
        #expect(netflix.monthly == 39.9)
        #expect(!insights.merchants.contains { $0.name == "Netflix" })
        let yearly = insights.recurrences?.yearly
        insights.keep(netflix)
        #expect(insights.recurrences?.items.map(\.name) == ["Spotify"])
        #expect(insights.recurrences?.yearly == yearly)
        let reopened = InsightsModel(session: session, defaults: defaults)
        await reopened.load()
        #expect(reopened.recurrences?.items.map(\.name) == ["Spotify"])
        reopened.keep(try #require(reopened.recurrences?.items.first))
        #expect(reopened.recurrences == nil)
    }

    @Test func budgetIdeasOpenWithTheSuggestionAndHideForGood() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let insights = InsightsModel(session: try await session(), defaults: defaults)
        await insights.load()
        let first = try #require(insights.budgetIdeas.first)
        #expect(insights.budgetIdeas.count == 3)
        #expect(first.suggested == 100)
        #expect(
            first.route
                == .addBudget(
                    id: nil, categoryID: first.categoryID, date: YearMonth(.now).startDate,
                    amount: 100))
        insights.hide(first)
        #expect(insights.budgetIdeas.count == 3)
        #expect(!insights.budgetIdeas.contains(first))
    }

    @Test func endingsShowWhenAPlanEnds() async throws {
        let session = try await session()
        let category = Category(
            id: "home", user: owner, name: "Casa", color: "0099FF", icon: "house")
        try await session.repositories.categories.save(category)
        try await session.repositories.transactions.save(
            Transaction(
                id: "sofa", participants: [], category: category, money: Money(minorUnits: 60_000),
                date: YearMonth(.now).startDate, summary: "Sofá", status: .settled,
                splitMode: nil, splitValue: nil, paymentsPlan: 2))
        let insights = InsightsModel(
            session: session, defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        let ending = try #require(insights.endings.first)
        #expect(ending.month == YearMonth(.now).adding(months: 2))
        #expect(ending.freed == 300)
    }

    @Test func recurringBandsLeaveRepeatPurchases() async throws {
        let session = try await session()
        let category = Category(
            id: "apps", user: owner, name: "Apps", color: "0099FF", icon: "app")
        try await session.repositories.categories.save(category)
        for offset in 0...3 {
            for (index, cents) in [990, 3_490].enumerated() {
                try await session.repositories.transactions.save(
                    Transaction(
                        id: "apple-\(offset)-\(index)", participants: [], category: category,
                        money: Money(minorUnits: Int64(cents)),
                        date: YearMonth(.now).adding(months: -offset).startDate,
                        summary: "APPLE.COM/BILL", status: .settled, splitMode: nil,
                        splitValue: nil, paymentsPlan: nil))
            }
        }
        let insights = InsightsModel(
            session: session, defaults: UserDefaults(suiteName: UUID().uuidString) ?? .standard)
        await insights.load()
        #expect(insights.recurrences?.items.filter { $0.name == "APPLE.COM/BILL" }.count == 2)
        #expect(!insights.merchants.contains { $0.name == "APPLE.COM/BILL" })
    }
}
