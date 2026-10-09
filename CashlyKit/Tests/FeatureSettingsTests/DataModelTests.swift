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
        #expect(data.message == "Backup salvo.")
    }

    @Test func readingAskForConfirmationBeforeRestoring() async throws {
        let (data, database) = try await model()
        let backup = try await database.backup.export().backup
        let url = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString + ".json")
        try backup.encoded().write(to: url)
        _ = try await database.backup.eraseAll()
        data.read(.success(url))
        #expect(data.isConfirmingRestore)
        let pending = try #require(data.pendingRestore)
        #expect(data.description(of: pending).hasPrefix("1 usuário, 0 categorias"))
        data.isConfirmingRestore = false
        #expect(data.pendingRestore == nil)
        await data.restore(pending)
        #expect(data.message == "Backup importado: 1 registro.")
        #expect(try await database.repositories(for: nil).users.users() == [owner])
    }

    @Test func unreadableFileShowsError() async throws {
        let (data, _) = try await model()
        let url = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString + ".json")
        try Data("texto".utf8).write(to: url)
        data.read(.success(url))
        #expect(data.pendingRestore == nil)
        #expect(data.error == .invalidInput("O arquivo não é um backup do Cashly."))
    }

    @Test func eraseRemovesEverything() async throws {
        let (data, database) = try await model()
        await data.eraseAll()
        #expect(data.message == "Todos os dados foram apagados.")
        #expect(try await database.repositories(for: nil).users.users().isEmpty)
    }
}
