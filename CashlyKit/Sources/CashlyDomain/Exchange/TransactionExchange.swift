import Foundation

public struct TransactionExchange: Hashable, Sendable {
    public var currencyCode: String
    public var money: Money
    public var rate: Decimal
    public var date: Date

    public init(currencyCode: String, money: Money, rate: Decimal, date: Date) {
        self.currencyCode = currencyCode
        self.money = money
        self.rate = rate
        self.date = date
    }

    public func converted() throws -> Money {
        try money.converted(by: rate)
    }
}
