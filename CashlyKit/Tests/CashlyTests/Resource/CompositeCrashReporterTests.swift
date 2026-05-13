//
//  CompositeCrashReporterTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyResource

@Suite("CompositeCrashReporter", .tags(.unit, .local))
struct CompositeCrashReporterTests {

    private struct DummyError: Error, Equatable {
        let code: Int
    }

    @Test("record fans out to every child")
    func recordFanout() {
        let a = SpyCrashReporter()
        let b = SpyCrashReporter()
        let composite = CompositeCrashReporter(a, b)
        composite.record(error: DummyError(code: 42), metadata: ["k": "v"])
        #expect(a.errors.count == 1)
        #expect(b.errors.count == 1)
        #expect(a.errors.first?.metadata["k"] == "v")
    }

    @Test("log fans out at each level")
    func logFanout() {
        let a = SpyCrashReporter()
        let b = SpyCrashReporter()
        let composite = CompositeCrashReporter([a, b])
        composite.log("hello", level: .warning)
        #expect(a.logs.first?.level == .warning)
        #expect(b.logs.first?.message == "hello")
    }

    @Test("setUser propagates to every child")
    func setUserFanout() {
        let a = SpyCrashReporter()
        let b = SpyCrashReporter()
        let composite = CompositeCrashReporter(a, b)
        composite.setUser(id: "abc")
        #expect(a.userId == "abc")
        #expect(b.userId == "abc")
        composite.setUser(id: nil)
        #expect(a.userId == nil)
    }

    @Test("Spy records error description even for non-Equatable errors")
    func spyDescription() {
        let spy = SpyCrashReporter()
        struct Anonymous: Error {}
        spy.record(error: Anonymous(), metadata: [:])
        #expect(spy.errors.first?.description.contains("Anonymous") == true)
    }
}
