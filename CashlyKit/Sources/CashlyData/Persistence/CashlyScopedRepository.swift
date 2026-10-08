import CashlyDomain
import Foundation

/// Immutable user context: sharing the actor never shares a window's selection.
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
    func snapshot(month: Int?) async throws -> CashlySnapshot {
        guard let userID else {
            return CashlySnapshot(
                users: try await repository.getUsers(), currentUser: nil, categories: [],
                budgets: [],
                tags: [], transactions: [], participants: [])
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
    func removeUsers() async throws { throw CashlyError.onRemove }
    func getCategory(id: String) async throws -> CashlyDomain.Category? {
        try await repository.getCategory(id: id, userID: scope())
    }
    func getCategories() async throws -> [CashlyDomain.Category] { try await snapshot().categories }
    func getCategories(ids: [String]?, users: [String]?) async throws -> [CashlyDomain.Category] {
        let scopeID = try scope()
        if let users, !users.contains(scopeID) { return [] }
        let records = try await getCategories()
        return records.filter { ids == nil || ids?.contains($0.id) == true }
    }
    func addCategory(id: String, user: String, name: String, color: String, icon: String)
        async throws
    {
        let scopeID = try scope()
        guard user == scopeID else { throw CashlyError.onSave }
        try await repository.addCategory(id: id, user: user, name: name, color: color, icon: icon)
    }
    func removeCategory(id: String) async throws {
        try await repository.removeCategory(id: id, userID: scope())
    }
    func removeCategories() async throws { try await repository.removeCategories(userID: scope()) }
    func getBudget(id: String) async throws -> Budget? {
        try await repository.getBudget(id: id, userID: scope())
    }
    func getBudgets() async throws -> [Budget] { try await snapshot().budgets }
    func getBudgets(categories: [String]?, date: Date?) async throws -> [Budget] {
        try await getBudgets().filter {
            (categories == nil || categories?.contains($0.category.id) == true)
                && (date == nil || $0.date == date?.timeIntervalSince1970.yearMonth)
        }
    }
    func addBudget(
        id: String, amount: Double, category: CashlyDomain.Category, date: Int, summary: String
    ) async throws {
        try await repository.addBudget(
            id: id, amount: amount, category: category, date: date, summary: summary,
            userID: scope())
    }
    func removeBudget(id: String) async throws {
        try await repository.removeBudget(id: id, userID: scope())
    }
    func removeBudgets() async throws { try await repository.removeBudgets(userID: scope()) }
    func getTag(id: String) async throws -> Tag? {
        try await repository.getTag(id: id, userID: scope())
    }
    func getTags() async throws -> [Tag] { try await snapshot().tags }
    func getTags(users: [String]?) async throws -> [Tag] {
        let scopeID = try scope()
        guard users == nil || users?.contains(scopeID) == true else { return [] }
        return try await getTags()
    }
    func addTag(id: String, user: String, name: String, color: String, icon: String) async throws {
        guard user == (try scope()) else { throw CashlyError.onSave }
        try await repository.addTag(id: id, user: user, name: name, color: color, icon: icon)
    }
    func removeTag(id: String) async throws {
        try await repository.removeTag(id: id, userID: scope())
    }
    func removeTags() async throws { try await repository.removeTags(userID: scope()) }
    func getTransaction(id: String) async throws -> CashlyDomain.Transaction? {
        try await repository.getTransaction(id: id, userID: scope())
    }
    func getTransactions() async throws -> [CashlyDomain.Transaction] {
        try await trainingData().transactions
    }
    func getTransactions(
        categories: [String]?, tags: [String]?, statuses: [Int]?, participants: [String]?,
        date: Date?
    ) async throws -> [CashlyDomain.Transaction] {
        let records = try await getTransactions()
        return records.filter { record in
            (categories == nil || categories?.contains(record.category.id) == true)
                && (tags == nil || tags?.contains { record.tagIDs.contains($0) } == true)
                && (statuses == nil || statuses?.contains(record.status.rawValue) == true)
                && (participants == nil
                    || participants?.contains { id in
                        record.participants.contains { $0.user.id == id }
                    }
                        == true)
                && (date == nil || record.occurs(in: date?.timeIntervalSince1970.yearMonth ?? 0))
        }
    }
    func addTransaction(
        id: String, participants: [Participant], categoryID: String, kind: TransactionKind,
        money: Money, date: TimeInterval,
        summary: String, status: TransactionStatus, splitMode: TransactionSplitMode?,
        splitValue: Double?, paymentsPlan: Int?, tagIDs: Set<String>
    ) async throws {
        try await repository.addTransaction(
            id: id, participants: participants, categoryID: categoryID, kind: kind, money: money,
            date: date,
            summary: summary, status: status, splitMode: splitMode, splitValue: splitValue,
            paymentsPlan: paymentsPlan, tagIDs: tagIDs, userID: scope())
    }
    func removeTransaction(id: String) async throws {
        try await repository.removeTransaction(id: id, userID: scope())
    }
    func removeTransactions(ids: Set<String>) async throws {
        try await repository.removeTransactions(ids: ids, userID: scope())
    }
    func removeTransactions() async throws {
        try await repository.removeTransactions(userID: scope())
    }
    func load(query: TransactionQuery) async throws -> DashboardState {
        try await repository.loadDashboard(userID: scope(), query: query)
    }
    func overview(query: TransactionQuery) async throws -> CashlyOverview {
        try await repository.overview(userID: scope(), query: query)
    }
    func page(query: TransactionQuery, after cursor: TransactionCursor?, limit: Int) async throws
        -> TransactionPage
    { try await repository.page(userID: scope(), query: query, after: cursor, limit: limit) }
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
