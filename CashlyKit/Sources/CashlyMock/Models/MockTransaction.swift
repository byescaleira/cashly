import CashlyDomain
import CashlyResource
import Foundation

extension CashlyDomain.Transaction {
    public static var mock: CashlyDomain.Transaction {
        mocks.first
            ?? CashlyDomain.Transaction(
                id: "preview-transaction", participants: [], category: Budget.mock.category,
                money: Money(minorUnits: 5000),
                date: Date.now.timeIntervalSince1970, summary: "Compra de exemplo",
                status: .settled,
                splitMode: nil, splitValue: nil, paymentsPlan: nil)
    }

    public static var mocks: [CashlyDomain.Transaction] {
        let transactions: [CashlyDomain.Transaction] =
            (try? CashlyResourceFile.transactions.decoded()) ?? []
        return transactions.map { record in
            var result = record
            result.category = record.category
            result.ownerID = record.category.user.id
            result.tagIDs = Set(
                Tag.mocks.filter {
                    $0.user.id == result.ownerID
                        && TagSuggestion.matches($0.name, in: result.summary)
                }.map(\.id))
            result.participants = record.participants.filter { $0.user.id != result.ownerID }
            if !result.participants.isEmpty {
                result.splitMode = .equal
                for index in result.participants.indices {
                    result.participants[index].splitMode = .equal
                    result.participants[index].splitValue = Double(result.participants.count + 1)
                }
                if let allocation = try? TransactionAllocation.resolve(
                    total: result.money, participants: result.participants)
                {
                    result.splitValue = allocation.owner.doubleValue
                    result.ownerMoney = allocation.owner
                    for index in result.participants.indices {
                        result.participants[index].allocatedMoney =
                            allocation.participants[result.participants[index].id]
                    }
                }
            } else {
                result.splitMode = nil
                result.splitValue = nil
            }
            return result
        }.sorted(by: \.date, using: >)
    }
}
