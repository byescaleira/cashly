import CashlyData
import CashlyDomain
import FeatureCore
import FeatureDashboard
import Foundation
import Testing

@MainActor
struct DashboardModelTests {
    private let owner = User(id: "owner", name: "Perfil")

    private func dashboard(
        defaults: UserDefaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
    )
        async throws -> (DashboardModel, FinanceModel)
    {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let market = Category(
            id: "market", user: owner, name: "Mercado", color: "00FF00", icon: "cart")
        let home = Category(id: "home", user: owner, name: "Casa", color: "0000FF", icon: "house")
        try await repositories.categories.save(market)
        try await repositories.categories.save(home)
        try await repositories.tags.save(
            Tag(id: "trip", user: owner, name: "viagem", color: "FF0000", icon: "airplane"))
        let month = try #require(YearMonth(rawValue: 202_601))
        try await repositories.budgets.save(
            Budget(
                id: "b", money: Money(minorUnits: 100_000), category: market, month: month,
                summary: "Mês"))
        try await repositories.transactions.save(
            Transaction(
                id: "t", participants: [], category: market, money: Money(minorUnits: 25_000),
                date: month.startDate, summary: "Feira", status: .settled, splitMode: nil,
                splitValue: nil, paymentsPlan: nil, tagIDs: ["trip"]))
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        session.filter.startDate = month.startDate
        let finance = FinanceModel(session: session)
        await finance.load()
        return (DashboardModel(session: session, finance: finance, defaults: defaults), finance)
    }

    @Test func topSpendingCarriesShareOfExpenses() async throws {
        let (dashboard, _) = try await dashboard()
        let item = try #require(dashboard.topSpending.first)
        #expect(item.summary == "Feira")
        #expect(item.amount == 250)
        #expect(item.share == 1)
        #expect(dashboard.topSpendingShare == 1)
    }

    @Test func availabilityUsesThePeriod() async throws {
        let (dashboard, finance) = try await dashboard()
        let market = try #require(finance.categories.first { $0.id == "market" })
        let availability = dashboard.availability(of: market)
        #expect(availability.budgeted == 1000)
        #expect(availability.available == 750)
        #expect(availability.remainingRatio == 0.75)
        #expect(dashboard.totalAvailable == 750)
    }

    @Test func shopSpotlightHidesUntilNextMonth() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let (dashboard, _) = try await dashboard(defaults: defaults)
        let october = try #require(YearMonth(rawValue: 202_610)).startDate.addingTimeInterval(
            86_400 * 14)
        let november = try #require(YearMonth(rawValue: 202_611)).startDate.addingTimeInterval(
            86_400 * 14)
        #expect(dashboard.shopSpotlight(owned: [], on: october) == .iconsHalloween)
        #expect(dashboard.shopSpotlight(owned: [.iconsHalloween], on: october) != .iconsHalloween)
        dashboard.hideShopSpotlight(on: october)
        #expect(dashboard.shopSpotlight(owned: [], on: october) == nil)
        #expect(dashboard.shopSpotlight(owned: [], on: november) != nil)
        let (reopened, _) = try await self.dashboard(defaults: defaults)
        #expect(reopened.shopSpotlight(owned: [], on: october) == nil)
    }
}
