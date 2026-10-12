import CashlyData
import CashlyDomain
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct CloudBackupTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
    private let local = BackupFolder(
        url: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    private let drive = BackupFolder(
        url: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))

    private func model(cloud: BackupCloud) async throws -> DataModel {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(
            User(id: "owner", name: "Perfil", photo: "1"))
        let intelligence = LocalIntelligenceService(
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        return DataModel(
            backup: database.backup, intelligence: intelligence, defaults: defaults,
            folder: local, cloud: cloud)
    }

    @Test func savesToICloudDriveAndRestoresFromIt() async throws {
        let drive = drive
        let data = try await model(cloud: BackupCloud { drive })
        await data.loadBackups()
        #expect(data.cloudState == .available)
        #expect(!data.isCloudToggleDisabled)

        await data.setPlace(.iCloud)
        await data.backUpNow()
        #expect(data.message == "Backup saved to iCloud Drive.")
        #expect(try drive.files().count == 1)
        #expect((try? local.files()) == nil)
        #expect(data.placeDescription.contains("iCloud Drive"))

        let saved = try #require(data.savedBackups.first)
        await data.openSaved(saved)
        #expect(data.isRestoringBackup)
        #expect(data.backupStep == .review)
        #expect(data.pendingRestore?.users.map(\.id) == ["owner"])
    }

    @Test func fallsBackToDeviceWhenICloudIsUnavailable() async throws {
        let data = try await model(cloud: .unavailable)
        await data.setPlace(.iCloud)
        await data.loadBackups()
        #expect(data.cloudState == .unavailable)
        #expect(data.cloudFooter.hasPrefix("iCloud Drive isn't available"))
        await data.backUpNow()
        #expect(data.message == "Backup saved on this device.")
        #expect(try local.files().count == 1)
        #expect(data.savedBackups.count == 1)
        #expect(try await model(cloud: .unavailable).place == .iCloud)
    }

    @Test func placeholdersCountAsSavedBackups() throws {
        try FileManager.default.createDirectory(at: drive.url, withIntermediateDirectories: true)
        try Data().write(to: drive.url.appending(path: ".Cashly 2026-10-01.json.icloud"))
        try Data().write(to: drive.url.appending(path: "Cashly 2026-10-08.json"))
        try Data().write(to: drive.url.appending(path: ".DS_Store"))
        let names = try drive.files().map(\.lastPathComponent)
        #expect(names == ["Cashly 2026-10-08.json", "Cashly 2026-10-01.json"])
    }

    @Test func savedBackupTitleShowsTheDay() {
        let saved = SavedBackup(url: URL(filePath: "/tmp/Cashly 2026-10-12.json"))
        #expect(saved.title.contains("2026"))
        #expect(SavedBackup(url: URL(filePath: "/tmp/outro.json")).title == "outro")
    }
}
