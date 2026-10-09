import CashlyDomain

struct SwiftDataBackupRepository: BackupRepository {
    let store: CashlyStore

    func export() async throws -> BackupExport {
        try await store.exportBackup()
    }

    func restore(_ backup: CashlyBackup) async throws {
        try await store.restore(backup)
    }

    func eraseAll() async throws -> [String] {
        try await store.eraseAll()
    }
}
