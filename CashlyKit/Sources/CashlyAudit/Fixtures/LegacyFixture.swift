import CashlyData
import CashlyDomain
import Foundation
import SwiftData

enum LegacyFixture {
    static let summary =
        "LEGACY_CREATED users=2 categories=1 budgets=1 tags=1 transactions=1 participants=1 amount=100.01"

    @MainActor static func create(at url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else {
            throw CashlyError.invalidInput("O arquivo já existe.")
        }
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let schema = Schema(CashlySchemaV1.models)
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        let context = ModelContext(try ModelContainer(for: schema, configurations: configuration))
        for id in ["owner", "friend"] {
            context.insert(CashlySchemaV1.UserEntity(id: id, name: id, photo: "person"))
        }
        context.insert(
            CashlySchemaV1.CategoryEntity(
                id: "category", user: "owner", name: "Mercado", color: "0099FF", icon: "cart"))
        context.insert(
            CashlySchemaV1.BudgetEntity(
                id: "budget", amount: 100.01, category: "category", date: 202601, summary: "Mensal")
        )
        context.insert(
            CashlySchemaV1.TagEntity(
                id: "tag", user: "owner", name: "Feira", color: "0099FF", icon: "tag"))
        context.insert(
            CashlySchemaV1.ParticipantEntity(
                id: "party", user: "friend", name: "friend", photo: "person", splitMode: 0,
                splitValue: 2, status: 0, transaction: "transaction"))
        context.insert(
            CashlySchemaV1.TransactionEntity(
                id: "transaction", participants: ["party"], budget: "budget", amount: 100.01,
                date: try YearMonth.audit(202601).startDate.timeIntervalSince1970,
                summary: "Compra Feira", status: 0, splitMode: 0, splitValue: 50.005,
                paymentsPlan: 3))
        try context.save()
    }
}
