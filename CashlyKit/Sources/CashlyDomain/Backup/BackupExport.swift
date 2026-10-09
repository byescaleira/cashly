public struct BackupExport: Sendable {
    public let backup: CashlyBackup
    public let skipped: Int

    public init(backup: CashlyBackup, skipped: Int) {
        self.backup = backup
        self.skipped = skipped
    }
}
