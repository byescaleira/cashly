//
//  FilterStateTests.swift
//  CashlyKit
//
//  FilterState is a value-type aggregate consumed by the filter bar
//  in HomeScreen and the transaction-list filtering modal. Its
//  Hashable + Equatable conformances drive MainState change-detection
//  (`onChange(of: filter)` in CashlyApp).
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@Suite("FilterState", .tags(.unit, .presentation, .local))
struct FilterStateTests {

    @Test("default init has startDate ≈ now, endDate nil, filtering by date on")
    func defaultInit() {
        let f = FilterState()
        #expect(f.endDate == nil)
        #expect(f.isFilteringByDate == true)
        #expect(f.transactionStatuses.isEmpty)
        #expect(f.categories.isEmpty)
        #expect(f.tags.isEmpty)
        #expect(f.participants.isEmpty)
        // startDate near now (within 5s)
        #expect(abs(f.startDate.timeIntervalSinceNow) < 5)
    }

    @Test("Equatable: identical filters equate")
    func equalIdenticalFilters() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let a = FilterState(startDate: date, isFilteringByDate: false)
        let b = FilterState(startDate: date, isFilteringByDate: false)
        #expect(a == b)
    }

    @Test("Equatable: distinct startDate makes filters unequal")
    func differentStartDateBreaksEquality() {
        let a = FilterState(startDate: Date(timeIntervalSince1970: 0))
        let b = FilterState(startDate: Date(timeIntervalSince1970: 1000))
        #expect(a != b)
    }

    @Test("transactionStatuses set membership")
    func transactionStatusesSet() {
        var f = FilterState()
        f.transactionStatuses.insert(.pendingToPay)
        f.transactionStatuses.insert(.settled)
        #expect(f.transactionStatuses.contains(.pendingToPay))
        #expect(f.transactionStatuses.contains(.settled))
        #expect(f.transactionStatuses.count == 2)
    }

    @Test("Hashable: same-content filters share a hash")
    func hashable() {
        let a = FilterState(startDate: Date(timeIntervalSince1970: 100), isFilteringByDate: true)
        let b = FilterState(startDate: Date(timeIntervalSince1970: 100), isFilteringByDate: true)
        var h1 = Hasher(); var h2 = Hasher()
        a.hash(into: &h1)
        b.hash(into: &h2)
        #expect(h1.finalize() == h2.finalize())
    }
}
