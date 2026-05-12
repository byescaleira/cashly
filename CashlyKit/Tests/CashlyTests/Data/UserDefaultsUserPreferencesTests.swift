//
//  UserDefaultsUserPreferencesTests.swift
//  CashlyKit
//
//  Covers the UserDefaults-backed UserPreferencesUseCase: empty state,
//  set/clear roundtrip, and one-shot migration from the legacy
//  `cashly.user` full-User blob to `cashly.user.id`.
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("UserDefaults User Preferences", .tags(.unit, .data, .local))
struct UserDefaultsUserPreferencesTests {
    /// Creates a fresh in-memory suite, seeds it via the given closure,
    /// and hands back the actor. Keeps the suite scoped — no cross-test
    /// pollution and no `sending` race with the actor.
    private func makePreferences(seed: (UserDefaults) -> Void = { _ in }) -> UserDefaultsUserPreferences {
        let name = "cashly.tests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: name)!
        suite.removePersistentDomain(forName: name)
        seed(suite)
        return UserDefaultsUserPreferences(suite: suite)
    }

    @Test("currentUserId is nil when no id has been set and no legacy blob exists")
    func emptyReturnsNil() async {
        let prefs = makePreferences()
        let id = await prefs.currentUserId()
        #expect(id == nil)
    }

    @Test("setCurrentUserId then currentUserId roundtrips")
    func setGetRoundtrip() async {
        let prefs = makePreferences()
        await prefs.setCurrentUserId("user-42")
        let fetched = await prefs.currentUserId()
        #expect(fetched == "user-42")
    }

    @Test("clearCurrentUserId wipes both the new id key and the legacy blob")
    func clearWipesBoth() async throws {
        let user = User(id: "legacy-1", name: "L", photo: "p")
        let legacy = try JSONEncoder().encode(user)
        let prefs = makePreferences { suite in
            suite.set(legacy, forKey: "cashly.user")
        }
        await prefs.setCurrentUserId("user-1")
        await prefs.clearCurrentUserId()
        let fetched = await prefs.currentUserId()
        #expect(fetched == nil)
    }

    @Test("migrates legacy cashly.user blob to cashly.user.id on first read")
    func migrationFromLegacyBlob() async throws {
        let user = User(id: "legacy-42", name: "Old", photo: "p")
        let legacy = try JSONEncoder().encode(user)
        let prefs = makePreferences { suite in
            suite.set(legacy, forKey: "cashly.user")
        }
        let id = await prefs.currentUserId()
        #expect(id == "legacy-42")
        // Second read should hit the migrated key directly.
        let again = await prefs.currentUserId()
        #expect(again == "legacy-42")
    }

    @Test("new id key wins when both new and legacy keys are present")
    func newKeyWinsOverLegacy() async throws {
        let user = User(id: "legacy-99", name: "Old", photo: "p")
        let legacy = try JSONEncoder().encode(user)
        let prefs = makePreferences { suite in
            suite.set(legacy, forKey: "cashly.user")
            suite.set("new-1", forKey: "cashly.user.id")
        }
        let id = await prefs.currentUserId()
        #expect(id == "new-1")
    }
}
