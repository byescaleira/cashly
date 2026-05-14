//
//  MockRecurringTransactionActorTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("MockRecurringTransactionActor", .tags(.unit, .local))
struct MockRecurringTransactionActorTests {

    private func fixture(daysAgo: Int, cadence: RecurringCadence = .weekly) -> RecurringTransactionTemplate {
        let start = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!.timeIntervalSince1970
        return RecurringTransactionTemplate(
            id: "t",
            summary: "Rent",
            amount: 100,
            budgetId: "b",
            categoryId: "c",
            startDate: start,
            cadence: cadence,
            kind: .expense
        )
    }

    @Test("add then templates returns the inserted template")
    func addRoundTrip() async throws {
        let actor = MockRecurringTransactionActor()
        try await actor.add(fixture(daysAgo: 0))
        let stored = try await actor.templates()
        #expect(stored.count == 1)
        #expect(stored.first?.summary == "Rent")
    }

    @Test("remove drops the template by id")
    func removalDrops() async throws {
        let actor = MockRecurringTransactionActor()
        try await actor.add(fixture(daysAgo: 0))
        try await actor.remove(id: "t")
        let stored = try await actor.templates()
        #expect(stored.isEmpty)
    }

    actor Counter {
        private(set) var value = 0
        func increment() { value += 1 }
    }

    @Test("materializeDue fires the closure for past occurrences")
    func materializeFires() async throws {
        let actor = MockRecurringTransactionActor()
        try await actor.add(fixture(daysAgo: 21, cadence: .weekly))
        let counter = Counter()
        try await actor.materializeDue(now: .now) { _, _ in await counter.increment() }
        #expect(await counter.value >= 3)
    }

    @Test("materializeDue stamps lastMaterializedAt so reruns skip past dates")
    func idempotent() async throws {
        let actor = MockRecurringTransactionActor()
        try await actor.add(fixture(daysAgo: 14, cadence: .weekly))
        try await actor.materializeDue(now: .now) { _, _ in }
        let counter = Counter()
        try await actor.materializeDue(now: .now) { _, _ in await counter.increment() }
        #expect(await counter.value == 0)
    }
}
