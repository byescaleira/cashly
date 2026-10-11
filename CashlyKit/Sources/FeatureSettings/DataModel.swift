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
    public var isConfirmingErase = false
    public var pendingRestore: CashlyBackup?
    public var isRestoringBackup = false
    public var backupStep = BackupStep.intro
    private(set) var document: BackupDocument?
    private(set) var exportType: UTType = .json
    private var skipped = 0
    @ObservationIgnored private let backup: any BackupRepository
    @ObservationIgnored private let intelligence: any IntelligenceService
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let folder: BackupFolder

    public init(
        backup: any BackupRepository, intelligence: any IntelligenceService,
        defaults: UserDefaults = .standard, folder: BackupFolder = .standard
    ) {
        self.backup = backup
        self.intelligence = intelligence
        self.defaults = defaults
        self.folder = folder
        autoBackup = defaults.bool(forKey: Key.autoBackup)
        lastAutoBackup = defaults.object(forKey: Key.lastAutoBackup) as? Date
    }

    var fileName: String {
        let name = exportType == .json ? "Cashly " : "Cashly transações "
        return name + Date.now.formatted(.iso8601.year().month().day())
    }

    var autoBackupToggle: Bool {
        get { autoBackup }
        set { Task { await setAutoBackup(newValue) } }
    }

    var autoBackupFooter: String {
        let place =
            "Uma cópia por semana, ao abrir o app. As 5 mais recentes ficam em Arquivos, na pasta Cashly › Backups."
        guard autoBackup, let lastAutoBackup else { return place }
        return place + " Última: "
            + lastAutoBackup.formatted(date: .abbreviated, time: .shortened) + "."
    }

    var isShowingMessage: Bool {
        get { message != nil }
        set { if !newValue { message = nil } }
    }

    var isShowingError: Bool {
        get { error != nil }
        set { if !newValue { error = nil } }
    }

    public enum BackupStep: Int, CaseIterable, Sendable {
        case intro, review, done
    }

    func startBackupImport() {
        pendingRestore = nil
        backupStep = .intro
        isRestoringBackup = true
    }

    func description(of backup: CashlyBackup) -> String {
        let counts = [
            counted(backup.users.count, "usuário", "usuários"),
            counted(backup.categories.count, "categoria", "categorias"),
            counted(backup.tags.count, "tag", "tags"),
            counted(backup.budgets.count, "orçamento", "orçamentos"),
        ].joined(separator: ", ")
        let transactions = counted(backup.transactions.count, "transação", "transações")
        return counts + " e " + transactions
            + ". Registros com o mesmo identificador são substituídos pelos do arquivo."
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
        await perform {
            let export = try await backup.export()
            try folder.save(export.backup.encoded(), on: now)
            lastAutoBackup = now
            defaults.set(now, forKey: Key.lastAutoBackup)
        }
    }

    func setAutoBackup(_ isOn: Bool) async {
        autoBackup = isOn
        defaults.set(isOn, forKey: Key.autoBackup)
        await runAutoBackupIfNeeded()
    }

    func finishExport(_ result: Result<URL, any Error>) {
        document = nil
        guard case .success = result else { return }
        let saved = exportType == .json ? "Backup salvo." : "Planilha salva."
        message =
            skipped == 0
            ? saved
            : saved + " Transações aguardando sincronização ficaram de fora: \(skipped)."
    }

    func read(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            pendingRestore = try CashlyBackup(data: Data(contentsOf: url))
            backupStep = .review
        } catch {
            self.error = error as? CashlyError ?? .invalidInput("Não foi possível ler o arquivo.")
        }
    }

    func restore(_ file: CashlyBackup) async {
        await perform {
            try await backup.restore(file)
            backupStep = .done
        }
    }

    func eraseAll() async {
        await perform {
            for userID in try await backup.eraseAll() {
                try? await intelligence.clean(userID: userID)
            }
            message = "Todos os dados foram apagados."
        }
    }

    private enum Key {
        static let autoBackup = "cashly.data.autoBackup"
        static let lastAutoBackup = "cashly.data.lastAutoBackup"
    }

    private func counted(_ count: Int, _ singular: String, _ plural: String) -> String {
        "\(count) " + (count == 1 ? singular : plural)
    }

    private func perform(_ operation: () async throws -> Void) async {
        guard !isWorking else { return }
        isWorking = true
        defer { isWorking = false }
        do { try await operation() } catch {
            self.error = error as? CashlyError ?? .onFetch
        }
    }
}
