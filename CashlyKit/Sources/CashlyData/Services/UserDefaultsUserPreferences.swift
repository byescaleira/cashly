//
//  UserDefaultsUserPreferences.swift
//  CashlyKit
//
//  Concrete UserPreferencesUseCase backed by UserDefaults. Migrates
//  the legacy full-User-blob format from key `cashly.user` to a plain
//  id stored under `cashly.user.id` on first read.
//

import Foundation
import CashlyDomain
import PrismFoundation

public actor UserDefaultsUserPreferences: UserPreferencesUseCase {
    private let suite: UserDefaults
    private static let currentUserIdKey = "cashly.user.id"
    private static let legacyUserKey = "cashly.user"

    public init(suite: UserDefaults = .standard) {
        self.suite = suite
    }

    public func currentUserId() async -> String? {
        if let id = suite.string(forKey: Self.currentUserIdKey) {
            return id
        }
        // Migration path: legacy key stored the full encoded User. If we
        // find it, decode, persist just the id under the new key, and
        // leave the legacy blob in place (will be wiped on next clear).
        if let legacyData = suite.data(forKey: Self.legacyUserKey),
           let user = try? legacyData.entity(for: User.self) {
            suite.set(user.id, forKey: Self.currentUserIdKey)
            return user.id
        }
        return nil
    }

    public func setCurrentUserId(_ id: String) async {
        suite.set(id, forKey: Self.currentUserIdKey)
    }

    public func clearCurrentUserId() async {
        suite.removeObject(forKey: Self.currentUserIdKey)
        suite.removeObject(forKey: Self.legacyUserKey)
    }
}
