//
//  SpotlightIndexerUseCase.swift
//  CashlyKit
//
//  CoreSpotlight indexer surface. UI / app delegate hand it a list
//  of transactions on every fetch; the implementation in CashlyData
//  builds CSSearchableItems and submits them. macOS / visionOS pull
//  the same path — CoreSpotlight ships there too.
//

import Foundation

public protocol SpotlightIndexerUseCase: Sendable {
    /// Replace the current Cashly index with the supplied list.
    /// Items not in the new list are dropped from Spotlight.
    func index(transactions: [Transaction]) async

    /// Wipe every Cashly entry — call on sign-out / data wipe.
    func clear() async
}
