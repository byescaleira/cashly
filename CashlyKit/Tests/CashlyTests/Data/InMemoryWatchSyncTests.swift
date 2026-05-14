//
//  InMemoryWatchSyncTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemoryWatchSync", .tags(.unit, .local))
struct InMemoryWatchSyncTests {

    private let payload = WatchSnapshot(
        userId: "u",
        income: 1000,
        expense: 400,
        net: 600,
        currencyCode: "USD",
        recent: []
    )

    @Test("send records every pushed payload")
    func recordsPushes() async {
        let sync = InMemoryWatchSync()
        await sync.send(payload)
        await sync.send(payload)
        let recorded = await sync.snapshots
        #expect(recorded.count == 2)
    }

    @Test("isCompanionInstalled reflects the initialiser")
    func companionState() async {
        let withoutWatch = InMemoryWatchSync(companionInstalled: false)
        let withWatch = InMemoryWatchSync(companionInstalled: true)
        #expect(await withoutWatch.isCompanionInstalled() == false)
        #expect(await withWatch.isCompanionInstalled())
    }

    @Test("setCompanionInstalled toggles state")
    func toggle() async {
        let sync = InMemoryWatchSync(companionInstalled: false)
        await sync.setCompanionInstalled(true)
        #expect(await sync.isCompanionInstalled())
    }

    @Test("WatchSnapshot round-trips through JSONEncoder/Decoder")
    func codable() throws {
        let encoded = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(WatchSnapshot.self, from: encoded)
        #expect(decoded == payload)
    }
}
