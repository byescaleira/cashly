import CashlyDomain
import Foundation

extension Money {
    public var formatted: String {
        decimalValue.formatted(.currency(code: Money.currencyCode).locale(.app))
    }
}
