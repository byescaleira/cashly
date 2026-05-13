//
//  CompositeCrashReporter.swift
//  CashlyKit
//
//  Fan-out reporter. Forwards every call to every child reporter so
//  the composition root can run os.Logger alongside a third-party
//  provider (Sentry / Crashlytics) without either knowing about the
//  other.
//

import Foundation

public struct CompositeCrashReporter: CrashReporter {
    private let reporters: [CrashReporter]

    public init(_ reporters: [CrashReporter]) {
        self.reporters = reporters
    }

    public init(_ reporters: CrashReporter...) {
        self.reporters = reporters
    }

    public func record(error: Error, metadata: [String: String]) {
        for r in reporters { r.record(error: error, metadata: metadata) }
    }

    public func log(_ message: String, level: CrashReporterLevel) {
        for r in reporters { r.log(message, level: level) }
    }

    public func setUser(id: String?) {
        for r in reporters { r.setUser(id: id) }
    }
}
