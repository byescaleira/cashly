import CashlyData
import CashlyDomain
import Foundation
import Testing

struct UserPhotoTests {
    @Test(arguments: [
        ProfilePhoto.initials(color: "2E7D74"),
        .symbol("cat.fill", color: "C47C86"),
        .illustration("ocean-01"),
    ])
    func everyKindOfPhotoIsSavedAndReadBack(photo: ProfilePhoto) async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        try await users.save(User(id: "ana", name: "Ana Souza", photo: photo))
        #expect(try await users.user(id: "ana")?.photo == photo)
    }

    @Test func invalidPhotoIsRefused() async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        await #expect(throws: CashlyError.self) {
            try await users.save(User(id: "ana", name: "Ana Souza", photo: .illustration("x")))
        }
        #expect(try await users.users().isEmpty)
    }

    @Test func restoringABackupKeepsTheIllustration() async throws {
        let source = try CashlyDatabase.open(inMemory: true)
        try await source.repositories(for: nil).users.save(
            User(id: "ana", name: "Ana Souza", photo: .illustration("savanna-02")))
        let backup = try await source.backup.export().backup
        let target = try CashlyDatabase.open(inMemory: true)
        try await target.backup.restore(backup)
        let restored = try await target.repositories(for: nil).users.user(id: "ana")
        #expect(restored?.photo == .illustration("savanna-02"))
    }
}
