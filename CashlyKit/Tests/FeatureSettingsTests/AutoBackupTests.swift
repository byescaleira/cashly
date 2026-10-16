import CashlyData
import CashlyDomain
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct AutoBackupTests {
    private let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard
    private let folder = BackupFolder(
        url: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString), keeping: 2)

    private func model() async throws -> (DataModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(
            User(id: "owner", name: "Perfil"))
        let intelligence = LocalIntelligenceService(
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        let data = DataModel(
            backup: database.backup, intelligence: intelligence, defaults: defaults, folder: folder)
        return (data, database)
    }

    private func backups(_ database: CashlyDatabase) async throws -> Int {
        try await database.repositories(for: "owner").game.events()
            .filter { $0.kind == .backupCreated }.count
    }

    @Test func weeklyCopiesKeepTheNewest() async throws {
        let (data, database) = try await model()
        await data.runAutoBackupIfNeeded()
        #expect((try? folder.files()) == nil)

        await data.setAutoBackup(true)
        let first = try #require(data.lastAutoBackup)
        await data.runAutoBackupIfNeeded(now: first.addingTimeInterval(60))
        #expect(try folder.files().count == 1)

        let week = DataModel.autoBackupInterval
        await data.runAutoBackupIfNeeded(now: first.addingTimeInterval(week))
        let latest = first.addingTimeInterval(week * 2)
        await data.runAutoBackupIfNeeded(now: latest)
        let files = try folder.files()
        #expect(files.count == 2)
        let name = "Cashly " + latest.formatted(.iso8601.year().month().day()) + ".json"
        #expect(files.first?.lastPathComponent == name)
        let saved = try CashlyBackup(data: Data(contentsOf: try #require(files.first)))
        #expect(saved.users.map(\.id) == ["owner"])
        #expect(data.autoBackupFooter.hasPrefix("One copy a week"))
        #expect(data.latestBackup == latest)
        #expect(try await backups(database) == 3)
    }

    @Test func backUpNowRecordsTheBackup() async throws {
        let (data, database) = try await model()
        #expect(try await backups(database) == 0)
        await data.backUpNow()
        #expect(try folder.files().count == 1)
        #expect(try await backups(database) == 1)
    }

    @Test func scheduleShowsLastAndNextCopy() async throws {
        let (data, _) = try await model()
        #expect(data.backupSchedule(now: .now) == nil)
        #expect(data.overviewValue(now: .now) == nil)
        await data.setAutoBackup(true)
        let last = try #require(data.lastAutoBackup)
        #expect(data.overviewValue(now: last) != nil)
        let week = DataModel.autoBackupInterval
        let halfway = try #require(data.backupSchedule(now: last.addingTimeInterval(week / 2)))
        #expect(abs(halfway.fraction - 0.5) < 0.001)
        #expect(halfway.last == RelativeTime.day(last, now: last.addingTimeInterval(week / 2)))
        #expect(halfway.next != "When Cashly next opens")
        let late = try #require(data.backupSchedule(now: last.addingTimeInterval(week * 2)))
        #expect(late.fraction == 1)
        #expect(late.next == "When Cashly next opens")
        data.resetAutoBackupSchedule()
        #expect(
            data.backupSchedule(now: .now)
                == .init(last: "Not yet", next: "When Cashly next opens", fraction: 1))
    }

    @Test func spreadsheetExportUsesCSV() async throws {
        let (data, database) = try await model()
        await data.prepareExport(as: .commaSeparatedText)
        #expect(data.exportType == .commaSeparatedText)
        #expect(data.fileName.hasPrefix("Cashly transactions"))
        let text = String(decoding: try #require(data.document).data, as: UTF8.self)
        #expect(text.hasPrefix("Date;Profile;"))
        await data.finishExport(.success(URL(filePath: "/tmp/a.csv")))
        #expect(data.message == "Spreadsheet saved.")
        #expect(try await backups(database) == 0)
    }
}
