import CashlyAnalytics
import CashlyData
import CashlyDomain
import CashlyGame
import CashlyWeb
import Foundation
import Testing

struct WebSnapshotSectionsTests {
    private let october = YearMonth(year: 2026, month: 10)

    @discardableResult
    private func busyMonth(_ fixture: WebSnapshotFixture) async throws
        -> [CashlyDomain.Category]
    {
        var categories: [CashlyDomain.Category] = []
        for index in 0..<10 { categories.append(try await fixture.category("cat\(index)")) }
        for index in 0..<9 { try await fixture.tag("tag\(index)") }
        try await fixture.budget(categories[0], cents: 50_000)
        try await fixture.budget(categories[1], cents: 20_000)
        for (index, category) in categories.enumerated() {
            try await fixture.record(
                "spend \(index)", category, cents: Int64(10 - index) * 1_000,
                on: try WebSnapshotFixture.day(index + 1), tags: ["tag\(index % 9)"])
        }
        try await fixture.record(
            "Internet", categories[0], cents: 5_900, on: try WebSnapshotFixture.day(20),
            status: .pendingToPay)
        try await fixture.record(
            "Salary", categories[1], cents: 420_000, on: try WebSnapshotFixture.day(5),
            kind: .income)
        return categories
    }

    private func ledger(_ fixture: WebSnapshotFixture) async throws -> LedgerSnapshot {
        try await RepositoriesLedgerSource(repositories: fixture.repositories)
            .ledger(today: try fixture.today)
    }

    private func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    @Test func dailySpendingFollowsTheLedgerUntilToday() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let snapshot = try await fixture.snapshot()
        let ledger = try await ledger(fixture)
        let month = try #require(october)
        let daily = try #require(snapshot.daily)

        #expect(daily.count == 17)
        #expect(daily.first?.date == "2026-10-01")
        #expect(daily.last?.date == "2026-10-17")
        for (index, day) in daily.enumerated() {
            let spent =
                ledger.spent(in: month, throughDay: index + 1)
                - ledger.spent(in: month, throughDay: index)
            #expect(day.spent == Money(minorUnits: spent).doubleValue)
        }
        #expect(daily.first?.spent == 100)
        #expect(daily.last?.spent == 0)
        let projection = try #require(MonthPace.projection(ledger))
        #expect(
            daily.reduce(0) { $0 + $1.spent } == Money(minorUnits: projection.spent).doubleValue)
    }

    @Test func forecastIsTheMonthPaceOfInsights() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let snapshot = try await fixture.snapshot()
        let ledger = try await ledger(fixture)
        let pace = try #require(MonthPace().run(ledger))
        let forecast = try #require(snapshot.forecast)
        let projected = try #require(pace.metric("projected")?.value)
        let planned = try #require(pace.metric("budgeted")?.value)

        #expect(rounded(forecast.spent) == projected)
        #expect(rounded(forecast.planned) == planned)
        #expect(forecast.planned == 700)
        #expect(rounded(forecast.available) == rounded(planned - projected))
        #expect(forecast.outcome == (projected > planned ? .over : .under))
    }

    @Test func forecastNeedsAPlan() async throws {
        let fixture = try await WebSnapshotFixture()
        let category = try await fixture.category("cat")
        try await fixture.record("spend", category, cents: 2_000, on: try WebSnapshotFixture.day(3))
        let snapshot = try await fixture.snapshot()
        #expect(snapshot.forecast == nil)
        #expect(snapshot.daily?.count == 17)
    }

    @Test func categoriesKeepTheEightLargestAndGroupTheRest() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let snapshot = try await fixture.snapshot()
        let overview = try await fixture.overview()
        let categories = try #require(snapshot.categories)

        #expect(categories.count == WebSnapshot.categoryLimit + 1)
        #expect(categories.prefix(8).map(\.name) == (0..<8).map { "cat\($0)" })
        let first = try #require(categories.first)
        let spent = overview.categoryExpenses["cat0", default: .zero].doubleValue
        #expect(first.spent == spent)
        #expect(first.spent == 159)
        #expect(first.share == rounded(spent / overview.expensesTotal.doubleValue))
        #expect(first.color == "olive")
        #expect(first.symbol == "cart")
        let other = try #require(categories.last)
        #expect(other.name == String(appLocalized: "Other"))
        #expect(other.symbol == WebSnapshot.otherSymbol)
        #expect(other.color == WebSnapshot.otherColor)
        #expect(
            other.spent
                == overview.categoryExpenses["cat8", default: .zero].doubleValue
                + overview.categoryExpenses["cat9", default: .zero].doubleValue)
    }

    @Test func tagsKeepTheEightLargestWithTheirCounts() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let snapshot = try await fixture.snapshot()
        let overview = try await fixture.overview()
        let tags = try #require(snapshot.tags)
        let shown = (0..<WebSnapshot.tagLimit).map { "tag\($0)" }

        #expect(tags.map(\.name) == shown)
        #expect(
            tags.map(\.spent) == shown.map { overview.tagExpenses[$0, default: .zero].doubleValue })
        #expect(tags.map(\.count) == shown.map { overview.tagCounts[$0, default: 0] })
        #expect(tags.first?.spent == 110)
        #expect(tags.first?.count == 2)
    }

    @Test func historyCoversTheLastSixMonthsOldestFirst() async throws {
        let fixture = try await WebSnapshotFixture()
        let category = try await fixture.category("cat")
        for month in 3...10 {
            try await fixture.budget(category, cents: Int64(month) * 10_000, month: month)
            try await fixture.record(
                "spend \(month)", category, cents: Int64(month) * 1_000,
                on: try WebSnapshotFixture.day(2, month: month))
            try await fixture.record(
                "income \(month)", category, cents: 100_000,
                on: try WebSnapshotFixture.day(3, month: month), kind: .income)
        }
        let snapshot = try await fixture.snapshot()
        let history = try #require(snapshot.history)

        #expect(history.count == WebSnapshot.historyLength)
        #expect(history.map(\.month) == (5...10).map { String(format: "2026-%02d", $0) })
        for (entry, month) in zip(history, 5...10) {
            let overview = try await fixture.overview(month: month)
            #expect(entry.planned == overview.budgetsTotal.doubleValue)
            #expect(entry.spent == overview.expensesTotal.doubleValue)
            #expect(entry.income == overview.incomeTotal.doubleValue)
        }
        let current = try await fixture.overview()
        let savings = try #require(snapshot.savings)
        let rates = (5...10).map { Double(100_000 - $0 * 1_000) / 100_000 }
        #expect(savings.saved == current.netTotal.doubleValue)
        #expect(savings.saved == 900)
        #expect(savings.rate == 0.9)
        #expect(savings.averageRate == rounded(rates.reduce(0, +) / Double(rates.count)))
    }

    @Test func historyStartsAtTheFirstMonthWithData() async throws {
        let fixture = try await WebSnapshotFixture()
        let category = try await fixture.category("cat")
        try await fixture.record(
            "august", category, cents: 1_000, on: try WebSnapshotFixture.day(4, month: 8))
        try await fixture.record("october", category, cents: 1_000, on: try fixture.today)
        let snapshot = try await fixture.snapshot()

        #expect(snapshot.history?.map(\.month) == ["2026-08", "2026-09", "2026-10"])
        #expect(snapshot.savings == nil)
    }

    @Test func scoreIsTheHomeScore() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let snapshot = try await fixture.snapshot()
        let overview = try await fixture.overview()
        let health = BudgetHealth(
            usage: BudgetUsage(spent: overview.expensesTotal, budgeted: overview.budgetsTotal))
        let score = try #require(snapshot.score)

        #expect(score.value == health.score)
        #expect(score.max == BudgetHealth.maximumScore)
        #expect(score.label == health.level.title)
        #expect(score.detail == health.level.summary)
    }

    @Test func journeyIsLeftOutWhenTheFlagIsOff() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let snapshot = try await fixture.snapshot(includesJourney: false)
        #expect(snapshot.journey == nil)
    }

    @Test func journeyFollowsTheGameEngine() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let challenge = Challenge(kind: .cap, categoryID: "cat0", limit: 100_000)
        try await fixture.repositories.game.record([
            GameEvent(kind: .transactionRecorded, date: try WebSnapshotFixture.day(16)),
            GameEvent(kind: .transactionRecorded, date: try WebSnapshotFixture.day(17)),
            GameEvent(
                kind: .challengeStarted, date: try WebSnapshotFixture.day(15),
                value: challenge.code),
        ])
        let snapshot = try await fixture.snapshot(includesJourney: true)
        let progress = GameEngine.progress(
            try await RepositoriesGameSource(repositories: fixture.repositories, guides: [])
                .snapshot(today: try fixture.today))
        let journey = try #require(snapshot.journey)

        #expect(journey.level == progress.level.number)
        #expect(journey.levelTitle == progress.level.title)
        #expect(journey.progress == rounded(progress.level.progress))
        #expect(journey.streak == progress.streak.current)
        let state = try #require(progress.challenge)
        guard case .active(let value) = state.status else {
            Issue.record("The challenge should be active")
            return
        }
        let active = try #require(journey.challenge)
        #expect(active.title == Challenge.Kind.cap.title)
        #expect(active.progress == rounded(min(max(value, 0), 1)))
        #expect(active.endsOn == "2026-10-31")
    }

    @Test func encodesAndDecodesEverySection() async throws {
        let fixture = try await WebSnapshotFixture()
        try await busyMonth(fixture)
        let snapshot = try await fixture.snapshot(includesJourney: true)
        let data = try snapshot.encoded()
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        for key in [
            "daily", "forecast", "categories", "tags", "history", "savings", "score", "journey",
        ] {
            #expect(object[key] != nil, "\(key) is missing")
        }
        let score = try #require(object["score"] as? [String: Any])
        #expect(score["max"] as? Int == BudgetHealth.maximumScore)
        #expect(try JSONDecoder().decode(WebSnapshot.self, from: data) == snapshot)
    }

    @Test func emptyMonthLeavesOutWhatItDoesNotHave() async throws {
        let fixture = try await WebSnapshotFixture()
        let snapshot = try await fixture.snapshot()
        let object = try #require(
            JSONSerialization.jsonObject(with: try snapshot.encoded()) as? [String: Any])

        for key in ["forecast", "categories", "tags", "savings", "journey"] {
            #expect(object[key] == nil, "\(key) should be left out")
        }
        #expect(snapshot.history?.map(\.month) == ["2026-10"])
    }

    @Test func heavyMonthStaysUnderTheSizeTarget() async throws {
        let fixture = try await WebSnapshotFixture()
        var categories: [CashlyDomain.Category] = []
        for index in 0..<12 {
            let category = try await fixture.category("Category number \(index)")
            try await fixture.budget(category, cents: 90_000)
            categories.append(category)
        }
        for index in 0..<8 { try await fixture.tag("Tag number \(index)") }
        for index in 0..<320 {
            try await fixture.record(
                "A rather long description for purchase number \(index) at the store",
                categories[index % 12], cents: Int64(1_000 + index * 37),
                on: try WebSnapshotFixture.day(1 + index % 28, hour: index % 24),
                tags: Set((0..<3).map { "Tag number \((index + $0) % 8)" }))
        }
        let snapshot = try await fixture.snapshot(includesJourney: true)

        #expect(snapshot.transactions.count == WebSnapshot.transactionLimit)
        #expect(try snapshot.encoded().count < 150_000)
    }
}
