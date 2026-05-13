//
//  SyncStatusUseCase.swift
//  CashlyKit
//
//  Read-only contract surfacing the last successful sync timestamp.
//  CloudKit exposes events via NSPersistentCloudKitContainer.Event;
//  this protocol is the seam UI uses — keeps the framework boundary
//  out of CashlyUI.
//

import Foundation

public struct SyncStatus: Sendable, Equatable {
    public let lastSyncedAt: Date?
    public let isHealthy: Bool

    public init(lastSyncedAt: Date?, isHealthy: Bool) {
        self.lastSyncedAt = lastSyncedAt
        self.isHealthy = isHealthy
    }

    public static let unknown = SyncStatus(lastSyncedAt: nil, isHealthy: true)
}

public protocol SyncStatusUseCase: Sendable {
    func currentStatus() async -> SyncStatus
    /// Persist a fresh "now" timestamp. The Data-side observer of
    /// `NSPersistentCloudKitContainer.eventChangedNotification` calls
    /// this when the export event reports success.
    func markSynced(at date: Date) async
}
