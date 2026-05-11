//
//  CashlySignpostTests.swift
//  CashlyKit
//
//  Behavior tests for CashlySignpost.withInterval — must return the
//  body's value (sync and async), rethrow errors, and not interfere
//  with the call site.
//

import Testing
import CashlyResource

@Suite("CashlySignpost.withInterval", .tags(.unit, .data, .local))
struct CashlySignpostTests {

    @Test("sync withInterval returns the body's value")
    func syncReturnsValue() {
        let result = CashlySignpost.withInterval("test.sync") { 42 }
        #expect(result == 42)
    }

    @Test("async withInterval returns the body's value")
    func asyncReturnsValue() async {
        let result = await CashlySignpost.withInterval("test.async") {
            try? await Task.sleep(nanoseconds: 1_000_000)
            return "ok"
        }
        #expect(result == "ok")
    }

    @Test("sync withInterval rethrows thrown errors")
    func syncRethrows() {
        struct Boom: Error {}
        var caught = false
        do {
            _ = try CashlySignpost.withInterval("test.throws") {
                throw Boom()
            }
        } catch is Boom {
            caught = true
        } catch {}
        #expect(caught == true)
    }
}
