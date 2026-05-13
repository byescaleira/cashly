//
//  OSLogAnalyticsTracker.swift
//  CashlyKit
//
//  Default AnalyticsTracker — sends every event as a structured
//  `os.Logger` info entry on the `com.cashly.app/analytics`
//  subsystem. Production composers swap this for a real provider
//  (Mixpanel, PostHog, Firebase) without touching call sites.
//

import Foundation
import OSLog

public struct OSLogAnalyticsTracker: AnalyticsTracker {
    private let logger: Logger

    public init(subsystem: String = "com.cashly.app", category: String = "analytics") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func track(event: String, properties: [String: String]) {
        if properties.isEmpty {
            logger.info("event=\(event, privacy: .public)")
            return
        }
        let serialised = properties
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        logger.info("event=\(event, privacy: .public) \(serialised, privacy: .public)")
    }
}
