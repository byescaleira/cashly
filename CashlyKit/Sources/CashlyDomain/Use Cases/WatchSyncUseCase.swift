//
//  WatchSyncUseCase.swift
//  CashlyKit
//
//  iOS-side contract for pushing snapshots to a paired Apple Watch.
//  Production impl wraps WatchConnectivity's WCSession; in-memory
//  impl records sent payloads so tests can assert without a paired
//  device. The Watch app target (when added via Xcode) consumes the
//  same payload shape on its WCSessionDelegate callbacks.
//

import Foundation

public struct WatchSnapshot: Sendable, Equatable, Codable {
    /// Identifier of the user the snapshot belongs to. Watch shows
    /// nothing when the iOS app has no current user selected.
    public let userId: String?
    /// Pre-formatted income / expense totals for the current month.
    public let income: Double
    public let expense: Double
    public let net: Double
    /// Currency code the iOS app currently displays in. Watch reuses
    /// it so the same locale grouping ships across devices.
    public let currencyCode: String
    /// Latest five transactions surfaced on the Watch root view.
    public let recent: [WatchTransactionRow]

    public init(
        userId: String?,
        income: Double,
        expense: Double,
        net: Double,
        currencyCode: String,
        recent: [WatchTransactionRow]
    ) {
        self.userId = userId
        self.income = income
        self.expense = expense
        self.net = net
        self.currencyCode = currencyCode
        self.recent = recent
    }
}

public struct WatchTransactionRow: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let summary: String
    public let amount: Double
    public let date: TimeInterval
    public let kindRaw: Int

    public init(id: String, summary: String, amount: Double, date: TimeInterval, kindRaw: Int) {
        self.id = id
        self.summary = summary
        self.amount = amount
        self.date = date
        self.kindRaw = kindRaw
    }
}

public protocol WatchSyncUseCase: Sendable {
    /// Pushes the snapshot to the paired Watch via WCSession's
    /// `updateApplicationContext` (idempotent, latest-wins). Silent
    /// no-op when no Watch is paired or WCSession is unavailable.
    func send(_ snapshot: WatchSnapshot) async
    /// `true` when WCSession reports a Watch installed + reachable.
    /// UI surfaces this as a chip when the user toggles a setting
    /// that depends on the Watch.
    func isCompanionInstalled() async -> Bool
}
