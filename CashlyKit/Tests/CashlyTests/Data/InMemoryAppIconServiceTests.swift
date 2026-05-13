//
//  InMemoryAppIconServiceTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemoryAppIconService", .tags(.unit, .data, .local))
struct InMemoryAppIconServiceTests {

    @Test("defaults to .primary")
    func defaultsToPrimary() async {
        let service = InMemoryAppIconService()
        let current = await service.currentIcon()
        #expect(current == .primary)
    }

    @Test("setIcon roundtrips and reports success")
    func setIconRoundtrips() async {
        let service = InMemoryAppIconService()
        let ok = await service.setIcon(.pro)
        #expect(ok)
        let current = await service.currentIcon()
        #expect(current == .pro)
    }

    @Test("initial seed honoured")
    func initialSeed() async {
        let service = InMemoryAppIconService(initial: .pro)
        let current = await service.currentIcon()
        #expect(current == .pro)
    }
}
