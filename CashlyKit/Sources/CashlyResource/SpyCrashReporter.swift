//
//  SpyCrashReporter.swift
//  CashlyKit
//
//  Test-double CrashReporter that records every call. Lets feature
//  tests assert "reporter saw this error" without booting a real
//  Sentry/Crashlytics client.
//

import Foundation

public final class SpyCrashReporter: CrashReporter, @unchecked Sendable {
    public struct ErrorRecord: Sendable {
        public let description: String
        public let metadata: [String: String]
    }

    public struct LogRecord: Sendable {
        public let message: String
        public let level: CrashReporterLevel
    }

    private let lock = NSLock()
    private var _errors: [ErrorRecord] = []
    private var _logs: [LogRecord] = []
    private var _userId: String?

    public init() {}

    public var errors: [ErrorRecord] {
        lock.lock(); defer { lock.unlock() }
        return _errors
    }

    public var logs: [LogRecord] {
        lock.lock(); defer { lock.unlock() }
        return _logs
    }

    public var userId: String? {
        lock.lock(); defer { lock.unlock() }
        return _userId
    }

    public func record(error: Error, metadata: [String: String]) {
        lock.lock()
        _errors.append(ErrorRecord(description: String(describing: error), metadata: metadata))
        lock.unlock()
    }

    public func log(_ message: String, level: CrashReporterLevel) {
        lock.lock()
        _logs.append(LogRecord(message: message, level: level))
        lock.unlock()
    }

    public func setUser(id: String?) {
        lock.lock()
        _userId = id
        lock.unlock()
    }
}
