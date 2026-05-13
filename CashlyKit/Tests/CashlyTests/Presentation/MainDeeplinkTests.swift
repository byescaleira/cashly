//
//  MainDeeplinkTests.swift
//  CashlyKit
//

import Foundation
import Testing
#if canImport(CoreSpotlight)
import CoreSpotlight
#endif
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

    @Test("shortcut add-transaction → .addTransaction(new)")
    func shortcutAddTransaction() {
        guard case let .addTransaction(state) = MainDeeplink.resolve(shortcutType: "com.cashly.app.shortcut.add-transaction") else {
            Issue.record("expected .addTransaction"); return
        }
        #expect(state.isNew)
    }

    @Test("shortcut insights → .insights")
    func shortcutInsights() {
        #expect(MainDeeplink.resolve(shortcutType: "com.cashly.app.shortcut.insights") == .insights)
    }

    @Test("shortcut paywall → .paywall(.upgradeButton)")
    func shortcutPaywall() {
        #expect(MainDeeplink.resolve(shortcutType: "com.cashly.app.shortcut.paywall") == .paywall(trigger: .upgradeButton))
    }

    @Test("unknown shortcut type → nil")
    func shortcutUnknown() {
        #expect(MainDeeplink.resolve(shortcutType: "com.cashly.app.shortcut.other") == nil)
    }

    #if canImport(CoreSpotlight)
    @Test("Spotlight activity resolves to addTransaction edit")
    func spotlightActivity() {
        let activity = NSUserActivity(activityType: "com.apple.corespotlightitem")
        activity.userInfo = ["kCSSearchableItemActivityIdentifier": "tx-42"]
        guard case let .addTransaction(state) = MainDeeplink.resolve(activity) else {
            Issue.record("expected .addTransaction"); return
        }
        #expect(state.id == "tx-42")
    }

    @Test("Unknown activity type resolves to nil")
    func unknownActivity() {
        let activity = NSUserActivity(activityType: "some.other.activity")
        #expect(MainDeeplink.resolve(activity) == nil)
    }
    #endif
}
