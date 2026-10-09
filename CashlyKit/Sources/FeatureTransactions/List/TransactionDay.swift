import CashlyDomain
import Foundation

public struct TransactionDay: Identifiable {
    public let date: Date
    public let items: [CashlyDomain.Transaction]

    public var id: Date { date }
}
