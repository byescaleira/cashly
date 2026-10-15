import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureSettings

struct DataSummaryTests {
    private static func backup(
        users: [String] = ["u1"], categories: [String] = ["c1"],
        transactions: [String: String] = [:]
    ) throws -> CashlyBackup {
        let userRecords = users.map { #"{"id":"\#($0)","name":"A","photo":"1"}"# }
        let categoryRecords = categories.map {
            #"{"id":"\#($0)","userID":"u1","name":"C","color":"FFFFFF","icon":"cart"}"#
        }
        let transactionRecords = transactions.map { id, date in
            #"{"id":"\#(id)","categoryID":"c1","kind":0,"amount":100,"date":"\#(date)","summary":"","status":0,"tagIDs":[],"participants":[]}"#
        }
        let json = """
            {"format":"cashly-backup","version":1,"currency":"BRL","exportedAt":"2026-10-01T12:00:00Z",\
            "users":[\(userRecords.joined(separator: ","))],\
            "categories":[\(categoryRecords.joined(separator: ","))],"tags":[],"budgets":[],\
            "transactions":[\(transactionRecords.joined(separator: ","))]}
            """
        return try CashlyBackup(data: Data(json.utf8))
    }

    @Test func inventoryCountsRecordsAndPeriod() throws {
        let file = try Self.backup(
            users: ["u1", "u2"], categories: ["c1", "c2", "c3"],
            transactions: ["t1": "2025-03-10T12:00:00Z", "t2": "2026-10-02T12:00:00Z"])
        let inventory = try DataInventory.measuring(file)
        #expect(inventory.transactions == 2)
        #expect(inventory.count(.categories) == 3)
        #expect(inventory.count(.profiles) == 2)
        #expect(inventory.count(.budgets) == 0)
        #expect(inventory.total == 7)
        #expect(!inventory.isEmpty)
        #expect(inventory.bytes > 0)
        #expect(
            inventory.period?.lowerBound
                == ISO8601DateFormatter().date(from: "2025-03-10T12:00:00Z"))
        #expect(inventory.periodText?.contains(" – ") == true)
        #expect(inventory.otherKinds == [.categories, .tags, .budgets, .profiles])
        #expect(inventory.summaryLine.contains(" · "))
    }

    @Test func inventoryWithoutTransactionsHasNoPeriod() throws {
        let inventory = DataInventory(backup: try Self.backup(users: [], categories: []), bytes: 0)
        #expect(inventory.isEmpty)
        #expect(inventory.period == nil)
        #expect(inventory.periodText == nil)
        #expect(inventory.summaryLine == inventory.sizeText)
    }

    @Test func mergeSeparatesNewFromUpdatedRecords() throws {
        let current = DataInventory(
            backup: try Self.backup(transactions: ["t1": "2026-01-01T12:00:00Z"]), bytes: 10)
        let file = try Self.backup(
            categories: ["c1", "c2"],
            transactions: [
                "t1": "2026-01-01T12:00:00Z", "t2": "2026-02-01T12:00:00Z",
                "t3": "2026-03-01T12:00:00Z",
            ])
        let merge = BackupMerge(file: file, bytes: 20, current: current)
        #expect(merge.updated == 3)
        #expect(merge.added == 3)
        #expect(merge.changeText == "3 new · 3 updated")
        #expect(merge.rows.map(\.isHighlighted) == [false, false, true])
        let fresh = BackupMerge(file: file, bytes: 20, current: nil)
        #expect(fresh.added == 6)
        #expect(fresh.changeText == "6 new")
    }

    @Test func emptyFileHasNothingToAdd() throws {
        let merge = BackupMerge(
            file: try Self.backup(users: [], categories: []), bytes: 0, current: nil)
        #expect(merge.changeText == "Nothing to add")
    }

    @Test func savedBackupReadsTheDayFromTheName() {
        let saved = SavedBackup(url: URL(filePath: "/tmp/Cashly 2026-10-10.json"))
        let date = Date(timeIntervalSince1970: 1_791_590_400)
        #expect(saved.date == date)
        let now = date.addingTimeInterval(3 * 24 * 60 * 60 + 3600)
        #expect(
            saved.detail(now: now)
                == RelativeTime.day(date, now: now, calendar: SavedBackup.calendar))
        #expect(SavedBackup(url: URL(filePath: "/tmp/other.json")).date == nil)
    }
}

struct ReleaseTests {
    private let releases = ["1.0", "2.0", "1.1"].map {
        Release(version: $0, headline: $0, notes: [])
    }

    @Test func featuresTheNewestReleaseUpToTheInstalledVersion() {
        #expect(Release.ordered(releases).map(\.version) == ["2.0", "1.1", "1.0"])
        #expect(Release.featured(for: "1.1.2", in: releases)?.version == "1.1")
        #expect(Release.featured(for: "2.0", in: releases)?.version == "2.0")
        #expect(Release.featured(for: "0.9", in: releases)?.version == "1.0")
        #expect(Release.earlier(than: "1.1.2", in: releases).map(\.version) == ["1.0"])
        #expect(Release.earlier(than: "10.0", in: releases).map(\.version) == ["1.1", "1.0"])
    }

    @Test func currentVersionHasNotesWithDistinctSymbols() throws {
        let release = try #require(Release.featured(for: "1.0"))
        #expect(release.version == "1.0")
        #expect(Set(release.notes.map(\.symbol)).count == release.notes.count)
        #expect(release.heroNotes.count == 5)
    }
}

@MainActor
struct DeveloperFlagsTests {
    @Test func tracksOverridesAndRestoresDefaults() {
        let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
        let flags = FeatureFlags(defaults: defaults)
        #expect(flags.overriddenCount == 0)
        #expect(flags.source(of: .intelligence) == "Default: off")
        #expect(flags.source(of: .guides) == "Default: on")
        flags.override(.guides, false)
        #expect(flags.isOverridden(.guides))
        #expect(flags.overriddenCount == 1)
        #expect(flags.source(of: .guides) == "Changed on this device")
        flags.restoreDefaults()
        #expect(flags.overriddenCount == 0)
        #expect(flags.isOn(.guides))
    }
}

@MainActor
struct CloudStatusTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    @Test func withoutContainerSyncIsUnavailable() {
        let settings = SettingsModel(defaults: defaults, cloudContainer: nil)
        #expect(settings.cloudStatus == .unavailable)
        #expect(settings.cloudDetail(now: .now) == "Sync isn't available in this installation.")
    }

    @Test func syncOnWaitsForTheFirstSyncAndThenShowsIt() {
        let settings = SettingsModel(defaults: defaults, cloudContainer: "iCloud.test")
        #expect(settings.cloudStatus == .on)
        #expect(settings.reachTitle == "All your devices")
        #expect(settings.cloudDetail(now: .now) == "Waiting for the first sync.")
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        settings.recordSync(date)
        #expect(settings.cloudDetail(now: date.addingTimeInterval(300)).hasPrefix("Last synced"))
        #expect(settings.syncedItems.count == 3)
        #expect(settings.localItems.count == 2)
    }

    @Test func changingSyncWaitsForTheNextLaunch() {
        let settings = SettingsModel(defaults: defaults, cloudContainer: "iCloud.test")
        settings.isSyncOn = false
        #expect(settings.cloudStatus == .pending)
        #expect(settings.cloudValue == "Restart to Apply")
        #expect(settings.cloudDetail(now: .now) == "Sync turns off the next time Cashly opens.")
        #expect(settings.cloudToggleFooter.hasPrefix("Turn it on"))
        let next = SettingsModel(defaults: defaults, cloudContainer: "iCloud.test")
        #expect(next.cloudStatus == .off)
        #expect(next.reachTitle == "This device only")
        next.isSyncOn = true
        #expect(next.cloudStatus == .pending)
        #expect(next.cloudDetail(now: .now) == "Sync turns on the next time Cashly opens.")
        #expect(next.cloudToggleFooter.hasPrefix("Turning sync off deletes nothing"))
    }
}
