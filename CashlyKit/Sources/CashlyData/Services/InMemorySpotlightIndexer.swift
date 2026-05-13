//
//  InMemorySpotlightIndexer.swift
//  CashlyKit
//
//  No-op stub used by tests + macOS where the CoreSpotlight import
//  is excluded by the production impl's `#if canImport`. Lives in
//  CashlyData so the factory can fall back without dragging the
//  Mock target into Release.
//

import Foundation
import CashlyDomain

public actor InMemorySpotlightIndexer: SpotlightIndexerUseCase {
    private var indexed: [Transaction] = []
    public init() {}

    public var contents: [Transaction] { indexed }

    public func index(transactions: [Transaction]) async {
        indexed = transactions
    }

    public func clear() async {
        indexed.removeAll()
    }
}
