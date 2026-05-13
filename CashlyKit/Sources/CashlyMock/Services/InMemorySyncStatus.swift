//
//  InMemorySyncStatus.swift
//  CashlyKit
//

import Foundation
import CashlyDomain

public actor InMemorySyncStatus: SyncStatusUseCase {
    private var status: SyncStatus

    public init(initial: SyncStatus = .unknown) {
        self.status = initial
    }

    public func currentStatus() async -> SyncStatus { status }

    public func markSynced(at date: Date) async {
        status = SyncStatus(lastSyncedAt: date, isHealthy: true)
    }
}
