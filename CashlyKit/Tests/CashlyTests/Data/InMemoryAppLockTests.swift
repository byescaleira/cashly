//
//  InMemoryAppLockTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("InMemoryAppLock", .tags(.unit, .data, .local))
struct InMemoryAppLockTests {

    @Test("defaults to disabled + unlocked outcome")
    func defaults() async {
        let lock = InMemoryAppLock()
        #expect(await lock.isEnabled() == false)
        #expect(await lock.authenticate(reason: "test") == .unlocked)
    }

    @Test("setEnabled persists state across calls")
    func enableToggle() async {
        let lock = InMemoryAppLock()
        await lock.setEnabled(true)
        #expect(await lock.isEnabled())
    }

    @Test("setOutcome controls the next authenticate result")
    func setOutcome() async {
        let lock = InMemoryAppLock()
        await lock.setOutcome(.failed(reason: "stub"))
        #expect(await lock.authenticate(reason: "test") == .failed(reason: "stub"))
    }

    @Test("authenticate records every reason")
    func recordsReasons() async {
        let lock = InMemoryAppLock()
        _ = await lock.authenticate(reason: "open")
        _ = await lock.authenticate(reason: "foreground")
        let calls = await lock.authenticationCalls
        #expect(calls == ["open", "foreground"])
    }
}
