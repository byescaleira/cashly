import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureSearch

@MainActor
struct SearchModelTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")

    private func search() async throws -> SearchModel {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let market = Category(
            id: "market", user: owner, name: "Mercado", color: "00FF00", icon: "cart")
        let home = Category(id: "home", user: owner, name: "Casa", color: "0000FF", icon: "house")
        try await repositories.categories.save(market)
        try await repositories.categories.save(home)
        try await repositories.tags.save(
            Tag(id: "trip", user: owner, name: "Viagem", color: "FF0000", icon: "airplane"))
        let months = [202_501, 202_601].compactMap(YearMonth.init(rawValue:))
        for (index, month) in months.enumerated() {
            try await repositories.transactions.save(
                Transaction(
                    id: "feira\(index)", participants: [], category: market,
                    money: Money(minorUnits: 1_000), date: month.startDate,
                    summary: "Feira de sábado", status: .settled, splitMode: nil,
                    splitValue: nil, paymentsPlan: nil))
        }
        try await repositories.transactions.save(
            Transaction(
                id: "aluguel", participants: [], category: home,
                money: Money(minorUnits: 150_000), date: months[1].startDate,
                summary: "Aluguel", status: .settled, splitMode: nil, splitValue: nil,
                paymentsPlan: nil))
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        let finance = FinanceModel(session: session)
        await finance.load()
        return SearchModel(session: session, finance: finance)
    }

    @Test func findsTransactionsInEveryPeriod() async throws {
        let model = try await search()
        model.text = "  feira "
        await model.search(debounce: .zero)
        #expect(Set(model.transactions.map(\.id)) == ["feira0", "feira1"])
        #expect(model.hasResults)
    }

    @Test func matchesCategoryNamesAndTags() async throws {
        let model = try await search()
        model.text = "casa"
        await model.search(debounce: .zero)
        #expect(model.transactions.map(\.id) == ["aluguel"])
        #expect(model.categories.map(\.id) == ["home"])
        model.text = "viag"
        await model.search(debounce: .zero)
        #expect(model.tags.map(\.id) == ["trip"])
        #expect(model.transactions.isEmpty)
    }

    @Test func emptyTextClearsResults() async throws {
        let model = try await search()
        model.text = "feira"
        await model.search(debounce: .zero)
        model.text = " "
        await model.search(debounce: .zero)
        #expect(model.transactions.isEmpty)
        #expect(model.categories.isEmpty)
        #expect(!model.hasResults)
    }
}
