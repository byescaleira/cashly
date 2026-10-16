import Foundation

public struct CurrencyEstimate: Hashable, Sendable {
    public let currencyCode: String
    public let money: Money
    public let ownerMoney: Money?
    public let rate: Decimal
    public let date: Date

    public init(
        currencyCode: String, money: Money, ownerMoney: Money? = nil, rate: Decimal, date: Date
    ) {
        self.currencyCode = currencyCode
        self.money = money
        self.ownerMoney = ownerMoney
        self.rate = rate
        self.date = date
    }
}
