//
//  InMemoryUserPreferences.swift
//  CashlyKit
//
//  In-memory `UserPreferencesUseCase` for tests/previews — no
//  UserDefaults, no migration path.
//

import CashlyDomain

public actor InMemoryUserPreferences: UserPreferencesUseCase {
    private var storedId: String?

    public init(initial: String? = nil) {
        self.storedId = initial
    }

    public func currentUserId() async -> String? { storedId }

    public func setCurrentUserId(_ id: String) async { storedId = id }

    public func clearCurrentUserId() async { storedId = nil }
}
