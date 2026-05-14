//
//  InMemoryWatchSync.swift
//  CashlyKit
//
//  Test stub. Records every snapshot the iOS code tries to push
//  so feature tests can assert "did the middleware ship a fresh
//  payload after a relevant state change" without a paired Watch.
//

import Foundation
import CashlyDomain

public actor InMemoryWatchSync: WatchSyncUseCase {
    public private(set) var snapshots: [WatchSnapshot] = []
    private var companionInstalled: Bool

    public init(companionInstalled: Bool = false) {
        self.companionInstalled = companionInstalled
    }

    public func setCompanionInstalled(_ value: Bool) {
        self.companionInstalled = value
    }

    public func send(_ snapshot: WatchSnapshot) async {
        snapshots.append(snapshot)
    }

    public func isCompanionInstalled() async -> Bool {
        companionInstalled
    }
}
