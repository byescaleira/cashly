//
//  CrashReporter.swift
//  CashlyKit
//
//  Crash + non-fatal reporting abstraction. The composition root
//  swaps a real provider (Sentry / Crashlytics / Bugsnag) in;
//  domain/data layers only see this protocol so the framework
//  boundary stays clean.
//

import Foundation
import OSLog

public protocol CrashReporter: Sendable {
    /// Record a non-fatal error. The reporter MAY also attach a
    /// stack trace if the host platform supports it. Optional
    /// metadata keys can carry structured context.
    func record(error: Error, metadata: [String: String])

    /// Drop a breadcrumb — small contextual note attached to the
    /// next reported error.
    func log(_ message: String, level: CrashReporterLevel)

    /// Tag the active session with user-scoped identifiers. Pass
    /// nil values to clear an identifier.
    func setUser(id: String?)
}

public enum CrashReporterLevel: String, Sendable {
    case info
    case warning
    case error
}

public extension CrashReporter {
    func record(error: Error) {
        record(error: error, metadata: [:])
    }
}

/// Default `os.Logger`-backed reporter — writes to the
/// `com.cashly.app/crash` subsystem. A real provider replaces this
/// at composition time.
public struct OSLogCrashReporter: CrashReporter {
    private let logger: Logger
    private let lock: NSLock = NSLock()
    private var _userId: String?

    public init(subsystem: String = "com.cashly.app", category: String = "crash") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func record(error: Error, metadata: [String: String]) {
        let metaStr = metadata
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        logger.error("error=\(String(describing: error), privacy: .public) \(metaStr, privacy: .public)")
    }

    public func log(_ message: String, level: CrashReporterLevel) {
        switch level {
        case .info: logger.info("\(message, privacy: .public)")
        case .warning: logger.warning("\(message, privacy: .public)")
        case .error: logger.error("\(message, privacy: .public)")
        }
    }

    public func setUser(id: String?) {
        logger.info("user_id=\(id ?? "<nil>", privacy: .public)")
    }
}

/// No-op reporter — used by tests + previews where logs would only
/// pollute the console.
public struct NoopCrashReporter: CrashReporter {
    public init() {}
    public func record(error: Error, metadata: [String: String]) {}
    public func log(_ message: String, level: CrashReporterLevel) {}
    public func setUser(id: String?) {}
}
