import CashlyData
import CashlyDomain
import FeatureCore
import FeatureReports
import Foundation
import Testing

@MainActor
struct ReportsModelTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")

    private func reports() async throws -> (ReportsModel, FinanceModel) {
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
        let intelligence = IntelligenceModel(
            service: LocalIntelligenceService(
                directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            ),
            session: session)
        return (
            ReportsModel(session: session, finance: finance, intelligence: intelligence), finance
        )
    }

    @Test func syncSelectsFirstItemsAndKeepsExistingChoice() async throws {
        let (reports, finance) = try await reports()
        reports.sync()
        #expect(reports.selectedTag?.id == "trip")
        #expect(reports.comparedCategory == finance.categories.first)
        let other = try #require(finance.categories.last)
        reports.comparedCategory = other
        reports.sync()
        #expect(reports.comparedCategory == other)
    }

    @Test func comparisonUsesThePeriod() async throws {
        let (reports, finance) = try await reports()
        let market = try #require(finance.categories.first { $0.id == "market" })
        reports.comparedCategory = market
        let comparison = reports.comparison
        #expect([comparison.planned, comparison.spent, comparison.ratio] == [1000, 250, 0.25])
    }

    @Test func tagPointsCarryExpenses() async throws {
        let (reports, _) = try await reports()
        reports.sync()
        let point = try #require(reports.tagPoints.first)
        #expect(reports.tagPoints.count == 1)
        #expect([point.id, point.label] == ["trip", "Viagem"])
        #expect(point.amount == 250)
        #expect(reports.selectedTagAmount == 250)
    }

    @Test func forecastNeedsATrainedModel() async throws {
        let (reports, _) = try await reports()
        #expect(!reports.showsForecast)
        #expect(!reports.suggestsTraining)
        await reports.loadForecast()
        #expect(reports.forecast == 0)
    }
}
