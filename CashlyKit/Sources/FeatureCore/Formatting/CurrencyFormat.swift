import CashlyDomain
import Foundation

extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    public static var brl: Self { .currency(code: Money.currencyCode) }
}
