//
//  InMemoryAppLock.swift
//  CashlyKit
//
//  Stub AppLockUseCase for tests + previews + macOS dev. Returns a
//  configurable outcome and records every call.
//

import Foundation
import CashlyDomain

public actor InMemoryAppLock: AppLockUseCase {
    private var enabled: Bool
    private var nextOutcome: AppLockOutcome
    public private(set) var authenticationCalls: [String] = []

    public init(enabled: Bool = false, outcome: AppLockOutcome = .unlocked) {
        self.enabled = enabled
        self.nextOutcome = outcome
    }

    public func isEnabled() async -> Bool { enabled }

    public func setEnabled(_ enabled: Bool) async {
        self.enabled = enabled
    }

    public func setOutcome(_ outcome: AppLockOutcome) {
        self.nextOutcome = outcome
    }

    public func authenticate(reason: String) async -> AppLockOutcome {
        authenticationCalls.append(reason)
        return nextOutcome
    }
}
