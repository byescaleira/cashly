//
//  MainDeeplinkTests.swift
//  CashlyKit
//

import Foundation
import Testing
@testable import CashlyPresentation

@Suite("MainDeeplink", .tags(.unit, .presentation, .local))
struct MainDeeplinkTests {

    @Test("nil for unknown scheme")
    func unknownScheme() {
        let url = URL(string: "https://example.com/paywall")!
        #expect(MainDeeplink.resolve(url) == nil)
    }

    @Test("cashly://paywall → .paywall(.upgradeButton)")
    func paywallDefault() {
        let url = URL(string: "cashly://paywall")!
        #expect(MainDeeplink.resolve(url) == .paywall(trigger: .upgradeButton))
    }

    @Test("cashly://paywall?trigger=limit → .paywall(.limitReached)")
    func paywallLimit() {
        let url = URL(string: "cashly://paywall?trigger=limit")!
        #expect(MainDeeplink.resolve(url) == .paywall(trigger: .limitReached))
    }

    @Test("cashly://paywall?trigger=intelligence → .paywall(.intelligenceTab)")
    func paywallIntelligence() {
        let url = URL(string: "cashly://paywall?trigger=intelligence")!
        #expect(MainDeeplink.resolve(url) == .paywall(trigger: .intelligenceTab))
    }

    @Test("cashly://settings → .settings")
    func settings() {
        let url = URL(string: "cashly://settings")!
        #expect(MainDeeplink.resolve(url) == .settings)
    }

    @Test("cashly://home → .home")
    func home() {
        let url = URL(string: "cashly://home")!
        #expect(MainDeeplink.resolve(url) == .home)
    }

    @Test("cashly://intelligence → .intelligence")
    func intelligence() {
        let url = URL(string: "cashly://intelligence")!
        #expect(MainDeeplink.resolve(url) == .intelligence)
    }

    @Test("cashly://transactions → .transaction")
    func transactionsAlias() {
        let url = URL(string: "cashly://transactions")!
        #expect(MainDeeplink.resolve(url) == .transaction)
    }

    @Test("nil for unknown host")
    func unknownHost() {
        let url = URL(string: "cashly://wallet")!
        #expect(MainDeeplink.resolve(url) == nil)
    }
}
