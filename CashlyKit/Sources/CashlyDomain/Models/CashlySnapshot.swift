import Foundation

public struct CashlySnapshot: Sendable {
    public let users: [User]
    public let currentUser: User?
    public let categories: [Category]
    public let budgets: [Budget]
    public let tags: [Tag]
    public let transactions: [Transaction]
    public let participants: [Participant]
    public var pendingReferences: Int = 0
    public init(
        users: [User], currentUser: User?, categories: [Category], budgets: [Budget], tags: [Tag],
        transactions: [Transaction], participants: [Participant]
    ) {
        self.users = users
        self.currentUser = currentUser
        self.categories = categories
        self.budgets = budgets
        self.tags = tags
        self.transactions = transactions
        self.participants = participants
    }
}
public protocol SnapshotUseCase: Sendable {
    func snapshot(month: Int?) async throws -> CashlySnapshot
}

extension SnapshotUseCase {
    public func snapshot() async throws -> CashlySnapshot { try await snapshot(month: nil) }
}
