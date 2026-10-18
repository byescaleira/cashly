import CashlyData
import CashlyDomain
import CashlyWeb
import Foundation
import Testing

struct WebSnapshotTests {
    private let owner = User(id: "owner", name: "Dana Teixeira", photo: .initials(color: "2E7D74"))

    private func day(_ value: Int, hour: Int = 12) throws -> Date {
        try #require(
            CashlyCalendar.current.date(
                from: DateComponents(year: 2026, month: 10, day: value, hour: hour)))
    }

    private func october() throws -> YearMonth {
        try #require(YearMonth(year: 2026, month: 10))
    }

    @Test(arguments: [
        (191_500, 17, WebSnapshot.Pace.onTrack), (250_000, 10, .ahead), (330_000, 17, .over),
        (320_000, 30, .over),
    ])
    func classifiesThePaceOfTheMonth(spent: Int64, today: Int, pace: WebSnapshot.Pace) throws {
        let month = WebSnapshot.Month(
            month: try october(), today: try day(today), planned: Money(minorUnits: 320_000),
            spent: Money(minorUnits: spent), income: Money(minorUnits: 420_000))
        #expect(month.pace == pace)
    }

    @Test func summarizesTheMonthLikeTheApp() throws {
        let month = WebSnapshot.Month(
            month: try october(), today: try day(17), planned: Money(minorUnits: 320_000),
            spent: Money(minorUnits: 191_500), income: Money(minorUnits: 420_000))
        #expect(month.start == "2026-10-01")
        #expect(month.end == "2026-10-31")
        #expect(month.today == "2026-10-17")
        #expect(month.available == 1285)
        #expect(month.usedRatio == 0.6)
        #expect(month.elapsedRatio == 0.55)
        #expect(month.perDay == 85.66)
    }

    @Test func monthWithoutPlanHasNoPace() throws {
        let month = WebSnapshot.Month(
            month: try october(), today: try day(5), planned: .zero,
            spent: Money(minorUnits: 5_000), income: .zero)
        #expect(month.pace == .onTrack)
        #expect(month.usedRatio == 0)
        #expect(month.perDay == 0)
        #expect(month.available == -50)
    }

    @Test func buildsTheSnapshotFromTheSameNumbersAsHome() async throws {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let groceries = Category(
            id: "groceries", user: owner, name: "Groceries", color: "6B7D35", icon: "cart")
        let dining = Category(
            id: "dining", user: owner, name: "Dining out", color: "C9962B", icon: "fork.knife")
        let income = Category(
            id: "income", user: owner, name: "Income", color: "2E7D74", icon: "arrow.up")
        for category in [groceries, dining, income] {
            try await repositories.categories.save(category)
        }
        try await repositories.tags.save(
            Tag(id: "home", user: owner, name: "Home", color: "466A93", icon: "house"))
        try await repositories.budgets.save(
            Budget(
                id: "b1", money: Money(minorUnits: 60_000), category: groceries,
                month: try october(), summary: "Plan"))
        try await repositories.budgets.save(
            Budget(
                id: "b2", money: Money(minorUnits: 22_000), category: dining,
                month: try october(), summary: "Plan"))
        let entries:
            [(
                String, CashlyDomain.Category, Int64, Int, TransactionKind,
                TransactionStatus, Set<String>
            )] = [
                ("Farmers market", groceries, 4_820, 17, .expense, .settled, ["home"]),
                ("Dinner", dining, 19_800, 10, .expense, .settled, []),
                ("Salary", income, 420_000, 16, .income, .settled, []),
                ("Internet", dining, 5_900, 20, .expense, .pendingToPay, []),
            ]
        for (summary, category, cents, value, kind, status, tags) in entries {
            try await repositories.transactions.save(
                Transaction(
                    id: summary, participants: [], category: category,
                    money: Money(minorUnits: cents), date: try day(value), summary: summary,
                    status: status, splitMode: nil, splitValue: nil, paymentsPlan: nil,
                    tagIDs: tags, kind: kind))
        }
        let context = WebSnapshot.Context(
            user: owner, today: try day(17), currency: "USD",
            locale: Locale(identifier: "pt_BR"),
            generatedAt: Date(timeIntervalSince1970: 1_792_316_460))
        let snapshot = try await WebSnapshot.make(repositories: repositories, context: context)
        let overview = try await repositories.dashboard.overview(
            query: TransactionQuery(month: try october()))

        #expect(snapshot.v == 1)
        #expect(snapshot.locale == "pt-BR")
        #expect(snapshot.currency == "USD")
        #expect(snapshot.generatedAt == "2026-10-18T09:41:00Z")
        #expect(snapshot.profile.initials == "DT")
        #expect(snapshot.profile.color == "teal")
        #expect(snapshot.month.planned == 820)
        #expect(snapshot.month.spent == overview.expensesTotal.doubleValue)
        #expect(snapshot.month.income == 4200)
        #expect(snapshot.month.available == 820 - overview.expensesTotal.doubleValue)
        #expect(snapshot.budgets.map(\.name).sorted() == ["Dining out", "Groceries"])
        let groceriesBudget = try #require(snapshot.budgets.first { $0.name == "Groceries" })
        #expect(groceriesBudget.color == "olive")
        #expect(groceriesBudget.symbol == "cart")
        #expect(groceriesBudget.spent == overview.budgetExpenses["b1", default: .zero].doubleValue)
        #expect(
            snapshot.transactions.map(\.date) == snapshot.transactions.map(\.date).sorted(by: >))
        let market = try #require(
            snapshot.transactions.first { $0.description == "Farmers market" })
        #expect(market.amount == 48.2)
        #expect(market.kind == "expense")
        #expect(market.status == "paid")
        #expect(market.tags == ["Home"])
        #expect(market.category.name == "Groceries")
        #expect(market.category.symbol == "cart")
        #expect(market.category.color == "olive")
        #expect(snapshot.transactions.first { $0.description == "Salary" }?.kind == "income")
        #expect(snapshot.upcoming.map(\.description) == ["Internet"])
        #expect(snapshot.upcoming.first?.dueDate == "2026-10-20")
        #expect(snapshot.upcoming.first?.amount == 59)
        let decoded = try JSONDecoder().decode(WebSnapshot.self, from: snapshot.encoded())
        #expect(decoded == snapshot)
    }

    @Test func keepsTheThreeHundredMostRecentTransactions() async throws {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let category = Category(
            id: "c", user: owner, name: "General", color: "C2602A", icon: "cart")
        try await repositories.categories.save(category)
        for index in 0..<305 {
            try await repositories.transactions.save(
                Transaction(
                    id: "t\(index)", participants: [], category: category,
                    money: Money(minorUnits: 100),
                    date: try day(1 + index % 28, hour: index % 24), summary: "Item \(index)",
                    status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
        }
        let snapshot = try await WebSnapshot.make(
            repositories: repositories,
            context: WebSnapshot.Context(
                user: owner, today: try day(28), currency: "USD",
                locale: Locale(identifier: "en_US")))
        #expect(snapshot.transactions.count == 300)
        #expect(snapshot.profile.color == "teal")
    }

    @Test func decodesTheVectorSnapshot() throws {
        let vector = try WebVector.load()
        let snapshot = try JSONDecoder().decode(WebSnapshot.self, from: Data(vector.plaintext.utf8))
        #expect(snapshot.budgets.count == 3)
        #expect(snapshot.transactions.first?.category.symbol == "cart")
        #expect(snapshot.upcoming.first?.amount == 59)
    }
}
