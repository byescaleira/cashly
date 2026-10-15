import CashlyData
import CashlyDomain
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct DataModelTests {
    private let owner = User(id: "owner", name: "Perfil")

    private func model() async throws -> (DataModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let intelligence = LocalIntelligenceService(
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        return (DataModel(backup: database.backup, intelligence: intelligence), database)
    }

    private func backups(_ database: CashlyDatabase) async throws -> Int {
        try await database.repositories(for: owner.id).game.events()
            .filter { $0.kind == .backupCreated }.count
    }

    @Test func exportPreparesDocumentAndReportsSaving() async throws {
        let (data, database) = try await model()
        await data.prepareExport()
        #expect(data.isExporting)
        let document = try #require(data.document)
        #expect(try CashlyBackup(data: document.data).users.map(\.id) == ["owner"])
        #expect(try await backups(database) == 0)
        await data.finishExport(.success(URL(filePath: "/tmp/backup.json")))
        #expect(data.document == nil)
        #expect(data.message == "Backup saved.")
        #expect(try await backups(database) == 1)
    }

    @Test func measuringInventoryRecordsNoBackup() async throws {
        let (data, database) = try await model()
        await data.load()
        await data.refreshInventory()
        #expect(data.inventory?.count(.profiles) == 1)
        #expect(try await database.repositories(for: owner.id).game.events().isEmpty)
    }

    @Test func cancelledExportRecordsNoBackup() async throws {
        let (data, database) = try await model()
        await data.prepareExport()
        await data.finishExport(.failure(CocoaError(.userCancelled)))
        #expect(data.message == nil)
        #expect(try await backups(database) == 0)
    }

    @Test func backupImportReviewsBeforeRestoring() async throws {
        let (data, database) = try await model()
        let backup = try await database.backup.export().backup
        let url = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString + ".json")
        try backup.encoded().write(to: url)
        _ = try await database.backup.eraseAll()
        data.startBackupImport()
        #expect(data.isRestoringBackup)
        #expect(data.backupStep == .intro)
        data.read(.success(url))
        #expect(data.backupStep == .review)
        let pending = try #require(data.pendingRestore)
        let merge = try #require(data.pendingMerge)
        #expect(merge.file.count(.profiles) == 1)
        #expect(merge.added == 1)
        #expect(merge.rows.count == 3)
        await data.restore(pending)
        #expect(data.backupStep == .done)
        #expect(data.inventory?.count(.profiles) == 1)
        #expect(try await database.repositories(for: nil).users.users() == [owner])
    }

    @Test func unreadableFileShowsError() async throws {
        let (data, _) = try await model()
        let url = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString + ".json")
        try Data("texto".utf8).write(to: url)
        data.read(.success(url))
        #expect(data.pendingRestore == nil)
        #expect(data.error == .invalidInput("This file isn't a Cashly backup."))
    }

    @Test func eraseRemovesEverything() async throws {
        let (data, database) = try await model()
        await data.load()
        #expect(data.inventory?.count(.profiles) == 1)
        data.startErase()
        #expect(data.isErasing)
        #expect(data.eraseStep == .review)
        await data.eraseAll()
        #expect(data.eraseStep == .done)
        #expect(data.message == nil)
        #expect(data.inventory?.isEmpty == true)
        #expect(try await database.repositories(for: nil).users.users().isEmpty)
        data.closeErase()
        #expect(!data.isErasing)
    }

    @Test func exportDuringEraseOnlyMarksTheBackup() async throws {
        let (data, _) = try await model()
        data.startErase()
        #expect(data.eraseBackupState(now: .now) == .init(text: "None yet", isSafe: false))
        await data.prepareExport()
        #expect(data.isExportingFromErase)
        #expect(!data.isExportingFromPage)
        await data.finishExport(.success(URL(filePath: "/tmp/backup.json")))
        #expect(data.message == nil)
        #expect(data.exportedBeforeErase)
        #expect(data.eraseBackupState(now: .now) == .init(text: "Exported just now", isSafe: true))
        data.startErase()
        #expect(!data.exportedBeforeErase)
    }
}
