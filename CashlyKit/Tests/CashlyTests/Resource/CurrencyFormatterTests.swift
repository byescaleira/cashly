//
//  CurrencyFormatterTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyResource

@Suite("CashlyCurrency", .tags(.unit, .local))
struct CurrencyFormatterTests {

    private func suite() -> UserDefaults {
        let name = "cashly.tests.\(UUID().uuidString)"
        let s = UserDefaults(suiteName: name)!
        s.removePersistentDomain(forName: name)
        return s
    }

    @Test("current returns default when key absent")
    func defaultCode() {
        let s = suite()
        #expect(CashlyCurrency.current(suite: s) == CashlyCurrency.default)
    }

    @Test("current respects override key")
    func overrideCode() {
        let s = suite()
        s.set("EUR", forKey: CashlyCurrency.userDefaultsKey)
        #expect(CashlyCurrency.current(suite: s) == "EUR")
    }

    @Test("format applies explicit code regardless of suite")
    func formatExplicit() {
        let s = suite()
        s.set("EUR", forKey: CashlyCurrency.userDefaultsKey)
        let output = CashlyCurrency.format(99.5, code: "BRL", locale: Locale(identifier: "pt-BR"), suite: s)
        #expect(output.contains("R$"))
    }

    @Test("format honours the suite preference when code nil")
    func formatFromSuite() {
        let s = suite()
        s.set("EUR", forKey: CashlyCurrency.userDefaultsKey)
        let output = CashlyCurrency.format(10, locale: Locale(identifier: "en-US"), suite: s)
        #expect(output.contains("€"))
    }

    @Test("common list contains USD as first entry")
    func commonList() {
        #expect(CashlyCurrency.common.first == "USD")
        #expect(CashlyCurrency.common.contains("BRL"))
    }
}
