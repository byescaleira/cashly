import CashlyDomain
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor @Observable
public final class DataModel {
    public static let autoBackupInterval: TimeInterval = 7 * 24 * 60 * 60

    public private(set) var autoBackup: Bool
    public private(set) var lastAutoBackup: Date?
    public private(set) var isWorking = false
    public var error: CashlyError?
    public var message: String?
    public var isExporting = false
    public var isImporting = false
    public var pendingRestore: CashlyBackup?
    var pendingMerge: BackupMerge?
    public var isRestoringBackup = false
    public var backupStep = BackupStep.intro
    public var isErasing = false
    public var eraseStep = EraseStep.review
    public internal(set) var exportedBeforeErase = false
    var inventory: DataInventory?
    public internal(set) var place: BackupPlace
    public internal(set) var cloudState = CloudDriveState.checking
    public internal(set) var savedBackups: [SavedBackup] = []
    private(set) var document: BackupDocument?
    private(set) var exportType: UTType = .json
    private var skipped = 0
    @ObservationIgnored let backup: any BackupRepository
    @ObservationIgnored let defaults: UserDefaults
    @ObservationIgnored let folder: BackupFolder
    @ObservationIgnored let cloud: BackupCloud
    @ObservationIgnored var cloudFolder: BackupFolder?

    public init(
        backup: any BackupRepository, defaults: UserDefaults = .standard,
        folder: BackupFolder = .standard,
        cloud: BackupCloud = .unavailable
    ) {
        self.backup = backup
        self.defaults = defaults
        self.folder = folder
        self.cloud = cloud
        autoBackup = defaults.bool(forKey: Key.autoBackup)
        lastAutoBackup = defaults.object(forKey: Key.lastAutoBackup) as? Date
        place = defaults.string(forKey: Key.place).flatMap(BackupPlace.init(rawValue:)) ?? .device
    }

    var fileName: String {
        let name =
            exportType == .json ? "Cashly " : String(appLocalized: "Cashly transactions") + " "
        return name + Date.now.formatted(.iso8601.year().month().day())
    }

    var autoBackupToggle: Bool {
        get { autoBackup }
        set { Task { await setAutoBackup(newValue) } }
    }

    var autoBackupFooter: String {
        String(appLocalized: "One copy a week, when you open the app.") + " " + placeDescription
    }

    var isShowingMessage: Bool {
        get { message != nil }
        set { if !newValue { message = nil } }
    }

    var isShowingError: Bool {
        get { error != nil }
        set { if !newValue { error = nil } }
    }

    var isExportingFromPage: Bool {
        get { isExporting && !isErasing }
        set { isExporting = newValue }
    }

    var isExportingFromErase: Bool {
        get { isExporting && isErasing }
        set { isExporting = newValue }
    }

    public enum BackupStep: Int, CaseIterable, Sendable {
        case intro, review, done
    }

    public enum EraseStep: Int, CaseIterable, Sendable {
        case review, confirm, done
    }

    func load() async {
        await loadBackups()
        await refreshInventory()
    }

    func refreshInventory() async {
        guard let export = try? await backup.export() else { return }
        let measured = await Task.detached(priority: .utility) {
            try? DataInventory.measuring(export.backup)
        }.value
        inventory = measured ?? inventory
    }

    func startBackupImport() {
        pendingRestore = nil
        pendingMerge = nil
        backupStep = .intro
        isRestoringBackup = true
    }

    func prepareExport(as type: UTType = .json) async {
        await perform {
            let export = try await backup.export()
            let data =
                type == .json
                ? try export.backup.encoded() : Data(export.backup.transactionsCSV.utf8)
            document = BackupDocument(data: data)
            exportType = type
            skipped = export.skipped
            isExporting = true
        }
    }

    public func runAutoBackupIfNeeded(now: Date = .now) async {
        guard autoBackup, !isWorking else { return }
        if let lastAutoBackup, now.timeIntervalSince(lastAutoBackup) < Self.autoBackupInterval {
            return
        }
        await resolveCloud()
        await perform {
            _ = try await saveCopy(on: now)
            lastAutoBackup = now
            defaults.set(now, forKey: Key.lastAutoBackup)
        }
        await refreshSavedBackups()
    }

    func backUpNow(now: Date = .now) async {
        await resolveCloud()
        await perform {
            let skipped = try await saveCopy(on: now)
            let saved =
                isUsingCloud
                ? String(appLocalized: "Backup saved to iCloud Drive.")
                : String(appLocalized: "Backup saved on this device.")
            message = skipped == 0 ? saved : saved + " " + Self.skippedNote(skipped)
        }
        await refreshSavedBackups()
    }

    func resetAutoBackupSchedule() {
        lastAutoBackup = nil
        defaults.removeObject(forKey: Key.lastAutoBackup)
        message = String(
            appLocalized: "The next automatic backup happens the next time Cashly opens.")
    }

    func setAutoBackup(_ isOn: Bool) async {
        autoBackup = isOn
        defaults.set(isOn, forKey: Key.autoBackup)
        await runAutoBackupIfNeeded()
    }

    func finishExport(_ result: Result<URL, any Error>) async {
        document = nil
        guard case .success = result else { return }
        if exportType == .json { try? await backup.recordBackup() }
        if isErasing {
            exportedBeforeErase = true
            return
        }
        let saved =
            exportType == .json
            ? String(appLocalized: "Backup saved.") : String(appLocalized: "Spreadsheet saved.")
        message = skipped == 0 ? saved : saved + " " + Self.skippedNote(skipped)
    }

    func read(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            try review(Data(contentsOf: url))
        } catch {
            self.error =
                error as? CashlyError
                ?? .invalidInput(String(appLocalized: "Couldn't read the file."))
        }
    }

    func review(_ data: Data) throws {
        let file = try CashlyBackup(data: data)
        pendingRestore = file
        pendingMerge = BackupMerge(file: file, bytes: data.count, current: inventory)
        backupStep = .review
    }

    func restore(_ file: CashlyBackup) async {
        await perform {
            try await backup.restore(file)
            backupStep = .done
        }
        await refreshInventory()
    }

    enum Key {
        static let autoBackup = "cashly.data.autoBackup"
        static let lastAutoBackup = "cashly.data.lastAutoBackup"
        static let place = "cashly.data.backupPlace"
    }

    private func saveCopy(on date: Date) async throws -> Int {
        let export = try await backup.export()
        let data = try export.backup.encoded()
        let destination = activeFolder
        try await Task.detached(priority: .utility) {
            try destination.save(data, on: date)
        }.value
        try? await backup.recordBackup()
        return export.skipped
    }

    private static func skippedNote(_ count: Int) -> String {
        String(appLocalized: "Transactions waiting for sync were left out: \(count).")
    }

    func perform(_ operation: () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do { try await operation() } catch {
            self.error = error as? CashlyError ?? .onFetch
        }
    }
}
