import CashlyDomain
import Foundation

struct CashlyScopedRepository: BudgetUseCase, CategoryUseCase, UserUseCase, TagUseCase,
    TransactionUseCase, SnapshotUseCase, DashboardUseCase
{
    let repository: CashlyRepository
    let userID: String?

    private func scope() throws -> String {
        guard let userID else {
            throw CashlyError.invalidInput("Selecione um usuário antes de continuar.")
        }
        return userID
    }

    func snapshot(month: YearMonth?) async throws -> CashlySnapshot {
        guard let userID else {
            return CashlySnapshot(
                users: try await repository.getUsers(), currentUser: nil, categories: [],
                budgets: [], tags: [])
        }
        return try await repository.catalog(userID: userID, month: month)
    }

    func getUsers() async throws -> [User] { try await repository.getUsers() }

    func getUser(id: String) async throws -> User? { try await repository.getUser(id: id) }

    func addUser(id: String, name: String, photo: String) async throws {
        try await repository.addUser(id: id, name: name, photo: photo, contextUserID: userID)
    }

    func removeUser(id: String) async throws {
        guard id == userID else { throw CashlyError.onRemove }
        try await repository.removeUser(id: id)
    }

    func getCategory(id: String) async throws -> CashlyDomain.Category? {
        try await repository.getCategory(id: id, userID: scope())
    }

    func addCategory(id: String, user: String, name: String, color: String, icon: String)
        async throws
    {
        guard user == (try scope()) else { throw CashlyError.onSave }
        try await repository.addCategory(id: id, user: user, name: name, color: color, icon: icon)
    }

    func removeCategory(id: String) async throws {
        try await repository.removeCategory(id: id, userID: scope())
    }

    func getBudget(id: String) async throws -> Budget? {
        try await repository.getBudget(id: id, userID: scope())
    }

    func addBudget(
        id: String, money: Money, category: CashlyDomain.Category, month: YearMonth,
        summary: String
    ) async throws {
        try await repository.addBudget(
            id: id, money: money, category: category, month: month, summary: summary,
            userID: scope())
    }

    func removeBudget(id: String) async throws {
        try await repository.removeBudget(id: id, userID: scope())
    }

    func getTag(id: String) async throws -> Tag? {
        try await repository.getTag(id: id, userID: scope())
    }

    func addTag(id: String, user: String, name: String, color: String, icon: String) async throws {
        guard user == (try scope()) else { throw CashlyError.onSave }
        try await repository.addTag(id: id, user: user, name: name, color: color, icon: icon)
    }

    func removeTag(id: String) async throws {
        try await repository.removeTag(id: id, userID: scope())
    }

    func getTransaction(id: String) async throws -> CashlyDomain.Transaction? {
        try await repository.getTransaction(id: id, userID: scope())
    }

    func addTransaction(
        id: String, participants: [Participant], categoryID: String, kind: TransactionKind,
        money: Money, date: Date, summary: String, status: TransactionStatus,
        splitMode: TransactionSplitMode?, splitValue: Double?, paymentsPlan: Int?,
        tagIDs: Set<String>
    ) async throws {
        try await repository.addTransaction(
            id: id, participants: participants, categoryID: categoryID, kind: kind, money: money,
            date: date, summary: summary, status: status, splitMode: splitMode,
            splitValue: splitValue, paymentsPlan: paymentsPlan, tagIDs: tagIDs, userID: scope())
    }

    func removeTransaction(id: String) async throws {
        try await repository.removeTransaction(id: id, userID: scope())
    }

    func removeTransactions(ids: Set<String>) async throws {
        try await repository.removeTransactions(ids: ids, userID: scope())
    }

    func load(query: TransactionQuery) async throws -> DashboardState {
        try await repository.loadDashboard(userID: scope(), query: query)
    }

    func overview(query: TransactionQuery) async throws -> CashlyOverview {
        try await repository.overview(userID: scope(), query: query)
    }

    func page(query: TransactionQuery, after cursor: TransactionCursor?, limit: Int) async throws
        -> TransactionPage
    {
        try await repository.page(userID: scope(), query: query, after: cursor, limit: limit)
    }

    func trainingData() async throws -> TrainingDataset {
        try await repository.trainingData(userID: scope())
    }

    func datasetRevision() async throws -> String {
        try await repository.datasetRevision(userID: scope())
    }

    func resolveBudgetConflict(keeping budgetID: String) async throws {
        try await repository.resolveBudgetConflict(keeping: budgetID, userID: scope())
    }
}
