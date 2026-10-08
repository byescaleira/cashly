import CashlyData
import CashlyDomain
import Foundation
import Testing

struct TestDatabase {
    let database: CashlyDatabase
    let owner = User(id: "owner", name: "Perfil", photo: "1")
    let friend = User(id: "friend", name: "Amigo", photo: "2")
    let category: CashlyDomain.Category

    init() async throws {
        database = try CashlyDatabase.open(inMemory: true)
        category = Category(
            id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        let users = database.repositories(for: nil).users
        try await users.save(owner)
        try await users.save(friend)
        try await repositories.categories.save(category)
    }

    var repositories: Repositories { database.repositories(for: owner.id) }

    var friendRepositories: Repositories { database.repositories(for: friend.id) }

    func month(_ rawValue: Int) throws -> YearMonth {
        try #require(YearMonth(rawValue: rawValue))
    }

    func transaction(
        _ id: String, cents: Int64, month rawMonth: Int = 202_601, plan: Int? = nil,
        kind: TransactionKind = .expense, status: TransactionStatus = .settled,
        participants: [Participant] = [], splitValue: Double? = nil, tags: Set<String> = []
    ) throws -> Transaction {
        Transaction(
            id: id, participants: participants, category: category,
            money: Money(minorUnits: cents), date: try month(rawMonth).startDate,
            summary: "Registro " + id, status: status,
            splitMode: participants.isEmpty ? nil : .equal, splitValue: splitValue,
            paymentsPlan: plan, tagIDs: tags, kind: kind)
    }

    func budget(_ id: String, cents: Int64, month rawMonth: Int) throws -> Budget {
        Budget(
            id: id, money: Money(minorUnits: cents), category: category,
            month: try month(rawMonth), summary: "Planejamento")
    }

    func saveFlowRecords() async throws {
        let transactions = repositories.transactions
        try await transactions.save(transaction("expense", cents: 10001))
        try await transactions.save(transaction("installments", cents: 10001, plan: 3))
        try await transactions.save(transaction("income", cents: 120_005, kind: .income))
    }
}
