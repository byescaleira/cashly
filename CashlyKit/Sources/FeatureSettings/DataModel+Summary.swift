import CashlyDomain
import Foundation

extension DataModel {
    struct BackupSchedule: Equatable {
        let last: String
        let next: String
        let fraction: Double
    }

    struct EraseBackupState: Equatable {
        let text: String
        let isSafe: Bool
    }

    func backupSchedule(now: Date, calendar: Calendar = .current) -> BackupSchedule? {
        guard autoBackup else { return nil }
        let due = String(appLocalized: "When Cashly next opens")
        guard let lastAutoBackup else {
            return BackupSchedule(last: String(appLocalized: "Not yet"), next: due, fraction: 1)
        }
        let next = lastAutoBackup.addingTimeInterval(Self.autoBackupInterval)
        let elapsed = now.timeIntervalSince(lastAutoBackup) / Self.autoBackupInterval
        return BackupSchedule(
            last: RelativeTime.day(lastAutoBackup, now: now, calendar: calendar),
            next: next <= now ? due : RelativeTime.day(next, now: now, calendar: calendar),
            fraction: min(max(elapsed, 0), 1))
    }

    var latestBackup: Date? {
        [savedBackups.first?.date, lastAutoBackup].compactMap(\.self).max()
    }

    func startErase() {
        eraseStep = .review
        exportedBeforeErase = false
        isErasing = true
    }

    func closeErase() {
        isErasing = false
    }

    func eraseBackupState(now: Date, calendar: Calendar = SavedBackup.calendar) -> EraseBackupState
    {
        if exportedBeforeErase {
            return EraseBackupState(text: String(appLocalized: "Exported just now"), isSafe: true)
        }
        guard let latestBackup else {
            return EraseBackupState(text: String(appLocalized: "None yet"), isSafe: false)
        }
        return EraseBackupState(
            text: RelativeTime.day(latestBackup, now: now, calendar: calendar),
            isSafe: now.timeIntervalSince(latestBackup) < Self.autoBackupInterval)
    }

    var eraseRecordsLabel: String { String(appLocalized: "Records") }

    var eraseExtrasLabel: String { String(appLocalized: "Not in backups") }

    var eraseExtrasText: String {
        String(appLocalized: "Journey progress, captured payments and intelligence models")
    }

    var eraseBackupLabel: String { String(appLocalized: "Latest backup") }

    var eraseCloudNote: String {
        String(appLocalized: "With iCloud on, your other devices lose them too.")
    }

    var eraseRecordsText: String {
        guard let inventory, !inventory.isEmpty else { return String(appLocalized: "Nothing yet") }
        return inventory.recordsText
    }

    var eraseTotalText: String {
        String(appLocalized: "\(inventory?.total ?? 0) records will be deleted")
    }

    func eraseAll() async {
        await perform {
            for userID in try await backup.eraseAll() {
                try? await intelligence.clean(userID: userID)
            }
            eraseStep = .done
        }
        await refreshInventory()
    }
}
