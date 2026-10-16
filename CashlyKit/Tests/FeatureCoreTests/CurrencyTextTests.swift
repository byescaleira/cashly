import CashlyDomain
import FeatureCore
import Foundation
import Testing

@MainActor
struct CurrencyTextTests {
    @Test func zeroDecimalCurrenciesTypeWholeUnits() {
        #expect(CurrencyInput.fractionDigits(for: "JPY") == 0)
        #expect(CurrencyInput.fractionDigits(for: "BRL") == 2)
        #expect(CurrencyInput.amount(typed: "1500", fractionDigits: 0) == 1500)
        #expect(CurrencyInput.amount(typed: "1500") == 15)
        #expect(CurrencyInput.digits(for: 1500, fractionDigits: 0) == "1500")
        #expect(CurrencyInput.digits(for: 15, fractionDigits: 2) == "1500")
    }

    @Test func pickerSectionsPutSuggestionsFirstAndSearch() {
        let codes = ["USD", "JPY", "BRL", "EUR"]
        let groups = CurrencyText.sections(codes: codes, suggested: ["BRL", "XXX"], query: "")
        #expect(groups.count == 2)
        #expect(groups[0].codes == ["BRL"])
        #expect(Set(groups[1].codes) == ["USD", "JPY", "EUR"])
        let search = CurrencyText.sections(codes: codes, suggested: ["BRL"], query: "jpy")
        #expect(search.map(\.codes) == [["JPY"]])
        #expect(CurrencyText.sections(codes: codes, suggested: [], query: "zzz").isEmpty)
        #expect(CurrencyText.label("USD").hasSuffix("· USD"))
    }

    @Test func convertedTransactionsAnnounceTheOriginal() {
        let user = User(id: "u", name: "Ana")
        let category = Category(id: "c", user: user, name: "Food", color: "#000000", icon: "fork")
        var transaction = Transaction(
            id: "t", participants: [], category: category, money: Money(minorUnits: 5265),
            date: .now, summary: "Sushi", status: .settled, splitMode: nil, splitValue: nil,
            paymentsPlan: nil)
        #expect(!transaction.isConverted)
        #expect(transaction.originalAmount == nil)
        transaction.exchange = TransactionExchange(
            currencyCode: "JPY", money: Money(minorUnits: 150_000), rate: 1, date: .now)
        #expect(transaction.displayAmount.hasPrefix("≈"))
        #expect(transaction.originalAmount != nil)
        #expect(transaction.amountAccessibilityLabel != transaction.money.formatted)
    }
}
