import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class DataModel {
    public private(set) var isWorking = false
    public var error: CashlyError?
    public var message: String?
    public var isExporting = false
    public var isImporting = false
    public var isConfirmingErase = false
    public var pendingRestore: CashlyBackup?
    private(set) var document: BackupDocument?
    private var skipped = 0
    @ObservationIgnored private let backup: any BackupRepository
    @ObservationIgnored private let intelligence: any IntelligenceService

    public init(backup: any BackupRepository, intelligence: any IntelligenceService) {
        self.backup = backup
        self.intelligence = intelligence
    }

    var fileName: String { "Cashly " + Date.now.formatted(.iso8601.year().month().day()) }

    var isShowingMessage: Bool {
        get { message != nil }
        set { if !newValue { message = nil } }
    }

    var isShowingError: Bool {
        get { error != nil }
        set { if !newValue { error = nil } }
    }

    var isConfirmingRestore: Bool {
        get { pendingRestore != nil }
        set { if !newValue { pendingRestore = nil } }
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

    func prepareExport() async {
        await perform {
            let export = try await backup.export()
            document = BackupDocument(data: try export.backup.encoded())
            skipped = export.skipped
            isExporting = true
        }
    }

    func finishExport(_ result: Result<URL, any Error>) {
        document = nil
        guard case .success = result else { return }
        message =
            skipped == 0
            ? "Backup salvo."
            : "Backup salvo. Transações aguardando sincronização ficaram de fora: \(skipped)."
    }

    func read(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let isScoped = url.startAccessingSecurityScopedResource()
            defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
            pendingRestore = try CashlyBackup(data: Data(contentsOf: url))
        } catch {
            self.error = error as? CashlyError ?? .invalidInput("Não foi possível ler o arquivo.")
        }
    }

    func restore(_ file: CashlyBackup) async {
        await perform {
            try await backup.restore(file)
            message =
                "Backup importado: " + counted(file.recordCount, "registro", "registros") + "."
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
