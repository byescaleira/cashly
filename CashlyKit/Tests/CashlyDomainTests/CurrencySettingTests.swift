import CashlyDomain
import Testing

struct CurrencySettingTests {
    @Test func onlySupportedCodesAreAccepted() {
        let setting = CurrencySetting()
        #expect(setting.code == "BRL")
        setting.code = "EUR"
        #expect(setting.code == "EUR")
        setting.code = "JPY"
        #expect(setting.code == "EUR")
        #expect(CurrencySetting.isSupported("USD"))
        #expect(!CurrencySetting.isSupported("XYZ"))
    }
}
