import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

@testable import FeatureSettings

@MainActor
struct TrainingRulesTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")

    private func models(transactions: Int) async throws -> (
        SessionModel, FinanceModel, IntelligenceModel
    ) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        let category = Category(id: "c", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        try await repositories.categories.save(category)
        let month = try #require(YearMonth(rawValue: 202_601))
        for index in 0..<transactions {
            try await repositories.transactions.save(
                Transaction(
                    id: "t\(index)", participants: [], category: category,
                    money: Money(minorUnits: 100), date: month.startDate, summary: "Compra",
                    status: .settled, splitMode: nil, splitValue: nil, paymentsPlan: nil))
        }
        let session = SessionModel(provider: database, preference: .disabled)
        await session.selectUser(id: owner.id)
        session.filter.startDate = month.startDate
        let finance = FinanceModel(session: session)
        await finance.load()
        let intelligence = IntelligenceModel(
            service: LocalIntelligenceService(
                directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
            ),
            session: session)
        return (session, finance, intelligence)
    }

    @Test func trainingNeedsAtLeastTwoTransactions() async throws {
        let (session, finance, intelligence) = try await models(transactions: 1)
        #expect(!intelligence.canTrain(with: session, finance: finance))
        let (moreSession, moreFinance, moreIntelligence) = try await models(transactions: 2)
        #expect(moreIntelligence.canTrain(with: moreSession, finance: moreFinance))
    }

    @Test func untrainedKindsHaveNoInfo() async throws {
        let (_, _, intelligence) = try await models(transactions: 0)
        #expect(CashlyIntelligence.allCases.allSatisfy { intelligence.info(for: $0) == nil })
    }

    @Test func deviceStatusDescribesThisDevice() {
        let status = DeviceStatus.current
        #expect(status.processors > 0)
        #expect(!status.memory.isEmpty)
        #expect(!status.thermalState.isEmpty)
    }
}
