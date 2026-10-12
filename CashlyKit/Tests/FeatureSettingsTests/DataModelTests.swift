import CashlyData
import CashlyDomain
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct DataModelTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")

    private func model() async throws -> (DataModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let intelligence = LocalIntelligenceService(
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        return (DataModel(backup: database.backup, intelligence: intelligence), database)
    }

    @Test func exportPreparesDocumentAndReportsSaving() async throws {
        let (data, _) = try await model()
        await data.prepareExport()
        #expect(data.isExporting)
        let document = try #require(data.document)
        #expect(try CashlyBackup(data: document.data).users.map(\.id) == ["owner"])
        data.finishExport(.success(URL(filePath: "/tmp/backup.json")))
        #expect(data.document == nil)
        #expect(data.message == "Backup saved.")
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
        #expect(data.description(of: pending).contains("0 categories"))
        await data.restore(pending)
        #expect(data.backupStep == .done)
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
        await data.eraseAll()
        #expect(data.message == "All data was deleted.")
        #expect(try await database.repositories(for: nil).users.users().isEmpty)
    }
}
