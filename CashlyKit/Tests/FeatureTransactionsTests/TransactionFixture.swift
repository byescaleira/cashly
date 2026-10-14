import CashlyData
import CashlyDomain
import FeatureCore
import FeatureTransactions
import Foundation

@MainActor
struct TransactionFixture {
    let owner = User(id: "owner", name: "Perfil", photo: "1")
    let friend = User(id: "friend", name: "Amigo", photo: "2")
    let database: CashlyDatabase
    let repositories: Repositories
    let category: CashlyDomain.Category
    let january: Date

    init() async throws {
        database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: nil).users.save(friend)
        repositories = database.repositories(for: owner.id)
        category = Category(
            id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        try await repositories.categories.save(category)
        january = YearMonth(year: 2026, month: 1)?.startDate ?? .now
    }

    func expense(
        _ id: String, cents: Int64, offset: TimeInterval = 0,
        category: CashlyDomain.Category? = nil,
        status: TransactionStatus = .settled, tagIDs: Set<String> = [],
        kind: TransactionKind = .expense
    ) -> CashlyDomain.Transaction {
        Transaction(
            id: id, participants: [], category: category ?? self.category,
            money: Money(minorUnits: cents), date: january.addingTimeInterval(offset),
            summary: "Compra", status: status, splitMode: nil, splitValue: nil, paymentsPlan: nil,
            tagIDs: tagIDs, kind: kind)
    }

    func list() async -> (SessionModel, FinanceModel, TransactionListModel) {
        let session = await session()
        let finance = FinanceModel(session: session)
        return (session, finance, TransactionListModel(session: session, finance: finance))
    }

    func session() async -> SessionModel {
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        session.filter.startDate = january
        return session
    }
}
