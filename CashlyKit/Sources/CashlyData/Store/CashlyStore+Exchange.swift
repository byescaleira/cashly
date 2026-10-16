import CashlyDomain
import Foundation

extension CashlyStore {
    func estimatedBudget(_ budget: Budget) throws -> Budget {
        guard let correction = CurrencySetting.shared.correctionRate(from: budget.currencyCode)
        else { return budget }
        var value = budget
        value.money = try budget.money.converted(by: correction.rate)
        value.currencyCode = correction.target
        value.estimate = CurrencyEstimate(
            currencyCode: budget.currencyCode, money: budget.money, rate: correction.rate,
            date: correction.date)
        return value
    }

    func estimatedTransaction(_ transaction: CashlyDomain.Transaction) throws
        -> CashlyDomain.Transaction
    {
        guard
            let correction = CurrencySetting.shared.correctionRate(
                from: transaction.currencyCode)
        else { return transaction }
        var value = transaction
        value.money = try transaction.money.converted(by: correction.rate)
        let parts =
            [transaction.ownerMoney ?? transaction.money]
            + transaction.participants.map { $0.allocatedMoney ?? .zero }
        let shares = ProportionalSplit.distribute(value.money, like: parts)
        for index in value.participants.indices {
            value.participants[index].allocatedMoney = shares[index + 1]
        }
        value.ownerMoney = shares[0]
        if !value.participants.isEmpty { value.splitValue = shares[0].doubleValue }
        value.currencyCode = correction.target
        value.estimate = CurrencyEstimate(
            currencyCode: transaction.currencyCode, money: transaction.money,
            ownerMoney: transaction.ownerMoney, rate: correction.rate, date: correction.date)
        return value
    }

    func exchange(of row: TransactionEntity) -> TransactionExchange? {
        guard let code = row.paidCurrencyCode, let paid = row.paidMinorUnits,
            let rate = row.exchangeRate, let date = row.exchangeRateDate,
            let decimal = Decimal(string: rate, locale: Locale(identifier: "en_US_POSIX"))
        else { return nil }
        return TransactionExchange(
            currencyCode: code, money: Money(minorUnits: paid), rate: decimal,
            date: Date(timeIntervalSince1970: date))
    }

    func apply(_ exchange: TransactionExchange?, to entity: TransactionEntity) throws {
        guard let exchange else {
            entity.paidCurrencyCode = nil
            entity.paidMinorUnits = nil
            entity.exchangeRate = nil
            entity.exchangeRateDate = nil
            return
        }
        guard exchange.currencyCode.count == 3, exchange.money.minorUnits > 0, exchange.rate > 0,
            exchange.rate.isFinite, exchange.date.timeIntervalSince1970.isFinite
        else { throw CashlyError.onSave }
        entity.paidCurrencyCode = exchange.currencyCode
        entity.paidMinorUnits = exchange.money.minorUnits
        entity.exchangeRate = NSDecimalNumber(decimal: exchange.rate).description(
            withLocale: Locale(identifier: "en_US_POSIX"))
        entity.exchangeRateDate = exchange.date.timeIntervalSince1970
    }
}
