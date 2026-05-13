//
//  UserDefaultsMigrationE2ETests.swift
//  CashlyKit
//
//  Belt-and-braces around the one-shot legacy-blob migration. The
//  unit tests in UserDefaultsUserPreferencesTests cover individual
//  branches; this suite simulates the realistic install timelines
//  — first-launch on a legacy build, cold restart after migration,
//  re-install scenario — and pins the post-conditions.
//

import Foundation
import Testing
import CashlyDomain
import CashlyData

@Suite("UserDefaults legacy-user migration E2E", .tags(.unit, .data, .local))
struct UserDefaultsMigrationE2ETests {

    private func freshSuite() -> (name: String, suite: UserDefaults) {
        let name = "cashly.tests.\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: name)!
        suite.removePersistentDomain(forName: name)
        return (name, suite)
    }

    @Test("first launch after upgrade: blob migrates, key persists, blob is dropped")
    func firstLaunchAfterUpgrade() async throws {
        let (name, seed) = freshSuite()
        let user = User(id: "migrated", name: "Old", photo: "p")
        seed.set(try JSONEncoder().encode(user), forKey: "cashly.user")

        let prefs = UserDefaultsUserPreferences(suite: UserDefaults(suiteName: name)!)
        let resolved = await prefs.currentUserId()
        #expect(resolved == "migrated")

        let check = UserDefaults(suiteName: name)!
        #expect(check.string(forKey: "cashly.user.id") == "migrated")
        #expect(check.data(forKey: "cashly.user") == nil)
    }

    @Test("cold restart after migration: read uses the new key directly")
    func coldRestartAfterMigration() async throws {
        let (name, seed) = freshSuite()
        // Simulate the prior session's outcome — only the new key.
        seed.set("steady", forKey: "cashly.user.id")

        let prefs = UserDefaultsUserPreferences(suite: UserDefaults(suiteName: name)!)
        let resolved = await prefs.currentUserId()
        #expect(resolved == "steady")
    }

    @Test("re-installation wipes both keys: nil is returned")
    func reinstallation() async {
        let (name, _) = freshSuite()
        let prefs = UserDefaultsUserPreferences(suite: UserDefaults(suiteName: name)!)
        let resolved = await prefs.currentUserId()
        #expect(resolved == nil)
    }

    @Test("clearCurrentUserId wipes both legacy and new key")
    func clearWipesBoth() async throws {
        let (name, seed) = freshSuite()
        let user = User(id: "doomed", name: "Old", photo: "p")
        seed.set(try JSONEncoder().encode(user), forKey: "cashly.user")
        seed.set("doomed", forKey: "cashly.user.id")

        let prefs = UserDefaultsUserPreferences(suite: UserDefaults(suiteName: name)!)
        await prefs.clearCurrentUserId()
        let check = UserDefaults(suiteName: name)!
        #expect(check.data(forKey: "cashly.user") == nil)
        #expect(check.string(forKey: "cashly.user.id") == nil)
    }

    @Test("re-running migration after blob re-appears is still idempotent")
    func migrationIdempotentOnReplay() async throws {
        let (name, seed) = freshSuite()
        let user = User(id: "ghost", name: "X", photo: "p")
        seed.set(try JSONEncoder().encode(user), forKey: "cashly.user")

        // First read — migrates.
        var prefs = UserDefaultsUserPreferences(suite: UserDefaults(suiteName: name)!)
        _ = await prefs.currentUserId()

        // Pathological replay: another build / restore re-seeds the
        // legacy key. The new key still exists — verify the new key
        // wins (per the existing unit test) and that re-running the
        // currentUserId() path doesn't blow up.
        let check = UserDefaults(suiteName: name)!
        let user2 = User(id: "stale-blob", name: "Y", photo: "p")
        check.set(try JSONEncoder().encode(user2), forKey: "cashly.user")

        prefs = UserDefaultsUserPreferences(suite: UserDefaults(suiteName: name)!)
        let resolved = await prefs.currentUserId()
        // First migration won — re-seeded blob is ignored.
        #expect(resolved == "ghost")
    }
}
