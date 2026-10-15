import CashlyData
import CashlyDomain
import Foundation
import SwiftData
import Testing

struct UserPhotoTests {
    @Test(arguments: [
        ProfilePhoto.initials(color: "2E7D74"),
        .symbol("cat.fill", color: "C47C86"),
        .emoji("🌻", color: "DDB040"),
        .memoji(Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A])),
    ])
    func everyKindOfPhotoIsSavedAndReadBack(photo: ProfilePhoto) async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        try await users.save(User(id: "ana", name: "Ana Souza", photo: photo))
        #expect(try await users.user(id: "ana")?.photo == photo)
    }

    @Test func switchingFromMemojiDropsTheImage() async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        try await users.save(User(id: "ana", name: "Ana Souza", photo: .memoji(Data([1, 2]))))
        try await users.save(User(id: "ana", name: "Ana Souza", photo: .initials(color: "2E7D74")))
        #expect(try await users.user(id: "ana")?.photo == .initials(color: "2E7D74"))
    }

    @Test func invalidPhotoIsRefused() async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        await #expect(throws: CashlyError.self) {
            try await users.save(User(id: "ana", name: "Ana Souza", photo: .memoji(Data())))
        }
        #expect(try await users.users().isEmpty)
    }

    @Test func restoringABackupBringsTheMemojiBack() async throws {
        let image = Data([0x89, 0x50, 0x4E, 0x47])
        let source = try CashlyDatabase.open(inMemory: true)
        try await source.repositories(for: nil).users.save(
            User(id: "ana", name: "Ana Souza", photo: .memoji(image)))
        let backup = try await source.backup.export().backup
        let target = try CashlyDatabase.open(inMemory: true)
        try await target.backup.restore(backup)
        #expect(
            try await target.repositories(for: nil).users.user(id: "ana")?.photo == .memoji(image))
    }

    @MainActor @Test func storesFromTheLastVersionOpenWithInitials() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "legacy.store")
        do {
            let schema = Schema(versionedSchema: CashlySchemaV5.self)
            let configuration = ModelConfiguration(
                schema: schema, url: url, cloudKitDatabase: .none)
            let context = ModelContext(
                try ModelContainer(for: schema, configurations: configuration))
            context.insert(CashlySchemaV5.UserEntity(id: "ana", name: "Ana Souza", photo: "58"))
            try context.save()
        }
        let database = try CashlyDatabase.open(cloudSync: false, storeURL: url)
        let user = try #require(try await database.repositories(for: nil).users.user(id: "ana"))
        #expect(user.photo == .default)
        #expect(user.initials == "AS")
    }
}
