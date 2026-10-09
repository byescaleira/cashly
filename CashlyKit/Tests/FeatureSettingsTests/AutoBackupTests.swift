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

    private func model() async throws -> DataModel {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(
            User(id: "owner", name: "Perfil", photo: "1"))
        let intelligence = LocalIntelligenceService(
            directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        return DataModel(
            backup: database.backup, intelligence: intelligence, defaults: defaults, folder: folder)
    }

    @Test func weeklyCopiesKeepTheNewest() async throws {
        let data = try await model()
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
        #expect(data.autoBackupFooter.contains("Última:"))
    }

    @Test func spreadsheetExportUsesCSV() async throws {
        let data = try await model()
        await data.prepareExport(as: .commaSeparatedText)
        #expect(data.exportType == .commaSeparatedText)
        #expect(data.fileName.hasPrefix("Cashly transações"))
        let text = String(decoding: try #require(data.document).data, as: UTF8.self)
        #expect(text.hasPrefix("Data;Usuário;"))
        data.finishExport(.success(URL(filePath: "/tmp/a.csv")))
        #expect(data.message == "Planilha salva.")
    }
}
