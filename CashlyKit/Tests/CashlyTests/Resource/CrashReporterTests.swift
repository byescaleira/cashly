//
//  CrashReporterTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyResource

@Suite("CrashReporter", .tags(.unit, .local))
struct CrashReporterTests {

    @Test("Noop reporter eats every call")
    func noop() {
        let reporter = NoopCrashReporter()
        reporter.record(error: TestError.x)
        reporter.log("hello", level: .info)
        reporter.setUser(id: "u")
        // No assertion needed — survival is the contract.
        #expect(true)
    }

    @Test("OSLog reporter accepts every call (real backing exercised at runtime)")
    func osLogSmoke() {
        let reporter = OSLogCrashReporter()
        reporter.record(error: TestError.x, metadata: ["k": "v"])
        reporter.log("hello", level: .warning)
        reporter.setUser(id: "tester")
        reporter.setUser(id: nil)
        #expect(true)
    }

    @Test("default record(error:) extension forwards to metadata-aware overload")
    func defaultRecordCallsMetadataVariant() {
        final class Spy: CrashReporter, @unchecked Sendable {
            var captured: [String: String]? = nil
            func record(error: Error, metadata: [String: String]) { captured = metadata }
            func log(_ message: String, level: CrashReporterLevel) {}
            func setUser(id: String?) {}
        }
        let spy = Spy()
        spy.record(error: TestError.x)
        #expect(spy.captured == [:])
    }

    private enum TestError: Error { case x }
}
