//
//  CashlyFuzzyMatchTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain

@Suite("CashlyFuzzyMatch", .tags(.unit, .local))
struct CashlyFuzzyMatchTests {

    private let items = ["Supermercado", "Restaurante", "Farmácia", "Lazer"]

    @Test("exact case-insensitive match wins")
    func exactMatch() {
        let hit = CashlyFuzzyMatch.bestMatch(for: "FARMACIA", in: items, key: { $0 })
        #expect(hit == "Farmácia")
    }

    @Test("substring match resolves 'mercado' to 'Supermercado'")
    func substring() {
        let hit = CashlyFuzzyMatch.bestMatch(for: "mercado", in: items, key: { $0 })
        #expect(hit == "Supermercado")
    }

    @Test("substring match also resolves 'Supermercado XYZ' to 'Supermercado'")
    func reverseSubstring() {
        let hit = CashlyFuzzyMatch.bestMatch(for: "Supermercado XYZ", in: items, key: { $0 })
        #expect(hit == "Supermercado")
    }

    @Test("typo within threshold returns closest item")
    func typoFallback() {
        let hit = CashlyFuzzyMatch.bestMatch(for: "Restaurnte", in: items, key: { $0 })
        #expect(hit == "Restaurante")
    }

    @Test("garbage returns nil")
    func noMatch() {
        let hit = CashlyFuzzyMatch.bestMatch(for: "xyzzyspoon", in: items, key: { $0 })
        #expect(hit == nil)
    }

    @Test("empty inputs return nil")
    func empties() {
        #expect(CashlyFuzzyMatch.bestMatch(for: "", in: items, key: { $0 }) == nil)
        #expect(CashlyFuzzyMatch.bestMatch(for: "any", in: [String](), key: { $0 }) == nil)
    }

    @Test("normalisedDistance returns 0 for identical strings")
    func zeroDistance() {
        #expect(CashlyFuzzyMatch.normalisedDistance(needle: "lazer", candidate: "lazer") == 0)
    }
}
