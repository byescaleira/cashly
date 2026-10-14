import CashlyDomain
import FeatureCore
import FeatureTransactions
import Testing

@MainActor
struct TransactionTotalsTests {
    @Test func totalsCoverEveryMatchingTransactionBeyondThePage() async throws {
        let fixture = try await TransactionFixture()
        for index in 0..<60 {
            try await fixture.repositories.transactions.save(
                fixture.expense(String(format: "t%02d", index), cents: 100, offset: Double(index)))
        }
        try await fixture.repositories.transactions.save(
            fixture.expense("salary", cents: 5_000, offset: 100, kind: .income))
        let (_, finance, list) = await fixture.list()
        await finance.load()
        await list.load()
        #expect(list.items.count == 50)
        #expect(list.totals.count == 61)
        #expect(list.totals.spent == 60)
        #expect(list.totals.received == 50)
        #expect(list.totals.balance == -10)
        #expect(list.totals.isMixed)
        #expect(list.totals.amount == 60)
        #expect(list.isShowingTotals)
    }

    @Test func totalsFollowTheActiveFilters() async throws {
        let fixture = try await TransactionFixture()
        let leisure = CashlyDomain.Category(
            id: "leisure", user: fixture.owner, name: "Lazer", color: "FF9900", icon: "film")
        try await fixture.repositories.categories.save(leisure)
        let trip = Tag(
            id: "trip", user: fixture.owner, name: "Viagem", color: "00AA66", icon: "car")
        try await fixture.repositories.tags.save(trip)
        try await fixture.repositories.transactions.save(
            fixture.expense("a", cents: 1_000, tagIDs: [trip.id]))
        try await fixture.repositories.transactions.save(
            fixture.expense("b", cents: 2_500, offset: 60, category: leisure))
        try await fixture.repositories.transactions.save(
            fixture.expense("c", cents: 300, offset: 120, status: .pendingToPay))
        let (session, finance, list) = await fixture.list()

        session.filter.categories = [leisure]
        await finance.load()
        await list.load()
        #expect(list.totals == TransactionTotals(count: 1, spent: 25, received: 0, balance: -25))
        #expect(list.activeFilters == [.category(leisure)])

        session.filter.categories = []
        session.filter.tags = [trip]
        session.filter.transactionStatuses = [.settled]
        await finance.load()
        await list.load()
        #expect(list.totals.count == 1)
        #expect(list.totals.spent == 10)
        #expect(list.activeFilters == [.tag(trip), .status(.settled)])

        session.filter.tags = []
        session.filter.transactionStatuses = [.pendingToPay]
        await finance.load()
        await list.load()
        #expect(list.items.map(\.id) == ["c"])
        #expect(list.totals.spent == 3)
    }

    @Test func filteredOutKeepsTheTotalsInsteadOfTheEmptyState() async throws {
        let fixture = try await TransactionFixture()
        try await fixture.repositories.transactions.save(fixture.expense("a", cents: 1_000))
        let (session, finance, list) = await fixture.list()
        session.filter.participants = [fixture.friend]
        await finance.load()
        await list.load()
        #expect(list.isFilteredOut)
        #expect(list.isShowingTotals)
        #expect(!list.isShowingEmptyState)
        #expect(list.totals.count == 0)
        #expect(list.totals.amount == 0)

        list.clearFilters()
        #expect(list.activeFilters.isEmpty)
        #expect(session.filter.month == YearMonth(fixture.january))
        await finance.load()
        await list.load()
        #expect(list.totals.count == 1)
        #expect(!list.isFilteredOut)
    }

    @Test func incomeOnlyShowsTheReceivedAmount() async throws {
        let fixture = try await TransactionFixture()
        try await fixture.repositories.transactions.save(
            fixture.expense("salary", cents: 8_000, kind: .income))
        let (_, finance, list) = await fixture.list()
        await finance.load()
        await list.load()
        #expect(list.totals.isIncomeOnly)
        #expect(!list.totals.isMixed)
        #expect(list.totals.amount == 80)
        #expect(list.totals.balance == 80)
    }

    @Test func emptyListShowsTheEmptyStateAndSelectionHidesTotals() async throws {
        let fixture = try await TransactionFixture()
        let (_, finance, list) = await fixture.list()
        await finance.load()
        await list.load()
        #expect(list.isShowingEmptyState)
        #expect(!list.isShowingTotals)

        try await fixture.repositories.transactions.save(fixture.expense("a", cents: 100))
        await finance.load()
        await list.load()
        #expect(list.isShowingTotals)
        list.isSelecting = true
        #expect(!list.isShowingTotals)
    }
}
