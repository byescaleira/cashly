import CashlyDomain
import FeatureTransactions
import Testing

@MainActor
struct TransactionListTests {
    @Test func paginatesAndDeletes() async throws {
        let fixture = try await TransactionFixture()
        for index in 0..<60 {
            try await fixture.repositories.transactions.save(
                fixture.expense(String(format: "t%02d", index), cents: 100, offset: Double(index)))
        }
        let (_, _, list) = await fixture.list()
        await list.load()
        #expect(list.items.count == 50)
        #expect(list.hasMore)
        await list.loadMore()
        #expect(list.items.count == 60)
        #expect(!list.hasMore)
        let first = try #require(list.items.first)
        await list.delete(first)
        await list.load()
        await list.loadMore()
        #expect(list.items.count == 59)
        #expect(!list.items.contains(first))
    }

    @Test func groupsByDayNewestFirst() async throws {
        let fixture = try await TransactionFixture()
        try await fixture.repositories.transactions.save(fixture.expense("a", cents: 100))
        try await fixture.repositories.transactions.save(
            fixture.expense("b", cents: 100, offset: 3600))
        try await fixture.repositories.transactions.save(
            fixture.expense("c", cents: 100, offset: 86_400 * 2))
        let (_, _, list) = await fixture.list()
        await list.load()
        #expect(list.days.count == 2)
        #expect(list.days.first?.items.map(\.id) == ["c"])
        #expect(Set(list.days.last?.items.map(\.id) ?? []) == ["a", "b"])
    }

    @Test func selectionTogglesAndDeletes() async throws {
        let fixture = try await TransactionFixture()
        try await fixture.repositories.transactions.save(fixture.expense("a", cents: 100))
        try await fixture.repositories.transactions.save(fixture.expense("b", cents: 200))
        let (_, _, list) = await fixture.list()
        await list.load()
        list.isSelecting = true
        list.toggleSelectAll()
        #expect(list.isAllSelected)
        #expect(list.shareMessage(participants: []).contains("Records: 2"))
        list.toggleSelectAll()
        #expect(list.selection.isEmpty)
        list.selection = [try #require(list.items.first { $0.id == "a" })]
        await list.deleteSelection()
        await list.load()
        #expect(list.items.map(\.id) == ["b"])
        #expect(list.selection.isEmpty)
        list.endSelection()
        #expect(!list.isSelecting)
    }
}
