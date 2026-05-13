//
//  UserDefaultsSyncStatus.swift
//  CashlyKit
//
//  Simple UserDefaults-backed SyncStatusUseCase. Stores the last
//  successful sync as a TimeInterval under
//  `cashly.sync.lastSyncedAt`. Health flag is derived from "synced
//  within the last 24h" so the Settings indicator can flip yellow
//  on stale syncs.
//

import Foundation
import CashlyDomain

public actor UserDefaultsSyncStatus: SyncStatusUseCase {
    private let suite: UserDefaults
    private static let lastSyncedAtKey = "cashly.sync.lastSyncedAt"

    public init(suite: UserDefaults = .standard) {
        self.suite = suite
    }

    public func currentStatus() async -> SyncStatus {
        let interval = suite.double(forKey: Self.lastSyncedAtKey)
        guard interval > 0 else { return .unknown }
        let date = Date(timeIntervalSince1970: interval)
        let isHealthy = Date().timeIntervalSince(date) < 60 * 60 * 24
        return SyncStatus(lastSyncedAt: date, isHealthy: isHealthy)
    }

    public func markSynced(at date: Date) async {
        suite.set(date.timeIntervalSince1970, forKey: Self.lastSyncedAtKey)
    }
}
