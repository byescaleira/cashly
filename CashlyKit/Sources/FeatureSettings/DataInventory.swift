import CashlyDomain
import Foundation

enum BackupRecordKind: CaseIterable, Sendable {
    case transactions, categories, tags, budgets, profiles

    func ids(in backup: CashlyBackup) -> [String] {
        switch self {
        case .transactions: backup.transactions.map(\.id)
        case .categories: backup.categories.map(\.id)
        case .tags: backup.tags.map(\.id)
        case .budgets: backup.budgets.map(\.id)
        case .profiles: backup.users.map(\.id)
        }
    }

    func count(_ value: Int) -> String {
        switch self {
        case .transactions: String(appLocalized: "\(value) transactions")
        case .categories: String(appLocalized: "\(value) categories")
        case .tags: String(appLocalized: "\(value) tags")
        case .budgets: String(appLocalized: "\(value) budgets")
        case .profiles: String(appLocalized: "\(value) profiles")
        }
    }

    var symbol: String {
        switch self {
        case .transactions: "list.bullet.rectangle"
        case .categories: "square.grid.2x2"
        case .tags: "tag"
        case .budgets: "chart.bar"
        case .profiles: "person.2"
        }
    }
}

struct DataInventory: Equatable, Sendable {
    let ids: [BackupRecordKind: Set<String>]
    let period: ClosedRange<Date>?
    let bytes: Int

    init(backup: CashlyBackup, bytes: Int) {
        ids = Dictionary(
            uniqueKeysWithValues: BackupRecordKind.allCases.map { ($0, Set($0.ids(in: backup))) })
        let dates = backup.transactions.map(\.date)
        if let first = dates.min(), let last = dates.max() {
            period = first...last
        } else {
            period = nil
        }
        self.bytes = bytes
    }

    static func measuring(_ backup: CashlyBackup) throws -> DataInventory {
        DataInventory(backup: backup, bytes: try backup.encoded().count)
    }

    func count(_ kind: BackupRecordKind) -> Int { ids[kind]?.count ?? 0 }

    var total: Int { BackupRecordKind.allCases.reduce(0) { $0 + count($1) } }

    var isEmpty: Bool { total == 0 }

    var transactions: Int { count(.transactions) }

    var transactionsValue: String { transactions.formatted(.number.locale(.app)) }

    var otherKinds: [BackupRecordKind] { [.categories, .tags, .budgets, .profiles] }

    func chip(_ kind: BackupRecordKind) -> String { kind.count(count(kind)) }

    var recordsText: String {
        BackupRecordKind.allCases.map(chip).formatted(.list(type: .and).locale(.app))
    }

    var periodText: String? {
        guard let period else { return nil }
        let style = Date.FormatStyle(locale: .app).month(.abbreviated).year()
        let first = period.lowerBound.formatted(style)
        let last = period.upperBound.formatted(style)
        return first == last ? first : first + " – " + last
    }

    var sizeText: String {
        String(
            appLocalized:
                "About \(Int64(bytes).formatted(.byteCount(style: .file).locale(.app)))")
    }

    var summaryLine: String {
        [periodText, sizeText].compactMap(\.self).joined(separator: " · ")
    }
}

struct BackupMerge: Equatable, Sendable {
    let file: DataInventory
    let exportedAt: Date
    let added: Int
    let updated: Int

    init(file backup: CashlyBackup, bytes: Int, current: DataInventory?) {
        let file = DataInventory(backup: backup, bytes: bytes)
        var added = 0
        var updated = 0
        for kind in BackupRecordKind.allCases {
            let existing = current?.ids[kind] ?? []
            let incoming = file.ids[kind] ?? []
            let shared = incoming.intersection(existing).count
            updated += shared
            added += incoming.count - shared
        }
        self.file = file
        exportedAt = backup.exportedAt
        self.added = added
        self.updated = updated
    }

    struct Row: Identifiable, Equatable {
        let label: String
        let value: String
        let isHighlighted: Bool
        var id: String { label }
    }

    var title: String { String(appLocalized: "Review the Backup") }

    var doneTitle: String { String(appLocalized: "Backup Imported") }

    var rows: [Row] {
        [
            Row(
                label: String(appLocalized: "In the file"), value: file.recordsText,
                isHighlighted: false),
            Row(
                label: String(appLocalized: "Period"),
                value: file.periodText ?? file.chip(.transactions), isHighlighted: false),
            Row(
                label: String(appLocalized: "On this device"), value: changeText,
                isHighlighted: true),
        ]
    }

    var changeText: String {
        let parts = [
            added > 0 ? String(appLocalized: "\(added) new") : nil,
            updated > 0 ? String(appLocalized: "\(updated) updated") : nil,
        ].compactMap(\.self)
        return parts.isEmpty
            ? String(appLocalized: "Nothing to add") : parts.joined(separator: " · ")
    }

    var message: String {
        let date = exportedAt.formatted(
            Date.FormatStyle(date: .abbreviated, time: .omitted, locale: .app))
        return String(
            appLocalized:
                "Backup from \(date). Nothing is deleted: records already here are updated with the file's version."
        )
    }

    var doneMessage: String {
        String(appLocalized: "\(added + updated) records already show up in the app.")
    }
}
