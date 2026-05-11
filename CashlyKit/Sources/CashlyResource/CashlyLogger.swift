//
//  CashlyLogger.swift
//  CashlyKit
//
//  Wave 8 G024: per-subsystem unified loggers + signpost helpers.
//  All call sites use `CashlyLogger.<subsystem>.<level>(...)` instead of
//  `print(...)` or scattered `os.Logger` instances.
//

import Foundation
import os

public enum CashlyLogger {
    /// Default subsystem prefix for all Cashly loggers. Matches the app's
    /// bundle id so unified logging filters by `subsystem:com.cashly.app`.
    public static let subsystem = "com.cashly.app"

    public static let data = Logger(subsystem: subsystem, category: "data")
    public static let domain = Logger(subsystem: subsystem, category: "domain")
    public static let presentation = Logger(subsystem: subsystem, category: "presentation")
    public static let ui = Logger(subsystem: subsystem, category: "ui")
    public static let intelligence = Logger(subsystem: subsystem, category: "intelligence")
    public static let app = Logger(subsystem: subsystem, category: "app")
}

/// Signpost helper for hot-path tracing. Use inside `withInterval(...)` for
/// scoped measurements that appear in Instruments under the Signposts track.
public enum CashlySignpost {
    public static let main = OSSignposter(
        subsystem: CashlyLogger.subsystem,
        category: "performance"
    )

    /// Wraps a synchronous block in a signpost interval.
    public static func withInterval<T>(
        _ name: StaticString,
        _ body: () throws -> T
    ) rethrows -> T {
        let id = main.makeSignpostID()
        let state = main.beginInterval(name, id: id)
        defer { main.endInterval(name, state) }
        return try body()
    }

    /// Wraps an async block in a signpost interval.
    public static func withInterval<T>(
        _ name: StaticString,
        _ body: () async throws -> T
    ) async rethrows -> T {
        let id = main.makeSignpostID()
        let state = main.beginInterval(name, id: id)
        defer { main.endInterval(name, state) }
        return try await body()
    }
}

// MARK: - Analytics

/// Simple analytics tracking abstraction. Concrete implementations live in
/// the composition root (app target) so domain/data layers stay framework-
/// agnostic. No-op `NoopAnalyticsTracker` provided for tests + previews.
public protocol AnalyticsTracker: Sendable {
    func track(event: String, properties: [String: String])
}

public extension AnalyticsTracker {
    func track(event: String) {
        track(event: event, properties: [:])
    }
}

public struct NoopAnalyticsTracker: AnalyticsTracker {
    public init() {}
    public func track(event: String, properties: [String: String]) {}
}
