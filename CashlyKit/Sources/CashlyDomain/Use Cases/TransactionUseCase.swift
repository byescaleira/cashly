import Foundation

public protocol TransactionUseCase: Sendable {
    func getTransaction(id: String) async throws -> Transaction?
    func getTransactions() async throws -> [Transaction]
    func getTransactions(
        categories: [String]?,
        tags: [String]?,
        statuses: [Int]?,
        participants: [String]?,
        date: Date?
    ) async throws -> [Transaction]
    func removeTransaction(id: String) async throws
    func removeTransactions(ids: Set<String>) async throws
    func removeTransactions() async throws
    func addTransaction(
        id: String,
        participants: [Participant],
        categoryID: String,
        kind: TransactionKind,
        money: Money,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?,
        tagIDs: Set<String>
    ) async throws
}
