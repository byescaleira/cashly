import FeatureCore
import Testing

struct CurrencyInputTests {
    @Test(arguments: [
        ("1", 0.01), ("1234", 12.34), ("R$ 1.234,56", 1234.56), ("", 0), ("abc", 0),
        ("R$ 0,005", 0.05),
    ])
    func digitsAreCents(typed: String, amount: Double) {
        #expect(CurrencyInput.amount(typed: typed) == amount)
    }

    @Test func longInputKeepsTheLastDigits() {
        let typed = String(repeating: "9", count: 20)
        #expect(CurrencyInput.amount(typed: typed) == 99_999_999_999.99)
    }

    @Test func cleanKeepsOnlySignificantDigits() {
        #expect(CurrencyInput.clean("0012a3,4") == "1234")
        #expect(CurrencyInput.clean("000") == "")
        #expect(CurrencyInput.clean(String(repeating: "9", count: 20)).count == 13)
        #expect(CurrencyInput.digits(for: 123.45) == "12345")
        #expect(CurrencyInput.digits(for: 0) == "")
    }
}
