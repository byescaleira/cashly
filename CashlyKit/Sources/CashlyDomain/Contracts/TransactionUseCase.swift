import Foundation

public protocol TransactionUseCase: Sendable {
    func getTransaction(id: String) async throws -> Transaction?
    func removeTransaction(id: String) async throws
    func removeTransactions(ids: Set<String>) async throws
    func addTransaction(
        id: String, participants: [Participant], categoryID: String, kind: TransactionKind,
        money: Money, date: Date, summary: String, status: TransactionStatus,
        splitMode: TransactionSplitMode?, splitValue: Double?, paymentsPlan: Int?,
        tagIDs: Set<String>
    ) async throws
}
