import CashlyData
import CashlyDomain
import CashlyWeb
import Foundation
import Testing

struct WebSnapshotFixture {
    let owner = User(id: "owner", name: "Dana Teixeira", photo: .initials(color: "2E7D74"))
    let database: CashlyDatabase
    let repositories: Repositories

    init() async throws {
        database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        repositories = database.repositories(for: owner.id)
    }

    static func day(_ value: Int, month: Int = 10, hour: Int = 12) throws -> Date {
        try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: month, day: value, hour: hour)))
    }

    static func month(_ value: Int) throws -> YearMonth {
        try #require(YearMonth(year: 2026, month: value))
    }

    var today: Date {
        get throws { try Self.day(17) }
    }

    @discardableResult
    func category(_ id: String, color: String = "6B7D35", icon: String = "cart") async throws
        -> CashlyDomain.Category
    {
        let category = Category(id: id, user: owner, name: id, color: color, icon: icon)
        try await repositories.categories.save(category)
        return category
    }

    func tag(_ id: String) async throws {
        try await repositories.tags.save(
            Tag(id: id, user: owner, name: id, color: "466A93", icon: "tag"))
    }

    func budget(_ category: CashlyDomain.Category, cents: Int64, month: Int = 10) async throws {
        try await repositories.budgets.save(
            Budget(
                id: "budget-\(category.id)-\(month)", money: Money(minorUnits: cents),
                category: category, month: try Self.month(month), summary: "Plan"))
    }

    func record(
        _ id: String, _ category: CashlyDomain.Category, cents: Int64, on date: Date,
        kind: TransactionKind = .expense, status: TransactionStatus = .settled,
        tags: Set<String> = []
    ) async throws {
        try await repositories.transactions.save(
            Transaction(
                id: id, participants: [], category: category, money: Money(minorUnits: cents),
                date: date, summary: id, status: status, splitMode: nil, splitValue: nil,
                paymentsPlan: nil, tagIDs: tags, kind: kind))
    }

    func snapshot(includesJourney: Bool = false) async throws -> WebSnapshot {
        try await WebSnapshot.make(
            repositories: repositories,
            context: WebSnapshot.Context(
                user: owner, today: try today, currency: "USD",
                locale: Locale(identifier: "en_US"), includesJourney: includesJourney))
    }

    func overview(month: Int = 10) async throws -> CashlyOverview {
        try await repositories.dashboard.overview(
            query: TransactionQuery(month: try Self.month(month)))
    }
}
