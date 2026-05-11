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
    /// Returns a fresh in-memory UserDefaults suite per test so writes
    /// can't bleed into .standard or other cases.
    private func makeSuite() -> UserDefaults {
        let name = "cashly.tests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: name)!
        suite.removePersistentDomain(forName: name)
        return suite
    }

    @Test("currentUserId is nil when no id has been set and no legacy blob exists")
    func emptyReturnsNil() async {
        let prefs = UserDefaultsUserPreferences(suite: makeSuite())
        let id = await prefs.currentUserId()
        #expect(id == nil)
    }

    @Test("setCurrentUserId then currentUserId roundtrips")
    func setGetRoundtrip() async {
        let suite = makeSuite()
        let prefs = UserDefaultsUserPreferences(suite: suite)
        await prefs.setCurrentUserId("user-42")
        let fetched = await prefs.currentUserId()
        #expect(fetched == "user-42")
    }

    @Test("clearCurrentUserId wipes both the new id key and the legacy blob")
    func clearWipesBoth() async throws {
        let suite = makeSuite()
        let user = User(id: "legacy-1", name: "L", photo: "p")
        let legacy = try JSONEncoder().encode(user)
        suite.set(legacy, forKey: "cashly.user")
        let prefs = UserDefaultsUserPreferences(suite: suite)
        await prefs.setCurrentUserId("user-1")
        await prefs.clearCurrentUserId()
        #expect(suite.string(forKey: "cashly.user.id") == nil)
        #expect(suite.data(forKey: "cashly.user") == nil)
        let fetched = await prefs.currentUserId()
        #expect(fetched == nil)
    }

    @Test("migrates legacy cashly.user blob to cashly.user.id on first read")
    func migrationFromLegacyBlob() async throws {
        let suite = makeSuite()
        let user = User(id: "legacy-42", name: "Old", photo: "p")
        suite.set(try JSONEncoder().encode(user), forKey: "cashly.user")
        let prefs = UserDefaultsUserPreferences(suite: suite)
        let id = await prefs.currentUserId()
        #expect(id == "legacy-42")
        #expect(suite.string(forKey: "cashly.user.id") == "legacy-42")
    }

    @Test("new id key wins when both new and legacy keys are present")
    func newKeyWinsOverLegacy() async throws {
        let suite = makeSuite()
        let user = User(id: "legacy-99", name: "Old", photo: "p")
        suite.set(try JSONEncoder().encode(user), forKey: "cashly.user")
        suite.set("new-1", forKey: "cashly.user.id")
        let prefs = UserDefaultsUserPreferences(suite: suite)
        let id = await prefs.currentUserId()
        #expect(id == "new-1")
    }
}
