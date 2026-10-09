public protocol BackupRepository: Sendable {
    func export() async throws -> BackupExport
    func restore(_ backup: CashlyBackup) async throws
    func eraseAll() async throws -> [String]
}
